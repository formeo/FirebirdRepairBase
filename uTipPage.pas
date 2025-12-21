unit uTipPage;

interface

uses
  Windows, SysUtils, uStructs, Math;

type

  TTIPHeader = packed record
    tip_header: TPag;
    tip_next: SLong;
  end;

  TTransactionState = (tsActive, tsLimbo, tsDead, tsCommitted, tsUnknown);
  TTransactionInfo = record
    ID: ULong;
    State: TTransactionState;
  end;


  TTransactionInfoArray = array of TTransactionInfo;


  TTIPAnalyzer = class
  private
    FPageSize: Integer;
    FPageNumber: ULong;
    FTipHeader: TTIPHeader;
    FTipData: TBytes;
    FNextTipPageNum: SLong;

    function GetStateFromBits(Bits: Byte): TTransactionState;
    function GetStartTransactionID: ULong;
    function GetMaxTransactionID: ULong;

  public

    constructor Create(const PageBuffer: TBytes; PageSize: Integer; PageNum: ULong);
    function GetTransactionInfo(StartTxID: ULong = ULong(-1); EndTxID: ULong = ULong(-1)): TTransactionInfoArray;
    property NextTipPageNumber: SLong read FNextTipPageNum;
    property StartTransactionID: ULong read GetStartTransactionID;
    property MaxTransactionID: ULong read GetMaxTransactionID;

  end;

implementation

constructor TTIPAnalyzer.Create(const PageBuffer: TBytes; PageSize: Integer; PageNum: ULong);
var
  ExpectedMinSize: Integer;
begin
  if (PageSize < MIN_PAGE_SIZE) or (PageSize > MAX_PAGE_SIZE) or
     (Length(PageBuffer) <> PageSize) then
    raise Exception.Create('Invalid page size or buffer size for TIP page.');

  ExpectedMinSize := SizeOf(TTIPHeader);
  if Length(PageBuffer) < ExpectedMinSize then
    raise Exception.Create('Page buffer too small for TIP header.');


  Move(PageBuffer[0], FTipHeader, SizeOf(TTIPHeader));

  if FTipHeader.tip_header.pag_type <> $03 then
    raise Exception.Create('Not a Transaction Inventory Page (TIP).');

  FPageSize := PageSize;
  FPageNumber := PageNum;
  FNextTipPageNum := FTipHeader.tip_next;

  SetLength(FTipData, FPageSize - ExpectedMinSize);
  if Length(FTipData) > 0 then
    Move(PageBuffer[ExpectedMinSize], FTipData[0], Length(FTipData));
end;

function TTIPAnalyzer.GetStateFromBits(Bits: Byte): TTransactionState;
begin
  case (Bits and $03) of
    $00: Result := tsActive;
    $01: Result := tsLimbo;
    $02: Result := tsDead;
    $03: Result := tsCommitted;
  else
    Result := tsUnknown;
  end;
end;

function TTIPAnalyzer.GetTransactionInfo(StartTxID, EndTxID: ULong): TTransactionInfoArray;
var
  StartIdx, EndIdx, TxID: ULong;
  RelStartIdx, RelEndIdx: ULong;
  ByteIdx, BitPairIdx: Integer;
  ByteValue: Byte;
  State: TTransactionState;
  InfoList: TTransactionInfoArray;
  InfoCount: Integer;
  MaxPossibleRelTxID: ULong;
begin
  Result := nil;
  MaxPossibleRelTxID := GetMaxTransactionID - GetStartTransactionID;
  if StartTxID = ULong(-1) then
    StartIdx := GetStartTransactionID
  else
    StartIdx := StartTxID;

  if EndTxID = ULong(-1) then
    EndTxID := GetMaxTransactionID;


  if (EndIdx < GetStartTransactionID) or (StartIdx > GetMaxTransactionID) then
    Exit;


  StartIdx := Max(StartIdx, GetStartTransactionID);
  EndIdx := Min(EndIdx, GetMaxTransactionID);


  RelStartIdx := StartIdx - GetStartTransactionID;
  RelEndIdx := EndIdx - GetStartTransactionID;

  if RelStartIdx > MaxPossibleRelTxID then
    Exit;


  SetLength(InfoList, RelEndIdx - RelStartIdx + 1);
  InfoCount := 0;

  TxID := RelStartIdx;
  while TxID <= RelEndIdx do
  begin

    ByteIdx := (TxID div 4);
    BitPairIdx := (TxID mod 4) * 2;

    if ByteIdx >= Length(FTipData) then
      Break;


    ByteValue := FTipData[ByteIdx];
    State := GetStateFromBits(ByteValue shr BitPairIdx);

    InfoList[InfoCount].ID := TxID + GetStartTransactionID;
    InfoList[InfoCount].State := State;
    Inc(InfoCount);

    Inc(TxID);
  end;

  SetLength(Result, InfoCount);
  if InfoCount > 0 then
    Move(InfoList[0], Result[0], InfoCount * SizeOf(TTransactionInfo));
end;


function TTIPAnalyzer.GetStartTransactionID: ULong;
begin
  Result := FPageNumber * ULong((FPageSize - SizeOf(TTIPHeader)) * 4);
end;


function TTIPAnalyzer.GetMaxTransactionID: ULong;
var
  TransactionsPerPage: ULong;
begin
  TransactionsPerPage := ULong((FPageSize - SizeOf(TTIPHeader)) * 4);
  Result := GetStartTransactionID + TransactionsPerPage - 1;
end;

end.
