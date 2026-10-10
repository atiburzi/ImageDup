unit ImageDup.Options;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Samples.Spin;

type
  TOptionsForm = class(TForm)
    MatchingGroupBox: TGroupBox;
    QualityLabel: TLabel;
    QualitySpin: TSpinEdit;
    QualityDescriptionLabel: TLabel;
    SearchScopeGroupBox: TGroupBox;
    RecursiveCheck: TCheckBox;
    RecursiveDescriptionLabel: TLabel;
    IncludeSingletonsCheck: TCheckBox;
    IncludeSingletonsDescriptionLabel: TLabel;
    ButtonsPanel: TPanel;
    OKButton: TButton;
    CancelButton: TButton;
  public
    class function Execute(AOwner: TComponent; var AQuality: Integer;
      var ARecursive, AIncludeSingletons: Boolean): Boolean; static;
  end;

implementation

{$R *.dfm}

class function TOptionsForm.Execute(AOwner: TComponent; var AQuality: Integer;
  var ARecursive, AIncludeSingletons: Boolean): Boolean;
var
  Dialog: TOptionsForm;
begin
  Dialog := TOptionsForm.Create(AOwner);
  try
    Dialog.QualitySpin.Value := AQuality;
    Dialog.RecursiveCheck.Checked := ARecursive;
    Dialog.IncludeSingletonsCheck.Checked := AIncludeSingletons;
    Result := Dialog.ShowModal = mrOk;
    if Result then
    begin
      AQuality := Dialog.QualitySpin.Value;
      ARecursive := Dialog.RecursiveCheck.Checked;
      AIncludeSingletons := Dialog.IncludeSingletonsCheck.Checked;
    end;
  finally
    Dialog.Free;
  end;
end;

end.


