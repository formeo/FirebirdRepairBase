unit uDataPage;

interface

uses uPag, Windows;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;

type
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

implementation

end.
