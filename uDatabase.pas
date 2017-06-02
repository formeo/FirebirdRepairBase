unit uDatabase;

interface

uses classes, Sysutils,uCommon,uHeaderPage;

const
  MAX_PAGE_SIZE = 32768;
  MIN_PAGE_SIZE = 1024;


type
  TFBDatabase = class(TObject)
  private
    _NameDB : string;
    _page_size_curr: integer;
    HeaderPage: THdrPage;
    function GetCount: integer;
    function GetNameDB: string;
    function GetCurrPageSizeDB :integer;
    procedure SetCurrPage;
  public
    constructor Create(nameDB: string);
    destructor Destroy; override;
    procedure AddValue(Value: string);
    procedure Clear;
    function Solve: real;
    function DBFileSize:Int64;
    function typeCurrPage(PageNum: int64):integer;
    function typePageChecksum(PageNum: int64):integer;
    property Count: integer read GetCount;
    property NameDB: string read GetNameDB;
    property Curr_page_size: integer read GetCurrPageSizeDB;


  end;


implementation

{ TDatabase }

procedure TFBDatabase.AddValue(Value: string);
begin

end;

procedure TFBDatabase.Clear;
begin

end;

constructor TFBDatabase.Create(nameDB: string);
begin
   _NameDB:= nameDB;
end;

function TFBDatabase.DBFileSize: Int64;
begin
  result:=GetFileSizeBase(_NameDB);
end;

destructor TFBDatabase.Destroy;
begin

  inherited;
end;

function TFBDatabase.GetCount: integer;
begin

end;

function TFBDatabase.GetCurrPageSizeDB: integer;
var FS: TFileStream;
begin
  result:=_page_size_curr;
end;

function TFBDatabase.GetNameDB: string;
begin
  result := _NameDB;
end;

procedure TFBDatabase.SetCurrPage;
var FS: TFileStream;
begin
  try
    FS := TFileStream.Create(_NameDB, fmOpenRead or fmShareDenyNone);
    FS.Read(HeaderPage, MIN_PAGE_SIZE);
    _page_size_curr:=HeaderPage.fix_data.hdr_page_size;
  finally
    FS.Free;
  end;

  try
    FS := TFileStream.Create(_NameDB, fmOpenRead or fmShareDenyNone);
    FS.Read(HeaderPage, _page_size_curr);
    _page_size_curr:=HeaderPage.fix_data.hdr_page_size;
  finally
    FS.Free;
  end;

end;

function TFBDatabase.Solve: real;
begin

end;

function TFBDatabase.typeCurrPage(PageNum: int64): integer;
var db,i:integer;
    DataPage:TDataPage;
begin
  try
    db := fileopen(_NameDB, fmOpenReadWrite + fmShareExclusive);
    fileseek(db, 0, 0);
    fileseek(db, PageNum*_page_size_curr, 0);
    i := fileread(db, DataPage, _page_size_curr);
    result:= DataPage.fix_data.pagHdr_Header.pag_type;
  finally
    FileClose(db);
  end;
end;

function TFBDatabase.typePageChecksum(PageNum: int64): integer;
var db,i:integer;
    DataPage:TDataPage;
begin
  try
    db := fileopen(_NameDB, fmOpenReadWrite + fmShareExclusive);
    fileseek(db, 0, 0);
    fileseek(db, PageNum*_page_size_curr, 0);
    i := fileread(db, DataPage, _page_size_curr);
    result:= DDataPage.fix_data.pagHdr_Header.pag_checksum;
  finally
    FileClose(db);
  end;    
end;

end.
