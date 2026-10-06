unit ImageDup.Session;

interface

uses System.SysUtils, ImageDup.Groups, System.Generics.Collections;

type
  TSessionState = record
    Roots: TArray<string>;
    Recursive: Boolean;
    IncludeSingletons: Boolean;
    Quality: Integer;
    PixelError: Double;
    ThreadCount: Integer;
    ScannedFiles: Integer;
    Groups: TArray<TImageGroup>;
    SelectedFiles: TArray<string>;
  end;

procedure SaveSession(const FileName: string; const State: TSessionState);
function LoadSession(const FileName: string): TSessionState;

implementation

uses System.Classes, System.DateUtils, System.IOUtils, System.JSON, System.Math,
  ImageDup.Core;

resourcestring
  rsObjectMissingFmt='Missing object: %s';
  rsListMissingFmt='Missing list: %s';
  rsValueMissingFmt='Missing value: %s';
  rsInvalidIntegerFmt='Invalid integer: %s';
  rsInvalidNumberFmt='Invalid number: %s';
  rsInvalidBooleanFmt='Invalid Boolean value: %s';
  rsInvalidJsonSession='Invalid JSON session.';
  rsUnrecognizedSessionFormat='Unrecognized session format.';
  rsUnsupportedSessionVersion='Unsupported session version.';
  rsInvalidSessionGroup='Invalid group.';
  rsInvalidSessionFile='Invalid file entry.';

function RequireObject(Parent: TJSONObject; const Name: string): TJSONObject;
begin
  Result := Parent.GetValue(Name) as TJSONObject;
  if Result = nil then raise EConvertError.CreateFmt(rsObjectMissingFmt, [Name]);
end;

function RequireArray(Parent: TJSONObject; const Name: string): TJSONArray;
begin
  Result := Parent.GetValue(Name) as TJSONArray;
  if Result = nil then raise EConvertError.CreateFmt(rsListMissingFmt, [Name]);
end;

function TextValue(Parent: TJSONObject; const Name: string): string;
var V: TJSONValue;
begin
  V := Parent.GetValue(Name);
  if V = nil then raise EConvertError.CreateFmt(rsValueMissingFmt, [Name]);
  Result := V.Value;
end;

function IntValue(Parent: TJSONObject; const Name: string): Integer;
begin
  if not TryStrToInt(TextValue(Parent, Name), Result) then
    raise EConvertError.CreateFmt(rsInvalidIntegerFmt, [Name]);
end;

function OptionalIntValue(Parent: TJSONObject; const Name: string;
  DefaultValue: Integer): Integer;
var V: TJSONValue;
begin
  V := Parent.GetValue(Name);
  if V = nil then Exit(DefaultValue);
  if not TryStrToInt(V.Value, Result) then
    raise EConvertError.CreateFmt(rsInvalidIntegerFmt, [Name]);
end;

function Int64Value(Parent: TJSONObject; const Name: string): Int64;
begin
  if not TryStrToInt64(TextValue(Parent, Name), Result) then
    raise EConvertError.CreateFmt(rsInvalidIntegerFmt, [Name]);
end;

function FloatValue(Parent: TJSONObject; const Name: string): Double;
begin
  if not TryStrToFloat(TextValue(Parent, Name), Result, TFormatSettings.Invariant) then
    raise EConvertError.CreateFmt(rsInvalidNumberFmt, [Name]);
end;

function OptionalFloatValue(Parent: TJSONObject; const Name: string;
  DefaultValue: Double): Double;
var V: TJSONValue;
begin
  V := Parent.GetValue(Name);
  if V = nil then Exit(DefaultValue);
  if not TryStrToFloat(V.Value, Result, TFormatSettings.Invariant) then
    raise EConvertError.CreateFmt(rsInvalidNumberFmt, [Name]);
end;

function BoolValue(Parent: TJSONObject; const Name: string): Boolean;
begin
  if not TryStrToBool(TextValue(Parent, Name), Result) then
    raise EConvertError.CreateFmt(rsInvalidBooleanFmt, [Name]);
end;

function OptionalBoolValue(Parent: TJSONObject; const Name: string;
  DefaultValue: Boolean): Boolean;
var V: TJSONValue;
begin
  V := Parent.GetValue(Name);
  if V = nil then Exit(DefaultValue);
  if not TryStrToBool(V.Value, Result) then
    raise EConvertError.CreateFmt(rsInvalidBooleanFmt, [Name]);
end;

procedure SaveSession(const FileName: string; const State: TSessionState);
var
  Root, Criteria, GO, MO, QO: TJSONObject;
  Paths, Groups, Members, Selected: TJSONArray;
  G: TImageGroup;
  M: TGroupMember;
  S: string;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('format', 'ImageDupSession');
    Root.AddPair('version', TJSONNumber.Create(1));
    Root.AddPair('scannedFiles', TJSONNumber.Create(State.ScannedFiles));
    Criteria := TJSONObject.Create;
    Root.AddPair('criteria', Criteria);
    Paths := TJSONArray.Create;
    Criteria.AddPair('paths', Paths);
    for S in State.Roots do Paths.Add(S);
    Criteria.AddPair('recursive', TJSONBool.Create(State.Recursive));
    Criteria.AddPair('includeSingletons', TJSONBool.Create(State.IncludeSingletons));
    Criteria.AddPair('quality', TJSONNumber.Create(State.Quality));
    Criteria.AddPair('pixelError', TJSONNumber.Create(State.PixelError));
    Criteria.AddPair('threadCount', TJSONNumber.Create(State.ThreadCount));
    Selected := TJSONArray.Create;
    Root.AddPair('selectedFiles', Selected);
    for S in State.SelectedFiles do Selected.Add(S);
    Groups := TJSONArray.Create;
    Root.AddPair('groups', Groups);
    for G in State.Groups do
    begin
      GO := TJSONObject.Create;
      Groups.AddElement(GO);
      GO.AddPair('id', TJSONNumber.Create(G.Id));
      Members := TJSONArray.Create;
      GO.AddPair('members', Members);
      for M in G.Members do
      begin
        MO := TJSONObject.Create;
        Members.AddElement(MO);
        MO.AddPair('fileName', M.Info.FileName);
        MO.AddPair('width', TJSONNumber.Create(M.Info.Width));
        MO.AddPair('height', TJSONNumber.Create(M.Info.Height));
        MO.AddPair('dpiX', TJSONNumber.Create(M.Info.DpiX));
        MO.AddPair('dpiY', TJSONNumber.Create(M.Info.DpiY));
        MO.AddPair('bytes', TJSONNumber.Create(M.Info.Bytes));
        MO.AddPair('modified', DateToISO8601(M.Info.Modified, False));
        QO := TJSONObject.Create;
        MO.AddPair('quality', QO);
        QO.AddPair('sharpness', TJSONNumber.Create(M.Info.Quality.Sharpness));
        QO.AddPair('noise', TJSONNumber.Create(M.Info.Quality.Noise));
        QO.AddPair('blockArtifacts', TJSONNumber.Create(M.Info.Quality.BlockArtifacts));
        QO.AddPair('clipping', TJSONNumber.Create(M.Info.Quality.Clipping));
        QO.AddPair('banding', TJSONNumber.Create(M.Info.Quality.Banding));
        QO.AddPair('upscaleRisk', TJSONNumber.Create(M.Info.Quality.UpscaleRisk));
        QO.AddPair('bitDepth', TJSONNumber.Create(M.Info.Quality.BitDepth));
        QO.AddPair('hasColorProfile', TJSONBool.Create(M.Info.Quality.HasColorProfile));
        QO.AddPair('chromaSubsampling',
          TJSONNumber.Create(Ord(M.Info.Quality.ChromaSubsampling)));
        QO.AddPair('colorMode',
          TJSONNumber.Create(Ord(M.Info.Quality.ColorMode)));
        MO.AddPair('qualityScore', TJSONNumber.Create(M.QualityScore));
        MO.AddPair('exactClass', TJSONNumber.Create(M.ExactClass));
        MO.AddPair('hasIdenticalPeer', TJSONBool.Create(M.HasIdenticalPeer));
        MO.AddPair('isReference', TJSONBool.Create(M.IsReference));
        MO.AddPair('distance', TJSONNumber.Create(M.Metrics.Distance));
        MO.AddPair('rgbError', TJSONNumber.Create(M.Metrics.RGBError));
        MO.AddPair('structural', TJSONNumber.Create(M.Metrics.Structural));
        MO.AddPair('worstStructural', TJSONNumber.Create(M.Metrics.WorstStructural));
        MO.AddPair('worstRGB', TJSONNumber.Create(M.Metrics.WorstRGB));
      end;
    end;
    TFile.WriteAllText(FileName, Root.Format(2), TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

function LoadSession(const FileName: string): TSessionState;
var
  JSON: TJSONValue;
  Root, Criteria, GO, MO, QO: TJSONObject;
  Paths, Groups, Members, Selected: TJSONArray;
  I, J: Integer;
  G: TImageGroup;
  M: TGroupMember;
begin
  Result := Default(TSessionState);
  JSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
  try
    if not (JSON is TJSONObject) then raise EConvertError.Create(rsInvalidJsonSession);
    Root := TJSONObject(JSON);
    if TextValue(Root, 'format') <> 'ImageDupSession' then raise EConvertError.Create(rsUnrecognizedSessionFormat);
    if IntValue(Root, 'version') <> 1 then raise EConvertError.Create(rsUnsupportedSessionVersion);
    Result.ScannedFiles := OptionalIntValue(Root, 'scannedFiles', 0);
    Criteria := RequireObject(Root, 'criteria');
    Paths := RequireArray(Criteria, 'paths');
    SetLength(Result.Roots, Paths.Count);
    for I := 0 to Paths.Count - 1 do Result.Roots[I] := Paths.Items[I].Value;
    Result.Recursive := BoolValue(Criteria, 'recursive');
    Result.IncludeSingletons := OptionalBoolValue(Criteria, 'includeSingletons', False);
    if Criteria.GetValue('quality') <> nil then
      Result.Quality := IntValue(Criteria, 'quality')
    else
      Result.Quality := DistanceToComparisonQuality(
        IntValue(Criteria, 'distance'));
    Result.PixelError := FloatValue(Criteria, 'pixelError');
    Result.ThreadCount := OptionalIntValue(Criteria, 'threadCount', 3);
    Selected := RequireArray(Root, 'selectedFiles');
    SetLength(Result.SelectedFiles, Selected.Count);
    for I := 0 to Selected.Count - 1 do Result.SelectedFiles[I] := Selected.Items[I].Value;
    Groups := RequireArray(Root, 'groups');
    SetLength(Result.Groups, Groups.Count);
    for I := 0 to Groups.Count - 1 do
    begin
      if not (Groups.Items[I] is TJSONObject) then raise EConvertError.Create(rsInvalidSessionGroup);
      GO := TJSONObject(Groups.Items[I]);
      G.Id := IntValue(GO, 'id');
      Members := RequireArray(GO, 'members');
      SetLength(G.Members, Members.Count);
      for J := 0 to Members.Count - 1 do
      begin
        if not (Members.Items[J] is TJSONObject) then raise EConvertError.Create(rsInvalidSessionFile);
        MO := TJSONObject(Members.Items[J]);
        M := Default(TGroupMember);
        M.ImageIndex := J;
        M.Info.FileName := TextValue(MO, 'fileName');
        M.Info.Width := IntValue(MO, 'width');
        M.Info.Height := IntValue(MO, 'height');
        M.Info.DpiX := OptionalFloatValue(MO, 'dpiX', 0);
        M.Info.DpiY := OptionalFloatValue(MO, 'dpiY', 0);
        M.Info.Bytes := Int64Value(MO, 'bytes');
        M.Info.Modified := ISO8601ToDate(TextValue(MO, 'modified'), False);
        QO := MO.GetValue('quality') as TJSONObject;
        if Assigned(QO) then begin
          M.Info.Quality.Sharpness := OptionalFloatValue(QO, 'sharpness', 0);
          M.Info.Quality.Noise := OptionalFloatValue(QO, 'noise', 0);
          M.Info.Quality.BlockArtifacts := OptionalFloatValue(QO, 'blockArtifacts', 0);
          M.Info.Quality.Clipping := OptionalFloatValue(QO, 'clipping', 0);
          M.Info.Quality.Banding := OptionalFloatValue(QO, 'banding', 0);
          M.Info.Quality.UpscaleRisk := OptionalFloatValue(QO, 'upscaleRisk', 0);
          M.Info.Quality.BitDepth := OptionalIntValue(QO, 'bitDepth', 0);
          M.Info.Quality.HasColorProfile := OptionalBoolValue(QO,
            'hasColorProfile', False);
          M.Info.Quality.ChromaSubsampling := TChromaSubsampling(EnsureRange(
            OptionalIntValue(QO, 'chromaSubsampling', Ord(csUnknown)),
            Ord(Low(TChromaSubsampling)), Ord(High(TChromaSubsampling))));
          if QO.GetValue('colorMode') <> nil then
            M.Info.Quality.ColorMode := TImageColorMode(EnsureRange(
              OptionalIntValue(QO, 'colorMode', Ord(icmUnknown)),
              Ord(Low(TImageColorMode)), Ord(High(TImageColorMode))))
          else
            case M.Info.Quality.ChromaSubsampling of
              csGray: M.Info.Quality.ColorMode := icmGrayscale;
              cs420, cs422, cs444, csOther:
                M.Info.Quality.ColorMode := icmColor;
            else
              M.Info.Quality.ColorMode := icmUnknown;
            end;
        end;
        M.Metrics.Distance := IntValue(MO, 'distance');
        M.Metrics.RGBError := FloatValue(MO, 'rgbError');
        M.Metrics.Structural := FloatValue(MO, 'structural');
        M.Metrics.WorstStructural := FloatValue(MO, 'worstStructural');
        M.Metrics.WorstRGB := FloatValue(MO, 'worstRGB');
        if MO.GetValue('exactClass') <> nil then
          M.ExactClass := IntValue(MO, 'exactClass')
        else if (M.Metrics.Distance = 0) and (M.Metrics.RGBError <= 1E-12) then
          M.ExactClass := 0
        else
          M.ExactClass := J;
        M.HasIdenticalPeer := OptionalBoolValue(MO, 'hasIdenticalPeer',
          (M.Metrics.Distance = 0) and (M.Metrics.RGBError <= 1E-12));
        M.IsReference := OptionalBoolValue(MO, 'isReference', False);
        G.Members[J] := M;
      end;
      CalculateGroupQuality(G);
      Result.Groups[I] := G;
    end;
  finally
    JSON.Free;
  end;
end;

end.


