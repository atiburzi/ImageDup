unit ImageDup.Settings;

interface

uses
  System.Classes;

const
  MinApplicationThreadCount = 1;
  DefaultApplicationThreadCount = 3;
  MaxRecentSessionFiles = 5;

procedure RestoreApplicationStyle;
function ApplicationMaxThreadCount: Integer;
function LoadApplicationThreadCount: Integer;
procedure LoadRecentSessionFiles(Destination: TStrings);
procedure SaveRecentSessionFiles(const Source: TStrings);
procedure SaveApplicationSettings(const StyleName: string; ThreadCount: Integer);

implementation

uses
  Winapi.Windows, System.SysUtils, System.Math,
  System.Win.Registry, Vcl.Themes;

const
  SettingsRegistryKey = 'Software\ImageDup';
  StyleRegistryValue = 'GUIStyle';
  ThreadCountRegistryValue = 'ProcessingThreadCount';
  RecentSessionRegistryValuePrefix = 'RecentSession';

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
  rsApplicationSettingsUnavailable = 'Unable to open the application settings for writing.';

function ApplicationMaxThreadCount: Integer;
begin
  Result := Max(MinApplicationThreadCount, TThread.ProcessorCount);
end;

function LoadApplicationThreadCount: Integer;
var
  MaxThreadCount: Integer;
  Registry: TRegistry;
begin
  MaxThreadCount := ApplicationMaxThreadCount;
  Result := EnsureRange(DefaultApplicationThreadCount,
    MinApplicationThreadCount, MaxThreadCount);
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    try
      if Registry.OpenKeyReadOnly(SettingsRegistryKey) and
        Registry.ValueExists(ThreadCountRegistryValue) then
        Result := EnsureRange(Registry.ReadInteger(ThreadCountRegistryValue),
          MinApplicationThreadCount, MaxThreadCount);
    except
      on E: ERegistryException do
        Result := EnsureRange(DefaultApplicationThreadCount,
          MinApplicationThreadCount, MaxThreadCount);
    end;
  finally
    Registry.Free;
  end;
end;

procedure LoadRecentSessionFiles(Destination: TStrings);
var
  FileName, ValueName: string;
  I: Integer;
  Registry: TRegistry;
begin
  Destination.BeginUpdate;
  try
    Destination.Clear;
    Registry := TRegistry.Create(KEY_READ);
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      try
        if Registry.OpenKeyReadOnly(SettingsRegistryKey) then
          for I := 1 to MaxRecentSessionFiles do
          begin
            ValueName := RecentSessionRegistryValuePrefix + IntToStr(I);
            if Registry.ValueExists(ValueName) then
            begin
              FileName := Registry.ReadString(ValueName);
              if (FileName <> '') and (Destination.IndexOf(FileName) < 0) then
                Destination.Add(ExpandFileName(FileName));
            end;
          end;
      except
        on E: ERegistryException do
          Destination.Clear;
      end;
    finally
      Registry.Free;
    end;
  finally
    Destination.EndUpdate;
  end;
end;

procedure SaveRecentSessionFiles(const Source: TStrings);
var
  I, SaveCount: Integer;
  Registry: TRegistry;
  ValueName: string;
begin
  Registry := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    try
      if not Registry.OpenKey(SettingsRegistryKey, True) then
        Exit;
      for I := 1 to MaxRecentSessionFiles do
      begin
        ValueName := RecentSessionRegistryValuePrefix + IntToStr(I);
        if Registry.ValueExists(ValueName) then
          Registry.DeleteValue(ValueName);
      end;
      SaveCount := Min(Source.Count, MaxRecentSessionFiles);
      for I := 0 to SaveCount - 1 do
        Registry.WriteString(RecentSessionRegistryValuePrefix +
          IntToStr(I + 1), Source[I]);
    except
      on E: ERegistryException do
        Exit;
    end;
  finally
    Registry.Free;
  end;
end;

procedure SaveApplicationSettings(const StyleName: string;
  ThreadCount: Integer);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKey(SettingsRegistryKey, True) then
      raise ERegistryException.CreateRes(@rsApplicationSettingsUnavailable);
    Registry.WriteString(StyleRegistryValue, StyleName);
    Registry.WriteInteger(ThreadCountRegistryValue, EnsureRange(ThreadCount,
      MinApplicationThreadCount, ApplicationMaxThreadCount));
  finally
    Registry.Free;
  end;
end;

end.
