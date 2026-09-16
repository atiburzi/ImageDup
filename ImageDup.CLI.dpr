program ImageDupCLI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  Winapi.Windows, ImageDup.Core in 'ImageDup.Core.pas';

type
  TEntry = record
    FileName: string;
    Signature: TImageSignature;
  end;

procedure Usage;
begin
  Writeln('ImageDup - candidati duplicati per contenuto visivo');
  Writeln('Uso: ImageDup <cartella> [--recursive] [--csv <nuovo-file.csv>]');
  Writeln('       [--distance 0..63] [--pixel-error 0..1]');
  Writeln('Default: distanza <= 8 E errore RGB <= 0.08 (punto decimale).');
  Writeln('Verifica aggiuntiva: SSIM medio >= 0.97, locale >= 0.80, RGB locale <= 0.18.');
  Writeln('Formati: JPEG, PNG, BMP. Nessun file immagine viene modificato.');
  Writeln('Exit code: 0 completato, 1 errore, 2 scansione parziale.');
end;

function QuotedCSV(const Value: string): string;
begin
  Result := '"' + StringReplace(Value, '"', '""', [rfReplaceAll]) + '"';
end;

function Run: Integer;
var
  Root, CSVPath, Arg, Extension, Line: string;
  Recursive: Boolean;
  MaxDistance, I, J, Distance, Failed: Integer;
  MaxPixelError, Error: Double;
  Matches: Int64;
  Metrics: TComparison;
  Entries: TList<TEntry>;
  Pending: TStack<string>;
  Search: TSearchRec;
  Folder, FileName: string;
  Entry: TEntry;
  CSV: TStreamWriter;
  Stream: THandleStream;
  OutputHandle: THandle;
  FormatSettings: TFormatSettings;

  function NextValue: string;
  begin
    Inc(I);
    if I > ParamCount then
      raise EArgumentException.Create('Valore mancante per ' + Arg);
    Result := ParamStr(I);
  end;

begin
  Result := 0;
  if (ParamCount = 0) or SameText(ParamStr(1), '--help') then
  begin
    Usage;
    Exit;
  end;
  Root := TPath.GetFullPath(ParamStr(1));
  if not DirectoryExists(Root) then
    raise EArgumentException.Create('Cartella inesistente: ' + Root);
  Recursive := False;
  MaxDistance := 8;
  MaxPixelError := 0.08;
  CSVPath := '';
  FormatSettings := TFormatSettings.Invariant;
  I := 2;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);
    if Arg = '--recursive' then Recursive := True
    else if Arg = '--csv' then CSVPath := TPath.GetFullPath(NextValue)
    else if Arg = '--distance' then
    begin
      if not TryStrToInt(NextValue, MaxDistance) or
        (MaxDistance < 0) or (MaxDistance > 63) then
        raise EArgumentException.Create('Distanza richiesta: intero tra 0 e 63');
    end
    else if Arg = '--pixel-error' then
    begin
      if not TryStrToFloat(NextValue, MaxPixelError, FormatSettings) then
        raise EArgumentException.Create('Errore pixel richiesto: numero tra 0 e 1');
      if not ((MaxPixelError >= 0) and (MaxPixelError <= 1)) then
        raise EArgumentException.Create('Errore pixel richiesto: numero tra 0 e 1');
    end
    else raise EArgumentException.Create('Opzione sconosciuta: ' + Arg);
    Inc(I);
  end;
  CSV := nil;
  Stream := nil;
  OutputHandle := INVALID_HANDLE_VALUE;
  Entries := TList<TEntry>.Create;
  Pending := TStack<string>.Create;
  try
    if CSVPath <> '' then
    begin
      // CREATE_NEW prevents overwriting an existing report or source file.
      OutputHandle := CreateFile(PChar(CSVPath), GENERIC_WRITE, 0,
        nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
      if OutputHandle = INVALID_HANDLE_VALUE then RaiseLastOSError;
      Stream := THandleStream.Create(OutputHandle);
      CSV := TStreamWriter.Create(Stream, TEncoding.UTF8);
      CSV.WriteLine('file_a,file_b,hash_distance,pixel_rmse');
    end;
    Failed := 0;
    Matches := 0;
    Pending.Push(Root);
    while Pending.Count > 0 do
    begin
      Folder := Pending.Pop;
      I := FindFirst(TPath.Combine(Folder, '*'), faAnyFile, Search);
      if I <> 0 then
      begin
        if (I <> ERROR_FILE_NOT_FOUND) and (I <> ERROR_NO_MORE_FILES) then
        begin
          Inc(Failed);
          Writeln(ErrOutput, 'Cartella non leggibile: ', Folder, ' (', I, ')');
        end;
        Continue;
      end;
      try
        repeat
          if (Search.Name = '.') or (Search.Name = '..') then Continue;
          FileName := TPath.Combine(Folder, Search.Name);
          if (Search.Attr and faDirectory) <> 0 then
          begin
            // Avoid junction/symlink cycles and traversal outside the tree.
            if Recursive and ((Search.Attr and faSymLink) = 0) and
              ((Search.FindData.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) = 0) then
              Pending.Push(FileName);
            Continue;
          end;
          Extension := LowerCase(TPath.GetExtension(FileName));
          if (Extension <> '.jpg') and (Extension <> '.jpeg') and
            (Extension <> '.png') and (Extension <> '.bmp') then Continue;
          try
            Entry.FileName := FileName;
            Entry.Signature := LoadSignature(FileName);
          except
            on E: Exception do
            begin
              Inc(Failed);
              Writeln(ErrOutput, 'Immagine saltata: ', FileName, ': ', E.Message);
              Continue;
            end;
          end;
          for J := 0 to Entries.Count - 1 do
          begin
            if not CompareSignatures(Entry.Signature, Entries[J].Signature,
              MaxDistance, MaxPixelError, Metrics) then Continue;
            Distance := Metrics.Distance;
            Error := Metrics.RGBError;
            Inc(Matches);
            Line := QuotedCSV(Entries[J].FileName) + ',' + QuotedCSV(FileName) + ',' +
              IntToStr(Distance) + ',' + FloatToStr(Error, FormatSettings);
            Writeln(Line);
            if Assigned(CSV) then CSV.WriteLine(Line);
          end;
          Entries.Add(Entry);
          if Entries.Count mod 100 = 0 then
            Writeln(ErrOutput, 'Analizzate: ', Entries.Count);
        until FindNext(Search) <> 0;
      finally
        System.SysUtils.FindClose(Search);
      end;
    end;
    Writeln(ErrOutput, 'Immagini: ', Entries.Count, '; coppie candidate: ', Matches,
      '; errori: ', Failed);
    if Failed > 0 then Result := 2;
  finally
    CSV.Free;
    Stream.Free;
    if OutputHandle <> INVALID_HANDLE_VALUE then CloseHandle(OutputHandle);
    Pending.Free;
    Entries.Free;
  end;
end;

begin
  try
    ExitCode := Run;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Errore: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
