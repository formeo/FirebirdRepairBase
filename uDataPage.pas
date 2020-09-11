unit uDataPage;

{
Dpg_header: The page starts with a standard page header. In this page type, the pag_flags byte is used as follows:
  Bit 0 - dpg_orphan. Setting this bit indicates that this page is an orphan - it has no entry in the pointer page for this relation. This may indicate a possible database corruption.
  Bit 1 - dpg_full. Setting this bit indicates that the page is full up. This will be also seen in the bitmap array on the corresponding pointer page for this table.
  Bit 2 - dpg_large. Setting this bit indicates that a large object is stored on this page. This will be also seen in the bitmap array on the corresponding pointer page for this table.

Dpg_sequence: Four bytes, signed. Offset 0x10 on the page. This field holds the sequence number for this page in the list of pages assigned to this table within the database. The first page of any table has sequence zero.
Dpg_relation: Two bytes, unsigned. Offset 0x12 on the page. The relation number for this table. This corresponds to RDB$RELATIONS.RDB$RELATION_ID.
Dpg_count: Two bytes, unsigned. Offset 0x14 on the page. The number of records (or record fragments) on this page. In other words, the number of entries in the dpg_rpt array.
Dpg_rpt: This is an array of two byte unsigned values. The array begins at offset 0x18 on the page and counts upwards from the low address to the higher address as each new record fragment is added.
         The two fields in this array are:
Dpg_offset: Two bytes, unsigned. The offset on the page where the record fragment starts. If the value here is zero and the length is zero, then this is an unused array entry. The offset is from the start address of the page. For example, if the offset is 0x0fc8 and this is a database with a 4Kb page size, and the page in question is page 0xcd (205 decimal) then we have the offset of 0xcdfc8 because 0xcd000 is the actual address (in the database file) of the start of the page.
Dpg_length: Two bytes, unsigned. The length of this record fragment in byte   }

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
