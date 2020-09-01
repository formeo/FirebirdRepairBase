unit uGenPage;

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

  TGenerator_page = record
    gpg_header: TPag;
    gpg_sequence: ULong; // Sequence number
    // Generator vector
  end;

  Tgnrtr_page = record
    fix_data1: TGenerator_page; // Sequence number
    gpg_values: array [0 .. (MAX_PAGE_SIZE - sizeof(TGenerator_page))] of Int64;
    // Generator vector
  end;

implementation

end.
