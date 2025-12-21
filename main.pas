unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileCtrl, ComCtrls, uStructs, DB, ExtCtrls,
  Menus, uCommon, uDatabase, XPMan, uDataPage, Grids, DBGrids, DBClient,
  DBCtrls, Spin, Vcl.Buttons,
  uPageAnalyzer, uDatabaseStats, uFlagManager;

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
    pnl6: TPanel;
    grpProcess: TGroupBox;
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
    sePosition: TSpinEdit;
    lbresult: TLabel;
    btnStopSearch: TButton;
    dsPagesRelation: TIntegerField;
    procedure btnOpenClick(Sender: TObject);
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
    FPageAnalyzer: TPageAnalyzer;
    FDatabaseStats: TDatabaseStats;
    FFlagManager: TFlagManager;
    FCurrentDBFileName: string;
    procedure clearUserGui;
    procedure checkDB;
    procedure UpdateFlagCheckboxesFromManager;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if dlgOpenDB.Execute then
  begin
    // Освобождаем предыдущую БД, если была
    btnClearDBClick(Sender); // Вызовем старую логику очистки

    try
      // Создаем анализатор
      FPageAnalyzer := TPageAnalyzer.Create(dlgOpenDB.FileName);
      // Создаем статистик
      FDatabaseStats := TDatabaseStats.Create(FPageAnalyzer);
      // Создаем менеджер флагов
      FFlagManager := TFlagManager.Create(dlgOpenDB.FileName);
      // Сохраняем имя файла
      FCurrentDBFileName := dlgOpenDB.FileName;

      lbNameDB.Caption := FPageAnalyzer.FileName;
      btnOpen.Enabled := False;
      clearUserGui; // Очищаем UI перед анализом
      checkDB; // Запускаем анализ через FDatabaseStats
    except
      on E: Exception do
      begin
        btnClearDBClick(Sender); // Очищаем, если возникла ошибка
        raise; // Повторно выбрасываем исключение
      end;
    end;
  end;
end;

procedure TfrmMain.mniN1Click(Sender: TObject);
begin
  if dlgSave1.Execute then
    lstLog.Items.SaveToFile(dlgSave1.FileName);
end;

procedure TfrmMain.btnSeekClick(Sender: TObject);
var
  PageNum: Int64;
  PageInfo: TPageInfo;
begin
  // Блокируем элементы на время операции
  edtPageNumber.Enabled := False;
  btnSeek.Enabled := False;
  cbbTypePage.Enabled := False;
  edtCheckSum.Enabled := False;
  btnReWrite.Enabled := False;

  try
    PageNum := StrToIntDef(edtPageNumber.text, 0);
    // Проверяем, в пределах ли номер страницы
    if (PageNum < 0) or (PageNum > FPageAnalyzer.GetLastPageNumber) then
    begin
      cbbTypePage.text := 'Unknown (Out of bounds)';
      edtCheckSum.text := 'N/A';
      Exit;
    end;

    PageInfo := FPageAnalyzer.GetPageInfo(PageNum);

    cbbTypePage.text := PageInfo.TypeStr;
    edtCheckSum.text := IntToStr(PageInfo.Header.pag_checksum);

  finally
    // Восстанавливаем доступность элементов
    edtPageNumber.Enabled := true;
    btnSeek.Enabled := true;
    cbbTypePage.Enabled := true;
    edtCheckSum.Enabled := true;
    btnReWrite.Enabled := true;
  end;
end;

procedure TfrmMain.btnReWriteClick(Sender: TObject);
var
  PageNum: Int64;
  NewChecksum: Integer;
  NewType: Integer;
  PageInfo: TPageInfo;
  NewPageBuffer: TBytes;
  FileStream: TFileStream;
begin
  // ReWriting page - ВНИМАНИЕ: Это ОПАСНАЯ операция!
  if Application.MessageBox('Do You Want to Rewrite Database Page? THIS IS DANGEROUS!',
    'ReWriting Page', MB_OKCANCEL + MB_ICONQUESTION) = 6 then
  begin
    PageNum := StrToIntDef(edtPageNumber.text, 0);
    NewChecksum := StrToIntDef(edtCheckSum.text, 12345);
    NewType := cbbTypePage.ItemIndex - 1; // Или как-то иначе, в зависимости от cbbTypePage

    try
      // Получаем текущую страницу
      PageInfo := FPageAnalyzer.GetPageInfo(PageNum);
      NewPageBuffer := Copy(PageInfo.Buffer); // Копируем текущий буфер

      // Модифицируем заголовок в буфере
      TPag(NewPageBuffer[0]).pag_checksum := UShort(NewChecksum);
      if (NewType >= 0) and (NewType <= $FF) then // Проверяем диапазон
        TPag(NewPageBuffer[0]).pag_type := SChar(NewType);

      // Записываем изменённый буфер обратно в файл
      FileStream := TFileStream.Create(FPageAnalyzer.FileName, fmOpenReadWrite or fmShareExclusive);
      try
        FileStream.Seek(PageNum * FPageAnalyzer.PageSize, soFromBeginning);
        if FileStream.Write(NewPageBuffer[0], FPageAnalyzer.PageSize) <> FPageAnalyzer.PageSize then
          raise Exception.Create('Error writing page.');
      finally
        FileStream.Free;
      end;

      Application.MessageBox('Page ReWritten!', 'Information', MB_OK + MB_ICONWARNING);
    except
      on E: Exception do
      begin
        Application.MessageBox(PChar('Error rewriting page: ' + E.Message), 'Error', MB_OK + MB_ICONERROR);
      end;
    end;
  end
end;

// btnGetDataClick: оставлен пустым или с комментарием, как и раньше
procedure TfrmMain.btnGetDataClick(Sender: TObject);
begin
  // Эта функция требует доработки или удаления
  // Может быть использована для вывода сырых байтов страницы
  lstLog.Items.Add('btnGetDataClick: Not implemented.');
end;

// btnPIPClick: оставлен пустым или с комментарием, как и раньше
procedure TfrmMain.btnPIPClick(Sender: TObject);
begin
  // Эта функция требует доработки или удаления
  lstLog.Items.Add('btnPIPClick: Not implemented.');
end;

procedure TfrmMain.btnClearDBClick(Sender: TObject);
begin
  // Освобождаем ресурсы
  FPageAnalyzer.Free;
  FDatabaseStats.Free;
  FFlagManager.Free;
  FPageAnalyzer := nil;
  FDatabaseStats := nil;
  FFlagManager := nil;
  FCurrentDBFileName := '';

  btnOpen.Enabled := true;
  clearUserGui;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  btnClearDBClick(Sender); // Очищаем ресурсы при закрытии формы
end;

procedure TfrmMain.btnGetHeaderFlagsClick(Sender: TObject);
var
  Flags: TDatabaseFlags;
begin
  lstDBFlags.Items.Clear; // Очищаем перед добавлением
  edtFlags.text := ''; // Очищаем поле

  if not Assigned(FFlagManager) then
  begin
    lstDBFlags.Items.Add('No database loaded.');
    Exit;
  end;

  try
    Flags := FFlagManager.GetFlags;

    // Формируем строку для отображения (например, бинарное представление или просто список)
    // Для простоты, выведем список активных флагов
    edtFlags.text := 'Active flags: ';
    if Flags.ActiveShadow then edtFlags.text := edtFlags.text + 'ActiveShadow, ';
    if Flags.ForceWrite then edtFlags.text := edtFlags.text + 'ForceWrite, ';
    if Flags.NoChecksums then edtFlags.text := edtFlags.text + 'NoChecksums, ';
    if Flags.NoReserve then edtFlags.text := edtFlags.text + 'NoReserve, ';
    if Flags.SqlDialect3 then edtFlags.text := edtFlags.text + 'SqlDialect3, ';
    if Flags.ReadOnly then edtFlags.text := edtFlags.text + 'ReadOnly, ';
    // Убираем последнюю запятую
    if edtFlags.text.EndsWith(', ') then
      edtFlags.text := edtFlags.text.Remove(edtFlags.text.Length - 2);

    // Или можно вывести все флаги с указанием статуса
    lstDBFlags.Items.Add(Format('Active Shadow: %s', [BoolToStr(Flags.ActiveShadow, True)]));
    lstDBFlags.Items.Add(Format('Force Write: %s', [BoolToStr(Flags.ForceWrite, True)]));
    lstDBFlags.Items.Add(Format('No Checksums: %s', [BoolToStr(Flags.NoChecksums, True)]));
    lstDBFlags.Items.Add(Format('No Reserve: %s', [BoolToStr(Flags.NoReserve, True)]));
    lstDBFlags.Items.Add(Format('SQL Dialect 3: %s', [BoolToStr(Flags.SqlDialect3, True)]));
    lstDBFlags.Items.Add(Format('Read Only: %s', [BoolToStr(Flags.ReadOnly, True)]));

  except
    on E: Exception do
    begin
      lstDBFlags.Items.Add('Error getting flags: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.clearUserGui;
begin
  lbNameDB.Caption := '';
  edtFlags.text := '';
  lstLog.Items.Clear;
  edtPageNumber.Enabled := False;
  btnSeek.Enabled := False;
end;

procedure TfrmMain.checkDB;
var
  PageStats: TPageTypeStats;
  TxStats: TTransactionStats;
  RelStats: TRelationStatsArray;
  i: Integer;
begin
  if not Assigned(FDatabaseStats) then
    exit;

  try
    lstLog.Items.Clear;
    dsPages.Close;
    dsPages.CreateDataSet;

    lstLog.Items.Add('Database: ' + FPageAnalyzer.FileName);
    lstLog.Items.Add('Database size: ' + IntToStr(FPageAnalyzer.FileSize));
    lstLog.Items.Add('Database page size: ' + IntToStr(FPageAnalyzer.PageSize));
    lstLog.Items.Add('Scanning pages...');

    // Вычисляем статистику через FDatabaseStats
    FDatabaseStats.CalculateStats;

    // Получаем результаты
    PageStats := FDatabaseStats.PageStats;
    TxStats := FDatabaseStats.TransactionStats;
    RelStats := FDatabaseStats.RelationStats;

    // Обновляем прогресс бар (для наглядности, хотя теперь это быстро)
    pbDetectedPage.Min := 0;
    pbDetectedPage.Max := 100; // Условно
    pbDetectedPage.Position := 100;

    // Выводим результаты подсчета
    lstLog.Items.Add('--- Page Type Summary ---');
    lstLog.Items.Add('Count Header Pages: ' + IntToStr(PageStats.HeaderPages));
    lstLog.Items.Add('Count Page Inventory Pages (PIP): ' + IntToStr(PageStats.PipPages));
    lstLog.Items.Add('Count Transaction Inventory Pages (TIP): ' + IntToStr(PageStats.TipPages));
    lstLog.Items.Add('Count Pointer Pages: ' + IntToStr(PageStats.PointerPages));
    lstLog.Items.Add('Count Data Pages: ' + IntToStr(PageStats.DataPages));
    lstLog.Items.Add('Count Index Root Pages: ' + IntToStr(PageStats.IndexRootPages));
    lstLog.Items.Add('Count Index B-Tree Pages: ' + IntToStr(PageStats.IndexBtreePages)); // Исправлено
    lstLog.Items.Add('Count Blob Pages: ' + IntToStr(PageStats.BlobPages));
    lstLog.Items.Add('Count Generator Pages: ' + IntToStr(PageStats.GeneratorPages));
    lstLog.Items.Add('Count Write Ahead Log Pages: ' + IntToStr(PageStats.WalPages));
    lstLog.Items.Add('Count Unknown Pages: ' + IntToStr(PageStats.UnknownPages));

    lstLog.Items.Add('--- Transaction Summary ---');
    lstLog.Items.Add('Count Active Transactions: ' + IntToStr(TxStats.Active));
    lstLog.Items.Add('Count Limbo Transactions: ' + IntToStr(TxStats.Limbo));
    lstLog.Items.Add('Count Dead Transactions: ' + IntToStr(TxStats.Dead));
    lstLog.Items.Add('Count Committed Transactions: ' + IntToStr(TxStats.Committed));
    lstLog.Items.Add('Total Transactions: ' + IntToStr(TxStats.Total));

    lstLog.Items.Add('--- Relation Summary ---');
    lstLog.Items.Add('Count Relations: ' + IntToStr(Length(RelStats)));
    for i := 0 to High(RelStats) do
    begin
      lstLog.Items.Add(Format('  Relation ID: %d, Page Count: %d, Record Fragments Count: %d',
        [RelStats[i].RelationID, RelStats[i].PageCount, RelStats[i].RecordCount]));
    end;

  finally
    dsPages.Close;
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  statDB.Panels[0].Width := 100;
  statDB.Panels[0].text := DateToStr(now());
  pgcServices.pages[0].Show;
end;

procedure TfrmMain.btnWriteFlagsClick(Sender: TObject);
var
  NewFlags: TDatabaseFlags;
begin
  if not Assigned(FFlagManager) then
  begin
    Application.MessageBox('No database loaded.', 'Error', MB_OK + MB_ICONERROR);
    Exit;
  end;

  try
    NewFlags := FFlagManager.GetFlags;

    // Обновляем флаги в соответствии с чекбоксами
    NewFlags.ForceWrite := chkSetFW.Checked;
    NewFlags.ReadOnly := chkReadOnly.Checked;
    // Добавьте другие флаги по необходимости

    // Устанавливаем флаги через FFlagManager
    FFlagManager.SetFlags(NewFlags);

    Application.MessageBox('Header flags updated!', 'Information', MB_OK + MB_ICONINFORMATION);

    UpdateFlagCheckboxesFromManager;
  except
    on E: Exception do
    begin
      Application.MessageBox(PChar('Error setting flags: ' + E.Message), 'Error', MB_OK + MB_ICONERROR);
    end;
  end;
end;

procedure TfrmMain.UpdateFlagCheckboxesFromManager;
var
  CurrentFlags: TDatabaseFlags;
begin
  if not Assigned(FFlagManager) then Exit;

  try
    CurrentFlags := FFlagManager.GetFlags;
    chkSetFW.Checked := CurrentFlags.ForceWrite;
    chkReadOnly.Checked := CurrentFlags.ReadOnly;
  except
    on E: Exception do
    begin
      lstDBFlags.Items.Add('Error updating flags UI: ' + E.Message);
    end;
  end;
end;

// tsFlagsShow - теперь использует UpdateFlagCheckboxesFromManager
procedure TfrmMain.tsFlagsShow(Sender: TObject);
begin
  // Обновляем чекбоксы при показе вкладки
  UpdateFlagCheckboxesFromManager;
end;

// pgcServicesChange - обновляет MaxValue для sePosition
procedure TfrmMain.pgcServicesChange(Sender: TObject);
begin
  if tsGenerateNewPage.Showing then
    if Assigned(FPageAnalyzer) then
    begin
      sePosition.MaxValue := FPageAnalyzer.GetLastPageNumber;
    end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
begin
  // Эта функция требует доработки, возможно, через FPageAnalyzer или TFBDatabase
  lstLog.Items.Add('btnGenerateClick: Not implemented via new modules yet.');
  // Если TFBDatabase.Create нужен для генерации, используйте его или добавьте логику в FPageAnalyzer
  // Пример:
  // if FCurrentDBFileName <> '' then
  // begin
  //   var TempDB := TFBDatabase.Create(FCurrentDBFileName);
  //   try
  //     if TempDB.GenerateNewPagePosition(cbbTypePageGen.ItemIndex, sePosition.Value) = 1 then
  //       Application.MessageBox('Page Added!', 'Information', MB_OK + MB_ICONWARNING);
  //   finally
  //     TempDB.Free;
  //   end;
  // end;
end;

procedure TfrmMain.btnGotoPageClick(Sender: TObject);
var
  PageNum: Int64;
  PageInfo: TPageInfo;
  PageFragments: TRecordFragmentsArray;
  i, j: integer;
begin
  PageNum := StrToIntDef(edtNPage.text, 0);

  if (PageNum < 0) or (PageNum > FPageAnalyzer.GetLastPageNumber) then
  begin
    Application.MessageBox('Page number out of bounds.', 'Error', MB_OK + MB_ICONERROR);
    Exit;
  end;

  try
    PageInfo := FPageAnalyzer.GetPageInfo(PageNum);

    if PageInfo.Header.pag_type <> $05 then // 0x05 = Data Page
    begin
      Application.MessageBox('It is not a Data Page, please select a Data Page.',
        'Information', MB_OK + MB_ICONWARNING);
      exit;
    end;

    btnGotoPage.Enabled := False;
    mmoData.Clear; // Очищаем Memo перед выводом

    // Используем функцию из uDataPage для извлечения фрагментов
    PageFragments := ExtractDataFragments(PageInfo.Buffer, PageInfo.Size);

    pbDataProgress.Min := 0;
    pbDataProgress.Max := Length(PageFragments) - 1; // Количество фрагментов

    for i := 0 to High(PageFragments) do // Используем High для массива
    begin
      pbDataProgress.Position := i;
      mmoData.Lines.Add('Fragment ' + IntToStr(i) + ', Offset: ' + IntToStr(PageFragments[i].Offset));
      var hexData: string := '';
      for j := 0 to High(PageFragments[i].Data) do
      begin
          hexData := hexData + IntToHex(PageFragments[i].Data[j], 2) + ' ';
      end;
      mmoData.Lines.Add('  Data (Hex): ' + Trim(hexData));

      Application.ProcessMessages;
    end;
    mmoData.Lines.Add('--- End of Page Data ---');
  finally
   btnGotoPage.Enabled := True;
  end;
end;

end.
