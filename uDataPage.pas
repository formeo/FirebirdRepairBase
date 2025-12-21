unit uDataPage;

interface

uses
  Windows, SysUtils, uStructs, Math;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;

type
  TDpg_rpt = packed record
    dpg_offset: Word;
    dpg_length: Word;
  end;


  TData_Page_Fixed_Part = packed record
    pagHdr_Header: TPag;        // 0x00 - Стандартный заголовок (16 байт)
    dpg_sequence: Longint;      // 0x10 - Номер в последовательности (4 байта)
    dpg_relation: Word;         // 0x14 - ID отношения (2 байта)
    dpg_count: Word;            // 0x16 - Количество фрагментов (2 байта)
  end;

  TRecordFragment = record
    Offset: Word;
    Data: TBytes; // Используем динамический массив байтов
  end;
  TRecordFragmentsArray = array of TRecordFragment;
function ExtractDataFragments(const PageBuffer: TBytes; PageSize: Integer): TRecordFragmentsArray;

// Функция для получения фиксированной части заголовка Data Page из буфера
function GetDataPageHeader(const PageBuffer: TBytes): TData_Page_Fixed_Part;

implementation

function GetDataPageHeader(const PageBuffer: TBytes): TData_Page_Fixed_Part;
begin
  if Length(PageBuffer) < SizeOf(TData_Page_Fixed_Part) then
    raise Exception.Create('Page buffer too small for Data Page header.');

  if PageBuffer[0] <> $05 then // pag_type == 0x05
    raise Exception.Create('Not a Data Page.');

  // Используем Move для копирования байтов в структуру
  Move(PageBuffer[0], Result, SizeOf(TData_Page_Fixed_Part));
end;

function ExtractDataFragments(const PageBuffer: TBytes; PageSize: Integer): TRecordFragmentsArray;
var
  Header: TData_Page_Fixed_Part;
  Fragments: TRecordFragmentsArray;
  i, Count: Integer; // Тип для Count
  ActualCount: Integer; // Тип для ActualCount
  DpgRepeatStartOffset: Integer;
  DataAreaStartOffset: Integer; // Новое: начало области данных (после dpg_repeat)
  FragmentEntryOffset: Integer;
  FragmentRec: TDpg_rpt;
  FragmentStart, FragmentEnd: Integer;
  FragmentLength: Word;
  MaxPossibleCount: Integer; // Новое: максимальное возможное количество записей
begin
  Result := nil; // Инициализация результата

  // Проверка на минимальный размер и соответствие размера буфера
  if (PageSize < MIN_PAGE_SIZE) or (PageSize > MAX_PAGE_SIZE) or
     (Length(PageBuffer) <> PageSize) then
  begin
    Exit; // Возвращаем nil, если размер неверен
  end;

  // Получаем фиксированную часть заголовка
  Header := GetDataPageHeader(PageBuffer);

  Count := Header.dpg_count;

  DpgRepeatStartOffset := SizeOf(TData_Page_Fixed_Part); // = 0x18


  MaxPossibleCount := (PageSize - DpgRepeatStartOffset) div SizeOf(TDpg_rpt);


  ActualCount := IfThen(Count < MaxPossibleCount, Count, MaxPossibleCount);

  DataAreaStartOffset := DpgRepeatStartOffset + (ActualCount * SizeOf(TDpg_rpt));

  SetLength(Fragments, ActualCount);

  for i := 0 to ActualCount - 1 do
  begin
    FragmentEntryOffset := DpgRepeatStartOffset + (i * SizeOf(TDpg_rpt));
    Move(PageBuffer[FragmentEntryOffset], FragmentRec, SizeOf(TDpg_rpt));
    FragmentStart := FragmentRec.dpg_offset;
    FragmentLength := FragmentRec.dpg_length;
    if (FragmentLength > 0) and
       (FragmentStart >= DataAreaStartOffset) and
       (FragmentStart <= Cardinal(PageSize - FragmentLength)) then
    begin
      Fragments[i].Offset := FragmentStart;
      SetLength(Fragments[i].Data, FragmentLength);
      Move(PageBuffer[FragmentStart], Fragments[i].Data[0], FragmentLength);
    end
    else
    begin
      Fragments[i].Offset := FragmentStart;
      SetLength(Fragments[i].Data, 0);
    end;
  end;

  Result := Fragments;
end;

end.
