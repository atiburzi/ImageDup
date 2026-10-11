unit ImageDup.LanguageBootstrap;

interface

implementation

uses
  Winapi.Windows;

const
  SettingsRegistryKey = 'Software\ImageDup';
  LanguageRegistryValue = 'UILanguage';

procedure ApplySavedLanguageOverride;
var
  Buffer: array[0..255] of Char;
  BufferSize, ValueType: DWORD;
  RegistryKey: HKEY;
begin
  if RegOpenKeyEx(HKEY_CURRENT_USER, SettingsRegistryKey, 0, KEY_QUERY_VALUE,
    RegistryKey) <> ERROR_SUCCESS then
    Exit;
  try
    Buffer[0] := #0;
    BufferSize := SizeOf(Buffer);
    ValueType := REG_NONE;
    if (RegQueryValueEx(RegistryKey, LanguageRegistryValue, nil, @ValueType,
      PByte(@Buffer[0]), @BufferSize) = ERROR_SUCCESS) and
      (ValueType in [REG_SZ, REG_EXPAND_SZ]) and (Buffer[0] <> #0) then
      System.SetLocaleOverride(PChar(@Buffer[0]));
  finally
    RegCloseKey(RegistryKey);
  end;
end;

initialization
  ApplySavedLanguageOverride;

end.
