object FormSettings: TFormSettings
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Application settings'
  ClientHeight = 460
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
      Top = 67
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
      Hint = 
        'Choose the visual style used by ImageDup. The selected theme is ' +
        'saved as an application-wide setting.'
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object LanguageGroupBox: TGroupBox
    Left = 16
    Top = 137
    Width = 468
    Height = 121
    Caption = ' Language '
    TabOrder = 1
    DesignSize = (
      468
      121)
    object LanguageLabel: TLabel
      Left = 20
      Top = 32
      Width = 123
      Height = 17
      Caption = 'Application language'
      FocusControl = LanguageComboBox
    end
    object LanguageDescriptionLabel: TLabel
      Left = 20
      Top = 61
      Width = 422
      Height = 47
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Choose the language used by the application.'
      WordWrap = True
    end
    object LanguageComboBox: TComboBox
      Left = 176
      Top = 28
      Width = 266
      Height = 25
      Hint = 
        'Choose Automatic or one of the installed translation languages. ' +
        'The selected language is used after ImageDup restarts.'
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object ScanningGroupBox: TGroupBox
    Left = 16
    Top = 266
    Width = 468
    Height = 125
    Caption = ' Scanning '
    TabOrder = 2
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
      Top = 64
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
      Hint = 
        'Set the number of parallel image-processing workers. Higher valu' +
        'es may scan faster but use more processor time and memory; the m' +
        'aximum is detected from this computer.'
      MaxValue = 1
      MinValue = 1
      TabOrder = 0
      Value = 1
    end
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 407
    Width = 500
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 399
    ExplicitWidth = 498
    DesignSize = (
      500
      53)
    object OkButton: TButton
      Left = 316
      Top = 14
      Width = 80
      Height = 29
      Hint = 'Apply and save these application-wide settings.'
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
      ExplicitLeft = 314
    end
    object CancelButton: TButton
      Left = 404
      Top = 14
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
