unit uGenPage;

interface

uses uStructs, Windows;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;

type
  SChar = Shortint;
  SShort = Smallint;
  UShort = Word;
  SLong = Longint;
  ULong = LongWord;

  TGenerator_page = record
    gpg_header: TPag;
    gpg_sequence: ULong;
  end;

  Tgnrtr_page = record
    fix_data1: TGenerator_page;
    gpg_values: array [0 .. (MAX_PAGE_SIZE - sizeof(TGenerator_page))] of Int64;
  end;

implementation

end.
