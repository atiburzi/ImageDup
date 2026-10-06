object OptionsForm: TOptionsForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Options'
  ClientHeight = 218
  ClientWidth = 448
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  Scaled = False
  TextHeight = 17
  object QualityLabel: TLabel
    Left = 24
    Top = 24
    Width = 300
    Height = 17
    Caption = 'Matching quality index (0 - Low, 10- High)'
    FocusControl = QualitySpin
  end
  object ThreadLabel: TLabel
    Left = 24
    Top = 60
    Width = 300
    Height = 17
    Caption = 'Number of threads to process images:'
    FocusControl = ThreadSpin
  end
  object QualitySpin: TSpinEdit
    Left = 344
    Top = 20
    Width = 72
    Height = 27
    MaxValue = 10
    MinValue = 0
    TabOrder = 0
    Value = 8
  end
  object ThreadSpin: TSpinEdit
    Left = 344
    Top = 56
    Width = 72
    Height = 27
    MaxValue = 64
    MinValue = 1
    TabOrder = 1
    Value = 3
  end
  object RecursiveCheck: TCheckBox
    Left = 24
    Top = 97
    Width = 392
    Height = 22
    Caption = 'Include subfolders in the search'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object IncludeSingletonsCheck: TCheckBox
    Left = 24
    Top = 129
    Width = 400
    Height = 22
    Caption = 'Include groups without duplicates (single file)'
    TabOrder = 3
  end
  object ButtonsPanel: TPanel
    Left = 0
    Top = 165
    Width = 448
    Height = 53
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object OKButton: TButton
      Left = 248
      Top = 13
      Width = 80
      Height = 30
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object CancelButton: TButton
      Left = 336
      Top = 13
      Width = 80
      Height = 30
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end