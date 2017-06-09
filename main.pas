unit main;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileCtrl, ComCtrls,struck, DB, ExtCtrls,
  Menus, uCommon,uDatabase, XPMan,uDataPage, Grids, DBGrids, DBClient,
  DBCtrls;

  type
PDpg_repeat = ^TDpg_rpt;


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



type
  TfrmMain = class(TForm)
    dlgOpenDB: TOpenDialog;
    dlgSave1: TSaveDialog;
    pmSaveInfo: TPopupMenu;
    mniN1: TMenuItem;
    pnl1: TPanel;
    lbl7: TLabel;
    lbNameDB: TLabel;
    pnl5: TPanel;
    btnOpen: TButton;
    btnCheck: TButton;
    pnl6: TPanel;
    grp1: TGroupBox;
    spl1: TSplitter;
    pnl2: TPanel;
    lstLog: TListBox;
    pnl3: TPanel;
    lbl1: TLabel;
    pbDetectedPage: TProgressBar;
    pgcServices: TPageControl;
    tsWorkPages: TTabSheet;
    grp2: TGroupBox;
    pnl4: TPanel;
    lbl2: TLabel;
    edtPageNumber: TEdit;
    btnSeek: TButton;
    grp3: TGroupBox;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    btnReWrite: TButton;
    edtNextTip: TEdit;
    edtCheckSum: TEdit;
    cbbTypePage: TComboBox;
    ts2: TTabSheet;
    grp4: TGroupBox;
    lbl6: TLabel;
    btnGetHeaderFlags: TButton;
    edtFlags: TEdit;
    tsFlags: TTabSheet;
    btnGetData: TButton;
    pmSaveLog: TPopupMenu;
    btnPIP: TButton;
    btnClearDB: TButton;
    xpmfMain: TXPManifest;
    lbAll: TLabel;
    lb1: TLabel;
    lbCurr: TLabel;
    lstDBFlags: TListBox;
    tsGenerateNewPage: TTabSheet;
    btnGenerate: TButton;
    lb2: TLabel;
    cbbTypePageGen: TComboBox;
    chkSetFW: TCheckBox;
    chkReadOnly: TCheckBox;
    statDB: TStatusBar;
    dsPages: TClientDataSet;
    fPageNumber: TLargeintField;
    fPageType: TStringField;
    dsDataPages: TDataSource;
    dGridPages: TDBGrid;
    fTypePageNumber: TSmallintField;
    btnWriteFlags: TButton;
    dNvgNav: TDBNavigator;
    fCheckSum: TIntegerField;
    pgcPagesData: TPageControl;
    tsDataPage: TTabSheet;
    edtNPage: TEdit;
    btnGotoPage: TButton;
    mmoData: TMemo;
    lb3: TLabel;
    pbDataProgress: TProgressBar;
    edtNewAddr: TEdit;
    lb4: TLabel;
    procedure btnOpenClick(Sender: TObject);
    procedure btnCheckClick(Sender: TObject);
    procedure mniN1Click(Sender: TObject);
    procedure btnSeekClick(Sender: TObject);
    procedure btnReWriteClick(Sender: TObject);
    procedure btnGetDataClick(Sender: TObject);
    procedure btnPIPClick(Sender: TObject);
    procedure btnClearDBClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGetHeaderFlagsClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnWriteFlagsClick(Sender: TObject);
    procedure tsFlagsShow(Sender: TObject);
    procedure pgcServicesChange(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnGotoPageClick(Sender: TObject);

  private
    { Private declarations }
    procedure clearUserGui;
  public
  end;

var
  frmMain: TfrmMain;
  new_header_page: THdrPage;
  page_size_curr: integer;
  RDatabase: TFBDatabase;
implementation

uses uPag;

{$R *.dfm}


procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if dlgOpenDB.Execute then
  begin
     RDatabase:= TFBDatabase.Create(dlgOpenDB.FileName);
     lbNameDB.Caption:=RDatabase.NameDB;
     btnOpen.Enabled:=False;

  end;
end;

procedure TfrmMain.btnCheckClick(Sender: TObject);
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
  if not Assigned(RDatabase) then exit;
  lstLog.Items.Clear;
  dsPages.Close;
  lstLog.Items.Add('Data base: '+ RDatabase.NameDB);
  lstLog.Items.Add('Database size: '+IntToStr(RDatabase.DBFileSize));
  if RDatabase.Curr_page_size = 0 then Application.MessageBox('Database page size is 0. ERROR!','Wrong page size',MB_OK+MB_ICONERROR);
  lstLog.Items.Add('Count Database Pages: '+floatToStr( Round(RDatabase.DBFileSize/RDatabase.Curr_page_size)));
  lbAll.Caption:=floatToStr( Round(RDatabase.DBFileSize/RDatabase.Curr_page_size));
  lbCurr.Caption:='0';
  lstLog.Items.Add('Database page size: '+inttostr(RDatabase.Curr_page_size));
  lstLog.Items.Add('Type pages detecting: ');
  CountPIPPage:=0;
  CountTIPPage:=0;
  CountPointerPage:=0;
  CountDataPage:=0;
  CountIndexRootPage:=0;
  CountBlobPage:=0;
  CountGeneratorPage:=0;
  CountWriteAheadLogPage:=0;
  CountUnknownPage:=0;
  pbDetectedPage.Min:=0;
  pbDetectedPage.Max:=round(RDatabase.DBFileSize/RDatabase.Curr_page_size);
  pbDetectedPage.Position:=1;
  dsPages.CreateDataSet;
  i:=1;
  while not RDatabase.EmptyDataPage
  do
  begin
    DataPage:= RDatabase.GetNextDataPage;
    case DataPage.fix_data.pagHdr_Header.pag_type of
       1:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Header page';dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post;  end;
       2:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Page Inventory Page (PIP)'; inc(CountPIPPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       3:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Page Inventory Page (TIP)'; inc(CountTIPPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       4:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Pointer Page'; inc(CountPointerPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       5:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Data Page'; inc(CountDataPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       6:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Index Root Page'; inc(CountIndexRootPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       7:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Index B-Tree Page'; inc(CountBlobPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       8:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Blob Page'; inc(CountBlobPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       9:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Generator Page'; inc(CountGeneratorPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type;dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post; end;
       10:begin dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Write Ahead Log page'; inc(CountWriteAheadLogPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type; dsPages.Fields[3].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_checksum; dsPages.Post;  end;
    else
      begin
        dsPages.Insert;dsPages.Fields[0].AsInteger:=i;dsPages.Fields[1].AsString:=' Unknown page'; inc(CountUnknownPage); dsPages.Fields[2].AsInteger:=DataPage.fix_data.pagHdr_Header.pag_type; dsPages.Post;
      end
    end;
      inc(i);
      lbCurr.Caption:=IntToStr(i);
      pbDetectedPage.Position:=i;
      Application.ProcessMessages;
  end;   
  lstLog.Items.Add('Count Page Inventory Pages (PIP) '+inttostr(CountPIPPage));
  lstLog.Items.Add('Count Page Inventory Pages (TIP) '+inttostr(CountTIPPage));
  lstLog.Items.Add('Count Pointer Page '+inttostr(CountPointerPage));
  lstLog.Items.Add('Count Data Pages '+inttostr(CountDataPage));
  lstLog.Items.Add('Count Index Root Pages '+inttostr(CountIndexRootPage));
  lstLog.Items.Add('Count Blob Pages '+inttostr(CountBlobPage));
  lstLog.Items.Add('Count Generator Pages '+inttostr(CountGeneratorPage));
  lstLog.Items.Add('Count Write Ahead Log Pages '+inttostr(CountWriteAheadLogPage));
  lstLog.Items.Add('Count Unknown Pages '+inttostr(CountUnknownPage));
end;

procedure TfrmMain.mniN1Click(Sender: TObject);
begin
  if dlgSave1.Execute then lstLog.Items.SaveToFile(dlgSave1.FileName );
end;

procedure TfrmMain.btnSeekClick(Sender: TObject);
var TypePage:integer;
begin
  edtPageNumber.Enabled:=False;
  btnSeek.Enabled:=false;
  cbbTypePage.Enabled:=False;
  edtCheckSum.Enabled:=False;
  btnReWrite.Enabled:=False;


  TypePage:= RDatabase.typeCurrPage(StrToIntDef(edtPageNumber.text,0));
  if TypePage<=0 then  cbbTypePage.Text:='Unknown' else  cbbTypePage.ItemIndex:=TypePage-1;
  edtCheckSum.Text:= IntToStr(RDatabase.typePageChecksum(StrToIntDef(edtPageNumber.text,0)));

  edtPageNumber.Enabled:=true;
  btnSeek.Enabled:=true;
  cbbTypePage.Enabled:=true;
  edtCheckSum.Enabled:=true;
  btnReWrite.Enabled:=true;
end;

procedure TfrmMain.btnReWriteClick(Sender: TObject);
var TypePage:ShortInt;

begin
  //ReWriting page
  if Application.MessageBox('Do You Want to Rewrite Database Page?','ReWriting Page',MB_OKCANCEL+MB_ICONQUESTION) =6
  then
  begin
    TypePage:= RDatabase.typeCurrPage(StrToIntDef(edtPageNumber.text,0));
    if RDatabase.ReWritePage(TypePage,StrToIntDef(edtPageNumber.text,0),StrToIntDef(edtCheckSum.text,12345),StrToIntDef(edtNextTip.text,0),cbbTypePage.ItemIndex-1) then
       Application.MessageBox('Data ReWrited!','Information',MB_OK+MB_ICONWARNING) else
     Application.MessageBox('Data Does Not ReWrited!','Information',MB_OK+MB_ICONERROR);
  end
end;

procedure TfrmMain.btnGetDataClick(Sender: TObject);
var i,db,pCurrSize :Integer;
    DataData:TDataPage;
begin
 {  pCurrSize:=getCurrPageSize(dlgOpenDB.FileName);
   try
     db := fileopen(dlgOpenDB.FileName, fmOpenReadWrite + fmShareExclusive);
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
   ShowMessage('Finished');  }
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
  { firstPointerPage:=-1;
   pCurrSize:=getCurrPageSize(dlgOpenDB.FileName);
   try
     FS := TFileStream.Create(dlgOpenDB.FileName, fmOpenRead or fmShareDenyNone);
     FS.Read(HeaderPage, pCurrSize);
   finally
     FS.Free;
   end;
   firstPointerPage:= HeaderPage.fix_data.hdr_pages;
   try
     db := fileopen(dlgOpenDB.FileName, fmOpenReadWrite + fmShareExclusive);
     fileseek(db, 0, 0);
     fileseek(db, firstPointerPage*pCurrSize, 0);
     i := fileread(db, pPage, pCurrSize);
   finally
     FileClose(db );
   end;

   lstLog.Items.Add('Readed pointer Page ');
   lstLog.Items.Add('RDB$PAGES состоит из  '+inttostr(pPage.fix_data.ppg_count) + ' страниц' );

   try
     db := fileopen(dlgOpenDB.FileName, fmOpenReadWrite + fmShareExclusive);
     fileseek(db, 0, 0);
     fileseek(db, (5*pCurrSize), 0);
     i := fileread(db, DataData, pCurrSize);
   finally
     FileClose(db);
   end;

   try
     db := fileopen(dlgOpenDB.FileName, fmOpenReadWrite + fmShareExclusive);
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

procedure TfrmMain.btnClearDBClick(Sender: TObject);
begin
 if Assigned(RDatabase) then RDatabase.Free;
 btnOpen.Enabled:=True;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(RDatabase)  then  RDatabase.Free;
end;

procedure TfrmMain.btnGetHeaderFlagsClick(Sender: TObject);
var i:integer;
begin
  //Hdr_flags: Two bytes, unsigned. Bytes 0x2a and 0x2b on the page. The database flags.
  //lstPages.Items.Clear;
  edtFlags.Text:='';
  edtFlags.Text:=RDatabase.GetHeaderFlags;
   if  edtFlags.Text[1]  = '1'  then   lstDBFlags.Items.Add('This file is an active shadow file');
   if  edtFlags.Text[2]  = '1'  then   lstDBFlags.Items.Add('The database is in forced writes mode');
   if  edtFlags.Text[4]  = '1'  then   lstDBFlags.Items.Add('Dont calculate checksums');
   if  edtFlags.Text[5]  = '1'  then   lstDBFlags.Items.Add('Dont reserve space for record versions in pages');

   { https://firebirdsql.org/manual/fbint-page-1.html
    hdr_active_shadow	0x01 (bit 0)	This file is an active shadow file.
    hdr_force_write	0x02 (bit 1)	The database is in forced writes mode.
    Unused	0x04 (bit 2)	Was previously for short term journalling, no longer used.
    Unused	0x08 (bit 3)	Was previously for long term journalling, no longer used.
    hdr_no_checksums	0x10 (bit 4)	Don't calculate checksums.
    hdr_no_reserve	0x20 (bit 5)	Don'r reserve space for record versions in pages.
    Unused	0x40 (bit 6)	Was used to indicate that the shared cache file was disabled.
    hdr_shutdown_mask (bit one of two)	0x1080 (bits 7 and 12)	Used with bit 12 (see below) to indicate the database shutdown mode.
    hdr_sql_dialect_3	0x100 (bit 8)	If set, the database is using SQL dialect 3.
    hdr_read_only	0x200 (bit 9)	Database is in read only mode.
    hdr_backup_mask	0xC00 (bits 10 and 11)	Indicates the current backup mode.
    hdr_shutdown_mask (bit two of two)	0x1080 (bits 7 and 12)	Used with bit 7 (see above) to indicate the database shutdown mode



   }



   if  edtFlags.Text[9]  = '1'  then   lstDBFlags.Items.Add('Dialect 3');
   if  edtFlags.Text[10]  = '1'  then   lstDBFlags.Items.Add('Read Only');

end;

procedure TfrmMain.clearUserGui;
begin
  lbNameDB.Caption:='';
  lbCurr.Caption:='0';
  lbAll.Caption:='0';
  edtFlags.text:='';
 // lstPages.Items.Clear;
  lstLog.Items.Clear;
  edtPageNumber.Enabled:=False;
  btnSeek.Enabled:=false
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  statDB.Panels[0].Width:=100;
  statDB.Panels[0].Text:= DateToStr(now());
  pgcServices.Pages[0].Show;
end;

// Write flag function
procedure TfrmMain.btnWriteFlagsClick(Sender: TObject);
var flags,resString:string;
  s:Byte;
  i:Integer;
begin
  flags:=RDatabase.GetHeaderFlags;
  if  flags[1]  = '1'  then   lstDBFlags.Items.Add('This file is an active shadow file');
  if  flags[2]  = '1'  then   lstDBFlags.Items.Add('The database is in forced writes mode');
  if  flags[4]  = '1'  then   lstDBFlags.Items.Add('Dont calculate checksums');
  if  flags[5]  = '1'  then   lstDBFlags.Items.Add('Dont reserve space for record versions in pages');
  if  flags[9]  = '1'  then   lstDBFlags.Items.Add('Dialect 3');
  if  flags[10]  = '1'  then   lstDBFlags.Items.Add('Read Only');
  if chkSetFW.Checked then    flags[2]  := '1' else  flags[2]  := '0';
  if chkReadOnly.Checked then    flags[10]  := '1' else flags[10]  := '0';
  RDatabase.SetHeaderFlags(flags);
end;

procedure TfrmMain.tsFlagsShow(Sender: TObject);
var flags:string;
begin
 { flags:=RDatabase.GetHeaderFlags;
  if  edtFlags.Text[10]  = '1'  then   chkReadOnly.Checked:=True;
  if  edtFlags.Text[2]  = '1'  then   chkSetFW.Checked:=True; }

end;

procedure TfrmMain.pgcServicesChange(Sender: TObject);
var flags : TCaption;
begin
  if tsFlags.Showing then
  begin
    if Assigned(RDatabase) then
    begin
      flags:=RDatabase.GetHeaderFlags;
      if  flags[10]  = '1'  then   chkReadOnly.Checked:=True;
      if  flags[2]  = '1'  then   chkSetFW.Checked:=True;
    end
  end
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
begin
  edtNewAddr.Text:= inttostr(RDatabase.GenerateNewPage(cbbTypePageGen.ItemIndex));
end;

procedure TfrmMain.btnGotoPageClick(Sender: TObject);
var DataPage:TDataPage;
    i:Integer;
begin
 { DataPage:=RDatabase.GetDataPage(StrToIntDef(edtNPaged:cd cd.text,0));
  pbDataProgress.Min:=0;
  pbDataProgress.Max:=length(DataPage.dpg_repeat)-1;
  for i :=0 to length(DataPage.dpg_repeat)-1
  do
  begin
    pbDataProgress.Position:=pbDataProgress.Position+1;
    // mmoData.Text:=  mmoData.Text+' '+  StrToInt('$'+ByteToHex(DataPage.dpg_repeat[i].dpg_offset));
     Application.ProcessMessages;

    // mmoData.Text:=  mmoData.Text+' '+ByteToHex(DataPage.rhd_data[i]) ;
      //mmoData.Text:=  mmoData.Text+' '+Chr(StrToInt('$'+ByteToHex(DataPage.rhd_data[i]))) ;
     {lstData.Items.Add(ByteToHex(DataData.rhd_data[i]));
     lstData.Items.Add(Chr(StrToInt('$'+ByteToHex(DataData.rhd_data[i]))));}
  { end;
       }



end;

end.
