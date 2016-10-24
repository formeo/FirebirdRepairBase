unit main;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileCtrl,ComCtrls,struck, DB, dxmdaset, ExtCtrls,
  Menus, dxExEdtr, dxDBCtrl, dxDBGrid, dxTL, dxCntner,uCommon;
const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;
  PBM_SETBARCOLOR = WM_USER + 9;
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


type
  TfrmMain = class(TForm)
    dlgOpen1: TOpenDialog;
    lst2: TListBox;
    GroupBox1: TGroupBox;
    lst4: TListBox;
    dxMeMPAGES: TdxMemData;
    dxMeMPAGESTYPE_PAGE: TStringField;
    intgrfldMeMPAGESNEXT_PAGE: TIntegerField;
    dxMeMPAGESNUM_PAGE: TStringField;
    dlgSave1: TSaveDialog;
    pmSaveInfo: TPopupMenu;
    mniN1: TMenuItem;
    dsBaseStat: TDataSource;
    pnl1: TPanel;
    lbl7: TLabel;
    lbl8: TLabel;
    pm1: TPopupMenu;
    mniN2: TMenuItem;
    pbProcess: TProgressBar;
    pnl5: TPanel;
    btn1: TButton;
    btn2: TButton;
    btn3: TButton;
    btn7: TButton;
    pnl6: TPanel;
    grp1: TGroupBox;
    spl1: TSplitter;
    pnl2: TPanel;
    lstLog: TListBox;
    pnl3: TPanel;
    lbl1: TLabel;
    pbDetectedPage: TProgressBar;
    pgc1: TPageControl;
    ts1: TTabSheet;
    grp2: TGroupBox;
    pnl4: TPanel;
    lbl2: TLabel;
    edt1: TEdit;
    btn5: TButton;
    grp3: TGroupBox;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    btn6: TButton;
    edt3: TEdit;
    edt4: TEdit;
    cbb1: TComboBox;
    ts2: TTabSheet;
    grp4: TGroupBox;
    lbl6: TLabel;
    btn4: TButton;
    edt2: TEdit;
    ts3: TTabSheet;
    dxGRD1: TdxDBGrid;
    dxdbgrdmskclmnDBGrid1NUM_PAGE: TdxDBGridMaskColumn;
    dxdbgrdclmnDBGrid1RecId: TdxDBGridColumn;
    dxdbgrdmskclmnDBGrid1TYPE_PAGE: TdxDBGridMaskColumn;
    dxdbgrdmskclmnDBGrid1NEXT_PAGE: TdxDBGridMaskColumn;
    btnGetData: TButton;
    pmSaveLog: TPopupMenu;
    btnPIP: TButton;
    pnl7: TPanel;
    pnl8: TPanel;
    pnl9: TPanel;
    mmoData: TMemo;
    pnl10: TPanel;
    pnl11: TPanel;
    pbData: TProgressBar;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure mniN1Click(Sender: TObject);
    procedure btn5Click(Sender: TObject);
    procedure btn6Click(Sender: TObject);
    procedure btn7Click(Sender: TObject);
    procedure btnGetDataClick(Sender: TObject);
    procedure btnPIPClick(Sender: TObject);
  private
    { Private declarations }
  public
  end;

var
  frmMain: TfrmMain;
  new_header_page: THdrPage;
  page_size_curr: integer;
implementation

{$R *.dfm}


procedure TfrmMain.btn1Click(Sender: TObject);
begin
  if dlgOpen1.Execute then { Display Open dialog box }
  begin
    lbl8.Caption:=dlgOpen1.FileName;
  end;
end;






procedure TfrmMain.btn2Click(Sender: TObject);
var
   FS: TFileStream;
   FileSize :Int64;
   HeaderPage: THdrPage;
   CountPIPPage:integer;
   CountTIPPage:integer;
   CountPointerPage:integer;
   CountDataPage:integer;
   CountIndexRootPage:integer;
   CountBlobPage:integer;
   CountGeneratorPage:integer;
   CountWriteAheadLogPage:integer;
   CountUnknownPage:integer;
   NumRead,i:Integer;
   pages :tippage;
   DataPage:TDataPage;
begin
  if  dlgOpen1.FileName='' then begin Exit; end;
  lstLog.Items.Clear;
  lstLog.Items.Add('База данных: '+dlgOpen1.FileName);
  
  FileSize := GetFileSizeBase(dlgOpen1.FileName);
  lstLog.Items.Add('Размер файла Базы: '+IntToStr(FileSize));
  try
    FS := TFileStream.Create(dlgOpen1.FileName, fmOpenRead or fmShareDenyNone);
    FS.Read(HeaderPage, MIN_PAGE_SIZE);
  finally
    FS.Free;
  end;

  page_size_curr:=HeaderPage.fix_data.hdr_page_size;
  try
    FS := TFileStream.Create(dlgOpen1.FileName, fmOpenRead or fmShareDenyNone);
    FS.Read(HeaderPage, HeaderPage.fix_data.hdr_page_size);
    lstLog.Items.Add('Количество страниц в базе '+floatToStr( Round(FileSize/HeaderPage.fix_data.hdr_page_size)));
  finally
    FS.Free;
  end;
  lstLog.Items.Add('Размер страницы базы '+inttostr(page_size_curr));
  lstLog.Items.Add('Определение типов страниц ');
  CountPIPPage:=0;
  CountTIPPage:=0;
  CountPointerPage:=0;
  CountDataPage:=0;
  CountIndexRootPage:=0;
  CountBlobPage:=0;
  CountGeneratorPage:=0;
  CountWriteAheadLogPage:=0;
  CountUnknownPage:=0;
  pbProcess.Min:=0;
  pbProcess.Max:=round(FileSize/HeaderPage.fix_data.hdr_page_size);
  pbProcess.Position:=1;
  try
    FS := TFileStream.Create(dlgOpen1.FileName, fmOpenRead or fmShareDenyNone);
    NumRead := FS.Read(pages, page_size_curr);
    i:=1;
    while (NumRead > 0) do
    begin
      NumRead := FS.Read(DataPage, page_size_curr);
      case DataPage.fix_data.pagHdr_Header.pag_type of
       1:begin lst4.Items.Add(IntToStr(i)+' header page');   end;
       2:begin lst4.Items.Add(IntToStr(i)+' Page Inventory Page (PIP)'); inc(CountPIPPage) end;
       3:begin lst4.Items.Add(IntToStr(i)+' Page Inventory Page (TIP)'); inc(CountTIPPage);end;
       4:begin lst4.Items.Add(IntToStr(i)+' Pointer Page '); inc(CountPointerPage)end;
       5:begin lst4.Items.Add(IntToStr(i)+' Data Page '); inc(CountDataPage)end;
       6:begin lst4.Items.Add(IntToStr(i)+' Index Root Page '); inc(CountIndexRootPage)end;
       8:begin lst4.Items.Add(IntToStr(i)+' Blob Page '); inc(CountBlobPage)end;
       9:begin lst4.Items.Add(IntToStr(i)+' Generator Page  '); inc(CountGeneratorPage)end;
       10:begin lst4.Items.Add(IntToStr(i)+' Write Ahead Log page   '); inc(CountWriteAheadLogPage)end;
       else
       begin
          inc(CountUnknownPage);
       end


      end;
      inc(i);
      pbProcess.Position:=i;
      Application.ProcessMessages;
    end;
  finally
    FS.Free;
  end;
  lstLog.Items.Add('Количество Page Inventory Page (PIP) '+inttostr(CountPIPPage));
  lstLog.Items.Add('Количество Page Inventory Page (TIP) '+inttostr(CountTIPPage));
  lstLog.Items.Add('Количество Pointer Page '+inttostr(CountPointerPage));
  lstLog.Items.Add('Количество Data Page '+inttostr(CountDataPage));
  lstLog.Items.Add('Количество Index Root Page '+inttostr(CountIndexRootPage));
  lstLog.Items.Add('Количество Blob Page '+inttostr(CountBlobPage));
  lstLog.Items.Add('Количество Generator Page '+inttostr(CountGeneratorPage));
  lstLog.Items.Add('Количество Write Ahead Log page '+inttostr(CountWriteAheadLogPage));
  lstLog.Items.Add('Количество Неизвестных страниц '+inttostr(CountUnknownPage));
end;

procedure TfrmMain.btn3Click(Sender: TObject);
var
  src_i, dst_i, len, found:integer;
  is_win32:integer;
  i:integer;
  HeaderPage: THdrPage;
  db:Integer;
  orig_link_name  : array[0..257] of char;
begin
  if dlgOpen1.Execute then { Display Open dialog box }
begin
  db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
  i := FileRead(db, HeaderPage, MIN_PAGE_SIZE);

  fileseek(db, 0, 0);

  i := fileread(db, HeaderPage, HeaderPage.fix_data.hdr_page_size);


  new_header_page.fix_data := HeaderPage.fix_data;
  new_header_page.fix_data.hdr_flags:=256;
  new_header_page.var_data:= HeaderPage.var_data;

  fileseek(db, 0, 0);


  i := filewrite(db, new_header_page, new_header_page.fix_data.hdr_page_size);

  if ( i = -1) then
  begin
    ShowMessage ('Cannot write header page.');
  end;
  FileClose(db );
  ShowMessage ('Header rewrite');




  Exit;



  found := 0;
  src_i := 0;
  dst_i := 0;
  while (HeaderPage.var_data[src_i] > 0) do
  begin
    len := HeaderPage.var_data[src_i+1];

    if (3 = HeaderPage.var_data[src_i]) then
    begin
      if ((sizeof(new_header_page.fix_data) + dst_i +  + 2) > new_header_page.fix_data.hdr_page_size ) then
      begin
        ShowMessage ('New file name does not fit into header page.');
      end;

      strlcopy(orig_link_name, Pchar(@HeaderPage.var_data[src_i+2]), len);
      orig_link_name[len] := #0;

     // writeln(format('Link changed from'+#13#10+'  "%s"'+#13#10+'to'+#13#10+'  "%s"', [orig_link_name, db_link_name]));

      new_header_page.var_data[dst_i] := 3; inc(dst_i);
      //new_header_page.var_data[dst_i] := strlen(PChar(dlgOpen1.FileName)); inc(dst_i);
      //strcopy (Pchar(@new_header_page.var_data[dst_i]), PChar(dlgOpen1.FileName));
      //inc(dst_i, strlen(db_link_name));
      found := 1;
    end else
    begin



      strlcopy(Pchar(@new_header_page.var_data[dst_i]), Pchar(@HeaderPage.var_data[src_i]), len+2);
      inc(dst_i, len + 2);
    end;

    inc(src_i, len + 2);
  end;

  if (found = ord(false)) then
  begin
    ShowMessage('Continuation file not specified in header.');

  end;

  // compute new checksum
  // 16 = "Microsoft Windows 32-bit Intel";
  // 18 = "Microsoft Windows 16-bit";
  is_win32 := ord(16 = new_header_page.fix_data.hdr_implementation);

  // IB4 = ODS 8;  IB5 = ODS 9;  IB6 = ODS 10
  // also see jrd/cch.c (CCH_checksum())
  if (((is_win32 = ord(false)) and (HeaderPage.fix_data.hdr_ods_version >= 8)) or
      ((is_win32 = ord(true))  and (HeaderPage.fix_data.hdr_ods_version >= 9)) or
      (HeaderPage.fix_data.hdr_sequence > 0) ) then
  begin
    new_header_page.fix_data.hdr_header.pag_checksum := 12345;
  end else
  begin
    //new_header_page.fix_data.hdr_header.pag_checksum :=
  //    compute_checksum (new_header_page, new_header_page.fix_data.hdr_page_size);
  end;

  // write new version of header
  fileseek(db, 0, 0);
  i := filewrite(db, new_header_page, new_header_page.fix_data.hdr_page_size);

  if ( i = -1) then
  begin
    ShowMessage ('Cannot write header page.');

  end;
  end;
end;

procedure TfrmMain.mniN1Click(Sender: TObject);
begin
  if dlgSave1.Execute then lstLog.Items.SaveToFile(dlgSave1.FileName );
end;

procedure TfrmMain.btn5Click(Sender: TObject);
var db,i:integer;
    DataPage:TDataPage;
begin
  try
    db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
    fileseek(db, 0, 0);
   // fileseek(db, strtoint(edt1.text)*page_size_curr, 0);
    fileseek(db, strtoint(edt1.text)*8192, 0);
    //i := fileread(db, DataPage, page_size_curr);
    i := fileread(db, DataPage, 8192);

    if DataPage.fix_data.pagHdr_Header.pag_type < 0 then cbb1.Text:='Неизвестно'
    else
     cbb1.ItemIndex:=DataPage.fix_data.pagHdr_Header.pag_type-1;
    edt4.Text:= inttostr(DataPage.fix_data.pagHdr_Header.pag_checksum);
  finally
    FileClose(db );
  end

  
end;

procedure TfrmMain.btn6Click(Sender: TObject);
var db,i:integer;
    DataPage:TDataPage;

begin
  page_size_curr:=8192;
  db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
  fileseek(db, 0, 0);
  fileseek(db, 1414484560*page_size_curr, 0);
  i := fileread(db, DataPage, page_size_curr);
  FileClose(db );
  ShowMessage(inttostr(DataPage.fix_data.pagHdr_Header.pag_type) );
  DataPage.fix_data.pagHdr_Header.pag_type:= 0;

 // DataPage.fix_data.pagHdr_Header.pag_type:=cbb1.ItemIndex;
 // DataPage.fix_data.pagHdr_Header.pag_type:=12;

  db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
  fileseek(db, 0, 0);
  fileseek(db, 1414484560*page_size_curr, 0);
  i := filewrite(db, DataPage, page_size_curr);
  FileClose(db );
  ShowMessage('Данные записаны');
end;

procedure TfrmMain.btn7Click(Sender: TObject);
var        db,i:Integer;
pages :tippage;
  newpages :tippage;
begin
  db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
  fileseek(db, 0, 0);
  fileseek(db, 148*8192, 0);
  i := fileread(db, pages, 8192);
  newpages:=pages;
  newpages.fix_data.tip_next:=0;
  fileseek(db, 0, 0);
  fileseek(db, 148*8192, 0);
  i := filewrite(db, newpages, 8192);
  FileClose(db );
end;

procedure TfrmMain.btnGetDataClick(Sender: TObject);
var i,db,pCurrSize :Integer;
    DataData:TDataPage;
begin
   pCurrSize:=getCurrPageSize(dlgOpen1.FileName);
   try
     db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
     fileseek(db, 0, 0);
     fileseek(db, 745754*pCurrSize, 0);
     i := fileread(db, DataData,pCurrSize);

   finally
     FileClose(db );
   end;
   pbData.Min:=0;
   pbData.Max:=length(DataData.dpg_repeat)-1;
   for i :=0 to length(DataData.dpg_repeat)-1
   do
   begin
     pbData.Position:=pbData.Position+1;
    // mmoData.Text:=  mmoData.Text+' '+  Chr(StrToInt('$'+ByteToHex(DataData.dpg_repeat[i])));
     Application.ProcessMessages;
    // lstData.Items.Add(ByteToHex(DataData.rhd_data[i]));
    // lstData.Items.Add(Chr(StrToInt('$'+ByteToHex(DataData.rhd_data[i]))));
   end;
   ShowMessage('Finished');
end;

procedure TfrmMain.btnPIPClick(Sender: TObject);
var   FS  :TFileStream;
      HeaderPage: THdrPage;
      db,firstPointerPage,i:integer;
      pPage: TPointer_page;
      DPage: TPointer_page;
      pCurrSize:Integer;
      DataData:TDataPage;
      DataData2:Trhd_page;
begin
   firstPointerPage:=-1;
   pCurrSize:=getCurrPageSize(dlgOpen1.FileName);
   try
     FS := TFileStream.Create(dlgOpen1.FileName, fmOpenRead or fmShareDenyNone);
     FS.Read(HeaderPage, pCurrSize);
   finally
     FS.Free;
   end;
   firstPointerPage:= HeaderPage.fix_data.hdr_pages;
   try
     db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
     fileseek(db, 0, 0);
     fileseek(db, firstPointerPage*pCurrSize, 0);
     i := fileread(db, pPage, pCurrSize);
   finally
     FileClose(db );
   end;

   lstLog.Items.Add('Readed pointer Page ');
   lstLog.Items.Add('RDB$PAGES состоит из  '+inttostr(pPage.fix_data.ppg_count) + ' страниц' );

   try
     db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
     fileseek(db, 0, 0);
     fileseek(db, (5*pCurrSize), 0);
     i := fileread(db, DataData, pCurrSize);
   finally
     FileClose(db);
   end;

   try
     db := fileopen(dlgOpen1.FileName, fmOpenReadWrite + fmShareExclusive);
     fileseek(db, 0, 0);
     fileseek(db, (1878*pCurrSize)+4524, 0);
     i := fileread(db, DataData2, 28);
   finally
     FileClose(db);
   end;
   pbData.Min:=0;
   pbData.Max:=length(DataData2.rhd_data)-1;
   for i :=0 to length(DataData2.rhd_data)-1
   do
   begin
     pbData.Position:=pbData.Position+1;
     mmoData.Text:=  mmoData.Text+' '+  Chr(StrToInt('$'+ByteToHex(DataData2.rhd_data[i])));
     Application.ProcessMessages;
    // lstData.Items.Add(ByteToHex(DataData.rhd_data[i]));
    // lstData.Items.Add(Chr(StrToInt('$'+ByteToHex(DataData.rhd_data[i]))));
   end;
   ShowMessage('Finished');
 { /* for i :=0 to 100
   do
   begin
     lstLog.Items.Add(ByteToHex(DataData.rhd_data[i]));
     lstLog.Items.Add(Chr(StrToInt('$'+ByteToHex(DataData.rhd_data[i]))));
   end;  */ }



end;

end.
