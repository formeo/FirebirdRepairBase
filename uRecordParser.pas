unit uRecordParser;

interface

uses
  Windows, SysUtils, uStructs, uDataPage;

const
  recDeleted = $01; // Запись помечена как удалённая
  recModified = $02; // Запись была модифицирована
  recHasSegment = $04; // Запись содержит сегмент (часть BLOB)
  recHasNulls = $08; // Запись содержит NULL значения
  recVersioned = $10; // Запись версионирована (MVCC)
  recLocalMod = $20; // Локальная модификация
  recRemoteMod = $40; // Удалённая модификация
  recLastForm = $80; // Последняя форма записи (в цепочке?)


  MIN_REC_HEADER_SIZE = 18;

type

  TRecordHeader = record
    Flags: UShort;            // rec_flags
    TransactionID: SLong;     // rec_transaction
    BackPointer: SLong;       // rec_back (SLONG - это кодирование PageNum и SlotNum)
    NextPointer: SLong;       // rec_next (SLONG - кодирование)
    Format: UShort;           // rec_format
    DataLength: UShort;       // rec_length
  end;

  TParsedRecordFragment = record
    Header: TRecordHeader;
    Data: TBytes;             // Фактические данные записи (rec_data)
    OffsetInPage: Word;       // Смещение фрагмента в исходной Data Page
    IsDeleted: Boolean;       // Удобное поле: результат проверки Flags
    // PageNum, SlotNum: Integer; // Можно добавить, если раскодируем rec_back/next
  end;


  TParsedRecordFragmentArray = array of TParsedRecordFragment;


  TRecordParser = class
  private
    // Внутренняя функция для извлечения заголовка из байтов
    function GetRecordHeaderFromBytes(const RecordFragmentData: TBytes): TRecordHeader;
  public
    // Парсит один фрагмент записи (TRecordFragment из uDataPage)
    // Вход: RawFragmentData - байты фрагмента (TRecordFragment.Data)
    //       FragmentOffset - смещение этого фрагмента на странице (TRecordFragment.Offset)
    // Возврат: TParsedRecordFragment с распарсенными данными
    function ParseRecordFragment(const RawFragmentData: TBytes; FragmentOffset: Word): TParsedRecordFragment;

    // Парсит массив фрагментов записей (например, результат uDataPage.ExtractDataFragments)
    // Вход: RawFragments - массив TRecordFragment
    // Возврат: массив TParsedRecordFragmentArray
    function ParseRecordFragments(const RawFragments: TRecordFragmentsArray): TParsedRecordFragmentArray;

    // Вспомогательная функция: проверяет, помечена ли версия как удалённая
    function IsRecordDeleted(const Header: TRecordHeader): Boolean;

    // Вспомогательная функция: проверяет, версионирована ли запись
    function IsRecordVersioned(const Header: TRecordHeader): Boolean;
  end;

implementation

function TRecordParser.GetRecordHeaderFromBytes(const RecordFragmentData: TBytes): TRecordHeader;
var
  Offset: Integer;
begin
  if Length(RecordFragmentData) < MIN_REC_HEADER_SIZE then
    raise Exception.Create('Record fragment data too small for record header.');

  Offset := 0;
  Result.Flags := PWord(@RecordFragmentData[Offset])^;
  Inc(Offset, 2);

  Result.TransactionID := PLongInt(@RecordFragmentData[Offset])^;
  Inc(Offset, 4);

  Result.BackPointer := PLongInt(@RecordFragmentData[Offset])^;
  Inc(Offset, 4);

  Result.NextPointer := PLongInt(@RecordFragmentData[Offset])^;
  Inc(Offset, 4);

  Result.Format := PWord(@RecordFragmentData[Offset])^;
  Inc(Offset, 2);

  Result.DataLength := PWord(@RecordFragmentData[Offset])^;
  Inc(Offset, 2);

  // Проверим, что длина данных не выходит за пределы буфера
  if Offset + Result.DataLength > Length(RecordFragmentData) then
    raise Exception.Create('Record header specifies data length exceeding fragment buffer size.');
end;

function TRecordParser.ParseRecordFragment(const RawFragmentData: TBytes; FragmentOffset: Word): TParsedRecordFragment;
begin
  Result.Header := GetRecordHeaderFromBytes(RawFragmentData);
  Result.OffsetInPage := FragmentOffset;
  Result.IsDeleted := IsRecordDeleted(Result.Header);

  // Копируем данные записи (rec_data)
  SetLength(Result.Data, Result.Header.DataLength);
  if Result.Header.DataLength > 0 then
    Move(RawFragmentData[MIN_REC_HEADER_SIZE], Result.Data[0], Result.Header.DataLength);
end;

function TRecordParser.ParseRecordFragments(const RawFragments: TRecordFragmentsArray): TParsedRecordFragmentArray;
var
  i: Integer;
begin
  SetLength(Result, Length(RawFragments));
  for i := 0 to High(RawFragments) do
  begin
    Result[i] := ParseRecordFragment(RawFragments[i].Data, RawFragments[i].Offset);
  end;
end;

function TRecordParser.IsRecordDeleted(const Header: TRecordHeader): Boolean;
begin
  Result := (Header.Flags and recDeleted) <> 0;
end;

function TRecordParser.IsRecordVersioned(const Header: TRecordHeader): Boolean;
begin
  Result := (Header.Flags and recVersioned) <> 0;
end;

end.
