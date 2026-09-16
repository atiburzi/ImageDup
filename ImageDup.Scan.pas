unit ImageDup.Scan;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections, ImageDup.Core, ImageDup.Groups;

type
  TScanUpdate = record
    Groups: TArray<TImageGroup>;
    Errors: TArray<string>;
    Scanned, TotalImages, ErrorCount, GroupCount, GroupedFiles: Integer;
    PairCount: Int64;
    CurrentFile, FatalError: string;
    Done, Cancelled: Boolean;
  end;

  // This coordinator never accesses controls. Dedicated workers decode images
  // and build signatures; results are consumed in enumeration order so that
  // group membership is independent from scheduling and thread count.
  TImageScan = class(TThread)
  private
    FRoots: TArray<string>;
    FRecursive: Boolean;
    FDistance: Integer;
    FPixelError: Double;
    FThreadCount: Integer;
    FLock: TObject;
    FPending: TList<TImageGroup>;
    FErrors: TList<string>;
    FState: TScanUpdate;
    procedure ReportError(const Value: string);
    procedure SetCurrentFile(const Value: string);
    procedure Scan;
  protected
    procedure Execute; override;
  public
    constructor Create(const Roots: TArray<string>; Recursive: Boolean;
      Distance: Integer; PixelError: Double; ThreadCount: Integer = 3);
    destructor Destroy; override;
    function Drain: TScanUpdate;
    property ThreadCount: Integer read FThreadCount;
  end;

implementation

uses Winapi.Windows, System.IOUtils, System.Math;

type
  TScanEntry = record
    Info: TImageInfo;
    Signature: TImageSignature;
  end;

  TWorkResult = class
  public
    Entry: TScanEntry;
    Error: string;
    Success: Boolean;
  end;

  TSignatureQueue = class
  private
    FOwner: TImageScan;
    FCandidates: TArray<TImageInfo>;
    FResults: TArray<TWorkResult>;
    FNextIndex, FConsumeIndex, FMaxAhead: Integer;
    FStopped: Boolean;
    FLock: TObject;
  public
    constructor Create(Owner: TImageScan; const Candidates: TArray<TImageInfo>);
    destructor Destroy; override;
    function Take(out Index: Integer; out Info: TImageInfo): Boolean;
    procedure Complete(Index: Integer; Work: TWorkResult);
    function WaitFor(Index: Integer; out Work: TWorkResult): Boolean;
    procedure Stop;
  end;

  TSignatureWorker = class(TThread)
  private
    FQueue: TSignatureQueue;
  protected
    procedure Execute; override;
  public
    constructor Create(Queue: TSignatureQueue);
  end;

constructor TSignatureQueue.Create(Owner: TImageScan;
  const Candidates: TArray<TImageInfo>);
begin
  inherited Create;
  FOwner := Owner;
  FCandidates := Copy(Candidates);
  SetLength(FResults, Length(FCandidates));
  FMaxAhead := Max(2, Owner.ThreadCount * 2);
  FLock := TObject.Create;
end;

destructor TSignatureQueue.Destroy;
var Work: TWorkResult;
begin
  for Work in FResults do Work.Free;
  FLock.Free;
  inherited;
end;

function TSignatureQueue.Take(out Index: Integer; out Info: TImageInfo): Boolean;
begin
  Result := False;
  TMonitor.Enter(FLock);
  try
    while not FStopped and not FOwner.Terminated do
    begin
      if FNextIndex >= Length(FCandidates) then Exit;
      if FNextIndex < FConsumeIndex + FMaxAhead then
      begin
        Index := FNextIndex;
        Inc(FNextIndex);
        Info := FCandidates[Index];
        Exit(True);
      end;
      TMonitor.Wait(FLock, 50);
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TSignatureQueue.Complete(Index: Integer; Work: TWorkResult);
begin
  TMonitor.Enter(FLock);
  try
    if FStopped then
      Work.Free
    else
    begin
      FResults[Index] := Work;
      TMonitor.PulseAll(FLock);
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TSignatureQueue.WaitFor(Index: Integer; out Work: TWorkResult): Boolean;
begin
  Work := nil;
  TMonitor.Enter(FLock);
  try
    while not FStopped and not FOwner.Terminated and
      (FResults[Index] = nil) do
      TMonitor.Wait(FLock, 50);
    if FResults[Index] = nil then Exit(False);
    Work := FResults[Index];
    FResults[Index] := nil;
    FConsumeIndex := Index + 1;
    TMonitor.PulseAll(FLock);
    Result := True;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TSignatureQueue.Stop;
begin
  TMonitor.Enter(FLock);
  try
    FStopped := True;
    TMonitor.PulseAll(FLock);
  finally
    TMonitor.Exit(FLock);
  end;
end;

constructor TSignatureWorker.Create(Queue: TSignatureQueue);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FQueue := Queue;
end;

procedure TSignatureWorker.Execute;
var
  Index: Integer;
  Info: TImageInfo;
  Work: TWorkResult;
begin
  while not Terminated and FQueue.Take(Index, Info) do
  begin
    Work := TWorkResult.Create;
    Work.Entry.Info := Info;
    try
      FQueue.FOwner.SetCurrentFile(Info.FileName);
      Work.Entry.Signature := LoadSignature(Info.FileName,
        Work.Entry.Info.Width, Work.Entry.Info.Height,
        Work.Entry.Info.DpiX, Work.Entry.Info.DpiY);
      Work.Entry.Info.Quality := Work.Entry.Signature.Quality;
      if FQueue.FOwner.Terminated then
      begin
        Work.Free;
        Break;
      end;
      Work.Success := True;
    except
      on E: Exception do Work.Error := Info.FileName + ': ' + E.Message;
    end;
    FQueue.Complete(Index, Work);
  end;
end;

constructor TImageScan.Create(const Roots: TArray<string>; Recursive: Boolean;
  Distance: Integer; PixelError: Double; ThreadCount: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FRoots := Copy(Roots);
  FRecursive := Recursive;
  FDistance := Distance;
  FPixelError := PixelError;
  FThreadCount := EnsureRange(ThreadCount, 1, 64);
  FLock := TObject.Create;
  FPending := TList<TImageGroup>.Create;
  FErrors := TList<string>.Create;
end;

destructor TImageScan.Destroy;
begin
  Terminate;
  // inherited waits for the coordinator and its child workers.
  inherited;
  FErrors.Free;
  FPending.Free;
  FLock.Free;
end;

procedure TImageScan.SetCurrentFile(const Value: string);
begin
  TMonitor.Enter(FLock);
  try
    FState.CurrentFile := Value;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TImageScan.ReportError(const Value: string);
begin
  TMonitor.Enter(FLock);
  try
    Inc(FState.ErrorCount);
    if FState.ErrorCount <= 200 then FErrors.Add(Value);
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TImageScan.Drain: TScanUpdate;
begin
  TMonitor.Enter(FLock);
  try
    Result := FState;
    if not Result.Done and (WaitForSingleObject(Handle, 0) = WAIT_OBJECT_0) then
    begin
      Result.Done := True;
      Result.Cancelled := Terminated;
    end;
    Result.Groups := FPending.ToArray;
    FPending.Clear;
    Result.Errors := FErrors.ToArray;
    FErrors.Clear;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TImageScan.Execute;
begin
  try
    try
      Scan;
    except
      on E: Exception do
      begin
        ReportError(E.Message);
        TMonitor.Enter(FLock);
        try
          FState.FatalError := E.Message;
        finally
          TMonitor.Exit(FLock);
        end;
      end;
    end;
  finally
    TMonitor.Enter(FLock);
    try
      FState.Done := True;
      FState.Cancelled := Terminated;
    finally
      TMonitor.Exit(FLock);
    end;
  end;
end;

procedure TImageScan.Scan;
var
  Candidates: TList<TImageInfo>;
  CandidateArray: TArray<TImageInfo>;
  Entries: TList<TScanEntry>;
  Folders: TStack<string>;
  SeenFolders, SeenFiles: TDictionary<string, Boolean>;
  Search: TSearchRec;
  Folder, FileName, Ext, Key: string;
  Info: TImageInfo;
  Entry: TScanEntry;
  Builder: TGroupBuilder;
  Accepted: TDictionary<Integer, TComparison>;
  Metrics: TComparison;
  Group: TImageGroup;
  GroupId: Integer;
  Queue: TSignatureQueue;
  Workers: TObjectList<TSignatureWorker>;
  Worker: TSignatureWorker;
  Work: TWorkResult;
  Code, I, J: Integer;
begin
  Candidates := TList<TImageInfo>.Create;
  Folders := TStack<string>.Create;
  SeenFolders := TDictionary<string, Boolean>.Create;
  SeenFiles := TDictionary<string, Boolean>.Create;
  try
    for Folder in FRoots do Folders.Push(Folder);
    while (Folders.Count > 0) and not Terminated do
    begin
      Folder := Folders.Pop;
      Key := UpperCase(ExcludeTrailingPathDelimiter(TPath.GetFullPath(Folder)));
      if SeenFolders.ContainsKey(Key) then Continue;
      SeenFolders.Add(Key, True);
      Code := FindFirst(TPath.Combine(Folder, '*'), faAnyFile, Search);
      if Code <> 0 then
      begin
        if (Code <> ERROR_FILE_NOT_FOUND) and (Code <> ERROR_NO_MORE_FILES) then
          ReportError(Folder + ': ' + SysErrorMessage(Code));
        Continue;
      end;
      try
        repeat
          if Terminated then Break;
          if (Search.Name <> '.') and (Search.Name <> '..') then
          begin
            FileName := TPath.Combine(Folder, Search.Name);
            if (Search.Attr and faDirectory) <> 0 then
            begin
              if FRecursive and
                ((Search.FindData.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) = 0) then
                Folders.Push(FileName);
            end
            else
            begin
              Ext := LowerCase(TPath.GetExtension(FileName));
              if (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.png') or (Ext = '.bmp') then
              begin
                Key := UpperCase(TPath.GetFullPath(FileName));
                if not SeenFiles.ContainsKey(Key) then
                begin
                  SeenFiles.Add(Key, True);
                  try
                    Info := Default(TImageInfo);
                    Info.FileName := FileName;
                    Info.Bytes := Search.Size;
                    Info.Modified := TFile.GetLastWriteTime(FileName);
                    Candidates.Add(Info);
                  except
                    on E: Exception do ReportError(FileName + ': ' + E.Message);
                  end;
                end;
              end;
            end;
          end;
          Code := FindNext(Search);
        until Code <> 0;
        if not Terminated and (Code <> ERROR_NO_MORE_FILES) and (Code <> 0) then
          ReportError(Folder + ': ' + SysErrorMessage(Code));
      finally
        System.SysUtils.FindClose(Search);
      end;
    end;
    CandidateArray := Candidates.ToArray;
    TMonitor.Enter(FLock);
    try
      FState.TotalImages := Length(CandidateArray);
    finally
      TMonitor.Exit(FLock);
    end;
    if Terminated or (Length(CandidateArray) = 0) then Exit;
  finally
    SeenFiles.Free;
    SeenFolders.Free;
    Folders.Free;
    Candidates.Free;
  end;

  Entries := TList<TScanEntry>.Create;
  Builder := TGroupBuilder.Create;
  Accepted := TDictionary<Integer, TComparison>.Create;
  Queue := TSignatureQueue.Create(Self, CandidateArray);
  Workers := TObjectList<TSignatureWorker>.Create(True);
  try
    for I := 1 to FThreadCount do Workers.Add(TSignatureWorker.Create(Queue));
    for Worker in Workers do Worker.Start;
    for I := 0 to High(CandidateArray) do
    begin
      if not Queue.WaitFor(I, Work) then Break;
      try
        if not Work.Success then
        begin
          ReportError(Work.Error);
          TMonitor.Enter(FLock);
          try
            Inc(FState.Scanned);
          finally
            TMonitor.Exit(FLock);
          end;
          Continue;
        end;
        if Terminated then Break;
        Entry := Work.Entry;
        Accepted.Clear;
        for J := 0 to Entries.Count - 1 do
        begin
          if Terminated then Break;
          if CompareSignatures(Entry.Signature, Entries[J].Signature,
            FDistance, FPixelError, Metrics) then Accepted.Add(J, Metrics);
        end;
        if Terminated then Break;
        GroupId := Builder.Add(Entry.Info, Accepted);
        Entries.Add(Entry);
        if GroupId >= 0 then
        begin
          Group := Builder.Snapshot(GroupId);
          for J := 0 to High(Group.Members) do
            if J = 0 then begin
              Group.Members[J].Metrics := Default(TComparison);
              Group.Members[J].Metrics.Structural := 1;
              Group.Members[J].Metrics.WorstStructural := 1;
            end else
              StructuralMetrics(Entries[Group.Members[0].ImageIndex].Signature,
                Entries[Group.Members[J].ImageIndex].Signature,
                Group.Members[J].Metrics);
          TMonitor.Enter(FLock);
          try
            FPending.Add(Group);
            if Length(Group.Members) = 2 then
            begin
              Inc(FState.GroupCount);
              Inc(FState.GroupedFiles, 2);
            end
            else Inc(FState.GroupedFiles);
          finally
            TMonitor.Exit(FLock);
          end;
        end;
        TMonitor.Enter(FLock);
        try
          Inc(FState.Scanned);
          Inc(FState.PairCount, Accepted.Count);
        finally
          TMonitor.Exit(FLock);
        end;
      finally
        Work.Free;
      end;
    end;
  finally
    Queue.Stop;
    for Worker in Workers do Worker.Terminate;
    for Worker in Workers do Worker.WaitFor;
    Workers.Free;
    Queue.Free;
    Accepted.Free;
    Builder.Free;
    Entries.Free;
  end;
end;

end.
