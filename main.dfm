object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Firebird Database Page Analyzer'
  ClientHeight = 680
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15

  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblDatabaseLabel: TLabel
      Left = 16
      Top = 12
      Width = 54
      Height = 15
      Caption = 'Database:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblDatabaseName: TLabel
      Left = 16
      Top = 30
      Width = 72
      Height = 17
      Caption = '(no database)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnOpen: TSpeedButton
      Left = 990
      Top = 12
      Width = 100
      Height = 36
      Caption = 'Open DB'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlight
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnOpenClick
    end
    object btnClose: TSpeedButton
      Left = 884
      Top = 12
      Width = 100
      Height = 36
      Caption = 'Close DB'
      Enabled = False
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnCloseClick
    end
  end

  object pnlStatus: TPanel
    Left = 0
    Top = 60
    Width = 1100
    Height = 28
    Align = alTop
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 1
    object lblStatus: TLabel
      Left = 16
      Top = 6
      Width = 35
      Height = 15
      Caption = 'Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object pbMain: TProgressBar
      Left = 900
      Top = 4
      Width = 190
      Height = 18
      TabOrder = 0
      Visible = False
    end
  end

  object pnlMain: TPanel
    Left = 0
    Top = 88
    Width = 1100
    Height = 570
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object splMain: TSplitter
      Left = 720
      Top = 0
      Width = 6
      Height = 570
      Align = alRight
      Color = clSilver
      ParentColor = False
      ExplicitLeft = 750
      ExplicitHeight = 540
    end
    object pnlLeft: TPanel
      Left = 0
      Top = 0
      Width = 720
      Height = 570
      Align = alClient
      BevelOuter = bvNone
      Padding.Left = 8
      Padding.Top = 8
      Padding.Right = 8
      Padding.Bottom = 8
      TabOrder = 0
      object pgcMain: TPageControl
        Left = 8
        Top = 8
        Width = 704
        Height = 554
        ActivePage = tsOverview
        Align = alClient
        TabOrder = 0
        OnChange = pgcMainChange

        object tsOverview: TTabSheet
          Caption = 'Overview'
          object grpDbInfo: TGroupBox
            Left = 0
            Top = 0
            Width = 696
            Height = 105
            Align = alTop
            Caption = ' Database Information '
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            object lblFileSize: TLabel
              Left = 16
              Top = 25
              Width = 54
              Height = 15
              Caption = 'File Size: -'
            end
            object lblPageSize: TLabel
              Left = 16
              Top = 48
              Width = 58
              Height = 15
              Caption = 'Page Size: -'
            end
            object lblPageCount: TLabel
              Left = 250
              Top = 25
              Width = 68
              Height = 15
              Caption = 'Page Count: -'
            end
            object lblOdsVersion: TLabel
              Left = 250
              Top = 48
              Width = 71
              Height = 15
              Caption = 'ODS Version: -'
            end
          end
          object grpPageStats: TGroupBox
            Left = 0
            Top = 105
            Width = 696
            Height = 210
            Align = alTop
            Caption = ' Page Type Statistics '
            TabOrder = 1
            object lvPageStats: TListView
              Left = 8
              Top = 22
              Width = 680
              Height = 178
              Columns = <
                item
                  Caption = 'Page Type'
                  Width = 200
                end
                item
                  Alignment = taRightJustify
                  Caption = 'Count'
                  Width = 100
                end>
              GridLines = True
              ReadOnly = True
              RowSelect = True
              TabOrder = 0
              ViewStyle = vsReport
            end
          end
          object grpTxStats: TGroupBox
            Left = 0
            Top = 315
            Width = 696
            Height = 160
            Align = alTop
            Caption = ' Transaction Statistics '
            TabOrder = 2
            object lvTxStats: TListView
              Left = 8
              Top = 22
              Width = 680
              Height = 128
              Columns = <
                item
                  Caption = 'State'
                  Width = 200
                end
                item
                  Alignment = taRightJustify
                  Caption = 'Count'
                  Width = 100
                end>
              GridLines = True
              ReadOnly = True
              RowSelect = True
              TabOrder = 0
              ViewStyle = vsReport
            end
          end
        end

        object tsPageInspector: TTabSheet
          Caption = 'Page Inspector'
          ImageIndex = 1
          object grpPageSeek: TGroupBox
            Left = 0
            Top = 0
            Width = 696
            Height = 65
            Align = alTop
            Caption = ' Navigate to Page '
            TabOrder = 0
            object lblPageNumber: TLabel
              Left = 16
              Top = 28
              Width = 77
              Height = 15
              Caption = 'Page Number:'
            end
            object edtPageNumber: TSpinEdit
              Left = 104
              Top = 24
              Width = 120
              Height = 27
              Enabled = False
              MaxValue = 0
              MinValue = 0
              TabOrder = 0
              Value = 0
              OnChange = edtPageNumberChange
            end
            object btnSeekPage: TButton
              Left = 240
              Top = 22
              Width = 100
              Height = 30
              Caption = 'Load Page'
              Enabled = False
              TabOrder = 1
              OnClick = btnSeekPageClick
            end
          end
          object grpPageInfo: TGroupBox
            Left = 0
            Top = 65
            Width = 696
            Height = 280
            Align = alTop
            Caption = ' Page Header Information '
            TabOrder = 1
            object lblPageType: TLabel
              Left = 16
              Top = 32
              Width = 57
              Height = 15
              Caption = 'Page Type:'
            end
            object lblChecksum: TLabel
              Left = 16
              Top = 68
              Width = 58
              Height = 15
              Caption = 'Checksum:'
            end
            object lblSequence: TLabel
              Left = 16
              Top = 104
              Width = 53
              Height = 15
              Caption = 'Sequence:'
            end
            object lblGeneration: TLabel
              Left = 16
              Top = 140
              Width = 61
              Height = 15
              Caption = 'Generation:'
            end
            object cbbPageType: TComboBox
              Left = 104
              Top = 28
              Width = 220
              Height = 23
              Style = csDropDownList
              Enabled = False
              TabOrder = 0
            end
            object edtChecksum: TEdit
              Left = 104
              Top = 64
              Width = 120
              Height = 23
              Enabled = False
              TabOrder = 1
            end
            object edtSequence: TEdit
              Left = 104
              Top = 100
              Width = 120
              Height = 23
              Enabled = False
              ReadOnly = True
              TabOrder = 2
            end
            object edtGeneration: TEdit
              Left = 104
              Top = 136
              Width = 120
              Height = 23
              Enabled = False
              ReadOnly = True
              TabOrder = 3
            end
            object btnRewritePage: TButton
              Left = 16
              Top = 200
              Width = 150
              Height = 36
              Caption = 'Rewrite Page'
              Enabled = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clMaroon
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              TabOrder = 4
              OnClick = btnRewritePageClick
            end
            object chkConfirmRewrite: TCheckBox
              Left = 180
              Top = 210
              Width = 200
              Height = 17
              Caption = 'I understand the risks'
              Enabled = False
              TabOrder = 5
            end
          end
        end

        object tsFlags: TTabSheet
          Caption = 'Database Flags'
          ImageIndex = 2
          object grpCurrentFlags: TGroupBox
            Left = 0
            Top = 0
            Width = 696
            Height = 200
            Align = alTop
            Caption = ' Current Flag Status '
            TabOrder = 0
            object lvFlags: TListView
              Left = 8
              Top = 22
              Width = 680
              Height = 168
              Columns = <
                item
                  Caption = 'Flag'
                  Width = 200
                end
                item
                  Caption = 'Value'
                  Width = 100
                end>
              GridLines = True
              ReadOnly = True
              RowSelect = True
              TabOrder = 0
              ViewStyle = vsReport
            end
          end
          object grpModifyFlags: TGroupBox
            Left = 0
            Top = 200
            Width = 696
            Height = 200
            Align = alTop
            Caption = ' Modify Flags '
            TabOrder = 1
            object chkForceWrite: TCheckBox
              Left = 16
              Top = 32
              Width = 200
              Height = 17
              Caption = 'Force Write (Sync I/O)'
              Enabled = False
              TabOrder = 0
            end
            object chkNoReserve: TCheckBox
              Left = 16
              Top = 60
              Width = 200
              Height = 17
              Caption = 'No Reserve (20% space)'
              Enabled = False
              TabOrder = 1
            end
            object chkNoChecksums: TCheckBox
              Left = 250
              Top = 32
              Width = 200
              Height = 17
              Caption = 'No Checksums'
              Enabled = False
              TabOrder = 2
            end
            object chkReadOnly: TCheckBox
              Left = 250
              Top = 60
              Width = 200
              Height = 17
              Caption = 'Read Only'
              Enabled = False
              TabOrder = 3
            end
            object btnApplyFlags: TButton
              Left = 16
              Top = 110
              Width = 130
              Height = 36
              Caption = 'Apply Changes'
              Enabled = False
              TabOrder = 4
              OnClick = btnApplyFlagsClick
            end
            object btnRefreshFlags: TButton
              Left = 160
              Top = 110
              Width = 130
              Height = 36
              Caption = 'Refresh'
              Enabled = False
              TabOrder = 5
              OnClick = btnRefreshFlagsClick
            end
          end
        end

        object tsDataViewer: TTabSheet
          Caption = 'Data Viewer'
          ImageIndex = 3
          object grpDataPage: TGroupBox
            Left = 0
            Top = 0
            Width = 696
            Height = 65
            Align = alTop
            Caption = ' Select Data Page '
            TabOrder = 0
            object lblDataPageNum: TLabel
              Left = 16
              Top = 28
              Width = 77
              Height = 15
              Caption = 'Page Number:'
            end
            object edtDataPageNum: TSpinEdit
              Left = 104
              Top = 24
              Width = 120
              Height = 27
              Enabled = False
              MaxValue = 0
              MinValue = 0
              TabOrder = 0
              Value = 0
            end
            object btnLoadDataPage: TButton
              Left = 240
              Top = 22
              Width = 120
              Height = 30
              Caption = 'Load Fragments'
              Enabled = False
              TabOrder = 1
              OnClick = btnLoadDataPageClick
            end
          end
          object grpFragments: TGroupBox
            Left = 0
            Top = 65
            Width = 696
            Height = 430
            Align = alClient
            Caption = ' Record Fragments '
            TabOrder = 1
            object mmoFragments: TMemo
              Left = 8
              Top = 22
              Width = 680
              Height = 368
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Consolas'
              Font.Style = []
              ParentFont = False
              ReadOnly = True
              ScrollBars = ssBoth
              TabOrder = 0
              WordWrap = False
            end
            object pbDataLoad: TProgressBar
              Left = 8
              Top = 398
              Width = 680
              Height = 18
              TabOrder = 1
            end
          end
        end

        object tsReports: TTabSheet
          Caption = 'Reports'
          ImageIndex = 4
          object grpExport: TGroupBox
            Left = 0
            Top = 0
            Width = 696
            Height = 200
            Align = alTop
            Caption = ' Export Report '
            TabOrder = 0
            object chkIncludePageStats: TCheckBox
              Left = 16
              Top = 28
              Width = 180
              Height = 17
              Caption = 'Include Page Statistics'
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object chkIncludeTxStats: TCheckBox
              Left = 16
              Top = 52
              Width = 180
              Height = 17
              Caption = 'Include Transaction Stats'
              Checked = True
              State = cbChecked
              TabOrder = 1
            end
            object chkIncludeRelations: TCheckBox
              Left = 220
              Top = 28
              Width = 180
              Height = 17
              Caption = 'Include Relation Stats'
              Checked = True
              State = cbChecked
              TabOrder = 2
            end
            object chkIncludeFlags: TCheckBox
              Left = 220
              Top = 52
              Width = 180
              Height = 17
              Caption = 'Include Database Flags'
              Checked = True
              State = cbChecked
              TabOrder = 3
            end
            object btnExportCSV: TButton
              Left = 16
              Top = 100
              Width = 130
              Height = 40
              Caption = 'Export to CSV'
              TabOrder = 4
              OnClick = btnExportCSVClick
            end
            object btnExportHTML: TButton
              Left = 160
              Top = 100
              Width = 130
              Height = 40
              Caption = 'Export to HTML'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGreen
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              TabOrder = 5
              OnClick = btnExportHTMLClick
            end
            object btnExportJSON: TButton
              Left = 304
              Top = 100
              Width = 130
              Height = 40
              Caption = 'Export to JSON'
              TabOrder = 6
              OnClick = btnExportJSONClick
            end
          end
          object grpCompare: TGroupBox
            Left = 0
            Top = 200
            Width = 696
            Height = 320
            Align = alClient
            Caption = ' Compare Databases '
            TabOrder = 1
            object lblCompareDb: TLabel
              Left = 16
              Top = 28
              Width = 103
              Height = 15
              Caption = 'Second Database:'
            end
            object edtCompareDbPath: TEdit
              Left = 16
              Top = 48
              Width = 530
              Height = 23
              ReadOnly = True
              TabOrder = 0
            end
            object btnBrowseCompare: TButton
              Left = 552
              Top = 46
              Width = 60
              Height = 27
              Caption = '...'
              TabOrder = 1
              OnClick = btnBrowseCompareClick
            end
            object btnRunCompare: TButton
              Left = 618
              Top = 46
              Width = 60
              Height = 27
              Caption = 'Compare'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clNavy
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              TabOrder = 2
              OnClick = btnRunCompareClick
            end
            object mmoCompareResult: TMemo
              Left = 16
              Top = 84
              Width = 662
              Height = 220
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Consolas'
              Font.Style = []
              ParentFont = False
              ReadOnly = True
              ScrollBars = ssBoth
              TabOrder = 3
              WordWrap = False
            end
          end
        end
      end
    end

    object pnlRight: TPanel
      Left = 726
      Top = 0
      Width = 374
      Height = 570
      Align = alRight
      BevelOuter = bvNone
      Padding.Left = 8
      Padding.Top = 8
      Padding.Right = 8
      Padding.Bottom = 8
      TabOrder = 1
      object grpLog: TGroupBox
        Left = 8
        Top = 8
        Width = 358
        Height = 554
        Align = alClient
        Caption = ' Activity Log '
        TabOrder = 0
        object lstLog: TListBox
          Left = 8
          Top = 22
          Width = 342
          Height = 522
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          PopupMenu = pmLog
          TabOrder = 0
        end
      end
    end
  end

  object statMain: TStatusBar
    Left = 0
    Top = 658
    Width = 1100
    Height = 22
    Panels = <
      item
        Width = 100
      end
      item
        Width = 400
      end
      item
        Width = 50
      end>
  end

  object dlgOpenDB: TOpenDialog
    Filter = 'Firebird Database (*.fdb;*.gdb)|*.fdb;*.gdb|All files (*.*)|*.*'
    Title = 'Open Firebird Database'
    Left = 48
    Top = 128
  end

  object dlgSave: TSaveDialog
    Filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*'
    Title = 'Save Log'
    Left = 48
    Top = 184
  end

  object dlgOpenCompare: TOpenDialog
    Filter = 'Firebird Database (*.fdb;*.gdb)|*.fdb;*.gdb|All files (*.*)|*.*'
    Title = 'Select Database to Compare'
    Left = 48
    Top = 240
  end

  object pmLog: TPopupMenu
    Left = 120
    Top = 128
    object mniSaveLog: TMenuItem
      Caption = 'Save Log...'
      OnClick = mniSaveLogClick
    end
    object mniCopyLog: TMenuItem
      Caption = 'Copy to Clipboard'
      OnClick = mniCopyLogClick
    end
    object mniSep1: TMenuItem
      Caption = '-'
    end
    object mniClearLog: TMenuItem
      Caption = 'Clear Log'
      OnClick = mniClearLogClick
    end
  end
end
