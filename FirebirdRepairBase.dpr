program FirebirdRepairBase;

uses
  Forms,
  Windows,
  SysUtils,
  Dialogs,
  main in 'main.pas' {frmMain},
  uStructs in 'uStructs.pas',
  uCommon in 'uCommon.pas',
  uTipPage in 'uTipPage.pas',
  uDataPage in 'uDataPage.pas',
  uGenPage in 'uGenPage.pas',
  uPointer in 'uPointer.pas',
  uPageAnalyzer in 'uPageAnalyzer.pas',
  uBtreePage in 'uBtreePage.pas',
  uDatabaseStats in 'uDatabaseStats.pas',
  uFlagManager in 'uFlagManager.pas',
  uRecordParser in 'uRecordParser.pas';

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
      MessageBox(Application.Handle,
        PChar(' Fatal error. Application will be closed' + E.Message), 'ERROR',
        MB_ICONERROR + MB_OK);
      Application.Terminate;
    end;
  end;

end.
