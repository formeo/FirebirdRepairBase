unit uPoiner;

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

  Tpnr_page = record
    pp_header: Tpag;
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

implementation

end.
