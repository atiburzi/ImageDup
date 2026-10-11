object OptionsForm: TOptionsForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Session options'
  ClientHeight = 313
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  ShowHint = True
  TextHeight = 17
  object MatchingGroupBox: TGroupBox
    Left = 16
    Top = 16
    Width = 468
    Height = 125
    Caption = ' Image comparison '
    TabOrder = 0
    DesignSize = (
      468
      125)
    object QualityLabel: TLabel
      Left = 20
      Top = 32
      Width = 96
      Height = 17
      Caption = 'Matching quality'
      FocusControl = QualitySpin
    end
    object QualityDescriptionLabel: TLabel
      Left = 20
      Top = 60
      Width = 422
      Height = 62
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 
        'Controls how closely images must resemble one another. Lower val' +
        'ues find more variations; higher values accept only closer visua' +
        'l matches.'
      WordWrap = True
    end
    object QualitySpin: TSpinEdit
      Left = 370
      Top = 27
      Width = 72
      Height = 27
      Hint = 
        'Set perceptual matching strictness from 0 to 10. Higher values r' +
        'equire images to be more visually similar; 10 is the strictest s' +
        'etting.'
      Anchors = [akTop, akRight]
      MaxValue = 10
      MinValue = 0
      TabOrder = 0
      Value = 8
    end
  end
  object SearchScopeGroupBox: TGroupBox
    Left = 16
    Top = 153
    Width = 468
    Height = 106
    Caption = ' Search scope '
    TabOrder = 1
    DesignSize = (
      468
      106)
    object RecursiveDescriptionLabel: TLabel
      Left = 20
      Top = 52
      Width = 398
      Height = 51
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Scan every subfolder below each selected search folder.'
      WordWrap = True
    end
    object RecursiveCheck: TCheckBox
      Left = 20
      Top = 24
      Width = 422
      Height = 22
      Hint = 
        'When enabled, scan every nested folder below each configured sea' +
        'rch root.'
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Include subfolders in the search'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 260
    Width = 500
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 242
    ExplicitWidth = 498
    DesignSize = (
      500
      53)
    object OKButton: TButton
      Left = 316
      Top = 12
      Width = 80
      Height = 29
      Hint = 'Apply these options to the current session and close the dialog.'
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
      ExplicitLeft = 314
    end
    object CancelButton: TButton
      Left = 404
      Top = 12
      Width = 80
      Height = 29
      Hint = 'Discard changes and close the dialog.'
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
      ExplicitLeft = 402
    end
  end
end
