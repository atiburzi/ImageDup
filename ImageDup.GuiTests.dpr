program ImageDup.GuiTests;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Forms, Vcl.Controls, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.Graphics,
  VirtualTrees, VirtualTrees.Types,
  ImageDup.Main in 'ImageDup.Main.pas',
  ImageDup.Scan in 'ImageDup.Scan.pas',
  ImageDup.Groups in 'ImageDup.Groups.pas',
  ImageDup.Session in 'ImageDup.Session.pas',
  ImageDup.Core in 'ImageDup.Core.pas';

procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create(MessageText);
end;

procedure AwaitScan(Form: TMainForm);
var Deadline: UInt64;
begin
  Deadline := GetTickCount64 + 30000;
  while Assigned(Form.Worker) do begin
    Application.ProcessMessages;
    Form.PollTimerTimer(nil);
    if GetTickCount64 > Deadline then raise Exception.Create('Scan timeout');
    Sleep(10);
  end;
end;

function LastChild(Tree: TVirtualStringTree; Parent: PVirtualNode): PVirtualNode;
var Next: PVirtualNode;
begin
  Result := Tree.GetFirstChild(Parent);
  if Result = nil then Exit;
  repeat
    Next := Tree.GetNextSibling(Result);
    if Assigned(Next) then Result := Next;
  until Next = nil;
end;

function TreeSnapshot(Tree: TVirtualStringTree): string;
var Node: PVirtualNode; Column: Integer;
begin
  Result := '';
  Node := Tree.GetFirst;
  while Assigned(Node) do begin
    for Column := 0 to Tree.Header.Columns.Count - 1 do
      Result := Result + Tree.Text[Node, Column] + #9;
    Result := Result + sLineBreak;
    Node := Tree.GetNext(Node);
  end;
end;

function CheckedFileCount(Tree: TVirtualStringTree): Integer;
var Node: PVirtualNode;
begin
  Result := 0;
  Node := Tree.GetFirst;
  while Assigned(Node) do begin
    if (Tree.CheckType[Node] = ctCheckBox) and
      (Tree.CheckState[Node] = csCheckedNormal) then Inc(Result);
    Node := Tree.GetNext(Node);
  end;
end;

procedure Test;
var
  Form: TMainForm;
  Root, EmptyFolder, Path, MovedPath, SessionPath, LegacySessionPath,
    SessionText: string;
  GroupNode, FileNode, LastFile: PVirtualNode;
  I, Pass, Column, ScannedBeforeSave: Integer;
  SelectedBytes: Int64;
  ReferenceQuality, FileQuality, PreviousQuality: Double;
  Snapshot1, Snapshot3: string;
  Stream: TFileStream;
  PaintBitmap: TBitmap;
  GreenRows, RedRows: Integer;
  CanClose: Boolean;
  HitInfo: THitInfo;
  HeaderHit: TVTHeaderHitInfo;
begin
  Root := TPath.GetFullPath(ParamStr(1));
  Check(DirectoryExists(Root), 'Fixture directory missing');
  EmptyFolder := TPath.Combine(Root, 'empty');
  ForceDirectories(EmptyFolder);
  SessionPath := TPath.Combine(Root, 'roundtrip.idup');
  LegacySessionPath := TPath.Combine(Root, 'legacy.idup');
  Form := TMainForm.Create(nil);
  try
    Form.Show;
    Form.Update;
    Application.ProcessMessages;
    Check(Form.ResultsTree.Header.Columns.Count = 5, 'DFM tree columns');
    Check((Form.StatusProgress.Max = 100) and (Form.StatusProgress.Position = 0),
      'Initial progress meter state');
    Check((Form.SelectedFileCount = 0) and (Form.SelectedFileBytes = 0) and
      (Pos('Selezionati: 0 file, 0 byte', Form.StatusBar.SimpleText) > 0),
      'Initial selected-file size');
    Check(Form.SelectionMenu.Items.Count >= 7, 'Selection menu commands');
    Check(not Form.ToolButtonSelectOptions.Enabled, 'Selection button initially enabled');
    Check(not Form.DeleteSelectedButton.Enabled, 'Recycle button initially enabled');
    Check(Form.ToolButtonNewSession.Enabled, 'Clear-session button initially disabled');
    Check((Form.Left >= Form.Monitor.WorkareaRect.Left) and
      (Form.Top >= Form.Monitor.WorkareaRect.Top) and
      (Form.Left + Form.Width <= Form.Monitor.WorkareaRect.Right) and
      (Form.Top + Form.Height <= Form.Monitor.WorkareaRect.Bottom),
      'Main window exceeds monitor work area');
    Check(Form.BrowseButton.Visible and Form.ToolButtonSelectOptions.Visible and
      Form.DeleteSelectedButton.Visible and Form.ErrorsButton.Visible and
      Form.ToolButtonNewSession.Visible and Form.ToolButtonSaveSession.Visible and
      Form.ToolButtonLoadSession.Visible and Form.StartButton.Visible and
      Form.StopButton.Visible, 'Command controls are not visible');
    Check(Form.OpenSessionDialog is TFileOpenDialog, 'Modern open dialog');
    Check(Form.SaveSessionDialog is TFileSaveDialog, 'Modern save dialog');
    Check(Form.OpenSessionDialog.DefaultExtension = 'idup', 'Open extension');
    Check(Form.SaveSessionDialog.DefaultExtension = 'idup', 'Save extension');
    Check(Form.SaveSessionDialog.FileName = 'sessione.idup', 'Default session name');
    Check(Form.ThreadEdit.Value = 3, 'Default worker thread count');
    Check(Form.PreviewPanel.Height >= 150, 'DFM preview height');
    Form.PathsMemo.Lines.Add(Root);
    Form.PathsMemo.Lines.Add(TPath.Combine(Root, 'nested'));
    Form.PathsMemo.Lines.Add(Root);
    Form.RecursiveCheck.Checked := True;
    Form.StartButtonClick(nil);
    Check(Assigned(Form.Worker), 'Worker was not started');
    Check(not Form.StartButton.Enabled, 'Start should be disabled during scan');
    Check(not Form.ToolButtonSaveSession.Enabled, 'Session save should be disabled during scan');
    Check(not Form.ThreadEdit.Enabled, 'Thread count should be disabled during scan');
    Check(not Form.DeleteSelectedButton.Enabled, 'Recycle button enabled during scan');
    AwaitScan(Form);
    Check(Form.ScannedFileCount > 0, 'Scanned-file count was not retained');
    Check(Form.StatusProgress.Position = Form.StatusProgress.Max,
      'Progress meter did not reach completion');
    Check(Form.ToolButtonSelectOptions.Enabled, 'Selection button not enabled after scan');
    Check(Form.ResultsTree.RootNodeCount = 1, 'Expected one group');
    Check(Form.ResultsTree.TotalCount = 5, 'Expected one group plus four files');
    GroupNode := Form.ResultsTree.GetFirst;
    Check(Form.ResultsTree.CheckType[GroupNode] = ctNone, 'Group has a checkbox');
    Check(Pos('Gruppo 1', Form.ResultsTree.Text[GroupNode, 0]) = 1, 'Group caption');
    for Column := 1 to Form.ResultsTree.Header.Columns.Count - 1 do
      Check(Form.ResultsTree.Text[GroupNode, Column] = '',
        'Group row contains default Node text');
    FileNode := Form.ResultsTree.GetFirstChild(GroupNode);
    ReferenceQuality := StrToFloat(Form.ResultsTree.Text[FileNode, 4]);
    PreviousQuality := ReferenceQuality;
    PaintBitmap := TBitmap.Create;
    GreenRows := 0;
    RedRows := 0;
    I := 0;
    try
      while Assigned(FileNode) do begin
        Inc(I);
        Check(Form.ResultsTree.CheckType[FileNode] = ctCheckBox, 'File checkbox missing');
        Path := Form.ResultsTree.Text[FileNode, 0];
        Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
        try
          Check(IntToStr(Stream.Size) = Form.ResultsTree.Text[FileNode, 2], 'Incorrect byte size');
        finally
          Stream.Free;
        end;
        Check(Form.ResultsTree.Text[FileNode, 1] <> '', 'Pixel dimensions missing');
        Check(Form.ResultsTree.Text[FileNode, 3] <> '', 'File date/time missing');
        FileQuality := StrToFloat(Form.ResultsTree.Text[FileNode, 4]);
        Check(FileQuality > 0, 'Quality score missing');
        Check(PreviousQuality >= FileQuality, 'Group is not sorted by descending quality');
        PreviousQuality := FileQuality;
        PaintBitmap.Canvas.Font.Color := clBlack;
        PaintBitmap.Canvas.Font.Style := [];
        Form.ResultsTreePaintText(Form.ResultsTree, PaintBitmap.Canvas,
          FileNode, 0, ttNormal);
        if I = 1 then
          Check((PaintBitmap.Canvas.Font.Color = clBlack) and
            not (fsBold in PaintBitmap.Canvas.Font.Style),
            'Reference row is not black with regular font')
        else if PaintBitmap.Canvas.Font.Color = RGB(0, 128, 0) then
          Inc(GreenRows)
        else if PaintBitmap.Canvas.Font.Color = RGB(128, 0, 0) then
          Inc(RedRows)
        else
          Check(False, 'Compared row has an unexpected color');
        FileNode := Form.ResultsTree.GetNextSibling(FileNode);
      end;
    finally
      PaintBitmap.Free;
    end;
    Check(I = 4, 'Expected four unique files');
    Check(GreenRows + RedRows = 3,
      'Compared rows do not use the expected identity colors');
    Check(RedRows > 0, 'No different-content row was painted dark red');
    FileNode := Form.ResultsTree.GetFirstChild(Form.ResultsTree.GetFirst);
    Form.ResultsTree.FocusedNode := FileNode;
    Form.ResultsTree.CheckState[FileNode] := csCheckedNormal;
    Form.ResultsTreeChecked(Form.ResultsTree, FileNode);
    Path := Form.ResultsTree.Text[FileNode, 0];
    Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
    try
      SelectedBytes := Stream.Size;
    finally
      Stream.Free;
    end;
    Check((Form.SelectedFileCount = 1) and
      (Form.SelectedFileBytes = SelectedBytes),
      'Selected-file count and byte total were not updated');
    HeaderHit := Default(TVTHeaderHitInfo);
    HeaderHit.Column := 4;
    Form.ResultsTreeHeaderClick(Form.ResultsTree.Header, HeaderHit);
    Check(Form.ResultsTree.Text[Form.ResultsTree.FocusedNode, 0] = Path,
      'Header sort did not preserve the focused file');
    Check(Form.ResultsTree.CheckState[Form.ResultsTree.FocusedNode] = csCheckedNormal,
      'Header sort did not preserve the file checkbox');
    Form.DeselectAllClick(nil);
    FileNode := Form.ResultsTree.GetFirstChild(Form.ResultsTree.GetFirst);
    PreviousQuality := StrToFloat(Form.ResultsTree.Text[FileNode, 4]);
    while Assigned(Form.ResultsTree.GetNextSibling(FileNode)) do begin
      FileNode := Form.ResultsTree.GetNextSibling(FileNode);
      FileQuality := StrToFloat(Form.ResultsTree.Text[FileNode, 4]);
      Check(PreviousQuality <= FileQuality, 'Ascending quality header sort failed');
      PreviousQuality := FileQuality;
    end;
    Form.ResultsTreeHeaderClick(Form.ResultsTree.Header, HeaderHit);
    FileNode := Form.ResultsTree.GetFirstChild(Form.ResultsTree.GetFirst);
    PreviousQuality := StrToFloat(Form.ResultsTree.Text[FileNode, 4]);
    while Assigned(Form.ResultsTree.GetNextSibling(FileNode)) do begin
      FileNode := Form.ResultsTree.GetNextSibling(FileNode);
      FileQuality := StrToFloat(Form.ResultsTree.Text[FileNode, 4]);
      Check(PreviousQuality >= FileQuality, 'Descending quality header sort failed');
      PreviousQuality := FileQuality;
    end;
    Form.DeselectAllClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = 0, 'Deselect all failed');
    Check((Form.SelectedFileCount = 0) and (Form.SelectedFileBytes = 0) and
      (Pos('Selezionati: 0 file, 0 byte', Form.StatusBar.SimpleText) > 0),
      'Selected-file byte total was not cleared');
    Check(not Form.DeleteSelectedButton.Enabled, 'Recycle button enabled without selections');
    Form.SelectSmallestClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = 1, 'Smallest-file selection failed');
    Check(Form.DeleteSelectedButton.Enabled, 'Recycle button disabled with a selection');
    Form.DeselectAllClick(nil);
    Form.SelectLowerResolutionClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = 1, 'Lower-resolution selection failed');
    Form.DeselectAllClick(nil);
    Form.SelectLowerQualityClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = 3,
      'Lower-quality images were not all selected');
    Form.SelectIdenticalToReferenceClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = GreenRows,
      'Files identical to the reference were not selected');
    Form.SelectOldestClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = 1,
      'Oldest-file selection did not replace previous selections');
    FileNode := Form.ResultsTree.GetFirstChild(Form.ResultsTree.GetFirst);
    while Assigned(FileNode) do begin
      Form.ResultsTree.CheckState[FileNode] := csCheckedNormal;
      Form.ResultsTreeChecked(Form.ResultsTree, FileNode);
      FileNode := Form.ResultsTree.GetNextSibling(FileNode);
    end;
    Form.EnsureUnselectedClick(nil);
    Check(CheckedFileCount(Form.ResultsTree) = 3,
      'Ensure-unselected did not preserve one file');
    Form.DeselectAllClick(nil);
    GroupNode := Form.ResultsTree.GetFirst;
    LastFile := LastChild(Form.ResultsTree, GroupNode);
    Form.ResultsTree.FocusedNode := LastFile;
    Form.ResultsTreeChange(Form.ResultsTree, LastFile);
    Check(Form.PreviewCardCount = 4, 'Dynamic preview count');
    Check(Pos(Form.ResultsTree.Text[Form.ResultsTree.GetFirstChild(GroupNode), 0],
      Form.PreviewCard(0).Caption.Hint) = 1,
      'Preview reference mismatch');
    Check(Pos(Form.ResultsTree.Text[LastFile, 0],
      Form.PreviewCard(3).Caption.Hint) = 1,
      'Selected preview mismatch');
    Check(Pos('Clipping:', Form.PreviewCard(0).Caption.Hint) > 0,
      'Detailed quality metrics missing from preview hint');
    Check(Form.PreviewCard(3).Panel.Selected,
      'Selected preview does not have its blue border');
    for I := 0 to Form.PreviewCardCount - 1 do begin
      Check(Form.PreviewCard(I).Image.Picture.Graphic <> nil, 'Preview image missing');
      Check(Pos(' px | ', Form.PreviewCard(I).Caption.Caption) > 0,
        'Preview attributes missing');
      Check((Form.PreviewCard(I).Panel.Width > 0) and
        (Form.PreviewCard(I).Panel.Height > 0), 'Preview card has invalid size');
    end;
    Check(not Form.FullSizeVisible, 'Full-size preview initially visible');
    Form.ResultsTree.FocusedNode := LastFile;
    HitInfo := Default(THitInfo);
    HitInfo.HitNode := LastFile;
    Form.ResultsTreeNodeDblClick(Form.ResultsTree, HitInfo);
    Application.ProcessMessages;
    Check(Form.FullSizeVisible, 'Tree double-click did not open full-size preview');
    Check(Form.FullSizeUsesNativeDimensions,
      'Tree double-click preview is scaling the source image');
    Form.FullSizeImageMouseDown(nil, mbLeft, [], 0, 0);
    Application.ProcessMessages;
    Check(not Form.FullSizeVisible, 'Click outside image did not close preview');
    Form.PreviewImageClick(Form.PreviewCard(3).Image);
    Application.ProcessMessages;
    Check(Form.FullSizeVisible, 'Full-size preview did not open');
    Check(Form.FullSizeUsesNativeDimensions,
      'Full-size preview is scaling the source image');
    Form.FullSizeImageMouseDown(nil, mbLeft, [], 1, 1);
    Form.FullSizeImageMouseUp(nil, mbLeft, [], 1, 1);
    Application.ProcessMessages;
    Check(not Form.FullSizeVisible, 'Full-size preview did not close');

    Form.ResultsTree.CheckState[LastFile] := csCheckedNormal;
    Form.ResultsTreeChecked(Form.ResultsTree, LastFile);
    Form.DistanceEdit.Value := 7;
    Form.ThreadEdit.Value := 5;
    Form.RecursiveCheck.Checked := False;
    ScannedBeforeSave := Form.ScannedFileCount;
    Form.SaveSessionToFile(SessionPath);
    Check(TFile.Exists(SessionPath), 'Session file was not written');
    Form.PathsMemo.Clear;
    Form.DistanceEdit.Value := 1;
    Form.LoadSessionFromFile(SessionPath);
    Check(Form.PathsMemo.Lines.Count = 3, 'Session paths not restored');
    Check(Form.DistanceEdit.Value = 7, 'Session distance not restored');
    Check(Form.ThreadEdit.Value = 5, 'Session thread count not restored');
    Check(Form.ScannedFileCount = ScannedBeforeSave,
      'Session scanned-file count not restored');
    Check(Pos('Analizzate: ' + IntToStr(ScannedBeforeSave),
      Form.StatusBar.SimpleText) > 0, 'Session scanned count missing from status bar');
    Check((Form.StatusProgress.Max = ScannedBeforeSave) and
      (Form.StatusProgress.Position = ScannedBeforeSave),
      'Session scan meter not restored');
    Check(not Form.RecursiveCheck.Checked, 'Session recursion not restored');
    Check(Form.ResultsTree.TotalCount = 5, 'Session groups not restored');
    GroupNode := Form.ResultsTree.GetFirst;
    LastFile := LastChild(Form.ResultsTree, GroupNode);
    Check(Form.ResultsTree.CheckState[LastFile] = csCheckedNormal, 'Session checkbox not restored');
    Check(Form.ResultsTree.Text[LastFile, 3] <> '', 'Session date/time not restored');
    SessionText := TFile.ReadAllText(SessionPath, TEncoding.UTF8);
    Check(Pos('"qualityScore"', SessionText) > 0, 'Quality score not saved');
    Check(Pos('"exactClass"', SessionText) > 0, 'Exact class not saved');
    Check(Pos('"scannedFiles": ' + IntToStr(ScannedBeforeSave), SessionText) > 0,
      'Scanned-file count not saved');
    Check(Pos('"sharpness"', SessionText) > 0, 'Quality metrics not saved');
    SessionText := StringReplace(SessionText,
      ',' + sLineBreak + '    "threadCount": 5', '', []);
    Check(Pos('threadCount', SessionText) = 0, 'Legacy fixture still has thread count');
    TFile.WriteAllText(LegacySessionPath, SessionText, TEncoding.UTF8);
    Form.ThreadEdit.Value := 9;
    Form.LoadSessionFromFile(LegacySessionPath);
    Check(Form.ThreadEdit.Value = 3, 'Legacy session default thread count');

    Form.Width := Form.Constraints.MinWidth;
    Form.Height := Form.Constraints.MinHeight;
    Form.Realign;
    Check(Form.ToolButtonSelectOptions.Visible and Form.StartButton.Visible and
      Form.StopButton.Visible, 'Command buttons hidden at minimum window size');
    Check(Form.PreviewCardCount = 4, 'Previews lost after resize');
    for I := 0 to Form.PreviewCardCount - 1 do
      Check((Form.PreviewCard(I).Panel.Left >= 0) and
        (Form.PreviewCard(I).Panel.Top >= 0), 'Preview outside gallery after resize');
    Check(Form.ResultsTree.Height >= 70, 'Tree disappeared at minimum size');

    Path := Form.ResultsTree.Text[LastFile, 0];
    MovedPath := Path + '.temporarily-moved';
    FileNode := Form.ResultsTree.GetNextSibling(Form.ResultsTree.GetFirstChild(GroupNode));
    Form.ResultsTreeChange(Form.ResultsTree, FileNode);
    TFile.Move(Path, MovedPath);
    try
      Form.ResultsTreeChange(Form.ResultsTree, LastFile);
      Check(Form.PreviewCard(3).Image.Picture.Graphic = nil,
        'Missing image retained stale preview');
      Check(Pos('non disponibile', Form.PreviewCard(3).Caption.Caption) > 0,
        'Missing image error not displayed');
    finally
      TFile.Move(MovedPath, Path);
    end;

    Form.RecursiveCheck.Checked := True;
    Form.DistanceEdit.Value := 8;
    Form.ThreadEdit.Value := 1;
    Form.StartButtonClick(nil);
    AwaitScan(Form);
    Snapshot1 := TreeSnapshot(Form.ResultsTree);
    Form.ThreadEdit.Value := 3;
    Form.StartButtonClick(nil);
    AwaitScan(Form);
    Snapshot3 := TreeSnapshot(Form.ResultsTree);
    Check(Snapshot1 = Snapshot3, 'Results depend on worker thread count');
    for Pass := 3 to 10 do begin
      Form.StartButtonClick(nil);
      AwaitScan(Form);
      Check(Form.ResultsTree.RootNodeCount = 1, 'Unstable group count during UI stress');
      Check(Form.ResultsTree.TotalCount = 5, 'Unstable members during UI stress');
    end;
    Writeln('PASS: deterministic scans with 1 and 3 workers plus UI stress.');

    TFile.Copy(TPath.Combine(Root, 'different.png'), TPath.Combine(Root, 'different-copy.png'), True);
    Form.PathsMemo.Lines.Text := Root;
    Form.StartButtonClick(nil);
    AwaitScan(Form);
    Check(Form.ResultsTree.RootNodeCount = 2, 'Expected two independent groups');
    Check(Form.ResultsTree.TotalCount = 8, 'Expected two groups with six files');
    HeaderHit.Column := 0;
    Form.ResultsTreeHeaderClick(Form.ResultsTree.Header, HeaderHit);
    GroupNode := Form.ResultsTree.GetFirst;
    FileNode := Form.ResultsTree.GetNextSibling(GroupNode);
    Check(GroupNode.ChildCount <= FileNode.ChildCount,
      'Ascending group-size header sort failed');
    Form.ResultsTreeHeaderClick(Form.ResultsTree.Header, HeaderHit);
    GroupNode := Form.ResultsTree.GetFirst;
    FileNode := Form.ResultsTree.GetNextSibling(GroupNode);
    Check(GroupNode.ChildCount >= FileNode.ChildCount,
      'Descending group-size header sort failed');

    Form.PathsMemo.Lines.Text := EmptyFolder;
    Form.StartButtonClick(nil);
    AwaitScan(Form);
    Check(Form.ResultsTree.TotalCount = 0, 'Old tree nodes retained');
    Check(Form.PreviewCardCount = 0, 'Old previews retained');
    Check(not Form.ErrorsButton.Enabled, 'Old error log retained');
    Form.ActionNewSession.Execute;
    Check(Form.PathsMemo.Lines.Count = 0, 'Session paths not cleared');
    Check(Form.ResultsTree.TotalCount = 0, 'Session results not cleared');
    Check(Form.PreviewCardCount = 0, 'Session previews not cleared');
    Check((Form.DistanceEdit.Value = 8) and
      (Form.ThreadEdit.Value = 3) and Form.RecursiveCheck.Checked and
      (Form.StatusProgress.Position = 0),
      'Session criteria not reset');
    Check(not Form.ToolButtonSelectOptions.Enabled, 'Selection enabled after clearing session');
    if ParamCount >= 2 then begin
      Form.PathsMemo.Lines.Text := TPath.GetFullPath(ParamStr(2));
      Form.DistanceEdit.Value := 1;
      Form.StartButtonClick(nil);
      AwaitScan(Form);
      Check(Form.ResultsTree.RootNodeCount = 0, 'Reported false-positive pair grouped');
      Writeln('PASS: reported real pair excluded by worker at distance 1.');
    end;

    Form.PathsMemo.Lines.Text := Root;
    Form.StartButtonClick(nil);
    Form.StopButtonClick(nil);
    AwaitScan(Form);
    Check(Form.StartButton.Enabled, 'Restart disabled after cancellation');
    Form.StartButtonClick(nil);
    CanClose := True;
    Form.FormCloseQuery(nil, CanClose);
    Check(not CanClose, 'Window closed before worker stopped');
    AwaitScan(Form);
    Writeln('PASS: DFM tree, checkboxes, metadata, previews, JSON session, resize, missing file, cancel, close.');
  finally
    Form.Free;
  end;
end;

begin
  Application.Initialize;
  try
    Test;
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); ExitCode := 1 end;
  end;
end.





