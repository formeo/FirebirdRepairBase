program FirebirdRepairBase;

uses
  Forms,
  Windows,
  SysUtils,
  Dialogs,
  main in 'main.pas' {frmMain},
  struck in 'struck.pas',
  uCommon in 'uCommon.pas',
  uDatabase in 'uDatabase.pas',
  uHeaderPage in 'uHeaderPage.pas',
  uPag in 'uPag.pas',
  uTipPage in 'uTipPage.pas',
  uDataPage in 'uDataPage.pas',
  uGenPage in 'uGenPage.pas',
  uPoiner in 'uPoiner.pas';

{$R *.res}

begin
  try
    Application.Initialize;
    Application.Title := 'FirebirdRepairBase';
    Application.CreateForm(TfrmMain, frmMain);
    Application.Run;
  except
    on E: Exception do
    begin
        MessageBox(Application.Handle, PChar(' Fatal error. Application will be closed'  + E.Message),
            'ERROR', MB_ICONERROR + MB_OK);
        Application.Terminate;
    end;
  end;
end.
