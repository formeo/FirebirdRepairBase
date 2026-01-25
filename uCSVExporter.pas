unit uCSVExporter;

interface

uses
  Classes, SysUtils, uPageAnalyzer, uDataPage, uRecordParser, uStructs;

type
  // Режим экспорта
  TExportMode = (
    emRawHex,        // Сырые данные в HEX
    emAutoDetect,    // Автоопределение типов (строки, числа)
    emFieldWidths    // Экспорт с указанными ширинами полей
  );

  // Информация о поле (для ручного задания структуры)
  TFieldInfo = record
    Name: string;
    Width: Integer;     // Ширина в байтах
    FieldType: Integer; // 0=raw, 7=smallint, 8=integer, 10=float, 14=varchar, 35=timestamp
  end;
  TFieldInfoArray = array of TFieldInfo;

  // Callback для прогресса
  TProgressCallback = procedure(Current, Total: Integer; var Cancel: Boolean) of object;

  TCSVExporter = class
  private
    FPageAnalyzer: TPageAnalyzer;
    FRecordParser: TRecordParser;
    FDelimiter: Char;
    FIncludeDeleted: Boolean;
    FOnProgress: TProgressCallback;

    // Вспомогательные функции для декодирования типов Firebird
    function BytesToHex(const Data: TBytes; MaxLen: Integer = 0): string;
    function TryDecodeAsString(const Data: TBytes; out Value: string): Boolean;
    function TryDecodeAsInteger(const Data: TBytes; Offset, Size: Integer; out Value: Int64): Boolean;
    function TryDecodeAsFloat(const Data: TBytes; Offset: Integer; out Value: Double): Boolean;
    function TryDecodeAsTimestamp(const Data: TBytes; Offset: Integer; out Value: TDateTime): Boolean;
    function DecodeVarchar(const Data: TBytes; Offset, MaxLen: Integer; out Value: string): Integer;

    // Автоопределение содержимого
    function AutoDetectFields(const Data: TBytes): string;

    // Сбор Data Pages для relation
    function CollectDataPages(RelationID: Word): TArray<ULong>;

  public
    constructor Create(APageAnalyzer: TPageAnalyzer);
    destructor Destroy; override;

    // Экспорт relation в CSV файл
    function ExportRelationToCSV(RelationID: Word; const FileName: string;
      Mode: TExportMode = emAutoDetect): Integer;

    // Экспорт с заданной структурой полей
    function ExportRelationWithFields(RelationID: Word; const FileName: string;
      const Fields: TFieldInfoArray): Integer;

    // Экспорт всех relations в отдельные файлы
    function ExportAllRelations(const OutputDir: string;
      Mode: TExportMode = emAutoDetect): Integer;

    // Получить список relation IDs в базе
    function GetRelationIDs: TArray<Word>;

    property Delimiter: Char read FDelimiter write FDelimiter;
    property IncludeDeleted: Boolean read FIncludeDeleted write FIncludeDeleted;
    property OnProgress: TProgressCallback read FOnProgress write FOnProgress;
  end;

implementation

uses
  Math, DateUtils;

constructor TCSVExporter.Create(APageAnalyzer: TPageAnalyzer);
begin
  inherited Create;
  FPageAnalyzer := APageAnalyzer;
  FRecordParser := TRecordParser.Create;
  FDelimiter := ';';
  FIncludeDeleted := False;
end;

destructor TCSVExporter.Destroy;
begin
  FRecordParser.Free;
  inherited;
end;

function TCSVExporter.BytesToHex(const Data: TBytes; MaxLen: Integer = 0): string;
var
  i, Len: Integer;
begin
  Result := '';
  if MaxLen > 0 then
    Len := Min(Length(Data), MaxLen)
  else
    Len := Length(Data);

  for i := 0 to Len - 1 do
    Result := Result + IntToHex(Data[i], 2);
end;

function TCSVExporter.TryDecodeAsString(const Data: TBytes; out Value: string): Boolean;
var
  i: Integer;
  Ch: Byte;
  IsPrintable: Boolean;
begin
  Result := False;
  Value := '';

  if Length(Data) = 0 then
    Exit;

  // Проверяем, что большинство байтов - печатные символы
  IsPrintable := True;
  for i := 0 to Length(Data) - 1 do
  begin
    Ch := Data[i];
    // Допускаем ASCII 32-126, кириллицу (192-255 в CP1251), TAB, CR, LF
    if not ((Ch >= 32) and (Ch <= 126)) and
       not ((Ch >= 192) and (Ch <= 255)) and
       not (Ch in [9, 10, 13, 0]) then
    begin
      IsPrintable := False;
      Break;
    end;
  end;

  if IsPrintable then
  begin
    // Конвертируем байты в строку (предполагаем CP1251/Win1251)
    SetLength(Value, Length(Data));
    for i := 0 to Length(Data) - 1 do
    begin
      if Data[i] = 0 then
      begin
        SetLength(Value, i);
        Break;
      end;
      Value[i + 1] := Chr(Data[i]);
    end;
    Value := Trim(Value);
    Result := Length(Value) > 0;
  end;
end;

function TCSVExporter.TryDecodeAsInteger(const Data: TBytes; Offset, Size: Integer;
  out Value: Int64): Boolean;
begin
  Result := False;
  Value := 0;

  if Offset + Size > Length(Data) then
    Exit;

  case Size of
    2: begin
      Value := PSmallInt(@Data[Offset])^;
      Result := True;
    end;
    4: begin
      Value := PLongInt(@Data[Offset])^;
      Result := True;
    end;
    8: begin
      Value := PInt64(@Data[Offset])^;
      Result := True;
    end;
  end;
end;

function TCSVExporter.TryDecodeAsFloat(const Data: TBytes; Offset: Integer;
  out Value: Double): Boolean;
begin
  Result := False;
  Value := 0;

  if Offset + 8 > Length(Data) then
    Exit;

  Value := PDouble(@Data[Offset])^;
  // Проверяем на NaN и Infinity
  Result := not IsNan(Value) and not IsInfinite(Value);
end;

function TCSVExporter.TryDecodeAsTimestamp(const Data: TBytes; Offset: Integer;
  out Value: TDateTime): Boolean;
var
  DatePart, TimePart: Integer;
  Days: Integer;
  MSec: Integer;
begin
  Result := False;
  Value := 0;

  if Offset + 8 > Length(Data) then
    Exit;

  // Firebird timestamp: 4 байта дата (дни с 17.11.1858) + 4 байта время (100мкс)
  DatePart := PLongInt(@Data[Offset])^;
  TimePart := PLongInt(@Data[Offset + 4])^;

  // Проверяем разумность значений
  if (DatePart < 0) or (DatePart > 100000) then // ~274 года
    Exit;

  // Базовая дата Firebird: 17 ноября 1858
  try
    Value := EncodeDate(1858, 11, 17) + DatePart;
    // Добавляем время (TimePart в единицах 100 микросекунд)
    MSec := TimePart div 10; // Конвертируем в миллисекунды
    Value := Value + MSec / MSecsPerDay;
    Result := (Value > EncodeDate(1900, 1, 1)) and (Value < EncodeDate(2100, 1, 1));
  except
    Result := False;
  end;
end;

function TCSVExporter.DecodeVarchar(const Data: TBytes; Offset, MaxLen: Integer;
  out Value: string): Integer;
var
  ActualLen: Word;
  i: Integer;
begin
  Result := 0;
  Value := '';

  if Offset + 2 > Length(Data) then
    Exit;

  // VARCHAR в Firebird: 2 байта длина + данные
  ActualLen := PWord(@Data[Offset])^;

  if ActualLen > MaxLen then
    ActualLen := MaxLen;

  if Offset + 2 + ActualLen > Length(Data) then
    ActualLen := Length(Data) - Offset - 2;

  SetLength(Value, ActualLen);
  for i := 0 to ActualLen - 1 do
    Value[i + 1] := Chr(Data[Offset + 2 + i]);

  Result := 2 + ActualLen;
end;

function TCSVExporter.AutoDetectFields(const Data: TBytes): string;
var
  StrValue: string;
  IntValue: Int64;
  FloatValue: Double;
  DateValue: TDateTime;
begin
  // Пробуем разные интерпретации

  // Сначала пробуем как строку
  if TryDecodeAsString(Data, StrValue) and (Length(StrValue) > 0) then
  begin
    // Экранируем кавычки и спецсимволы
    StrValue := StringReplace(StrValue, '"', '""', [rfReplaceAll]);
    StrValue := StringReplace(StrValue, #13#10, ' ', [rfReplaceAll]);
    StrValue := StringReplace(StrValue, #10, ' ', [rfReplaceAll]);
    StrValue := StringReplace(StrValue, #13, ' ', [rfReplaceAll]);
    Result := '"' + StrValue + '"';
    Exit;
  end;

  // Пробуем как целое число (4 байта)
  if (Length(Data) >= 4) and TryDecodeAsInteger(Data, 0, 4, IntValue) then
  begin
    // Проверяем разумность значения
    if (IntValue > -2000000000) and (IntValue < 2000000000) then
    begin
      Result := IntToStr(IntValue);
      Exit;
    end;
  end;

  // Пробуем как timestamp
  if (Length(Data) >= 8) and TryDecodeAsTimestamp(Data, 0, DateValue) then
  begin
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', DateValue);
    Exit;
  end;

  // Пробуем как float
  if (Length(Data) >= 8) and TryDecodeAsFloat(Data, 0, FloatValue) then
  begin
    if (Abs(FloatValue) < 1E15) and (Abs(FloatValue) > 1E-15) or (FloatValue = 0) then
    begin
      Result := FloatToStr(FloatValue);
      Exit;
    end;
  end;

  // Fallback - HEX
  Result := '0x' + BytesToHex(Data, 64);
end;

function TCSVExporter.CollectDataPages(RelationID: Word): TArray<ULong>;
var
  PageNum: ULong;
  PageInfo: TPageInfo;
  DataPageHeader: TData_Page_Fixed_Part;
  PageList: TList;
  i: Integer;
begin
  PageList := TList.Create;
  try
    for PageNum := 0 to FPageAnalyzer.GetLastPageNumber do
    begin
      PageInfo := FPageAnalyzer.GetPageInfo(PageNum);
      if PageInfo.Header.pag_type = pag_data then
      begin
        if Length(PageInfo.Buffer) >= SizeOf(TData_Page_Fixed_Part) then
        begin
          Move(PageInfo.Buffer[0], DataPageHeader, SizeOf(TData_Page_Fixed_Part));
          if DataPageHeader.dpg_relation = RelationID then
            PageList.Add(Pointer(PageNum));
        end;
      end;
    end;

    SetLength(Result, PageList.Count);
    for i := 0 to PageList.Count - 1 do
      Result[i] := ULong(PageList[i]);
  finally
    PageList.Free;
  end;
end;

function TCSVExporter.GetRelationIDs: TArray<Word>;
var
  PageNum: ULong;
  PageInfo: TPageInfo;
  DataPageHeader: TData_Page_Fixed_Part;
  RelList: TList;
  i, j: Integer;
  RelID: Word;
  Found: Boolean;
begin
  RelList := TList.Create;
  try
    for PageNum := 0 to FPageAnalyzer.GetLastPageNumber do
    begin
      PageInfo := FPageAnalyzer.GetPageInfo(PageNum);
      if PageInfo.Header.pag_type = pag_data then
      begin
        if Length(PageInfo.Buffer) >= SizeOf(TData_Page_Fixed_Part) then
        begin
          Move(PageInfo.Buffer[0], DataPageHeader, SizeOf(TData_Page_Fixed_Part));
          RelID := DataPageHeader.dpg_relation;

          // Проверяем, есть ли уже в списке
          Found := False;
          for j := 0 to RelList.Count - 1 do
          begin
            if Word(RelList[j]) = RelID then
            begin
              Found := True;
              Break;
            end;
          end;

          if not Found then
            RelList.Add(Pointer(RelID));
        end;
      end;
    end;

    SetLength(Result, RelList.Count);
    for i := 0 to RelList.Count - 1 do
      Result[i] := Word(RelList[i]);
  finally
    RelList.Free;
  end;
end;

function TCSVExporter.ExportRelationToCSV(RelationID: Word; const FileName: string;
  Mode: TExportMode): Integer;
var
  DataPages: TArray<ULong>;
  PageInfo: TPageInfo;
  Fragments: TRecordFragmentsArray;
  ParsedFragments: TParsedRecordFragmentArray;
  Output: TStringList;
  i, j, PageIdx: Integer;
  Line: string;
  Cancel: Boolean;
begin
  Result := 0;
  Cancel := False;

  DataPages := CollectDataPages(RelationID);
  if Length(DataPages) = 0 then
    Exit;

  Output := TStringList.Create;
  try
    // Заголовок CSV
    case Mode of
      emRawHex:
        Output.Add('PageNum' + FDelimiter + 'FragmentIdx' + FDelimiter +
                   'Offset' + FDelimiter + 'TxID' + FDelimiter +
                   'Flags' + FDelimiter + 'Deleted' + FDelimiter +
                   'DataLen' + FDelimiter + 'DataHex');
      emAutoDetect:
        Output.Add('PageNum' + FDelimiter + 'FragmentIdx' + FDelimiter +
                   'TxID' + FDelimiter + 'Deleted' + FDelimiter + 'Data');
    end;

    for PageIdx := 0 to High(DataPages) do
    begin
      // Callback прогресса
      if Assigned(FOnProgress) then
      begin
        FOnProgress(PageIdx + 1, Length(DataPages), Cancel);
        if Cancel then
          Break;
      end;

      PageInfo := FPageAnalyzer.GetPageInfo(DataPages[PageIdx]);
      Fragments := ExtractDataFragments(PageInfo.Buffer, PageInfo.Size);

      if Length(Fragments) = 0 then
        Continue;

      // Парсим фрагменты
      ParsedFragments := FRecordParser.ParseRecordFragments(Fragments);

      for j := 0 to High(ParsedFragments) do
      begin
        // Пропускаем удалённые, если не включён режим
        if ParsedFragments[j].IsDeleted and not FIncludeDeleted then
          Continue;

        // Пропускаем пустые записи
        if Length(ParsedFragments[j].Data) = 0 then
          Continue;

        case Mode of
          emRawHex:
            begin
              Line := Format('%d%s%d%s%d%s%d%s%d%s%s%s%d%s%s',
                [DataPages[PageIdx], FDelimiter,
                 j, FDelimiter,
                 ParsedFragments[j].OffsetInPage, FDelimiter,
                 ParsedFragments[j].Header.TransactionID, FDelimiter,
                 ParsedFragments[j].Header.Flags, FDelimiter,
                 IfThen(ParsedFragments[j].IsDeleted, 'Y', 'N'), FDelimiter,
                 Length(ParsedFragments[j].Data), FDelimiter,
                 BytesToHex(ParsedFragments[j].Data, 256)]);
            end;

          emAutoDetect:
            begin
              Line := Format('%d%s%d%s%d%s%s%s%s',
                [DataPages[PageIdx], FDelimiter,
                 j, FDelimiter,
                 ParsedFragments[j].Header.TransactionID, FDelimiter,
                 IfThen(ParsedFragments[j].IsDeleted, 'Y', 'N'), FDelimiter,
                 AutoDetectFields(ParsedFragments[j].Data)]);
            end;
        end;

        Output.Add(Line);
        Inc(Result);
      end;
    end;

    Output.SaveToFile(FileName);
  finally
    Output.Free;
  end;
end;

function TCSVExporter.ExportRelationWithFields(RelationID: Word; const FileName: string;
  const Fields: TFieldInfoArray): Integer;
var
  DataPages: TArray<ULong>;
  PageInfo: TPageInfo;
  Fragments: TRecordFragmentsArray;
  ParsedFragments: TParsedRecordFragmentArray;
  Output: TStringList;
  i, j, k, PageIdx, Offset: Integer;
  Line, Header, FieldValue, StrVal: string;
  Cancel: Boolean;
  IntVal: Int64;
  FloatVal: Double;
  DateVal: TDateTime;
begin
  Result := 0;
  Cancel := False;

  if Length(Fields) = 0 then
  begin
    Result := ExportRelationToCSV(RelationID, FileName, emAutoDetect);
    Exit;
  end;

  DataPages := CollectDataPages(RelationID);
  if Length(DataPages) = 0 then
    Exit;

  Output := TStringList.Create;
  try
    // Формируем заголовок из имён полей
    Header := 'PageNum' + FDelimiter + 'TxID';
    for k := 0 to High(Fields) do
      Header := Header + FDelimiter + Fields[k].Name;
    Output.Add(Header);

    for PageIdx := 0 to High(DataPages) do
    begin
      if Assigned(FOnProgress) then
      begin
        FOnProgress(PageIdx + 1, Length(DataPages), Cancel);
        if Cancel then
          Break;
      end;

      PageInfo := FPageAnalyzer.GetPageInfo(DataPages[PageIdx]);
      Fragments := ExtractDataFragments(PageInfo.Buffer, PageInfo.Size);

      if Length(Fragments) = 0 then
        Continue;

      ParsedFragments := FRecordParser.ParseRecordFragments(Fragments);

      for j := 0 to High(ParsedFragments) do
      begin
        if ParsedFragments[j].IsDeleted and not FIncludeDeleted then
          Continue;

        if Length(ParsedFragments[j].Data) = 0 then
          Continue;

        Line := Format('%d%s%d',
          [DataPages[PageIdx], FDelimiter,
           ParsedFragments[j].Header.TransactionID]);

        // Декодируем поля по заданной структуре
        Offset := 0;
        for k := 0 to High(Fields) do
        begin
          FieldValue := '';

          if Offset < Length(ParsedFragments[j].Data) then
          begin
            case Fields[k].FieldType of
              7: // SMALLINT
                begin
                  if TryDecodeAsInteger(ParsedFragments[j].Data, Offset, 2, IntVal) then
                    FieldValue := IntToStr(IntVal);
                  Inc(Offset, 2);
                end;

              8: // INTEGER
                begin
                  if TryDecodeAsInteger(ParsedFragments[j].Data, Offset, 4, IntVal) then
                    FieldValue := IntToStr(IntVal);
                  Inc(Offset, 4);
                end;

              16: // BIGINT
                begin
                  if TryDecodeAsInteger(ParsedFragments[j].Data, Offset, 8, IntVal) then
                    FieldValue := IntToStr(IntVal);
                  Inc(Offset, 8);
                end;

              10, 11: // FLOAT, DOUBLE
                begin
                  if TryDecodeAsFloat(ParsedFragments[j].Data, Offset, FloatVal) then
                    FieldValue := FloatToStr(FloatVal);
                  Inc(Offset, 8);
                end;

              14, 37: // CHAR, VARCHAR
                begin
                  Inc(Offset, DecodeVarchar(ParsedFragments[j].Data, Offset,
                    Fields[k].Width, StrVal));
                  FieldValue := '"' + StringReplace(StrVal, '"', '""', [rfReplaceAll]) + '"';
                end;

              35: // TIMESTAMP
                begin
                  if TryDecodeAsTimestamp(ParsedFragments[j].Data, Offset, DateVal) then
                    FieldValue := FormatDateTime('yyyy-mm-dd hh:nn:ss', DateVal);
                  Inc(Offset, 8);
                end;

              else // RAW
                begin
                  if Offset + Fields[k].Width <= Length(ParsedFragments[j].Data) then
                  begin
                    SetLength(StrVal, Fields[k].Width);
                    Move(ParsedFragments[j].Data[Offset], StrVal[1], Fields[k].Width);
                    FieldValue := '0x' + BytesToHex(
                      Copy(ParsedFragments[j].Data, Offset, Fields[k].Width));
                  end;
                  Inc(Offset, Fields[k].Width);
                end;
            end;
          end;

          Line := Line + FDelimiter + FieldValue;
        end;

        Output.Add(Line);
        Inc(Result);
      end;
    end;

    Output.SaveToFile(FileName);
  finally
    Output.Free;
  end;
end;

function TCSVExporter.ExportAllRelations(const OutputDir: string;
  Mode: TExportMode): Integer;
var
  RelIDs: TArray<Word>;
  i, Count: Integer;
  FileName: string;
  Cancel: Boolean;
begin
  Result := 0;
  Cancel := False;

  RelIDs := GetRelationIDs;

  for i := 0 to High(RelIDs) do
  begin
    if Assigned(FOnProgress) then
    begin
      FOnProgress(i + 1, Length(RelIDs), Cancel);
      if Cancel then
        Break;
    end;

    FileName := IncludeTrailingPathDelimiter(OutputDir) +
      Format('relation_%d.csv', [RelIDs[i]]);

    Count := ExportRelationToCSV(RelIDs[i], FileName, Mode);
    Inc(Result, Count);
  end;
end;

end.
