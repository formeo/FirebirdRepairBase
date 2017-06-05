unit uTipPage;

interface

uses uPag,Windows;

type
  SChar = Shortint;
  SShort = Smallint;
  UShort = Word;
  SLong = Longint;
  ULong = LongWord;

   tip = packed record
    tip_header: Tpag ;
    tip_next: SLONG;
  end;

   TTipPage = packed record
    fix_data: tip;
    tip_transactions: array[0..(4096-sizeof(tip))] of UCHAR;
  end;

implementation

end.
