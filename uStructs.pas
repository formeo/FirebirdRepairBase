unit uStructs;

interface

uses
  SysUtils, Classes;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;

type
  SChar = Shortint;
  SShort = Smallint;
  UShort = Word;
  SLong = Longint;
  ULong = LongWord;
  UChar = type Byte;

  TPag = packed record
    pag_type: SChar;       // 0x00 - Тип страницы
    pag_flags: UChar;      // 0x01 - Флаги страницы (unsigned!)
    pag_checksum: UShort;  // 0x02-0x03 - Контрольная сумма (не используется, 12345)
    pag_generation: ULong; // 0x04-0x07 - Номер поколения страницы
    pag_scn: ULong;        // 0x08-0x0b - SCN (Sequence Number), использовался WAL
    reserved: ULong;       // 0x0c-0x0f - Зарезервировано
  end;

  THdr = packed record
    hdr_header: TPag;              // 0x00-0x0F - Стандартный заголовок
    hdr_page_size: UShort;         // 0x10-0x11 - Размер страницы
    hdr_ods_version: UShort;       // 0x12-0x13 - Major ODS version
    hdr_pages: SLong;              // 0x14-0x17 - Номер первой Pointer Page для RDB$PAGES
    hdr_next_page: ULong;          // 0x18-0x1B - Номер следующей страницы (многофайловая БД)
    hdr_oldest_transaction: SLong; // 0x1C-0x1F - Самая старая активная транзакция
    hdr_oldest_active: SLong;      // 0x20-0x23 - Самая старая активная (на момент старта)
    hdr_next_transaction: SLong;   // 0x24-0x27 - Номер следующей транзакции
    hdr_sequence: UShort;          // 0x28-0x29 - Номер файла в многофайловой БД
    hdr_flags: UShort;             // 0x2A-0x2B - Флаги базы данных
    hdr_creation_date: array [0 .. 1] of SLong; // 0x2C-0x33 - Дата создания
    hdr_attachment_id: SLong;      // 0x34-0x37 - ID следующего подключения
    hdr_shadow_count: SLong;       // 0x38-0x3B - Счетчик синхронизации теней
    hdr_implementation: SShort;    // 0x3C-0x3D - Платформа создания
    hdr_ods_minor: UShort;         // 0x3E-0x3F - Minor ODS version
    hdr_ods_minor_original: UShort;// 0x40-0x41 - Original minor ODS version
    hdr_end: UShort;               // 0x42-0x43 - Конец данных hdr_data
    hdr_page_buffers: ULong;       // 0x44-0x47 - Размер кэша страниц
    hdr_bumped_transaction: SLong; // 0x48-0x4B - Зарезервировано/устаревшее
    hdr_oldest_snapshot: SLong;    // 0x4C-0x4F - Самый старый снэпшот
    hdr_backup_pages: SLong;       // 0x50-0x53 - Количество заблокированных страниц для бэкапа
    hdr_misc: array [0 .. 2] of SLong; // 0x54-0x5F - Исправлено: было [0..3], теперь [0..2] (3 элемента)
  end;

  THdrPage = packed record
    fix_data: THdr;
    var_data: array [0 .. MAX_PAGE_SIZE - 1 - SizeOf(THdr)] of Byte;
  end;

  // Not IB related
  EGDBError = class(Exception);

  PGDBFile = ^TGDBFileInfo;

  TGDBFileInfo = record
    Header: THdr;
    Filename: ShortString;
    ContinuationFile: ShortString;
    FirstLogicalPage: LongWord;
    LastLogicalPage: LongWord;
    TotalPages: LongWord;
  end;

  TGDBInfo = class
  private
    FList: TList;
    FFilename: string;
    procedure GetDBFiles;
    function GetItem(I: Integer): TGDBFileInfo;
  public
    constructor Create(const AFilename: string);
    destructor Destroy; override;
    function Count: Integer;
    property Items[I: Integer]: TGDBFileInfo read GetItem; default;
  end;

implementation

{ TGDBInfo }

function TGDBInfo.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TGDBInfo.Create(const AFilename: string);
begin
  inherited Create;
  FList := TList.Create;
  FFilename := AFilename;
  GetDBFiles;
end;

destructor TGDBInfo.Destroy;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    FreeMem(FList[I]);
    FList.Delete(I);
  end;
  inherited;
end;

procedure TGDBInfo.GetDBFiles;
var
  FS: TFileStream;
  HeaderPage: THdrPage;
  NewFile: PGDBFile;
  CurrentFilename: ShortString;
  FilenameSize: Byte;
  StartPage: LongWord;
  SourceDir: string;
  DataOffset: Integer;
begin
  if not FileExists(FFilename) then
    raise EGDBError.Create('File does not exist - ' + FFilename);

  SourceDir := ExtractFilePath(FFilename);
  if SourceDir = '' then
    SourceDir := IncludeTrailingBackSlash(GetCurrentDir);
  StartPage := 0;
  CurrentFilename := SourceDir + ExtractFilename(FFilename);
  repeat
    FS := TFileStream.Create(CurrentFilename, fmOpenRead or fmShareDenyNone);
    try
      GetMem(NewFile, SizeOf(TGDBFileInfo));
      FS.Read(HeaderPage, SizeOf(HeaderPage));
      Move(HeaderPage, NewFile.Header, SizeOf(THdr));
      DataOffset := 0;

      while HeaderPage.var_data[DataOffset] <> 3 do // HDR_file
      begin
        if HeaderPage.var_data[DataOffset + 1] = 0 then
          Break;
        Inc(DataOffset, HeaderPage.var_data[DataOffset + 1] + 2);
        if DataOffset > HeaderPage.fix_data.hdr_page_size -
          SizeOf(HeaderPage.fix_data) then
          raise EGDBError.Create('Continuation');
      end;
      FilenameSize := HeaderPage.var_data[DataOffset + 1];
      NewFile.Filename := CurrentFilename;
      SetLength(NewFile.ContinuationFile, FilenameSize);
      if FilenameSize > 0 then
        Move(HeaderPage.var_data[DataOffset + 2], NewFile.ContinuationFile[1],
          FilenameSize);


      Inc(DataOffset, 2 + FilenameSize);
      while (DataOffset < HeaderPage.fix_data.hdr_page_size - SizeOf(HeaderPage.fix_data)) and
            (HeaderPage.var_data[DataOffset] <> 4) do
      begin
         if HeaderPage.var_data[DataOffset + 1] = 0 then
           Break;
         Inc(DataOffset, HeaderPage.var_data[DataOffset + 1] + 2);
      end;

      if (DataOffset < HeaderPage.fix_data.hdr_page_size - SizeOf(HeaderPage.fix_data)) and
         (HeaderPage.var_data[DataOffset] = 4) then
      begin
          Move(HeaderPage.var_data[DataOffset + 2], NewFile.LastLogicalPage, SizeOf(ULong));
      end
      else
      begin
          NewFile.LastLogicalPage := 0;
      end;

      NewFile.FirstLogicalPage := StartPage;
      if NewFile.LastLogicalPage <> 0 then
        NewFile.TotalPages := NewFile.LastLogicalPage - NewFile.FirstLogicalPage + 1
      else
        NewFile.TotalPages := 0;

      Inc(StartPage, NewFile.TotalPages);
      FList.Add(NewFile);
      CurrentFilename := NewFile.ContinuationFile;
      if CurrentFilename = '' then
      begin
        Break;
      end;
    finally
      FS.Free;
    end;
  until False;
end;

function TGDBInfo.GetItem(I: Integer): TGDBFileInfo;
begin
  Result := PGDBFile(FList[I])^;
end;

end.
