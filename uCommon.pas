unit uCommon;

interface

uses
  Classes, Windows, SysUtils;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;

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

  tip = packed record
    tip_header: TPag;
    tip_next: SLong;
  end;

  tippage = packed record
    fix_data: tip;
    tip_transactions: array [0 .. (4096 - sizeof(tip))] of UCHAR;
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
    hdr_creation_date: array [0 .. 1] of SLong;
    hdr_attachment_id: SLong;
    hdr_shadow_count: SLong;
    hdr_implementation: SShort;
    hdr_ods_minor: UShort;
    hdr_ods_minor_original: UShort;
    hdr_end: UShort;
    hdr_page_buffers: ULong;
    hdr_bumped_transaction: SLong;
    hdr_oldest_snapshot: SLong;
    hdr_misc: array [0 .. 3] of SLong;
  end;

  THdrPage = packed record
    fix_data: THdr;
    var_data: array [0 .. (MAX_PAGE_SIZE - sizeof(THdr))] of UCHAR;
  end;

  Tgenerator_page = record
    gpg_header: TPag;
    gpg_sequence: ULong; // Sequence number
    // Generator vector
  end;

  Tgnrtr_page = record
    fix_data1: Tgenerator_page; // Sequence number
    gpg_values: array [0 .. (MAX_PAGE_SIZE - sizeof(Tgenerator_page))] of Int64;
    // Generator vector
  end;

  PDpg_repeat = ^TDpg_rpt;

  TDpg_rpt = record
    dpg_offset: Word;
    dpg_length: Word;
  end;

  TData_Page = record
    pagHdr_Header: TPag;
    dpg_sequence: Longint;
    dpg_relation: Word;
    dpg_count: Word;
  end;

  TDataPage = record
    fix_data: TData_Page;
    dpg_repeat: array [0 .. (MAX_PAGE_SIZE - sizeof(TData_Page))] of TDpg_rpt;
  end;

  trhd1 = record
    rhd_transaction: SLong;
    rhd_b_page: SLong;
    rhd_b_line: UShort;
    rhd_flags: UShort;
    rhd_format: UCHAR;
  end;

  Trhd_page = record
    fix_data: trhd1;
    rhd_data: array [0 .. (MAX_PAGE_SIZE - sizeof(trhd1))] of UCHAR;
  end;

  Tpnr_page = record
    pp_header: TPag;
    ppg_sequence: SLong;
    ppg_next: SLong;
    ppg_count: UShort;
    ppg_relation: UShort;
    ppg_min_space: UShort;
    ppg_max_space: UShort;

  end;

  TPointer_page = record
    fix_data: Tpnr_page;
    ppg_page: array [0 .. (MAX_PAGE_SIZE - sizeof(Tpnr_page))] of SLong;
  end;

function getCurrPageSize(const fileName: string): Integer;
function ByteToHex(InByte: byte): shortstring;
function GetFileSizeBase(const AFileName: String): Int64;
function IntToBinLowByte(const Value: LongWord): string;
function IntToBin1(Value: Longint; Digits: Integer): string;
function IntToBin2(d: Longint): string;
function Get_a_Bit(const aValue: Cardinal; const Bit: byte): Boolean;
function Set_a_Bit(const aValue: Cardinal; const Bit: byte): Cardinal;
function Clear_a_Bit(const aValue: Cardinal; const Bit: byte): Cardinal;
function BinToInt(BinStr: string): Int64;
function Hex2Byte(S: String): byte;
function Enable_a_Bit(const aValue: Cardinal; const Bit: byte;
  const Flag: Boolean): Cardinal;
procedure CopyDatabaseFile(ADatabaseOriginalPath: string;
  ADatabaseCopyPath: String);

implementation

// bits function for flags

// get if a particular bit is 1
function Get_a_Bit(const aValue: Cardinal; const Bit: byte): Boolean;
begin
  Result := (aValue and (1 shl Bit)) <> 0;
end;

// set a particular bit as 1
function Set_a_Bit(const aValue: Cardinal; const Bit: byte): Cardinal;
begin
  Result := aValue or (1 shl Bit);
end;

// set a particular bit as 0
function Clear_a_Bit(const aValue: Cardinal; const Bit: byte): Cardinal;
begin
  Result := aValue and not(1 shl Bit);
end;

// Enable o disable a bit
function Enable_a_Bit(const aValue: Cardinal; const Bit: byte;
  const Flag: Boolean): Cardinal;
begin
  Result := (aValue or (1 shl Bit)) xor (Integer(not Flag) shl Bit);
end;

function BinToInt(BinStr: string): Int64;
var
  i: byte;
  RetVar: Int64;
begin
  BinStr := UpperCase(BinStr);
  if BinStr[length(BinStr)] = 'B' then
    Delete(BinStr, length(BinStr), 1);
  RetVar := 0;
  for i := 1 to length(BinStr) do
  begin
    if not(BinStr[i] in ['0', '1']) then
    begin
      RetVar := 0;
      Break;
    end;
    RetVar := (RetVar shl 1) + (byte(BinStr[i]) and 1);
  end;

  Result := RetVar;
end;

// Integer to Binary

function IntToBin1(Value: Longint; Digits: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := Digits downto 0 do
    if Value and (1 shl i) <> 0 then
      Result := Result + '1'
    else
      Result := Result + '0';
end;

function Hex2Byte(S: String): byte;
const
  C: string[16] = '0123456789ABCDEF';
begin
  if length(S) < 2 then
    Result := Pos(S, C) - 1
  else
    Result := (Pos(S[1], C) - 1) * 16 + Pos(S[2], C) - 1
end;

function IntToBin2(d: Longint): string;
var
  x, p: Integer;
  bin: string;
begin
  bin := '';
  for x := 1 to 8 * sizeof(d) do
  begin
    if Odd(d) then
      bin := '1' + bin
    else
      bin := '0' + bin;
    d := d shr 1;
  end;
  Delete(bin, 1, 8 * ((Pos('1', bin) - 1) div 8));
  Result := bin;
end;

function IntToBinLowByte(const Value: LongWord): string;
var
  i: Integer;
begin
  SetLength(Result, 8);
  for i := 1 to 8 do
  begin
    if ((Value shl (24 + i - 1)) shr 31) = 0 then
    begin
      Result[i] := '0'
    end
    else
    begin
      Result[i] := '1';
    end;
  end;
end;

function getCurrPageSize(const fileName: string): Integer;
var
  fs: TFileStream;
  HeaderPage: THdrPage;
begin
  try
    fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
    fs.Read(HeaderPage, MIN_PAGE_SIZE);
  finally
    fs.Free;
  end;

  Result := HeaderPage.fix_data.hdr_page_size;
end;

function ByteToHex(InByte: byte): shortstring;
const
  Digits: array [0 .. 15] of char = '0123456789ABCDEF';
begin
  Result := Digits[InByte shr 4] + Digits[InByte and $0F];
end;

function GetFileSizeBase(const AFileName: String): Int64;
var
  SR: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SR) = 0 then
    try
      Result := (SR.FindData.nFileSizeHigh * Int64(MAXDWORD)) +
        SR.FindData.nFileSizeLow;
    finally
      FindClose(SR);
    end;
end;

procedure CopyDatabaseFile(ADatabaseOriginalPath: string;
  ADatabaseCopyPath: String);
const
  BUFFER_SIZE = 10240; // 10KB
var
  FromFile, ToFile: TFileStream;
  Buffer: array [0 .. BUFFER_SIZE - 1] of byte;
  NumRead: Integer;
  FileSize, CopiedSize: Int64;
begin
  FileSize := GetFileSizeBase(ADatabaseOriginalPath);
  FromFile := TFileStream.Create(ADatabaseOriginalPath, fmOpenRead or
    fmShareDenyNone);
  try
    // Создадим или перезапишем целевой файл
    if FileExists(ADatabaseCopyPath) then
      ToFile := TFileStream.Create(ADatabaseCopyPath, fmOpenReadWrite or
        fmShareDenyWrite)
    else
      ToFile := TFileStream.Create(ADatabaseCopyPath, fmCreate);
    try
      CopiedSize := 0;
      ToFile.Size := FileSize;
      ToFile.Position := 0;
      FromFile.Position := 0;
      NumRead := FromFile.Read(Buffer[0], BUFFER_SIZE);
      while NumRead > 0 do
      begin
        CopiedSize := CopiedSize + NumRead;
        NumRead := FromFile.Read(Buffer[0], BUFFER_SIZE);
      end;

    finally
      FreeAndNil(ToFile);
    end;
  finally
    FreeAndNil(FromFile);
  end;
end;

end.
