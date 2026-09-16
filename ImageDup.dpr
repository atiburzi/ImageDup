program ImageDup;

uses
  Vcl.Forms,
  ImageDup.Main in 'ImageDup.Main.pas' {MainForm},
  ImageDup.Scan in 'ImageDup.Scan.pas',
  ImageDup.Groups in 'ImageDup.Groups.pas',
  ImageDup.Session in 'ImageDup.Session.pas',
  ImageDup.Recycle in 'ImageDup.Recycle.pas',
  ImageDup.Core in 'ImageDup.Core.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'ImageDup';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
