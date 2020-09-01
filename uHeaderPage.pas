unit uHeaderPage;

interface

uses uPag, Windows;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;

type
  SChar = Shortint;
  SShort = Smallint;
  UShort = Word;
  SLong = Longint;
  ULong = LongWord;

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

implementation

end.
