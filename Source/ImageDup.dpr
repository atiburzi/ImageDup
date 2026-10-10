program ImageDup;

uses
  Vcl.Forms,
  ImageDup.FormMain in 'ImageDup.FormMain.pas' {FormMain},
  ImageDup.FormSession in 'ImageDup.FormSession.pas' {FormSession},
  ImageDup.FormAbout in 'ImageDup.FormAbout.pas' {FormAbout},
  ImageDup.FormSettings in 'ImageDup.FormSettings.pas' {FormSettings},
  ImageDup.Options in 'ImageDup.Options.pas' {OptionsForm},
  ImageDup.ExcelExport in 'ImageDup.ExcelExport.pas',
  ImageDup.Scan in 'ImageDup.Scan.pas',
  ImageDup.Groups in 'ImageDup.Groups.pas',
  ImageDup.Session in 'ImageDup.Session.pas',
  ImageDup.Recycle in 'ImageDup.Recycle.pas',
  ImageDup.FileMove in 'ImageDup.FileMove.pas',
  ImageDup.Core in 'ImageDup.Core.pas',
  ImageDup.Settings in 'ImageDup.Settings.pas',
  Vcl.Themes,
  Vcl.Styles,
  ImageDup.Resource in 'ImageDup.Resource.pas' {DataModuleResources: TDataModule};

resourcestring
  rsApplicationTitle = 'ImageDup';

{$R *.res}
{$R *.dres}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10');
  RestoreApplicationStyle;
  Application.Title := 'ImageDup';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TDataModuleResources, DataModuleResources);
  Application.Run;
end.







