unit uCommon;

interface
uses 
  Classes,Windows,SysUtils;
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
    tip_header: Tpag ;
    tip_next: SLONG;
  end;

   tippage = packed record
    fix_data: tip;
    tip_transactions: array[0..(4096-sizeof(tip))] of UCHAR;
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
    var_data:array[0..(MAX_PAGE_SIZE-sizeof(THdr))] of UCHAR;
  end;

  Tgenerator_page  = record
	gpg_header: TPag;
	gpg_sequence: ULONG ;			// Sequence number
        		// Generator vector
  end;
  Tgnrtr_page  = record
    fix_data1: Tgenerator_page;			// Sequence number
    gpg_values :array[0..(MAX_PAGE_SIZE-sizeof(Tgenerator_page))] of Int64;    		// Generator vector
  end;
   PDpg_repeat = ^TDpg_rpt;


 TDpg_rpt = record
 dpg_offset : Word;
 dpg_length : Word;
end;

TData_Page = record
 pagHdr_Header : TPag;
 dpg_sequence : Longint;
 dpg_relation : Word;
 dpg_count : Word;
end;

TDataPage = record
 fix_data: TData_Page;
dpg_repeat : array[0..(MAX_PAGE_SIZE-sizeof(TData_Page))] of TDpg_rpt;
end;

trhd1 = record
    rhd_transaction: SLONG ;
    rhd_b_page:  SLONG ;
    rhd_b_line:  USHORT ;
    rhd_flags:  USHORT ;
    rhd_format:  UCHAR ;
  end ;
   Trhd_page  = record
    fix_data: trhd1;
    rhd_data:array[0..(MAX_PAGE_SIZE-sizeof(trhd1))] of UCHAR;
  end ;

Tpnr_page  =  record
    pp_header: Tpag;
    ppg_sequence: SLONG ;
    ppg_next: SLONG;
    ppg_count: USHORT;
    ppg_relation: USHORT;
    ppg_min_space: USHORT;
    ppg_max_space: USHORT;

end;

TPointer_page =  record
    fix_data: Tpnr_page;
    ppg_page:array[0..(MAX_PAGE_SIZE-sizeof(Tpnr_page))] of SLONG;
  end;


function getCurrPageSize(const fileName: string):Integer;
function ByteToHex(InByte:byte):shortstring;
function GetFileSizeBase(const AFileName: String): Int64;
procedure CopyDatabaseFile( ADatabaseOriginalPath: string; ADatabaseCopyPath: String);

implementation



function getCurrPageSize(const fileName: string):Integer;
var fs: TFileStream;
    HeaderPage: THdrPage;
begin
   try
    FS := TFileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
    FS.Read(HeaderPage, MIN_PAGE_SIZE);
  finally
    FS.Free;
  end;

  Result:=HeaderPage.fix_data.hdr_page_size;
end;

function ByteToHex(InByte:byte):shortstring;
const Digits:array[0..15] of char='0123456789ABCDEF';
begin
   result:=digits[InByte shr 4]+digits[InByte and $0F];
end;

function GetFileSizeBase(const AFileName: String): Int64;
var
  SR : TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SR) = 0 then
  try
    Result := (SR.FindData.nFileSizeHigh * Int64(MAXDWORD)) + SR.FindData.nFileSizeLow;
  finally
    FindClose(SR);
  end;
end;


procedure CopyDatabaseFile( ADatabaseOriginalPath: string; ADatabaseCopyPath: String);
const
  BUFFER_SIZE = 10240; // 10KB
var
  FromFile, ToFile: TFileStream;
  Buffer: array[0..BUFFER_SIZE - 1] of byte;
  NumRead: Integer;
  FileSize, CopiedSize: Int64;
begin
  FileSize := GetFileSizeBase(ADatabaseOriginalPath);
  FromFile := TFileStream.Create(ADatabaseOriginalPath, fmOpenRead or fmShareDenyNone);
  try
    // Создадим или перезапишем целевой файл
    if FileExists(ADatabaseCopyPath) then
      ToFile := TFileStream.Create(ADatabaseCopyPath, fmOpenReadWrite or fmShareDenyWrite)
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
