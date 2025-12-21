unit uFlagManager;

interface

uses
  Classes, SysUtils, uStructs;

type
  TDatabaseFlags = record
    ActiveShadow: Boolean;       // hdr_active_shadow	0x01 (bit 0)
    ForceWrite: Boolean;         // hdr_force_write	0x02 (bit 1)
    NoChecksums: Boolean;        // hdr_no_checksums	0x10 (bit 4)
    NoReserve: Boolean;          // hdr_no_reserve	0x20 (bit 5)
    SqlDialect3: Boolean;        // hdr_sql_dialect_3	0x100 (bit 8)
    ReadOnly: Boolean;           // hdr_read_only	0x200 (bit 9)
  end;


  TFlagManager = class
  private
    FFileName: string;
    FHeaderPageBuffer: TBytes;
    FHeaderPageSize: Integer;

    procedure LoadHeaderPage;
    procedure SaveHeaderPage;
    function FlagsToUShort(const Flags: TDatabaseFlags): UShort;
    function UShortToFlags(FlagsValue: UShort): TDatabaseFlags;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    function GetFlags: TDatabaseFlags;
    procedure SetFlags(const NewFlags: TDatabaseFlags);
    procedure SetForceWrite(Value: Boolean);
    procedure SetReadOnly(Value: Boolean);
  end;

implementation

uses
   uPageAnalyzer;

constructor TFlagManager.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  LoadHeaderPage;
end;

destructor TFlagManager.Destroy;
begin
  inherited;
end;

procedure TFlagManager.LoadHeaderPage;
var
  FileStream: TFileStream;
  HeaderPageStruct: THdrPage;
  PageSize: Integer;
begin
  if not FileExists(FFileName) then
    raise Exception.Create('File does not exist: ' + FFileName);

  FileStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(FHeaderPageBuffer, MIN_PAGE_SIZE); // Читаем минимум для получения hdr_page_size
    if FileStream.Read(FHeaderPageBuffer[0], MIN_PAGE_SIZE) <> MIN_PAGE_SIZE then
      raise Exception.Create('Cannot read header page.');


    if FHeaderPageBuffer[0] <> pag_header then
      raise Exception.Create('File does not start with a Header Page (type 0x01).');


    Move(FHeaderPageBuffer[0], HeaderPageStruct, SizeOf(THdr));
    PageSize := HeaderPageStruct.fix_data.hdr_page_size;


    if (PageSize < MIN_PAGE_SIZE) or (PageSize > MAX_PAGE_SIZE) then
      raise Exception.Create('Invalid page size in header: ' + IntToStr(PageSize));


    SetLength(FHeaderPageBuffer, PageSize);
    FileStream.Seek(0, soFromBeginning);
    if FileStream.Read(FHeaderPageBuffer[0], PageSize) <> PageSize then
      raise Exception.Create('Cannot read full header page.');

    FHeaderPageSize := PageSize;
  finally
    FileStream.Free;
  end;
end;

procedure TFlagManager.SaveHeaderPage;
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareExclusive);
  try
    FileStream.Seek(0, soFromBeginning);
    if FileStream.Write(FHeaderPageBuffer[0], FHeaderPageSize) <> FHeaderPageSize then
      raise Exception.Create('Cannot write header page.');
  finally
    FileStream.Free;
  end;
end;

function TFlagManager.FlagsToUShort(const Flags: TDatabaseFlags): UShort;
begin
  Result := 0;
  if Flags.ActiveShadow then Result := Result or $01;
  if Flags.ForceWrite then Result := Result or $02;
  if Flags.NoChecksums then Result := Result or $10;
  if Flags.NoReserve then Result := Result or $20;
  if Flags.SqlDialect3 then Result := Result or $100;
  if Flags.ReadOnly then Result := Result or $200;
end;

function TFlagManager.UShortToFlags(FlagsValue: UShort): TDatabaseFlags;
begin
  Result.ActiveShadow := (FlagsValue and $01) <> 0;
  Result.ForceWrite := (FlagsValue and $02) <> 0;
  Result.NoChecksums := (FlagsValue and $10) <> 0;
  Result.NoReserve := (FlagsValue and $20) <> 0;
  Result.SqlDialect3 := (FlagsValue and $100) <> 0;
  Result.ReadOnly := (FlagsValue and $200) <> 0;
end;

function TFlagManager.GetFlags: TDatabaseFlags;
var
  HeaderStruct: THdrPage;
  FlagsValue: UShort;
begin
  Move(FHeaderPageBuffer[0], HeaderStruct, SizeOf(THdr));
  FlagsValue := HeaderStruct.fix_data.hdr_flags;
  Result := UShortToFlags(FlagsValue);
end;

procedure TFlagManager.SetFlags(const NewFlags: TDatabaseFlags);
var
  HeaderStruct: THdrPage;
  NewFlagsValue: UShort;
begin
  Move(FHeaderPageBuffer[0], HeaderStruct, SizeOf(THdr));
  NewFlagsValue := FlagsToUShort(NewFlags);
  HeaderStruct.fix_data.hdr_flags := NewFlagsValue;
  Move(HeaderStruct, FHeaderPageBuffer[0], SizeOf(THdr));
  SaveHeaderPage;
end;

procedure TFlagManager.SetForceWrite(Value: Boolean);
var
  CurrentFlags: TDatabaseFlags;
begin
  CurrentFlags := GetFlags();
  CurrentFlags.ForceWrite := Value;
  SetFlags(CurrentFlags);
end;

procedure TFlagManager.SetReadOnly(Value: Boolean);
var
  CurrentFlags: TDatabaseFlags;
begin
  CurrentFlags := GetFlags();
  CurrentFlags.ReadOnly := Value;
  SetFlags(CurrentFlags);
end;

end.
