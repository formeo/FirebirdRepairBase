unit uSearchForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, 
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids, Vcl.Buttons;

type
  TSearchForm = class(TForm)
    // ===== TOP PANEL - Критерии поиска =====
    pnlTop: TPanel;
      lblSearchFor: TLabel;
      edtSearchText: TEdit;                    // Текст для поиска
      rgSearchType: TRadioGroup;               // Text/Hex/Integer/Date
      
      lblPageRange: TLabel;
      edtPageFrom: TEdit;                      // От страницы
      lblPageTo: TLabel;
      edtPageTo: TEdit;                        // До страницы
      btnSelectAll: TSpeedButton;              // Все страницы
      
      chkCaseSensitive: TCheckBox;            // Учитывать регистр
      chkWholeWord: TCheckBox;                // Целое слово
      
      btnSearch: TButton;                      // Кнопка ПОИСК
      btnStop: TButton;                        // Остановить поиск
      
    // ===== MIDDLE PANEL - Фильтры =====
    pnlFilters: TPanel;
      gbPageTypes: TGroupBox;                  // Типы страниц
        chkDataPages: TCheckBox;               // Data pages (5)
        chkIndexPages: TCheckBox;              // Index pages (7)
        chkBlobPages: TCheckBox;               // Blob pages (8)
        chkAllTypes: TCheckBox;                // Все типы
      
    // ===== CENTER PANEL - Результаты поиска =====
    pnlCenter: TPanel;
      lblResults: TLabel;                      // "Найдено: X записей"
      sgResults: TStringGrid;                  // Таблица результатов
      // Колонки: Page# | Type | Offset | Match | Preview
      
    // ===== BOTTOM PANEL - Детали и действия =====
    pnlBottom: TPanel;
      pgcDetails: TPageControl;
        tsHexView: TTabSheet;                  // Hex просмотр
          memHexView: TMemo;
        tsTextView: TTabSheet;                 // Текстовый просмотр
          memTextView: TMemo;
      
      pnlActions: TPanel;
        btnExtract: TButton;                   // Извлечь запись
        btnCopyToClipboard: TButton;          // Скопировать
        btnSaveToFile: TButton;               // Сохранить в файл
        btnJumpToPage: TButton;               // Перейти к странице
        
    // ===== STATUS BAR =====
    StatusBar: TStatusBar;                     // Прогресс поиска
    ProgressBar: TProgressBar;
    
    // События
    procedure btnSearchClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure sgResultsClick(Sender: TObject);
    procedure btnExtractClick(Sender: TObject);
    procedure chkAllTypesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    
  private
    FSearching: Boolean;
    FDatabase: TObject;  // TFBDatabase из основного проекта
    procedure UpdateSearchProgress(Current, Total: Integer);
    procedure AddSearchResult(PageNum, Offset: Integer; const Preview: string);
    procedure DisplayPageContent(PageNum: Integer);
    procedure PerformSearch(const SearchText: string;
                                     PageFrom, PageTo: Integer);
    procedure SearchInPage(PageNum: Integer;
                                    const PageData, Pattern: TBytes);
    function PrepareSearchPattern(const SearchText: string): TBytes;

var
  public
    { Public declarations }
  end;

var
  SearchForm: TSearchForm;

implementation

{$R *.dfm}

procedure TSearchForm.FormCreate(Sender: TObject);
begin
  // Инициализация StringGrid
  sgResults.ColCount := 5;
  sgResults.RowCount := 1;
  sgResults.FixedRows := 1;
  
  // Заголовки колонок
  sgResults.Cells[0, 0] := 'Page #';
  sgResults.Cells[1, 0] := 'Type';
  sgResults.Cells[2, 0] := 'Offset';
  sgResults.Cells[3, 0] := 'Match';
  sgResults.Cells[4, 0] := 'Preview';
  
  // Ширина колонок
  sgResults.ColWidths[0] := 80;   // Page #
  sgResults.ColWidths[1] := 100;  // Type
  sgResults.ColWidths[2] := 80;   // Offset
  sgResults.ColWidths[3] := 150;  // Match
  sgResults.ColWidths[4] := 400;  // Preview
  
  FSearching := False;
  btnStop.Enabled := False;
end;

procedure TSearchForm.btnSearchClick(Sender: TObject);
var
  SearchText: string;
  PageFrom, PageTo: Integer;
begin
  // Валидация
  SearchText := Trim(edtSearchText.Text);
  if SearchText = '' then
  begin
    ShowMessage('Введите текст для поиска');
    edtSearchText.SetFocus;
    Exit;
  end;
  
  PageFrom := StrToIntDef(edtPageFrom.Text, 0);
  PageTo := StrToIntDef(edtPageTo.Text, 0);
  
  if (PageFrom < 0) or (PageTo < PageFrom) then
  begin
    ShowMessage('Некорректный диапазон страниц');
    Exit;
  end;
  
  // Очистка предыдущих результатов
  sgResults.RowCount := 1;
  memHexView.Clear;
  memTextView.Clear;
  
  // Запуск поиска
  FSearching := True;
  btnSearch.Enabled := False;
  btnStop.Enabled := True;
  
//  try
//    PerformSearch(SearchText, PageFrom, PageTo);
//  finally
//    FSearching := False;
//    btnSearch.Enabled := True;
//    btnStop.Enabled := False;
//  end;
end;

procedure TSearchForm.btnStopClick(Sender: TObject);
begin
  FSearching := False;
  StatusBar.SimpleText := 'Поиск остановлен пользователем';
end;

procedure TSearchForm.sgResultsClick(Sender: TObject);
var
  PageNum: Integer;
begin
  if sgResults.Row > 0 then
  begin
    PageNum := StrToIntDef(sgResults.Cells[0, sgResults.Row], 0);
    if PageNum > 0 then
      DisplayPageContent(PageNum);
  end;
end;

procedure TSearchForm.btnExtractClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  PageNum: Integer;
begin
  if sgResults.Row <= 0 then
  begin
    ShowMessage('Выберите запись для извлечения');
    Exit;
  end;
  
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    SaveDialog.DefaultExt := 'txt';
    
    if SaveDialog.Execute then
    begin
      PageNum := StrToIntDef(sgResults.Cells[0, sgResults.Row], 0);
      // TODO: Извлечь данные и сохранить
      ShowMessage('Данные сохранены в ' + SaveDialog.FileName);
    end;
  finally
    SaveDialog.Free;
  end;
end;


procedure TSearchForm.SearchInPage(PageNum: Integer;
                                    const PageData, Pattern: TBytes);
var
  Offset: Integer;
  MatchPos: Integer;
  Preview: string;
begin
  Offset := 0;

  // Ищем все вхождения в странице
  while Offset < Length(PageData) do
  begin
    MatchPos := FindPattern(PageData, Pattern, Offset);

    if MatchPos < 0 then
      Break;

    // Извлекаем превью (50 байт вокруг найденного)
    Preview := ExtractPreview(PageData, MatchPos, 50);

    // Добавляем в результаты
    AddSearchResult(PageNum, MatchPos, Preview);

    // Продолжаем поиск дальше
    Offset := MatchPos + Length(Pattern);
  end;
end;

procedure TSearchForm.chkAllTypesClick(Sender: TObject);
begin
  if chkAllTypes.Checked then
  begin
    chkDataPages.Checked := True;
    chkIndexPages.Checked := True;
    chkBlobPages.Checked := True;
  end;
end;

function TSearchForm.PrepareSearchPattern(const SearchText: string): TBytes;
begin
  case rgSearchType.ItemIndex of
    0: // Text
      Result := TEncoding.UTF8.GetBytes(SearchText);

    1: // Hex
      Result := HexStringToBytes(SearchText);

    2: // Integer
      begin
        SetLength(Result, 4);
        PInteger(@Result[0])^ := StrToIntDef(SearchText, 0);
      end;

    3: // Date
      Result := DateToFirebirdBytes(StrToDate(SearchText));
  end;
end;

procedure TSearchForm.SearchInPage(PageNum: Integer;
                                    const PageData, Pattern: TBytes);
var
  Offset: Integer;
  MatchPos: Integer;
  Preview: string;
begin
  Offset := 0;

  // Ищем все вхождения в странице
  while Offset < Length(PageData) do
  begin
    MatchPos := FindPattern(PageData, Pattern, Offset);

    if MatchPos < 0 then
      Break;

    // Извлекаем превью (50 байт вокруг найденного)
    Preview := ExtractPreview(PageData, MatchPos, 50);

    // Добавляем в результаты
    AddSearchResult(PageNum, MatchPos, Preview);

    // Продолжаем поиск дальше
    Offset := MatchPos + Length(Pattern);
  end;
end;

procedure TSearchForm.PerformSearch(const SearchText: string;
                                     PageFrom, PageTo: Integer);
var
  CurrentPage: Integer;
  TotalPages: Integer;
  PageData: TBytes;
  SearchBytes: TBytes;
  PageType: Integer;
begin
  // 1. Определяем общее количество страниц
  if PageTo = 0 then
    TotalPages := FDatabase.GetTotalPages  // Из главной формы
  else
    TotalPages := PageTo;

  // 2. Конвертируем искомый текст в байты
  SearchBytes := PrepareSearchPattern(SearchText);

  // 3. Сканируем страницы
  for CurrentPage := PageFrom to TotalPages do
  begin
    // Проверка остановки
    if not FSearching then
      Break;

    // Обновляем прогресс
    UpdateSearchProgress(CurrentPage, TotalPages);

    // Читаем страницу
    PageData := FDatabase.ReadPage(CurrentPage);

    // Проверяем тип страницы
    PageType := GetPageType(PageData);

    // Фильтруем по типам
    if not ShouldSearchInPageType(PageType) then
      Continue;

    // Ищем в странице
    SearchInPage(CurrentPage, PageData, SearchBytes);
  end;

  StatusBar.SimpleText := Format('Поиск завершён. Найдено: %d',
                                  [sgResults.RowCount - 1]);
end;


procedure TSearchForm.UpdateSearchProgress(Current, Total: Integer);
begin
  ProgressBar.Max := Total;
  ProgressBar.Position := Current;
  StatusBar.SimpleText := Format('Поиск... %d из %d страниц', [Current, Total]);
  Application.ProcessMessages;
end;

procedure TSearchForm.AddSearchResult(PageNum, Offset: Integer; const Preview: string);
var
  Row: Integer;
begin
  Row := sgResults.RowCount;
  sgResults.RowCount := Row + 1;
  
  sgResults.Cells[0, Row] := IntToStr(PageNum);
  sgResults.Cells[1, Row] := 'Data Page';  // TODO: определить реальный тип
  sgResults.Cells[2, Row] := IntToStr(Offset);
  sgResults.Cells[3, Row] := edtSearchText.Text;
  sgResults.Cells[4, Row] := Preview;
  
  lblResults.Caption := Format('Найдено: %d записей', [Row]);
end;

procedure TSearchForm.DisplayPageContent(PageNum: Integer);
var
  PageData: array[0..16383] of Byte;  // Предполагаем 16K страницы
  i: Integer;
  HexLine, TextLine: string;
begin
  // TODO: Считать страницу из БД
  // FDatabase.ReadPage(PageNum, @PageData);
  
  memHexView.Clear;
  memTextView.Clear;
  
  // Hex view (по 16 байт в строке)
  for i := 0 to 15 do  // Показываем первые 256 байт
  begin
    HexLine := Format('%04X: ', [i * 16]);
    TextLine := '';
    
    // TODO: Заполнить реальными данными
    HexLine := HexLine + '00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F';
    TextLine := '................';
    
    memHexView.Lines.Add(HexLine + '  ' + TextLine);
  end;
  
  // Text view
  memTextView.Lines.Add('Page #' + IntToStr(PageNum) + ' content...');
  memTextView.Lines.Add('TODO: Добавить декодирование текста');
end;

end.
