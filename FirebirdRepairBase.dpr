program FirebirdRepairBase;

uses
  Forms,
  main in 'main.pas' {frmMain},
  struck in 'struck.pas',
  uCommon in 'uCommon.pas',
  uDatabase in 'uDatabase.pas',
  uHeaderPage in 'uHeaderPage.pas',
  uPag in 'uPag.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'FirebirdRepairBase';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
