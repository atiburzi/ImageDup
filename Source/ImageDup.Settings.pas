unit ImageDup.Settings;

interface

procedure RestoreApplicationStyle;
procedure SaveApplicationStyle(const StyleName: string);

implementation

uses
  Winapi.Windows, System.SysUtils, System.Win.Registry, Vcl.Themes;

const
  SettingsRegistryKey = 'Software\ImageDup';
  StyleRegistryValue = 'GUIStyle';

function LoadApplicationStyle: string;
var
  Registry: TRegistry;
begin
  Result := '';
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    try
      if Registry.OpenKeyReadOnly(SettingsRegistryKey) and
        Registry.ValueExists(StyleRegistryValue) then
        Result := Registry.ReadString(StyleRegistryValue);
    except
      on E: ERegistryException do
        Result := '';
    end;
  finally
    Registry.Free;
  end;
end;

procedure RestoreApplicationStyle;
var
  SavedStyle, DefaultStyle: string;

  function TryApplyStyle(const StyleName: string): Boolean;
  begin
    try
      Result := TStyleManager.TrySetStyle(StyleName, False);
    except
      on E: Exception do
        Result := False;
    end;
  end;

begin
  // The DPR has already applied the default selected in Project Options.
  // An absent, removed or unreadable preference must not prevent startup.
  DefaultStyle := TStyleManager.ActiveStyle.Name;
  SavedStyle := LoadApplicationStyle;
  if (SavedStyle = '') or SameText(SavedStyle, DefaultStyle) then
    Exit;
  if not TryApplyStyle(SavedStyle) then
    TryApplyStyle(DefaultStyle);
end;

resourcestring
  rsStyleSettingsUnavailable = 'Unable to open the GUI style settings for writing.';

procedure SaveApplicationStyle(const StyleName: string);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKey(SettingsRegistryKey, True) then
      raise ERegistryException.CreateRes(@rsStyleSettingsUnavailable);
    Registry.WriteString(StyleRegistryValue, StyleName);
  finally
    Registry.Free;
  end;
end;

end.
