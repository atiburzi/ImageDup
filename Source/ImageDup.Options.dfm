object OptionsForm: TOptionsForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Session options'
  ClientHeight = 378
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  StyleElements = [seFont, seClient, seBorder]
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
      Width = 101
      Height = 17
      Caption = 'Matching quality'
      FocusControl = QualitySpin
    end
    object QualityDescriptionLabel: TLabel
      Left = 20
      Top = 68
      Width = 422
      Height = 42
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption =
        'Controls how closely images must resemble one another. Lower ' +
        'values find more variations; higher values accept only closer ' +
        'visual matches.'
      WordWrap = True
    end
    object QualitySpin: TSpinEdit
      Left = 370
      Top = 27
      Width = 72
      Height = 27
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
    Height = 160
    Caption = ' Search scope '
    TabOrder = 1
    DesignSize = (
      468
      160)
    object RecursiveCheck: TCheckBox
      Left = 20
      Top = 28
      Width = 422
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Include subfolders in the search'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object RecursiveDescriptionLabel: TLabel
      Left = 44
      Top = 53
      Width = 398
      Height = 26
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Scan every subfolder below each selected search folder.'
      WordWrap = True
    end
    object IncludeSingletonsCheck: TCheckBox
      Left = 20
      Top = 88
      Width = 422
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Include groups without duplicates (single file)'
      TabOrder = 1
    end
    object IncludeSingletonsDescriptionLabel: TLabel
      Left = 44
      Top = 113
      Width = 398
      Height = 34
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption =
        'Also show images that did not match any other file, as groups ' +
        'containing one item.'
      WordWrap = True
    end
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 325
    Width = 500
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      500
      53)
    object OKButton: TButton
      Left = 316
      Top = 12
      Width = 80
      Height = 29
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object CancelButton: TButton
      Left = 404
      Top = 12
      Width = 80
      Height = 29
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
