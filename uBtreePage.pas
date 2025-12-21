unit uBtreePage;

interface

uses
  Windows, SysUtils, uStructs, Math;

const
  pag_left  = $01; // Это самая левая страница в уровне
  pag_root  = $02; // Это корневая страница
  pag_leaf  = $04; // Это листовая страница

  key_delete = $01; // Ключ помечен как удалённый
  key_right  = $02; // Ключ указывает на правый узел (внутренний узел)
  key_bias   = $04; // Ключ является смещенным (bias key)
  key_dupeq  = $08; // Ключ помечен как дубликат (для уникальных индексов)

type
  TBtreePageHeader = packed record
    pag_header: TPag;  // 0x00-0x0F - Стандартный заголовок
    pag_next: SLong;   // 0x10-0x13 - Указатель на следующую страницу (лист)
    pag_sibling: SLong;// 0x14-0x17 - Указатель на соседнюю страницу
    pag_parent: SLong; // 0x18-0x1B - Указатель на родительскую страницу
    pag_count: UShort; // 0x1C-0x1D - Количество ключей на странице
    pag_flags: UChar;  // 0x1E     - Флаги страницы
    pag_fill: UChar;   // 0x1F     - Процент заполнения (не используется)
    // pag_keys начинается с байта 0x20
  end;


  TBtreeKey = record
    Length: UShort;
    Flags: SChar;
    Data: TBytes;
    PageOrRecordNumber: SLong;
  end;


  TBtreeKeyArray = array of TBtreeKey;


  TBtreePageAnalyzer = class
  private
    FPageSize: Integer;
    FPageNumber: ULong; // Номер самой B-Tree страницы (передаётся для контекста)
    FHeader: TBtreePageHeader;
    FPageData: TBytes; // Данные всей страницы (для извлечения ключей)


    function GetKeyAtOffset(Offset: Integer): TBtreeKey;

    function GetIsLeaf: Boolean;
    function GetIsRoot: Boolean;
    function GetIsLeftmost: Boolean;
  public
    // Конструктор - принимает байты страницы, размер страницы и номер страницы
    constructor Create(const PageBuffer: TBytes; PageSize: Integer; PageNum: ULong);

    // Получить массив всех ключей на странице
    function GetKeys: TBtreeKeyArray;

    // Получить флаги страницы
    property Flags: UChar read FHeader.pag_flags;
    // Получить количество ключей
    property Count: UShort read FHeader.pag_count;
    // Получить номер следующей страницы
    property NextPage: SLong read FHeader.pag_next;
    // Получить номер соседней страницы
    property SiblingPage: SLong read FHeader.pag_sibling;
    // Получить номер родительской страницы
    property ParentPage: SLong read FHeader.pag_parent;
    // Это листовая страница?
    property IsLeaf: Boolean read GetIsLeaf; // Используем метод-геттер
    // Это корневая страница?
    property IsRoot: Boolean read GetIsRoot; // Используем метод-геттер
    // Это самая левая страница?
    property IsLeftmost: Boolean read GetIsLeftmost; // Используем метод-геттер

  end;

implementation

constructor TBtreePageAnalyzer.Create(const PageBuffer: TBytes; PageSize: Integer; PageNum: ULong);
var
  ExpectedMinSize: Integer;
begin
  if (PageSize < MIN_PAGE_SIZE) or (PageSize > MAX_PAGE_SIZE) or
     (Length(PageBuffer) <> PageSize) then
    raise Exception.Create('Invalid page size or buffer size for B-Tree page.');

  ExpectedMinSize := SizeOf(TBtreePageHeader);
  if Length(PageBuffer) < ExpectedMinSize then
    raise Exception.Create('Page buffer too small for B-Tree header.');

  // Копируем фиксированную часть заголовка
  Move(PageBuffer[0], FHeader, SizeOf(TBtreePageHeader));

  // Проверяем тип страницы
  if FHeader.pag_header.pag_type <> $07 then
    raise Exception.Create('Not a B-Tree Index Page.');

  FPageSize := PageSize;
  FPageNumber := PageNum;
  FPageData := Copy(PageBuffer); // Копируем все данные страницы
end;

function TBtreePageAnalyzer.GetKeyAtOffset(Offset: Integer): TBtreeKey;
var
  KeyLength: UShort;
  KeyFlags: SChar;
  KeyDataOffset, KeyPageOffset: Integer;
begin

  if (Offset + 2 {key_length} + 1 {key_flags} > Length(FPageData)) then
    raise Exception.Create('Invalid offset for key in B-Tree page.');

  KeyLength := PWord(@FPageData[Offset])^;
  Inc(Offset, 2);


  KeyFlags := PShortInt(@FPageData[Offset])^;
  Inc(Offset, 1);


  if (Offset + KeyLength + 4 {key_page} > Length(FPageData)) then
    raise Exception.Create('Key length exceeds page boundary.');


  SetLength(Result.Data, KeyLength);
  if KeyLength > 0 then
    Move(FPageData[Offset], Result.Data[0], KeyLength);
  Inc(Offset, KeyLength);


  Result.PageOrRecordNumber := PLongInt(@FPageData[Offset])^;


  Result.Length := KeyLength;
  Result.Flags := KeyFlags;
end;

function TBtreePageAnalyzer.GetKeys: TBtreeKeyArray;
var
  i: Integer;
  CurrentOffset: Integer;
  Keys: TBtreeKeyArray;
begin
  SetLength(Keys, FHeader.pag_count);


  CurrentOffset := SizeOf(TBtreePageHeader);

  for i := 0 to FHeader.pag_count - 1 do
  begin
    Keys[i] := GetKeyAtOffset(CurrentOffset);
    CurrentOffset := CurrentOffset + 2 + 1 + Keys[i].Length + 4;
  end;

  Result := Keys;
end;


function TBtreePageAnalyzer.GetIsLeaf: Boolean;
begin
  Result := (FHeader.pag_flags and pag_leaf) <> 0;
end;

function TBtreePageAnalyzer.GetIsRoot: Boolean;
begin
  Result := (FHeader.pag_flags and pag_root) <> 0;
end;

function TBtreePageAnalyzer.GetIsLeftmost: Boolean;
begin
  Result := (FHeader.pag_flags and pag_left) <> 0;
end;

end.
