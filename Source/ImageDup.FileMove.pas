unit ImageDup.FileMove;

interface

uses
  System.Classes;

function CommonSearchRoot(Paths: TStrings): string;
function PreservedDestination(const SourceFile, SearchRoot,
  DestinationRoot: string): string;
function MoveFilePreservingStructure(const SourceFile, SearchRoot,
  DestinationRoot: string; out DestinationFile, ErrorText: string): Boolean;

implementation

uses
  System.SysUtils, System.IOUtils;

resourcestring
  rsMoveSameSourceDestination='The source and destination are the same.';
  rsMoveDestinationExistsFmt='The destination file already exists: %s';

function NormalizedDirectory(const Value: string): string;
var
  PathRoot: string;
begin
  Result := TPath.GetFullPath(Trim(Value));
  PathRoot := TPath.GetPathRoot(Result);
  while (Length(Result) > Length(PathRoot)) and
    Result.EndsWith(TPath.DirectorySeparatorChar) do
    Delete(Result, Length(Result), 1);
end;

function IsSameOrChild(const DirectoryName, ParentDirectory: string): Boolean;
var
  ParentWithSeparator: string;
begin
  ParentWithSeparator := IncludeTrailingPathDelimiter(ParentDirectory);
  Result := SameText(DirectoryName, ParentDirectory) or
    SameText(Copy(DirectoryName, 1, Length(ParentWithSeparator)),
      ParentWithSeparator);
end;

function CommonSearchRoot(Paths: TStrings): string;
var
  Candidate, Current, Parent: string;
  I: Integer;
begin
  Result := '';
  for I := 0 to Paths.Count - 1 do
  begin
    if Trim(Paths[I]) = '' then
      Continue;
    Current := NormalizedDirectory(Paths[I]);
    if Result = '' then
    begin
      Result := Current;
      Continue;
    end;
    if not SameText(TPath.GetPathRoot(Result), TPath.GetPathRoot(Current)) then
      Exit('');
    Candidate := Result;
    while not IsSameOrChild(Current, Candidate) do
    begin
      Parent := NormalizedDirectory(ExtractFileDir(Candidate));
      if SameText(Parent, Candidate) or (Parent = '') then
        Exit('');
      Candidate := Parent;
    end;
    Result := Candidate;
  end;
end;

function VolumeFolderName(const Root: string): string;
var
  C: Char;
begin
  Result := '';
  for C in Root do
    if CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + C;
  if Result = '' then
    Result := 'root';
end;

function PreservedDestination(const SourceFile, SearchRoot,
  DestinationRoot: string): string;
var
  SourceFull, Base, RelativePath: string;
begin
  SourceFull := TPath.GetFullPath(SourceFile);
  Base := SearchRoot;
  if (Base = '') or not IsSameOrChild(ExtractFileDir(SourceFull), Base) then
  begin
    Base := TPath.GetPathRoot(SourceFull);
    RelativePath := TPath.Combine(VolumeFolderName(Base),
      Copy(SourceFull, Length(IncludeTrailingPathDelimiter(Base)) + 1,
        MaxInt));
  end
  else
    RelativePath := Copy(SourceFull,
      Length(IncludeTrailingPathDelimiter(Base)) + 1, MaxInt);
  Result := TPath.Combine(TPath.GetFullPath(DestinationRoot), RelativePath);
end;

function MoveFilePreservingStructure(const SourceFile, SearchRoot,
  DestinationRoot: string; out DestinationFile, ErrorText: string): Boolean;
begin
  Result := False;
  ErrorText := '';
  DestinationFile := PreservedDestination(SourceFile, SearchRoot,
    DestinationRoot);
  try
    if SameText(TPath.GetFullPath(SourceFile), DestinationFile) then
      raise Exception.Create(rsMoveSameSourceDestination);
    if TFile.Exists(DestinationFile) then
      raise Exception.CreateFmt(rsMoveDestinationExistsFmt,
        [DestinationFile]);
    ForceDirectories(ExtractFileDir(DestinationFile));
    TFile.Move(SourceFile, DestinationFile);
    Result := True;
  except
    on E: Exception do
      ErrorText := E.Message;
  end;
end;

end.



