object FormSettings: TFormSettings
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Application settings'
  ClientHeight = 325
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 17
  object AppearanceGroupBox: TGroupBox
    Left = 16
    Top = 16
    Width = 468
    Height = 113
    Caption = ' Appearance '
    TabOrder = 0
    DesignSize = (
      468
      113)
    object ThemeLabel: TLabel
      Left = 20
      Top = 32
      Width = 74
      Height = 17
      Caption = 'Visual theme'
      FocusControl = ThemeComboBox
    end
    object ThemeDescriptionLabel: TLabel
      Left = 20
      Top = 76
      Width = 422
      Height = 29
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Choose the visual theme used by the application.'
      WordWrap = True
    end
    object ThemeComboBox: TComboBox
      Left = 176
      Top = 28
      Width = 266
      Height = 25
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object ScanningGroupBox: TGroupBox
    Left = 16
    Top = 132
    Width = 468
    Height = 125
    Caption = ' Scanning '
    TabOrder = 1
    DesignSize = (
      468
      125)
    object ThreadLabel: TLabel
      Left = 20
      Top = 34
      Width = 220
      Height = 17
      Caption = 'Number of image processing threads'
      FocusControl = ThreadSpin
    end
    object ThreadDescriptionLabel: TLabel
      Left = 20
      Top = 72
      Width = 422
      Height = 50
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'The maximum number of threads depends on this computer.'
      WordWrap = True
    end
    object ThreadSpin: TSpinEdit
      Left = 370
      Top = 29
      Width = 72
      Height = 27
      MaxValue = 1
      MinValue = 1
      TabOrder = 0
      Value = 1
    end
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 272
    Width = 500
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 296
    DesignSize = (
      500
      53)
    object OkButton: TButton
      Left = 316
      Top = 14
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
      Top = 14
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
