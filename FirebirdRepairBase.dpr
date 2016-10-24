program FirebirdRepairBase;

uses
  Forms,
  main in 'main.pas' {frmMain},
  struck in 'struck.pas',
  uCommon in 'uCommon.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'FirebirdRepairBase';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
