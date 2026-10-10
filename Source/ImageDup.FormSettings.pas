unit ImageDup.FormSettings;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Samples.Spin;

type
  TFormSettings = class(TForm)
    AppearanceGroupBox: TGroupBox;
    ThemeLabel: TLabel;
    ThemeComboBox: TComboBox;
    ThemeDescriptionLabel: TLabel;
    ScanningGroupBox: TGroupBox;
    ThreadLabel: TLabel;
    ThreadSpin: TSpinEdit;
    ThreadDescriptionLabel: TLabel;
    ButtonsPanel: TPanel;
    OkButton: TButton;
    CancelButton: TButton;
  public
    class function Execute(AOwner: TComponent; const AActiveStyle: string;
      AThreadCount: Integer; out ASelectedStyle: string;
      out ASelectedThreadCount: Integer): Boolean; static;
  end;

function ApplicationStyleDisplayName(const StyleName: string): string;

implementation

{$R *.dfm}

uses
  System.Math, Vcl.Themes, ImageDup.Settings;

resourcestring
  rsStyleLight = 'Light Theme';
  rsStyleBlue = 'Blue Theme';
  rsStyleDark = 'Dark Theme';
  rsStyleGreen = 'Green Theme';
  rsStylePurple = 'Purple Theme';
  rsStyleSlateGray = 'Slate Gray Theme';
  rsThreadCountDescription =
    'This computer supports up to %d concurrent processing threads. Lower ' +
    'values leave more processor capacity available to other applications.';

function ApplicationStyleDisplayName(const StyleName: string): string;
begin
  if SameText(StyleName, 'Windows10') then
    Result := rsStyleLight
  else if SameText(StyleName, 'Windows10 Blue') then
    Result := rsStyleBlue
  else if SameText(StyleName, 'Windows10 Dark') then
    Result := rsStyleDark
  else if SameText(StyleName, 'Windows10 Green') then
    Result := rsStyleGreen
  else if SameText(StyleName, 'Windows10 Purple') then
    Result := rsStylePurple
  else if SameText(StyleName, 'Windows10 SlateGray') then
    Result := rsStyleSlateGray
  else
    Result := StyleName;
end;

class function TFormSettings.Execute(AOwner: TComponent;
  const AActiveStyle: string; AThreadCount: Integer;
  out ASelectedStyle: string; out ASelectedThreadCount: Integer): Boolean;
var
  Form: TFormSettings;
  I: Integer;
  MaxThreadCount: Integer;
  StyleName: string;
  StyleNames: TArray<string>;
begin
  Form := TFormSettings.Create(AOwner);
  try
    SetLength(StyleNames, 0);
    for StyleName in TStyleManager.StyleNames do
      if not SameText(StyleName, 'Windows') then
      begin
        SetLength(StyleNames, Length(StyleNames) + 1);
        StyleNames[High(StyleNames)] := StyleName;
        Form.ThemeComboBox.Items.Add(
          ApplicationStyleDisplayName(StyleName));
      end;
    Form.ThemeComboBox.ItemIndex := -1;
    for I := 0 to High(StyleNames) do
      if SameText(StyleNames[I], AActiveStyle) then
      begin
        Form.ThemeComboBox.ItemIndex := I;
        Break;
      end;
    if (Form.ThemeComboBox.ItemIndex < 0) and
      (Form.ThemeComboBox.Items.Count > 0) then
      Form.ThemeComboBox.ItemIndex := 0;
    MaxThreadCount := ApplicationMaxThreadCount;
    Form.ThreadSpin.MaxValue := MaxThreadCount;
    Form.ThreadDescriptionLabel.Caption := Format(rsThreadCountDescription,
      [MaxThreadCount]);
    Form.ThreadSpin.Value := EnsureRange(AThreadCount,
      MinApplicationThreadCount, MaxThreadCount);

    Result := Form.ShowModal = mrOk;
    if Result and (Form.ThemeComboBox.ItemIndex >= 0) and
      (Form.ThemeComboBox.ItemIndex < Length(StyleNames)) then
    begin
      ASelectedStyle := StyleNames[Form.ThemeComboBox.ItemIndex];
      ASelectedThreadCount := Form.ThreadSpin.Value;
    end
    else
      Result := False;
  finally
    Form.Free;
  end;
end;

end.
