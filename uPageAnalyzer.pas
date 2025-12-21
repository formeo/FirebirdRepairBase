unit uPageAnalyzer;

interface

uses
  Windows, SysUtils, Classes, uStructs; // uStructs содержит исправленные TPag и типы

const
  // Типы страниц Firebird (ODS 11.1 / Firebird 2.1+)
  // Эти константы можно определить здесь для удобства
  pag_undefined         = $00;
  pag_header            = $01;
  pag_pip               = $02; // Page Inventory Page
  pag_tip               = $03; // Transaction Inventory Page
  pag_pointer           = $04; // Pointer Page
  pag_data              = $05; // Data Page
  pag_index_root        = $06; // Index Root Page
  pag_index_bt          = $07; // Index B-Tree Page
  pag_blob              = $08; // Blob Page
  pag_generator         = $09; // Generator Page
  pag_wal               = $0a; // Write Ahead Log page (устаревшее)

type
  // Используем TPag из uStructs
  // TPag = packed record
  //   pag_type: SChar;
  //   pag_flags: UChar;
  //   pag_checksum: UShort;
  //   pag_generation: ULong;
  //   pag_scn: ULong;
  //   reserved: ULong;
  // end;

  // Информация о прочитанной странице
  TPageInfo = record
    Number: ULong;           // Номер страницы
    Buffer: TBytes;          // Байтовый буфер страницы
    Header: TPag;            // Стандартный заголовок страницы
    Size: Integer;           // Размер страницы
    TypeStr: string;         // Строковое описание типа
  end;

  // Класс для общего анализа страниц базы данных
  TPageAnalyzer = class
  private
    FFileName: string;
    FPageSize: Integer;
    FFileSize: Int64;
    FFileStream: TFileStream;


    function ReadPageToBuffer(PageNumber: ULong): TBytes;
    function GetPageHeader(const PageBuffer: TBytes): TPag;
    function GetPageTypeString(PageType: SChar): string;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    function GetPageInfo(PageNumber: ULong): TPageInfo;
    function GetLastPageNumber: ULong;

    property FileName: string read FFileName;
    property PageSize: Integer read FPageSize;
    property FileSize: Int64 read FFileSize;
  end;

implementation

constructor TPageAnalyzer.Create(const AFileName: string);
var
  HeaderPageBuffer: TBytes;
  HeaderPageStruct: THdrPage;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('File does not exist: ' + AFileName);

  FFileName := AFileName;
  FFileStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
  FFileSize := FFileStream.Size;

  SetLength(HeaderPageBuffer, MIN_PAGE_SIZE);
  FFileStream.Seek(0, soFromBeginning);
  if FFileStream.Read(HeaderPageBuffer[0], MIN_PAGE_SIZE) <> MIN_PAGE_SIZE then
    raise Exception.Create('Cannot read header page.');


  if HeaderPageBuffer[0] <> pag_header then
    raise Exception.Create('File does not start with a Header Page (type 0x01).');

  Move(HeaderPageBuffer[0], HeaderPageStruct, SizeOf(THdr));
  FPageSize := HeaderPageStruct.fix_data.hdr_page_size;


  if (FPageSize < MIN_PAGE_SIZE) or (FPageSize > MAX_PAGE_SIZE) or
     ((FPageSize and (FPageSize - 1)) <> 0) then
    raise Exception.Create('Invalid page size found in header: ' + IntToStr(FPageSize));


  SetLength(HeaderPageBuffer, FPageSize);
  FFileStream.Seek(0, soFromBeginning);
  if FFileStream.Read(HeaderPageBuffer[0], FPageSize) <> FPageSize then
    raise Exception.Create('Cannot read full header page.');

  Move(HeaderPageBuffer[0], HeaderPageStruct, SizeOf(THdr));
  FPageSize := HeaderPageStruct.fix_data.hdr_page_size;
end;

destructor TPageAnalyzer.Destroy;
begin
  FFileStream.Free;
  inherited;
end;

function TPageAnalyzer.ReadPageToBuffer(PageNumber: ULong): TBytes;
var
  Offset: Int64;
begin
  Offset := Int64(PageNumber) * FPageSize;
  if Offset + FPageSize > FFileSize then
    raise Exception.Create('Page number out of file bounds: ' + IntToStr(PageNumber));

  SetLength(Result, FPageSize);
  FFileStream.Seek(Offset, soFromBeginning);
  if FFileStream.Read(Result[0], FPageSize) <> FPageSize then
    raise Exception.Create('Error reading page: ' + IntToStr(PageNumber));
end;

function TPageAnalyzer.GetPageHeader(const PageBuffer: TBytes): TPag;
begin
  if Length(PageBuffer) < SizeOf(TPag) then
    raise Exception.Create('Page buffer too small for standard header.');

  Move(PageBuffer[0], Result, SizeOf(TPag));
end;

function TPageAnalyzer.GetPageTypeString(PageType: SChar): string;
begin
  case PageType of
    pag_undefined: Result := 'Undefined page';
    pag_header: Result := 'Header page';
    pag_pip: Result := 'Page Inventory Page (PIP)';
    pag_tip: Result := 'Transaction Inventory Page (TIP)';
    pag_pointer: Result := 'Pointer Page';
    pag_data: Result := 'Data Page';
    pag_index_root: Result := 'Index Root Page';
    pag_index_bt: Result := 'Index B-Tree Page';
    pag_blob: Result := 'Blob Page';
    pag_generator: Result := 'Generator Page';
    pag_wal: Result := 'Write Ahead Log page';
  else
    Result := 'Unknown page type: $' + IntToHex(Byte(PageType), 2);
  end;
end;

function TPageAnalyzer.GetPageInfo(PageNumber: ULong): TPageInfo;
begin
  Result.Number := PageNumber;
  Result.Size := FPageSize;
  Result.Buffer := ReadPageToBuffer(PageNumber);
  Result.Header := GetPageHeader(Result.Buffer);
  Result.TypeStr := GetPageTypeString(Result.Header.pag_type);
end;

function TPageAnalyzer.GetLastPageNumber: ULong;
begin
  Result := (FFileSize div FPageSize) - 1;
  if FFileSize mod FPageSize <> 0 then
    raise Exception.Create('File size is not a multiple of page size. File might be corrupted.');
end;

end.
