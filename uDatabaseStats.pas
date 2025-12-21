unit uDatabaseStats;

interface

uses
  Classes, uPageAnalyzer, uDataPage, uTipPage, uBtreePage;

type
  SChar = Shortint;
  SShort = Smallint;
  UShort = Word;
  SLong = Longint;
  ULong = LongWord;
  UChar = type Byte;

  TPageTypeStats = record
    HeaderPages: ULong;
    PipPages: ULong;
    TipPages: ULong;
    PointerPages: ULong;
    DataPages: ULong;
    IndexRootPages: ULong;
    IndexBtreePages: ULong;
    BlobPages: ULong;
    GeneratorPages: ULong;
    WalPages: ULong;
    UnknownPages: ULong;
  end;


  TTransactionStats = record
    Active: ULong;
    Limbo: ULong;
    Dead: ULong;
    Committed: ULong;
    Total: ULong;
  end;


  TRelationStats = record
    RelationID: ULong;
    PageCount: ULong; // Количество Data Pages, принадлежащих отношению
    RecordCount: ULong; // Пример: количество записей (требует парсинга фрагментов)
  end;
  TRelationStatsArray = array of TRelationStats;

  TDatabaseStats = class
  private
    FPageAnalyzer: TPageAnalyzer;
    FPageStats: TPageTypeStats;
    FTransactionStats: TTransactionStats;
    FRelationStats: TRelationStatsArray;
    FStatsCalculated: Boolean;

    // Внутренняя функция для подсчета типов страниц
    procedure CalculatePageStats;
    // Внутренняя функция для подсчета статистики по TIP
    procedure CalculateTransactionStats;
    // Внутренняя функция для подсчета статистики по отношениям (упрощенная)
    procedure CalculateRelationStats;
  public
    // Конструктор - принимает TPageAnalyzer
    constructor Create(APageAnalyzer: TPageAnalyzer);
    // Деструктор
    destructor Destroy; override;

    // Вычислить всю статистику
    procedure CalculateStats;

    // Получить статистику по типам страниц
    property PageStats: TPageTypeStats read FPageStats;
    // Получить статистику по транзакциям
    property TransactionStats: TTransactionStats read FTransactionStats;
    // Получить статистику по отношениям
    property RelationStats: TRelationStatsArray read FRelationStats;
    // Статистика уже вычислена?
    property StatsCalculated: Boolean read FStatsCalculated;
  end;

implementation

uses
  SysUtils;

constructor TDatabaseStats.Create(APageAnalyzer: TPageAnalyzer);
begin
  inherited Create;
  FPageAnalyzer := APageAnalyzer;
  FStatsCalculated := False;
end;

destructor TDatabaseStats.Destroy;
begin
  inherited;
end;

procedure TDatabaseStats.CalculatePageStats;
var
  PageNum: ULong;
  PageInfo: TPageInfo;
begin

  FillChar(FPageStats, SizeOf(FPageStats), 0);

  for PageNum := 0 to FPageAnalyzer.GetLastPageNumber do
  begin
    PageInfo := FPageAnalyzer.GetPageInfo(PageNum);
    case PageInfo.Header.pag_type of
      pag_header: Inc(FPageStats.HeaderPages);
      pag_pip: Inc(FPageStats.PipPages);
      pag_tip: Inc(FPageStats.TipPages);
      pag_pointer: Inc(FPageStats.PointerPages);
      pag_data: Inc(FPageStats.DataPages);
      pag_index_root: Inc(FPageStats.IndexRootPages);
      pag_index_bt: Inc(FPageStats.IndexBtreePages);
      pag_blob: Inc(FPageStats.BlobPages);
      pag_generator: Inc(FPageStats.GeneratorPages);
      pag_wal: Inc(FPageStats.WalPages);
    else
      Inc(FPageStats.UnknownPages);
    end;
  end;
end;

procedure TDatabaseStats.CalculateTransactionStats;
var
  PageNum: ULong;
  PageInfo: TPageInfo;
  TipAnalyzer: TTIPAnalyzer;
  TxInfoArray: TTransactionInfoArray;
  i: Integer;
begin
  // Инициализируем счетчики
  FillChar(FTransactionStats, SizeOf(FTransactionStats), 0);

  for PageNum := 0 to FPageAnalyzer.GetLastPageNumber do
  begin
    PageInfo := FPageAnalyzer.GetPageInfo(PageNum);
    if PageInfo.Header.pag_type = pag_tip then
    begin
      TipAnalyzer := TTIPAnalyzer.Create(PageInfo.Buffer, PageInfo.Size, PageInfo.Number);
      try
        TxInfoArray := TipAnalyzer.GetTransactionInfo(); // Получить все транзакции на странице
        for i := 0 to High(TxInfoArray) do
        begin
          case TxInfoArray[i].State of
            tsActive: Inc(FTransactionStats.Active);
            tsLimbo: Inc(FTransactionStats.Limbo);
            tsDead: Inc(FTransactionStats.Dead);
            tsCommitted: Inc(FTransactionStats.Committed);
          end;
          Inc(FTransactionStats.Total);
        end;
      finally
        TipAnalyzer.Free;
      end;
    end;
  end;
end;

procedure TDatabaseStats.CalculateRelationStats;
var
  PageNum: ULong;
  PageInfo: TPageInfo;
  DataPageHeader: TData_Page_Fixed_Part;
  Fragments: TRecordFragmentsArray;
  FoundRelation: Boolean;
  i, j: Integer;
begin
  SetLength(FRelationStats, 0);

  for PageNum := 0 to FPageAnalyzer.GetLastPageNumber do
  begin
    PageInfo := FPageAnalyzer.GetPageInfo(PageNum);
    if PageInfo.Header.pag_type = pag_data then
    begin
      if Length(PageInfo.Buffer) >= SizeOf(TData_Page_Fixed_Part) then
      begin
        DataPageHeader := TData_Page_Fixed_Part(PageInfo.Buffer[0]);
        var RelationID := DataPageHeader.dpg_relation;

        FoundRelation := False;
        for j := 0 to High(FRelationStats) do
        begin
          if FRelationStats[j].RelationID = RelationID then
          begin
            Inc(FRelationStats[j].PageCount);
            FoundRelation := True;
            Break;
          end;
        end;


        if not FoundRelation then
        begin
          SetLength(FRelationStats, Length(FRelationStats) + 1);
          FRelationStats[High(FRelationStats)].RelationID := RelationID;
          FRelationStats[High(FRelationStats)].PageCount := 1;
          FRelationStats[High(FRelationStats)].RecordCount := 0;
        end;


        Fragments := ExtractDataFragments(PageInfo.Buffer, PageInfo.Size);

        for j := 0 to High(FRelationStats) do
        begin
          if FRelationStats[j].RelationID = RelationID then
          begin
            Inc(FRelationStats[j].RecordCount, Length(Fragments));
            Break;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDatabaseStats.CalculateStats;
begin
  CalculatePageStats;
  CalculateTransactionStats;
  CalculateRelationStats;
  FStatsCalculated := True;
end;

end.
