object SearchForm: TSearchForm
  Left = 0
  Top = 0
  Caption = #1055#1086#1080#1089#1082' '#1076#1072#1085#1085#1099#1093' '#1074' '#1073#1072#1079#1077' Firebird'
  ClientHeight = 800
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 120
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblSearchFor: TLabel
      Left = 16
      Top = 16
      Width = 40
      Height = 13
      Caption = #1048#1089#1082#1072#1090#1100':'
    end
    object lblPageRange: TLabel
      Left = 16
      Top = 59
      Width = 97
      Height = 13
      Caption = #1044#1080#1072#1087#1072#1079#1086#1085' '#1089#1090#1088#1072#1085#1080#1094':'
    end
    object lblPageTo: TLabel
      Left = 232
      Top = 67
      Width = 18
      Height = 13
      Caption = #1044#1086':'
    end
    object btnSelectAll: TSpeedButton
      Left = 342
      Top = 59
      Width = 100
      Height = 23
      Caption = #1042#1089#1077' '#1089#1090#1088#1072#1085#1080#1094#1099
      Flat = True
    end
    object edtSearchText: TEdit
      Left = 16
      Top = 32
      Width = 400
      Height = 21
      TabOrder = 0
      TextHint = #1042#1074#1077#1076#1080#1090#1077' '#1090#1077#1082#1089#1090' '#1076#1083#1103' '#1087#1086#1080#1089#1082#1072
    end
    object edtPageFrom: TEdit
      Left = 146
      Top = 59
      Width = 80
      Height = 21
      NumbersOnly = True
      TabOrder = 1
      Text = '0'
    end
    object edtPageTo: TEdit
      Left = 256
      Top = 59
      Width = 80
      Height = 21
      NumbersOnly = True
      TabOrder = 2
      Text = '0'
    end
    object chkCaseSensitive: TCheckBox
      Left = 16
      Top = 86
      Width = 145
      Height = 17
      Caption = #1059#1095#1080#1090#1099#1074#1072#1090#1100' '#1088#1077#1075#1080#1089#1090#1088
      TabOrder = 3
    end
    object chkWholeWord: TCheckBox
      Left = 175
      Top = 86
      Width = 113
      Height = 17
      Caption = #1062#1077#1083#1086#1077' '#1089#1083#1086#1074#1086
      TabOrder = 4
    end
    object btnSearch: TButton
      Left = 456
      Top = 24
      Width = 120
      Height = 40
      Caption = #1055#1054#1048#1057#1050
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = btnSearchClick
    end
    object btnStop: TButton
      Left = 584
      Top = 24
      Width = 100
      Height = 40
      Caption = #1057#1058#1054#1055
      Enabled = False
      TabOrder = 6
      OnClick = btnStopClick
    end
    object rgSearchType: TRadioGroup
      Left = 704
      Top = 8
      Width = 121
      Height = 105
      Caption = #1058#1080#1087' '#1087#1086#1080#1089#1082#1072
      ItemIndex = 0
      Items.Strings = (
        'Text'
        'Hex'
        'Integer'
        'Date')
      TabOrder = 7
    end
  end
  object pnlFilters: TPanel
    Left = 0
    Top = 120
    Width = 1200
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 1
    object gbPageTypes: TGroupBox
      AlignWithMargins = True
      Left = 8
      Top = 8
      Width = 1184
      Height = 44
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 8
      Margins.Bottom = 8
      Align = alClient
      Caption = #1060#1080#1083#1100#1090#1088' '#1090#1080#1087#1086#1074' '#1089#1090#1088#1072#1085#1080#1094
      TabOrder = 0
      ExplicitLeft = 12
      ExplicitTop = 5
      object chkDataPages: TCheckBox
        Left = 16
        Top = 18
        Width = 120
        Height = 17
        Caption = 'Data Pages (5)'
        Checked = True
        State = cbChecked
        TabOrder = 0
      end
      object chkIndexPages: TCheckBox
        Left = 160
        Top = 18
        Width = 120
        Height = 17
        Caption = 'Index Pages (7)'
        Checked = True
        State = cbChecked
        TabOrder = 1
      end
      object chkBlobPages: TCheckBox
        Left = 304
        Top = 18
        Width = 120
        Height = 17
        Caption = 'Blob Pages (8)'
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object chkAllTypes: TCheckBox
        Left = 448
        Top = 18
        Width = 97
        Height = 17
        Caption = #1042#1089#1077' '#1090#1080#1087#1099
        TabOrder = 3
        OnClick = chkAllTypesClick
      end
    end
  end
  object pnlCenter: TPanel
    Left = 0
    Top = 180
    Width = 1200
    Height = 300
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblResults: TLabel
      Left = 0
      Top = 0
      Width = 1200
      Height = 16
      Align = alTop
      Caption = ' '#1053#1072#1081#1076#1077#1085#1086': 0 '#1079#1072#1087#1080#1089#1077#1081
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 134
    end
    object sgResults: TStringGrid
      Left = 0
      Top = 16
      Width = 1200
      Height = 284
      Align = alClient
      DefaultRowHeight = 22
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      TabOrder = 0
      OnClick = sgResultsClick
      ExplicitTop = 10
      ColWidths = (
        80
        100
        80
        150
        400)
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 480
    Width = 1200
    Height = 295
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object pgcDetails: TPageControl
      Left = 0
      Top = 0
      Width = 1200
      Height = 245
      ActivePage = tsHexView
      Align = alClient
      TabOrder = 0
      object tsHexView: TTabSheet
        Caption = 'Hex View'
        object memHexView: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 217
          Align = alClient
          Color = clBlack
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clLime
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object tsTextView: TTabSheet
        Caption = 'Text View'
        ImageIndex = 1
        object memTextView: TMemo
          Left = 0
          Top = 0
          Width = 1192
          Height = 217
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
    end
    object pnlActions: TPanel
      Left = 0
      Top = 245
      Width = 1200
      Height = 50
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object btnExtract: TButton
        Left = 16
        Top = 8
        Width = 110
        Height = 35
        Caption = #1048#1079#1074#1083#1077#1095#1100' '#1079#1072#1087#1080#1089#1100
        TabOrder = 0
        OnClick = btnExtractClick
      end
      object btnCopyToClipboard: TButton
        Left = 136
        Top = 8
        Width = 110
        Height = 35
        Caption = #1050#1086#1087#1080#1088#1086#1074#1072#1090#1100
        TabOrder = 1
      end
      object btnSaveToFile: TButton
        Left = 256
        Top = 8
        Width = 110
        Height = 35
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
        TabOrder = 2
      end
      object btnJumpToPage: TButton
        Left = 376
        Top = 8
        Width = 130
        Height = 35
        Caption = #1055#1077#1088#1077#1081#1090#1080' '#1082' '#1089#1090#1088#1072#1085#1080#1094#1077
        TabOrder = 3
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 775
    Width = 1200
    Height = 25
    Panels = <
      item
        Width = 800
      end
      item
        Width = 300
      end
      item
        Width = 50
      end>
  end
  object ProgressBar: TProgressBar
    Left = 808
    Top = 777
    Width = 289
    Height = 17
    TabOrder = 5
  end
end
