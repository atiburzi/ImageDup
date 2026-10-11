unit ImageDup.Language;

interface

const
  AutomaticApplicationLanguage = '';
  BuiltInApplicationLanguage = 'en';

type
  TApplicationLanguageInfo = record
    Code: string;
    DisplayName: string;
  end;

function AvailableApplicationLanguages: TArray<TApplicationLanguageInfo>;
function LoadApplicationLanguage: string;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Character, System.Win.Registry;

const
  SettingsRegistryKey = 'Software\ImageDup';
  LanguageRegistryValue = 'UILanguage';

function TryLocaleDisplayName(const LanguageCode: string;
  out DisplayName: string): Boolean;
var
  Buffer: array[0..255] of Char;
  I: Integer;
begin
  Result := IsValidLocaleName(PChar(LanguageCode));
  if Result then
  begin
    if GetLocaleInfoEx(PChar(LanguageCode), LOCALE_SNATIVEDISPLAYNAME, Buffer,
      Length(Buffer)) > 0 then
      DisplayName := PChar(@Buffer[0])
    else
      DisplayName := LanguageCode;
  end
  else
    for I := 0 to Languages.Count - 1 do
      if SameText(Languages.Ext[I], LanguageCode) then
      begin
        DisplayName := Languages.Name[I];
        Result := True;
        Break;
      end;
  if Result then
  begin
    if DisplayName <> '' then
      DisplayName[Low(DisplayName)] := UpCase(DisplayName[Low(DisplayName)]);
    DisplayName := Format('%s (%s)', [DisplayName, UpperCase(LanguageCode)]);
  end;
end;

function AvailableApplicationLanguages: TArray<TApplicationLanguageInfo>;
var
  AppBaseName, AppFolder, FileName, LanguageCode, LanguageDisplayName,
    SearchMask: string;
  I, J: Integer;
  ModuleHandle: HMODULE;
  SearchRec: TSearchRec;
  Swap: TApplicationLanguageInfo;

  procedure AddLanguage(const Code, DisplayName: string);
  var
    K: Integer;
  begin
    for K := 0 to High(Result) do
      if SameText(Result[K].Code, Code) then
        Exit;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Code := Code;
    Result[High(Result)].DisplayName := DisplayName;
  end;

begin
  SetLength(Result, 0);
  if not TryLocaleDisplayName(BuiltInApplicationLanguage,
    LanguageDisplayName) then
    LanguageDisplayName := BuiltInApplicationLanguage;
  AddLanguage(BuiltInApplicationLanguage, LanguageDisplayName);
  AppFolder := ExtractFilePath(ParamStr(0));
  AppBaseName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  SearchMask := IncludeTrailingPathDelimiter(AppFolder) + AppBaseName + '.*';
  if FindFirst(SearchMask, faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
      begin
        FileName := IncludeTrailingPathDelimiter(AppFolder) + SearchRec.Name;
        if SameFileName(FileName, ParamStr(0)) then
          Continue;
        LanguageCode := Copy(ExtractFileExt(SearchRec.Name), 2, MaxInt);
        if (LanguageCode <> '') and
          TryLocaleDisplayName(LanguageCode, LanguageDisplayName) then
        begin
          ModuleHandle := LoadLibraryEx(PChar(FileName), 0,
            LOAD_LIBRARY_AS_DATAFILE);
          if ModuleHandle <> 0 then
          try
            AddLanguage(LanguageCode, LanguageDisplayName);
          finally
            FreeLibrary(ModuleHandle);
          end;
        end;
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;

  for I := 0 to High(Result) - 1 do
    for J := I + 1 to High(Result) do
      if CompareText(Result[I].DisplayName, Result[J].DisplayName) > 0 then
      begin
        Swap := Result[I];
        Result[I] := Result[J];
        Result[J] := Swap;
      end;
end;

function LoadApplicationLanguage: string;
var
  Registry: TRegistry;
begin
  Result := AutomaticApplicationLanguage;
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    try
      if Registry.OpenKeyReadOnly(SettingsRegistryKey) and
        Registry.ValueExists(LanguageRegistryValue) then
        Result := Registry.ReadString(LanguageRegistryValue);
    except
      on E: ERegistryException do
        Result := AutomaticApplicationLanguage;
    end;
  finally
    Registry.Free;
  end;
end;

end.
