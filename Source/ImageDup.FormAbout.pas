unit ImageDup.FormAbout;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage;

type
  TFormAbout = class(TForm)
    AppImage: TImage;
    ProductLabel: TLabel;
    VersionLabel: TLabel;
    DescriptionLabel: TLabel;
    DetailLabel: TLabel;
    CloseButton: TButton;
    procedure FormCreate(Sender: TObject);
  public
    class procedure Execute(AOwner: TComponent); static;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Graphics;

{$R *.dfm}

resourcestring
  rsVersionFmt='Version %s';

function ExecutableVersion: string;
var
  Handle, InfoSize: Cardinal;
  Buffer: TBytes;
  FixedInfo: PVSFixedFileInfo;
  FixedInfoSize: UINT;
begin
  Result := '1.0.0.0';
  InfoSize := GetFileVersionInfoSize(PChar(Application.ExeName), Handle);
  if InfoSize = 0 then
    Exit;
  SetLength(Buffer, InfoSize);
  if not GetFileVersionInfo(PChar(Application.ExeName), Handle, InfoSize, Buffer) then
    Exit;
  if VerQueryValue(Buffer, '\', Pointer(FixedInfo), FixedInfoSize) and (FixedInfoSize >= SizeOf(TVSFixedFileInfo)) then
    Result := Format('%d.%d.%d.%d', [HiWord(FixedInfo.dwFileVersionMS), LoWord(FixedInfo.dwFileVersionMS), HiWord(FixedInfo.dwFileVersionLS), LoWord(FixedInfo.dwFileVersionLS)]);
end;

procedure TFormAbout.FormCreate(Sender: TObject);
begin
  VersionLabel.Caption := Format(rsVersionFmt, [ExecutableVersion]);
  DescriptionLabel.Caption := 'Andrea Tiburzi (2026)';
end;

class procedure TFormAbout.Execute(AOwner: TComponent);
var
  Dialog: TFormAbout;
begin
  Dialog := TFormAbout.Create(AOwner);
  try
    Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
end;

end.


