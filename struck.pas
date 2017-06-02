unit struck;



interface

uses 
  SysUtils, Classes;
const
  cMAX_PAGE_SIZE = 32768;
type
       SChar = Shortint;
  SShort = Smallint;
  UShort = Word;
  SLong = Longint;
  ULong = LongWord;



  TPag = packed record

    pag_type: SChar;

    pag_flags: SChar;

    pag_checksum: UShort;

    pag_generation: ULong;

    pag_seqno: ULong;

    pg_offset: ULong;

  end;



  THdr = packed record

    hdr_header: TPag;

    hdr_page_size: UShort;

    hdr_ods_version: UShort;

    hdr_pages: SLong;

    hdr_next_page: ULong;

    hdr_oldest_transaction: SLong;

    hdr_oldest_active: SLong;

    hdr_next_transaction: SLong;

    hdr_sequence: UShort;

    hdr_flags: UShort;

    hdr_creation_date: array[0..1] of SLong;

    hdr_attachment_id: SLong;

    hdr_shadow_count: SLong;

    hdr_implementation: SShort;

    hdr_ods_minor: UShort;

    hdr_ods_minor_original: UShort;

    hdr_end: UShort;

    hdr_page_buffers: ULong;

    hdr_bumped_transaction: SLong;

    hdr_oldest_snapshot: SLong;

    hdr_misc: array[0..3] of SLong;

  end;



  THdrPage = packed record

    fix_data: THdr;

    var_data: array[0..cMAX_PAGE_SIZE - 1 - SizeOf(THdr)] of Byte;

  end;



  //Not IB related

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

  protected

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
  if not FileExists(FFilename) then raise EGDBError.Create('File does not exist - ' + FFilename);

  SourceDir := ExtractFilePath(FFilename);
  if SourceDir = '' then SourceDir := IncludeTrailingBackSlash(GetCurrentDir);
  StartPage := 0;
  CurrentFilename := SourceDir + ExtractFilename(FFilename);
  repeat
    FS := TFileStream.Create(CurrentFilename, fmOpenRead or fmShareDenyNone);
    try
      GetMem(NewFile, SizeOf(TGDBFileInfo));
      FS.Read(HeaderPage, SizeOf(HeaderPage));
      Move(HeaderPage, NewFile.Header, SizeOf(THdr));
      DataOffset := 0;
      //Format of var_data is repeated
      //1 = Root file name
      //2 = Journal server
      //3 = Continuation file (this is the one we want)
      //4 = Last logical page
      //5 = Unlicensed accesses
      //6 = Sweep interval
      //7 = Replay logging file
      //11= Shared cache file

      while HeaderPage.var_data[DataOffset] <> 3 do
      begin
        if HeaderPage.var_data[DataOffset + 1] = 0 then Break;
        Inc(DataOffset, HeaderPage.var_data[DataOffset + 1] + 2);
        if DataOffset > HeaderPage.fix_data.hdr_page_size - SizeOf(HeaderPage.fix_data) then raise EGDBError.Create('Continuation');
      end;
      FilenameSize := HeaderPage.var_data[DataOffset + 1];
      NewFile.Filename := CurrentFileName;
      SetLength(NewFile.ContinuationFile, FilenameSize);
      if FilenameSize > 0 then
        Move(HeaderPage.var_data[DataOffset + 2], NewFile.ContinuationFile[1], FilenameSize);
      NewFile.FirstLogicalPage := StartPage;
      Move(HeaderPage.var_data[DataOffset + FilenameSize + 4], NewFile.LastLogicalPage, SizeOf(LongWord));
      NewFile.TotalPages := NewFile.LastLogicalPage - NewFile.FirstLogicalPage;
      Inc(StartPage, NewFile.TotalPages);
      FList.Add(NewFile);
      CurrentFilename := NewFile.ContinuationFile;
      if CurrentFilename = '' then
      begin
        NewFile.LastLogicalPage := 0;
        NewFile.TotalPages := 0;
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
