unit ImageDup.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Samples.Spin, Vcl.Menus,
  VirtualTrees, VirtualTrees.Types, ImageDup.Scan, ImageDup.Groups,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL, Vcl.ToolWin, System.Actions,
  Vcl.ActnList, Vcl.BaseImageCollection, Vcl.ImageCollection, System.ImageList, Vcl.ImgList, Vcl.VirtualImageList;

type
  TNodeKind = (nkGroup, nkFile);
  TAutoSelectionCriterion = (ascSmallestFile, ascLowerResolution,
    ascLowerQuality, ascIdenticalToReference, ascOldest);
  PNodeData = ^TNodeData;
  TNodeData = record
    Kind: TNodeKind;
    GroupIndex, MemberIndex: Integer;
  end;

  TPreviewPanel = class(TPanel)
  private
    FSelected: Boolean;
    procedure SetSelected(Value: Boolean);
  protected
    procedure Paint; override;
  public
    property Selected: Boolean read FSelected write SetSelected;
  end;

  TPreviewCard = class
  public
    Panel: TPreviewPanel;
    Caption: TLabel;
    Image: TImage;
    MemberIndex: Integer;
    constructor Create(Owner: TComponent; Parent: TWinControl);
    destructor Destroy; override;
  end;

  TFullSizeView = class(TCustomControl)
  private
    FPicture: TPicture;
    FImageLeft, FImageTop: Integer;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetPosition(ALeft, ATop: Integer);
    property Picture: TPicture read FPicture;
    property ImageLeft: Integer read FImageLeft;
    property ImageTop: Integer read FImageTop;
  end;

  TMainForm = class(TForm)
    SetupPanel: TPanel;
    PathsLabel: TLabel;
    PathsMemo: TMemo;
    BrowseButton: TButton;
    RecursiveCheck: TCheckBox;
    DistanceLabel: TLabel;
    DistanceEdit: TSpinEdit;
    ThreadLabel: TLabel;
    ThreadEdit: TSpinEdit;
    ErrorsButton: TButton;
    DeleteSelectedButton: TButton;
    StartButton: TButton;
    StopButton: TButton;
    ResultsPanel: TPanel;
    ResultsLabel: TLabel;
    ResultsTree: TVirtualStringTree;
    PreviewSplitter: TSplitter;
    PreviewPanel: TPanel;
    PreviewScroll: TScrollBox;
    StatusBar: TStatusBar;
    StatusProgress: TProgressBar;
    PollTimer: TTimer;
    OpenSessionDialog: TFileOpenDialog;
    SaveSessionDialog: TFileSaveDialog;
    SelectionMenu: TPopupMenu;
    SelectSmallestItem: TMenuItem;
    SelectLowerResolutionItem: TMenuItem;
    SelectLowerQualityItem: TMenuItem;
    SelectIdenticalToReferenceItem: TMenuItem;
    SelectOldestItem: TMenuItem;
    EnsureUnselectedItem: TMenuItem;
    DeselectAllItem: TMenuItem;
    ToolBar: TToolBar;
    VirtualImageList: TVirtualImageList;
    ImageCollection: TImageCollection;
    ToolButtonNewSession: TToolButton;
    ActionList: TActionList;
    ActionNewSession: TAction;
    ActionSaveSession: TAction;
    ToolButtonSaveSession: TToolButton;
    ActionLoadSession: TAction;
    ActionBrowse: TAction;
    ActionStartScan: TAction;
    ActionStopScan: TAction;
    ActionShowErrors: TAction;
    ActionDeleteSelected: TAction;
    ActionSelectionOptions: TAction;
    ActionSelectSmallest: TAction;
    ActionSelectLowerResolution: TAction;
    ActionSelectLowerQuality: TAction;
    ActionSelectIdenticalToReference: TAction;
    ActionSelectOldest: TAction;
    ActionEnsureUnselected: TAction;
    ActionDeselectAll: TAction;
    ToolButtonLoadSession: TToolButton;
    ToolButtonSeparator1: TToolButton;
    ToolButtonSeparator2: TToolButton;
    ToolButtonSelectOptions: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure BrowseButtonClick(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure PollTimerTimer(Sender: TObject);
    procedure PreviewPanelResize(Sender: TObject);
    procedure ErrorsButtonClick(Sender: TObject);
    procedure ResultsTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ResultsTreePaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure ResultsTreeHeaderClick(Sender: TVTHeader;
      const HitInfo: TVTHeaderHitInfo);
    procedure ResultsTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ResultsTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ResultsTreeNodeDblClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
    procedure PreviewImageClick(Sender: TObject);
    procedure FullSizeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FullSizeFormDestroy(Sender: TObject);
    procedure FullSizeFormDeactivate(Sender: TObject);
    procedure FullSizeImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FullSizeImageMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure FullSizeImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SelectionButtonClick(Sender: TObject);
    procedure DeleteSelectedButtonClick(Sender: TObject);
    procedure SelectSmallestClick(Sender: TObject);
    procedure SelectLowerResolutionClick(Sender: TObject);
    procedure SelectLowerQualityClick(Sender: TObject);
    procedure SelectIdenticalToReferenceClick(Sender: TObject);
    procedure SelectOldestClick(Sender: TObject);
    procedure EnsureUnselectedClick(Sender: TObject);
    procedure DeselectAllClick(Sender: TObject);
    procedure ActionNewSessionExecute(Sender: TObject);
    procedure ActionSaveSessionExecute(Sender: TObject);
    procedure ActionLoadSessionExecute(Sender: TObject);
  private
    FWorker: TImageScan;
    FGroups: TList<TImageGroup>;
    FChecked: TDictionary<string, Boolean>;
    FErrors: TStringList;
    FPreviewCards: TObjectList<TPreviewCard>;
    FFullSizeForm: TForm;
    FFullSizeView: TFullSizeView;
    FPanStart, FPanImageStart: TPoint;
    FPanning, FPanMoved: Boolean;
    FClosePending, FUpdatingTree: Boolean;
    FSelectedGroup, FSelectedMember: Integer;
    FPreviewMemberCount: Integer;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    FDeleting: Boolean;
    FScannedFileCount: Integer;
    FStatusMessage: string;
    procedure SetRunning(Value: Boolean);
    procedure BuildTree(CaptureCurrent: Boolean = True;
      const FocusFileOverride: string = '');
    procedure CaptureChecks;
    function FocusedFileName: string;
    procedure ShowNode(Node: PVirtualNode);
    procedure ClearPreviews;
    procedure BuildPreviews(GroupIndex: Integer);
    procedure LayoutPreviews;
    procedure UpdatePreviewSelection;
    procedure LoadPreview(Card: TPreviewCard; const Member: TGroupMember);
    procedure CloseFullSize(Deferred: Boolean);
    procedure SetFullSizeImagePosition(ALeft, ATop: Integer);
    function FullSizeImageContains(X, Y: Integer): Boolean;
    procedure ApplyAutoSelection(Criterion: TAutoSelectionCriterion);
    procedure SortGroupsBySize(Ascending: Boolean);
    procedure SortMembers(Column: Integer; Ascending: Boolean);
    function HasCheckedFiles: Boolean;
    function CheckedFileBytes: Int64;
    function CheckedFileCount: Integer;
    procedure UpdateCheckedSizeStatus;
    procedure SetStatusMessage(const Value: string);
    procedure RemoveRecycledFiles(const FileNames: TArray<string>);
  public
    property Worker: TImageScan read FWorker;
    property ScannedFileCount: Integer read FScannedFileCount;
    property SelectedFileBytes: Int64 read CheckedFileBytes;
    property SelectedFileCount: Integer read CheckedFileCount;
    function PreviewCardCount: Integer;
    function PreviewCard(Index: Integer): TPreviewCard;
    function FullSizeVisible: Boolean;
    function FullSizeUsesNativeDimensions: Boolean;
    procedure SaveSessionToFile(const FileName: string);
    procedure LoadSessionFromFile(const FileName: string);
  end;

var MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils, System.Math, ImageDup.Session, ImageDup.Core, ImageDup.Recycle,
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage;

procedure TPreviewPanel.SetSelected(Value: Boolean);
begin
  if FSelected = Value then Exit;
  FSelected := Value;
  if Value then Color := $00FFE8D8 else Color := clWindow;
  Invalidate;
end;

procedure TPreviewPanel.Paint;
var I: Integer; R: TRect;
begin
  inherited;
  if not FSelected then Exit;
  R := ClientRect;
  for I := 0 to 4 do begin
    Canvas.Pen.Color := RGB(35 + I * 22, 95 + I * 20, 175 + I * 15);
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(R);
    InflateRect(R, -1, -1);
  end;
end;

constructor TPreviewCard.Create(Owner: TComponent; Parent: TWinControl);
begin
  inherited Create;
  Panel := TPreviewPanel.Create(Owner);
  Panel.Parent := Parent;
  Panel.BevelOuter := bvNone;
  Panel.ParentBackground := False;
  Panel.Color := clWindow;
  Panel.Padding.Left := 6;
  Panel.Padding.Top := 6;
  Panel.Padding.Right := 6;
  Panel.Padding.Bottom := 6;

  Caption := TLabel.Create(Owner);
  Caption.Parent := Panel;
  Caption.Align := alBottom;
  Caption.AutoSize := False;
  Caption.EllipsisPosition := epPathEllipsis;
  Caption.Layout := tlCenter;
  Caption.ParentShowHint := False;
  Caption.ShowHint := True;
  Caption.WordWrap := True;

  Image := TImage.Create(Owner);
  Image.Parent := Panel;
  Image.Align := alClient;
  Image.Center := True;
  Image.Proportional := True;
  Image.Stretch := True;
  Image.ParentShowHint := False;
  Image.ShowHint := True;
end;

constructor TFullSizeView.Create(AOwner: TComponent);
begin
  inherited;
  FPicture := TPicture.Create;
  Color := clBlack;
  ParentBackground := False;
  DoubleBuffered := True;
end;

destructor TFullSizeView.Destroy;
begin
  FPicture.Free;
  inherited;
end;

procedure TFullSizeView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  // Paint writes the complete back buffer; erasing first causes visible flashes.
  Message.Result := 1;
end;

procedure TFullSizeView.Paint;
begin
  Canvas.Brush.Color := clBlack;
  Canvas.FillRect(ClientRect);
  if Assigned(FPicture.Graphic) and not FPicture.Graphic.Empty then
    Canvas.Draw(FImageLeft, FImageTop, FPicture.Graphic);
end;

procedure TFullSizeView.SetPosition(ALeft, ATop: Integer);
begin
  if (FImageLeft = ALeft) and (FImageTop = ATop) then Exit;
  FImageLeft := ALeft;
  FImageTop := ATop;
  Invalidate;
end;

destructor TPreviewCard.Destroy;
begin
  Panel.Free;
  inherited;
end;

function Dimensions(const Info: TImageInfo): string;
begin
  Result := Format('%d x %d', [Info.Width, Info.Height]);
end;

function FileSizeText(Bytes: Int64): string;
begin
  if Bytes < 1024 then Result := IntToStr(Bytes) + ' B'
  else if Bytes < 1024 * 1024 then Result := FormatFloat('0.0', Bytes / 1024) + ' KiB'
  else Result := FormatFloat('0.00', Bytes / (1024 * 1024)) + ' MiB';
end;

function DpiText(const Info: TImageInfo): string;
begin
  if (Info.DpiX <= 0) and (Info.DpiY <= 0) then
    Result := 'DPI sconosciuti'
  else if (Info.DpiX > 0) and (Info.DpiY > 0) and
    SameValue(Info.DpiX, Info.DpiY, 0.05) then
    Result := Format('%.0f DPI', [Info.DpiX])
  else
    Result := Format('%.0f x %.0f DPI', [Info.DpiX, Info.DpiY]);
end;

function QualityDetailsText(const Member: TGroupMember): string;
const YesNo: array[Boolean] of string = ('no', 'si');
begin
  Result := Format(
    'Qualita: %.1f/100%sNitidezza: %.3f | rumore: %.3f | artefatti: %.3f%s' +
    'Clipping: %.3f | banding: %.3f | rischio upscaling: %.3f%s' +
    'Profondita: %d bit/canale | profilo ICC: %s | chroma: %s',
    [Member.QualityScore, sLineBreak,
     Member.Info.Quality.Sharpness, Member.Info.Quality.Noise,
     Member.Info.Quality.BlockArtifacts, sLineBreak,
     Member.Info.Quality.Clipping, Member.Info.Quality.Banding,
     Member.Info.Quality.UpscaleRisk, sLineBreak,
     Member.Info.Quality.BitDepth, YesNo[Member.Info.Quality.HasColorProfile],
     ChromaSubsamplingText(Member.Info.Quality.ChromaSubsampling)]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FGroups := TList<TImageGroup>.Create;
  FChecked := TDictionary<string, Boolean>.Create;
  FErrors := TStringList.Create;
  FPreviewCards := TObjectList<TPreviewCard>.Create(True);
  FSelectedGroup := -1;
  FSelectedMember := -1;
  FPreviewMemberCount := 0;
  FSortColumn := -1;
  FSortAscending := True;
  ResultsTree.NodeDataSize := SizeOf(TNodeData);
  PreviewPanelResize(nil);
  SetRunning(False);
  FStatusMessage := StatusBar.SimpleText;
  UpdateCheckedSizeStatus;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  MakeFullyVisible(Monitor);
end;

function TMainForm.CheckedFileBytes: Int64;
var
  G, M: Integer;
  IsChecked: Boolean;
begin
  Result := 0;
  if not Assigned(FGroups) or not Assigned(FChecked) then Exit;
  for G := 0 to FGroups.Count - 1 do
    for M := 0 to High(FGroups[G].Members) do
    begin
      IsChecked := False;
      if FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName,
        IsChecked) and IsChecked then
        Inc(Result, FGroups[G].Members[M].Info.Bytes);
    end;
end;

function TMainForm.CheckedFileCount: Integer;
var
  G, M: Integer;
  IsChecked: Boolean;
begin
  Result := 0;
  if not Assigned(FGroups) or not Assigned(FChecked) then Exit;
  for G := 0 to FGroups.Count - 1 do
    for M := 0 to High(FGroups[G].Members) do
    begin
      IsChecked := False;
      if FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName,
        IsChecked) and IsChecked then
        Inc(Result);
    end;
end;
procedure TMainForm.UpdateCheckedSizeStatus;
var
  Bytes: Int64;
  SizeText: string;
begin
  Bytes := CheckedFileBytes;
  if Bytes >= Int64(1024) * 1024 * 1024 then
    SizeText := FormatFloat('0.00 GB', Bytes / (Int64(1024) * 1024 * 1024))
  else if Bytes >= Int64(1024) * 1024 then
    SizeText := FormatFloat('0.00 MB', Bytes / (Int64(1024) * 1024))
  else if Bytes >= 1024 then
    SizeText := FormatFloat('0.00 KB', Bytes / 1024)
  else
    SizeText := Format('%d byte', [Bytes]);
  StatusBar.SimpleText := Format('%s | Selezionati: %d file, %s',
    [FStatusMessage, CheckedFileCount, SizeText]);
end;

procedure TMainForm.SetStatusMessage(const Value: string);
begin
  FStatusMessage := Value;
  UpdateCheckedSizeStatus;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  PollTimer.Enabled := False;
  if Assigned(FWorker) then begin FWorker.Terminate; FWorker.Free end;
  CloseFullSize(False);
  FPreviewCards.Free;
  FErrors.Free;
  FChecked.Free;
  FGroups.Free;
end;

procedure TMainForm.FormResize(Sender: TObject);
var Available: Integer;
begin
  if not Assigned(PreviewPanel) or not Assigned(SetupPanel) or
    not Assigned(StatusBar) or not Assigned(PreviewSplitter) then Exit;
  Available := ClientHeight - SetupPanel.Height - StatusBar.Height -
    PreviewSplitter.Height - MulDiv(150, CurrentPPI, 96);
  PreviewPanel.Height := Min(PreviewPanel.Height,
    Max(PreviewPanel.Constraints.MinHeight, Available));
end;

procedure TMainForm.SetRunning(Value: Boolean);
begin
  PathsMemo.Enabled := not Value;
  ActionBrowse.Enabled := not Value;
  RecursiveCheck.Enabled := not Value;
  DistanceEdit.Enabled := not Value;
  ThreadEdit.Enabled := not Value;
  ActionStartScan.Enabled := not Value;
  ActionLoadSession.Enabled := not Value;
  ActionSaveSession.Enabled := not Value;
  ActionNewSession.Enabled := not Value;
  ActionSelectionOptions.Enabled := (not Value) and Assigned(FGroups) and
    (FGroups.Count > 0);
  ActionDeleteSelected.Enabled := (not Value) and (not FDeleting) and HasCheckedFiles;
  ActionStopScan.Enabled := Value;
end;

function TMainForm.HasCheckedFiles: Boolean;
var Pair: TPair<string, Boolean>;
begin
  Result := False;
  if not Assigned(FChecked) then Exit;
  for Pair in FChecked do
    if Pair.Value then Exit(True);
end;

procedure TMainForm.BrowseButtonClick(Sender: TObject);
var Dialog: TFileOpenDialog; Path: string;
begin
  Dialog := TFileOpenDialog.Create(Self);
  try
    Dialog.Title := 'Aggiungi una cartella alla ricerca';
    Dialog.Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
    if Dialog.Execute(Handle) then begin
      Path := Dialog.FileName;
      if PathsMemo.Lines.IndexOf(Path) < 0 then PathsMemo.Lines.Add(Path);
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
var Roots: TList<string>; Path, Root: string; HashLimit: Integer;
begin
  if Assigned(FWorker) then Exit;
  Roots := TList<string>.Create;
  try
    try
      if not TryStrToInt(DistanceEdit.Text, HashLimit) or
        (HashLimit < 0) or (HashLimit > 63) then
        raise EArgumentException.Create('La distanza deve essere tra 0 e 63.');
      for Path in PathsMemo.Lines do if Trim(Path) <> '' then begin
        Root := TPath.GetFullPath(Trim(Path));
        if not DirectoryExists(Root) then
          raise EArgumentException.Create('Cartella inesistente: ' + Root);
        Roots.Add(Root);
      end;
      if Roots.Count = 0 then raise EArgumentException.Create('Aggiungi almeno una cartella.');
      FWorker := TImageScan.Create(Roots.ToArray, RecursiveCheck.Checked,
        HashLimit, DefaultMaxRGBError, ThreadEdit.Value);
    except
      on E: Exception do begin MessageDlg(E.Message, mtError, [mbOK], 0); Exit end;
    end;
    FGroups.Clear;
    FScannedFileCount := 0;
    FChecked.Clear;
    FErrors.Clear;
    ResultsTree.Clear;
    ActionShowErrors.Enabled := False;
    FSelectedGroup := -1;
    FSelectedMember := -1;
    ClearPreviews;
    ResultsLabel.Caption := 'Ricerca in corso - i gruppi appariranno qui';
    SetStatusMessage(Format('Avvio scansione con %d thread...',
      [ThreadEdit.Value]));
    StatusProgress.Style := pbstMarquee;
    StatusProgress.Position := 0;
    SetRunning(True);
    FWorker.Start;
    PollTimer.Enabled := True;
  finally
    Roots.Free;
  end;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  if Assigned(FWorker) then begin
    FWorker.Terminate;
    ActionStopScan.Enabled := False;
    SetStatusMessage('Arresto in corso, attendo la fine dell''immagine corrente...');
  end;
end;


procedure TMainForm.CaptureChecks;
var Node: PVirtualNode; Data: PNodeData;
begin
  if FUpdatingTree then Exit;
  Node := ResultsTree.GetFirst;
  while Assigned(Node) do begin
    Data := ResultsTree.GetNodeData(Node);
    if Assigned(Data) and (Data.Kind = nkFile) and
      (Data.GroupIndex < FGroups.Count) and
      (Data.MemberIndex < Length(FGroups[Data.GroupIndex].Members)) then
      FChecked.AddOrSetValue(FGroups[Data.GroupIndex].Members[Data.MemberIndex].Info.FileName,
        ResultsTree.CheckState[Node] = csCheckedNormal);
    Node := ResultsTree.GetNext(Node);
  end;
end;

function TMainForm.FocusedFileName: string;
var Data: PNodeData;
begin
  Result := '';
  if not Assigned(ResultsTree.FocusedNode) then Exit;
  Data := ResultsTree.GetNodeData(ResultsTree.FocusedNode);
  if Assigned(Data) and (Data.Kind = nkFile) and
    (Data.GroupIndex >= 0) and (Data.GroupIndex < FGroups.Count) and
    (Data.MemberIndex >= 0) and
    (Data.MemberIndex < Length(FGroups[Data.GroupIndex].Members)) then
    Result := FGroups[Data.GroupIndex].Members[Data.MemberIndex].Info.FileName;
end;

procedure TMainForm.BuildTree(CaptureCurrent: Boolean;
  const FocusFileOverride: string);
var
  G, M: Integer;
  GroupNode, FileNode, FocusNode: PVirtualNode;
  Data: PNodeData;
  FocusFile: string;
  IsChecked: Boolean;
begin
  FocusFile := FocusFileOverride;
  if FocusFile = '' then FocusFile := FocusedFileName;
  if CaptureCurrent then CaptureChecks;
  FUpdatingTree := True;
  ResultsTree.BeginUpdate;
  try
    ResultsTree.Clear;
    FocusNode := nil;
    for G := 0 to FGroups.Count - 1 do begin
      GroupNode := ResultsTree.AddChild(nil);
      Data := ResultsTree.GetNodeData(GroupNode);
      Data.Kind := nkGroup; Data.GroupIndex := G; Data.MemberIndex := -1;
      ResultsTree.CheckType[GroupNode] := ctNone;
      for M := 0 to High(FGroups[G].Members) do begin
        FileNode := ResultsTree.AddChild(GroupNode);
        Data := ResultsTree.GetNodeData(FileNode);
        Data.Kind := nkFile; Data.GroupIndex := G; Data.MemberIndex := M;
        ResultsTree.CheckType[FileNode] := ctCheckBox;
        IsChecked := False;
        FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName, IsChecked);
        if IsChecked then ResultsTree.CheckState[FileNode] := csCheckedNormal
        else ResultsTree.CheckState[FileNode] := csUncheckedNormal;
        if (FocusFile <> '') and SameText(FocusFile, FGroups[G].Members[M].Info.FileName) then
          FocusNode := FileNode;
        if FocusNode = nil then FocusNode := FileNode;
      end;
      ResultsTree.Expanded[GroupNode] := True;
    end;
    if Assigned(FocusNode) then begin
      ResultsTree.FocusedNode := FocusNode;
      ResultsTree.Selected[FocusNode] := True;
    end;
  finally
    ResultsTree.EndUpdate;
    FUpdatingTree := False;
  end;
  if Assigned(FocusNode) then ShowNode(FocusNode) else ClearPreviews;
  ActionDeleteSelected.Enabled := not Assigned(FWorker) and
    not FDeleting and HasCheckedFiles;
  UpdateCheckedSizeStatus;
end;

procedure TMainForm.PollTimerTimer(Sender: TObject);
var
  Update: TScanUpdate;
  Group: TImageGroup;
  I, Found: Integer;
  Phase, FocusFile: string;
begin
  if not Assigned(FWorker) then Exit;
  Update := FWorker.Drain;
  FScannedFileCount := Update.Scanned;
  if Update.TotalImages > 0 then begin
    StatusProgress.Style := pbstNormal;
    StatusProgress.Max := Update.TotalImages;
    StatusProgress.Position := Min(Update.Scanned, Update.TotalImages);
    StatusProgress.Hint := Format('%d / %d immagini',
      [Update.Scanned, Update.TotalImages]);
  end;
  FErrors.AddStrings(Update.Errors);
  ActionShowErrors.Enabled := FErrors.Count > 0;
  if Length(Update.Groups) > 0 then begin
    FocusFile := FocusedFileName;
    CaptureChecks;
    for Group in Update.Groups do begin
      Found := -1;
      for I := 0 to FGroups.Count - 1 do
        if FGroups[I].Id = Group.Id then begin Found := I; Break end;
      if Found < 0 then FGroups.Add(Group) else FGroups[Found] := Group;
    end;
    if FSortColumn = 0 then SortGroupsBySize(FSortAscending)
    else if FSortColumn > 0 then SortMembers(FSortColumn, FSortAscending);
    BuildTree(False, FocusFile);
  end;
  if Update.Done then begin
    PollTimer.Enabled := False;
    FreeAndNil(FWorker);
    SetRunning(False);
    StatusProgress.Style := pbstNormal;
    if (Update.FatalError = '') and not Update.Cancelled then begin
      if Update.TotalImages > 0 then begin
        StatusProgress.Max := Update.TotalImages;
        StatusProgress.Position := Update.TotalImages;
      end else begin
        StatusProgress.Max := 100;
        StatusProgress.Position := 100;
      end;
    end;
    if Update.FatalError <> '' then Phase := 'Scansione fallita'
    else if Update.Cancelled then Phase := 'Scansione interrotta'
    else if Update.ErrorCount > 0 then Phase := 'Completata con errori'
    else Phase := 'Scansione completata';
    if FGroups.Count = 0 then ResultsLabel.Caption := Phase + ' - nessun gruppo trovato'
    else ResultsLabel.Caption := Format('%s - %d gruppi, %d file raggruppati.',
      [Phase, FGroups.Count, Update.GroupedFiles]);
    SetStatusMessage(Format('%s | Analizzate: %d | Gruppi: %d | File: %d | Errori: %d',
      [Phase, Update.Scanned, FGroups.Count, Update.GroupedFiles, Update.ErrorCount]));
    if FClosePending then Close;
  end else if ActionStopScan.Enabled then
    SetStatusMessage(Format('Thread: %d | Immagini: %d | Gruppi: %d | Errori: %d | %s',
      [FWorker.ThreadCount, Update.Scanned, FGroups.Count, Update.ErrorCount,
       Update.CurrentFile]));
end;

procedure TMainForm.ResultsTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var Data: PNodeData; G: TImageGroup; M: TGroupMember;
begin
  CellText := '';
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) or (Data.GroupIndex < 0) or (Data.GroupIndex >= FGroups.Count) then Exit;
  G := FGroups[Data.GroupIndex];
  if Data.Kind = nkGroup then begin
    if Column = 0 then CellText := Format('Gruppo %d  (%d immagini)',
      [Data.GroupIndex + 1, Length(G.Members)]);
    Exit;
  end;
  if (Data.MemberIndex < 0) or (Data.MemberIndex >= Length(G.Members)) then Exit;
  M := G.Members[Data.MemberIndex];
  case Column of
    0: CellText := M.Info.FileName;
    1: CellText := Dimensions(M.Info);
    2: CellText := IntToStr(M.Info.Bytes);
    3: CellText := FormatDateTime('yyyy-mm-dd hh:nn:ss', M.Info.Modified);
    4: CellText := FormatFloat('0.0', M.QualityScore);
  end;
end;

procedure TMainForm.ResultsTreePaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var Data: PNodeData; Member: TGroupMember;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) or (Data.Kind <> nkFile) or
    (Data.GroupIndex < 0) or (Data.GroupIndex >= FGroups.Count) or
    (Data.MemberIndex < 0) or
    (Data.MemberIndex >= Length(FGroups[Data.GroupIndex].Members)) then Exit;
  Member := FGroups[Data.GroupIndex].Members[Data.MemberIndex];
  if Member.IsReference then begin
    TargetCanvas.Font.Color := clBlack;
    TargetCanvas.Font.Style := [];
    Exit;
  end;
  TargetCanvas.Font.Style := [];
  if Member.ExactClass =
    FGroups[Data.GroupIndex].Members[0].ExactClass then
    TargetCanvas.Font.Color := RGB(0, 128, 0)
  else
    TargetCanvas.Font.Color := RGB(128, 0, 0);
end;

procedure TMainForm.SortGroupsBySize(Ascending: Boolean);
var I, J: Integer; Item: TImageGroup; Move: Boolean;
begin
  for I := 1 to FGroups.Count - 1 do begin
    Item := FGroups[I];
    J := I - 1;
    repeat
      if J < 0 then Break;
      if Ascending then
        Move := Length(FGroups[J].Members) > Length(Item.Members)
      else
        Move := Length(FGroups[J].Members) < Length(Item.Members);
      if not Move then Break;
      FGroups[J + 1] := FGroups[J];
      Dec(J);
    until False;
    FGroups[J + 1] := Item;
  end;
end;

procedure TMainForm.SortMembers(Column: Integer; Ascending: Boolean);
var
  G, I, J, Comparison: Integer;
  Item: TGroupMember;
  Group: TImageGroup;
  LeftPixels, RightPixels: Int64;
begin
  for G := 0 to FGroups.Count - 1 do begin
    Group := FGroups[G];
    for I := 1 to High(Group.Members) do begin
      Item := Group.Members[I];
      J := I - 1;
      while J >= 0 do begin
        Comparison := 0;
        case Column of
          1: begin
            LeftPixels := Int64(Group.Members[J].Info.Width) *
              Group.Members[J].Info.Height;
            RightPixels := Int64(Item.Info.Width) * Item.Info.Height;
            if LeftPixels < RightPixels then Comparison := -1
            else if LeftPixels > RightPixels then Comparison := 1;
          end;
          2:
            if Group.Members[J].Info.Bytes < Item.Info.Bytes then Comparison := -1
            else if Group.Members[J].Info.Bytes > Item.Info.Bytes then Comparison := 1;
          3:
            if Group.Members[J].Info.Modified < Item.Info.Modified then Comparison := -1
            else if Group.Members[J].Info.Modified > Item.Info.Modified then Comparison := 1;
          4:
            if Group.Members[J].QualityScore < Item.QualityScore then Comparison := -1
            else if Group.Members[J].QualityScore > Item.QualityScore then Comparison := 1;
        end;
        if (Ascending and (Comparison <= 0)) or
          ((not Ascending) and (Comparison >= 0)) then Break;
        Group.Members[J + 1] := Group.Members[J];
        Dec(J);
      end;
      Group.Members[J + 1] := Item;
    end;
    FGroups[G] := Group;
  end;
end;

procedure TMainForm.ResultsTreeHeaderClick(Sender: TVTHeader;
  const HitInfo: TVTHeaderHitInfo);
var FocusFile: string;
begin
  if (HitInfo.Column < 0) or (HitInfo.Column >= ResultsTree.Header.Columns.Count) then Exit;
  FocusFile := FocusedFileName;
  CaptureChecks;
  if FSortColumn = HitInfo.Column then
    FSortAscending := not FSortAscending
  else begin
    FSortColumn := HitInfo.Column;
    FSortAscending := True;
  end;
  ResultsTree.Header.SortColumn := FSortColumn;
  if FSortAscending then ResultsTree.Header.SortDirection := sdAscending
  else ResultsTree.Header.SortDirection := sdDescending;
  if FSortColumn = 0 then SortGroupsBySize(FSortAscending)
  else SortMembers(FSortColumn, FSortAscending);
  BuildTree(False, FocusFile);
end;

procedure TMainForm.SelectionButtonClick(Sender: TObject);
var P: TPoint;
begin
  P := ToolButtonSelectOptions.ClientToScreen(Point(0, ToolButtonSelectOptions.Height));
  SelectionMenu.Popup(P.X, P.Y);
end;

procedure TMainForm.RemoveRecycledFiles(const FileNames: TArray<string>);
var
  Removed: TDictionary<string, Boolean>;
  Members: TList<TGroupMember>;
  Group: TImageGroup;
  Member: TGroupMember;
  Signatures: TArray<TImageSignature>;
  Available: TArray<Boolean>;
  Metrics: TComparison;
  G, I, J: Integer;
  FileName, FocusFile: string;
  Changed: Boolean;
begin
  FocusFile := FocusedFileName;
  Removed := TDictionary<string, Boolean>.Create;
  Members := TList<TGroupMember>.Create;
  try
    for FileName in FileNames do begin
      Removed.AddOrSetValue(FileName, True);
      FChecked.Remove(FileName);
    end;
    for G := FGroups.Count - 1 downto 0 do begin
      Group := FGroups[G];
      Members.Clear;
      Changed := False;
      for Member in Group.Members do
        if Removed.ContainsKey(Member.Info.FileName) then Changed := True
        else Members.Add(Member);
      if not Changed then Continue;
      if Members.Count = 0 then begin
        FGroups.Delete(G);
        Continue;
      end;
      Group.Members := Members.ToArray;
      CalculateGroupQuality(Group);
      SetLength(Signatures, Length(Group.Members));
      SetLength(Available, Length(Group.Members));
      for I := 0 to High(Group.Members) do begin
        Group.Members[I].HasIdenticalPeer := False;
        Available[I] := False;
        try
          Signatures[I] := LoadSignature(Group.Members[I].Info.FileName);
          Available[I] := True;
        except
          on E: Exception do
            FErrors.Add(Group.Members[I].Info.FileName + ': ' + E.Message);
        end;
      end;
      for I := 0 to High(Group.Members) do begin
        Group.Members[I].Metrics := Default(TComparison);
        if Available[0] and Available[I] then
          StructuralMetrics(Signatures[0], Signatures[I], Group.Members[I].Metrics);
        if not Available[I] then Continue;
        for J := 0 to I - 1 do
          if Available[J] then begin
            StructuralMetrics(Signatures[J], Signatures[I], Metrics);
            if (Metrics.Distance = 0) and (Metrics.RGBError <= 1E-12) then begin
              Group.Members[J].HasIdenticalPeer := True;
              Group.Members[I].HasIdenticalPeer := True;
            end;
          end;
      end;
      FGroups[G] := Group;
    end;
    if FSortColumn = 0 then SortGroupsBySize(FSortAscending)
    else if FSortColumn > 0 then SortMembers(FSortColumn, FSortAscending);
    ClearPreviews;
    BuildTree(False, FocusFile);
  finally
    Members.Free;
    Removed.Free;
  end;
end;

procedure TMainForm.DeleteSelectedButtonClick(Sender: TObject);
var
  Selected, Recycled: TList<string>;
  Group: TImageGroup;
  Member: TGroupMember;
  IsChecked: Boolean;
  FileName, ErrorText: string;
  Failures: Integer;
begin
  if Assigned(FWorker) or FDeleting then Exit;
  CaptureChecks;
  Selected := TList<string>.Create;
  Recycled := TList<string>.Create;
  try
    for Group in FGroups do
      for Member in Group.Members do
        if FChecked.TryGetValue(Member.Info.FileName, IsChecked) and IsChecked then
          Selected.Add(Member.Info.FileName);
    if Selected.Count = 0 then Exit;
    if MessageDlg(Format('Spostare i %d file selezionati nel Cestino di Windows?',
      [Selected.Count]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    FDeleting := True;
    SetRunning(True);
    ActionStopScan.Enabled := False;
    ResultsTree.Enabled := False;
    CloseFullSize(False);
    Failures := 0;
    try
      for FileName in Selected do begin
        SetStatusMessage('Spostamento nel Cestino: ' + FileName);
        if RecycleFile(Handle, FileName, ErrorText) then Recycled.Add(FileName)
        else begin
          Inc(Failures);
          FErrors.Add(FileName + ': ' + ErrorText);
        end;
      end;
      RemoveRecycledFiles(Recycled.ToArray);
      ActionShowErrors.Enabled := FErrors.Count > 0;
      ResultsLabel.Caption := Format('Risultati aggiornati - %d gruppi, %d file.',
        [FGroups.Count, ResultsTree.TotalCount - FGroups.Count]);
      SetStatusMessage(Format('Nel Cestino: %d | Non spostati: %d',
        [Recycled.Count, Failures]));
      if Failures > 0 then
        MessageDlg(Format('%d file non sono stati spostati e restano selezionati.' +
          sLineBreak + 'Consulta Dettagli errori per i motivi.', [Failures]),
          mtWarning, [mbOK], 0);
    finally
      FDeleting := False;
      ResultsTree.Enabled := True;
      SetRunning(False);
    end;
  finally
    Recycled.Free;
    Selected.Free;
  end;
end;


procedure TMainForm.ActionLoadSessionExecute(Sender: TObject);
begin
  if not OpenSessionDialog.Execute(Handle) then Exit;
  try
    LoadSessionFromFile(OpenSessionDialog.FileName);
    SetStatusMessage(Format('Sessione caricata: %s | Analizzate: %d',
      [OpenSessionDialog.FileName, FScannedFileCount]));
  except
    on E: Exception do MessageDlg('Impossibile caricare la sessione:' + sLineBreak + E.Message,
      mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.ActionNewSessionExecute(Sender: TObject);
begin
  if Assigned(FWorker) then Exit;
  CloseFullSize(False);
  PathsMemo.Clear;
  RecursiveCheck.Checked := True;
  DistanceEdit.Value := 8;
  ThreadEdit.Value := 3;
  FGroups.Clear;
  FScannedFileCount := 0;
  FChecked.Clear;
  FErrors.Clear;
  ActionShowErrors.Enabled := False;
  ActionSelectionOptions.Enabled := False;
  ActionDeleteSelected.Enabled := False;
  ResultsTree.Clear;
  ClearPreviews;
  ResultsLabel.Caption :=
    'Gruppi di immagini simili - aggiungi le cartelle e avvia la ricerca';
  SetStatusMessage('Sessione pulita.');
  StatusProgress.Style := pbstNormal;
  StatusProgress.Max := 100;
  StatusProgress.Position := 0;
end;

procedure TMainForm.ActionSaveSessionExecute(Sender: TObject);
begin
  try
    if SaveSessionDialog.Execute(Handle) then begin
      SaveSessionToFile(SaveSessionDialog.FileName);
      SetStatusMessage('Sessione salvata: ' + SaveSessionDialog.FileName);
    end;
  except
    on E: Exception do MessageDlg('Impossibile salvare la sessione:' + sLineBreak + E.Message,
      mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.ApplyAutoSelection(Criterion: TAutoSelectionCriterion);
var
  G, M, Best, ReferenceClass: Integer;
  Candidate, BestValue: Double;
begin
  CaptureChecks;
  FChecked.Clear;
  for G := 0 to FGroups.Count - 1 do begin
    if Length(FGroups[G].Members) = 0 then Continue;
    if Criterion = ascLowerQuality then begin
      for M := 0 to High(FGroups[G].Members) do
        if not FGroups[G].Members[M].IsReference then
          FChecked.AddOrSetValue(FGroups[G].Members[M].Info.FileName, True);
      Continue;
    end;
    if Criterion = ascIdenticalToReference then begin
      ReferenceClass := FGroups[G].Members[0].ExactClass;
      for M := 0 to High(FGroups[G].Members) do
        if (not FGroups[G].Members[M].IsReference) and
          (FGroups[G].Members[M].ExactClass = ReferenceClass) then
          FChecked.AddOrSetValue(FGroups[G].Members[M].Info.FileName, True);
      Continue;
    end;
    Best := 0;
    case Criterion of
      ascSmallestFile: BestValue := FGroups[G].Members[0].Info.Bytes;
      ascLowerResolution: BestValue := Int64(FGroups[G].Members[0].Info.Width) *
        FGroups[G].Members[0].Info.Height;
    else
      BestValue := FGroups[G].Members[0].Info.Modified;
    end;
    for M := 1 to High(FGroups[G].Members) do begin
      case Criterion of
        ascSmallestFile: Candidate := FGroups[G].Members[M].Info.Bytes;
        ascLowerResolution: Candidate := Int64(FGroups[G].Members[M].Info.Width) *
          FGroups[G].Members[M].Info.Height;
      else
        Candidate := FGroups[G].Members[M].Info.Modified;
      end;
      if Candidate < BestValue then begin
        Best := M;
        BestValue := Candidate;
      end;
    end;
    FChecked.AddOrSetValue(FGroups[G].Members[Best].Info.FileName, True);
  end;
  BuildTree(False);
  SetStatusMessage('Selezione automatica applicata a tutti i gruppi.');
end;


procedure TMainForm.SelectSmallestClick(Sender: TObject);
begin
  ApplyAutoSelection(ascSmallestFile);
end;

procedure TMainForm.SelectLowerResolutionClick(Sender: TObject);
begin
  ApplyAutoSelection(ascLowerResolution);
end;

procedure TMainForm.SelectLowerQualityClick(Sender: TObject);
begin
  ApplyAutoSelection(ascLowerQuality);
end;

procedure TMainForm.SelectIdenticalToReferenceClick(Sender: TObject);
begin
  ApplyAutoSelection(ascIdenticalToReference);
end;

procedure TMainForm.SelectOldestClick(Sender: TObject);
begin
  ApplyAutoSelection(ascOldest);
end;

procedure TMainForm.EnsureUnselectedClick(Sender: TObject);
var G, M: Integer; AllSelected, IsSelected: Boolean;
begin
  CaptureChecks;
  for G := 0 to FGroups.Count - 1 do begin
    AllSelected := Length(FGroups[G].Members) > 0;
    for M := 0 to High(FGroups[G].Members) do begin
      IsSelected := False;
      FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName, IsSelected);
      if not IsSelected then begin AllSelected := False; Break end;
    end;
    if AllSelected then begin
      for M := 0 to High(FGroups[G].Members) do
        if FGroups[G].Members[M].IsReference then begin
          FChecked.AddOrSetValue(FGroups[G].Members[M].Info.FileName, False);
          Break;
        end;
    end;
  end;
  BuildTree(False);
  SetStatusMessage('Ogni gruppo conserva almeno un file non selezionato.');
end;

procedure TMainForm.DeselectAllClick(Sender: TObject);
begin
  FChecked.Clear;
  BuildTree(False);
  SetStatusMessage('Tutte le selezioni sono state rimosse.');
end;

procedure TMainForm.ResultsTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if not FUpdatingTree then ShowNode(Node);
end;

procedure TMainForm.ResultsTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
var Data: PNodeData;
begin
  if FUpdatingTree or not Assigned(Node) then Exit;
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) and (Data.Kind = nkFile) and (Data.GroupIndex < FGroups.Count) and
    (Data.MemberIndex < Length(FGroups[Data.GroupIndex].Members)) then
    FChecked.AddOrSetValue(FGroups[Data.GroupIndex].Members[Data.MemberIndex].Info.FileName,
      Sender.CheckState[Node] = csCheckedNormal);
  ActionDeleteSelected.Enabled := not Assigned(FWorker) and
    not FDeleting and HasCheckedFiles;
  UpdateCheckedSizeStatus;
end;

procedure TMainForm.ResultsTreeNodeDblClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
var Data: PNodeData;
begin
  if not Assigned(HitInfo.HitNode) then Exit;
  Data := ResultsTree.GetNodeData(HitInfo.HitNode);
  if not Assigned(Data) or (Data.Kind <> nkFile) or
    (Data.GroupIndex < 0) or (Data.GroupIndex >= FGroups.Count) or
    (Data.MemberIndex < 0) or
    (Data.MemberIndex >= Length(FGroups[Data.GroupIndex].Members)) then Exit;
  ShowNode(HitInfo.HitNode);
  if (Data.MemberIndex < FPreviewCards.Count) then
    PreviewImageClick(FPreviewCards[Data.MemberIndex].Image);
end;

procedure TMainForm.ShowNode(Node: PVirtualNode);
var Data: PNodeData; GroupIndex, MemberIndex: Integer; G: TImageGroup;
begin
  if not Assigned(Node) then Exit;
  Data := ResultsTree.GetNodeData(Node);
  if not Assigned(Data) then Exit;
  GroupIndex := Data.GroupIndex;
  if (GroupIndex < 0) or (GroupIndex >= FGroups.Count) then Exit;
  G := FGroups[GroupIndex];
  if Length(G.Members) < 1 then Exit;
  if Data.Kind = nkGroup then MemberIndex := 0 else MemberIndex := Data.MemberIndex;
  if (FSelectedGroup <> GroupIndex) or
    (FPreviewMemberCount <> Length(G.Members)) then
  begin
    FSelectedGroup := GroupIndex;
    BuildPreviews(GroupIndex)
  end
  else if (MemberIndex >= 0) and (MemberIndex < FPreviewCards.Count) then
    LoadPreview(FPreviewCards[MemberIndex], G.Members[MemberIndex]);
  FSelectedGroup := GroupIndex;
  FSelectedMember := MemberIndex;
  UpdatePreviewSelection;
end;

procedure TMainForm.ClearPreviews;
begin
  FPreviewCards.Clear;
  FSelectedGroup := -1;
  FSelectedMember := -1;
  FPreviewMemberCount := 0;
end;

procedure TMainForm.BuildPreviews(GroupIndex: Integer);
var I: Integer; Card: TPreviewCard;
begin
  FPreviewCards.Clear;
  if (GroupIndex < 0) or (GroupIndex >= FGroups.Count) then Exit;
  for I := 0 to High(FGroups[GroupIndex].Members) do
  begin
    Card := TPreviewCard.Create(Self, PreviewScroll);
    Card.MemberIndex := I;
    Card.Image.Cursor := crHandPoint;
    Card.Image.OnClick := PreviewImageClick;
    FPreviewCards.Add(Card);
    LoadPreview(Card, FGroups[GroupIndex].Members[I]);
  end;
  FPreviewMemberCount := FPreviewCards.Count;
  LayoutPreviews;
end;

procedure TMainForm.PreviewImageClick(Sender: TObject);
var
  I, Margin: Integer;
  Card: TPreviewCard;
  Bounds: TRect;
begin
  if Assigned(FFullSizeForm) then
  begin
    CloseFullSize(True);
    Exit;
  end;
  Card := nil;
  for I := 0 to FPreviewCards.Count - 1 do
    if FPreviewCards[I].Image = Sender then
    begin
      Card := FPreviewCards[I];
      Break;
    end;
  if not Assigned(Card) or (Card.Image.Picture.Graphic = nil) then Exit;

  FFullSizeForm := TForm.CreateNew(Self);
  FFullSizeForm.BorderStyle := bsNone;
  FFullSizeForm.Caption := Card.Caption.Hint;
  FFullSizeForm.Color := clBlack;
  FFullSizeForm.FormStyle := fsStayOnTop;
  FFullSizeForm.KeyPreview := True;
  FFullSizeForm.Scaled := False;
  FFullSizeForm.OnClick := PreviewImageClick;
  FFullSizeForm.OnDeactivate := FullSizeFormDeactivate;
  FFullSizeForm.OnDestroy := FullSizeFormDestroy;
  FFullSizeForm.OnKeyDown := FullSizeKeyDown;
  FFullSizeForm.OnMouseMove := FullSizeImageMouseMove;
  FFullSizeForm.OnMouseUp := FullSizeImageMouseUp;
  FFullSizeForm.Position := poDesigned;

  FFullSizeView := TFullSizeView.Create(FFullSizeForm);
  FFullSizeView.Parent := FFullSizeForm;
  FFullSizeView.Align := alClient;
  FFullSizeView.OnMouseDown := FullSizeImageMouseDown;
  FFullSizeView.OnMouseMove := FullSizeImageMouseMove;
  FFullSizeView.OnMouseUp := FullSizeImageMouseUp;
  FFullSizeView.Picture.Assign(Card.Image.Picture);
  FFullSizeView.Hint := Card.Caption.Hint;

  Bounds := Monitor.WorkareaRect;
  Margin := MulDiv(24, CurrentPPI, 96);
  FFullSizeForm.SetBounds(
    Bounds.Left + (Bounds.Width - Min(FFullSizeView.Picture.Width + Margin * 2,
      Bounds.Width)) div 2,
    Bounds.Top + (Bounds.Height - Min(FFullSizeView.Picture.Height + Margin * 2,
      Bounds.Height)) div 2,
    Min(FFullSizeView.Picture.Width + Margin * 2, Bounds.Width),
    Min(FFullSizeView.Picture.Height + Margin * 2, Bounds.Height));
  SetFullSizeImagePosition(
    (FFullSizeForm.ClientWidth - FFullSizeView.Picture.Width) div 2,
    (FFullSizeForm.ClientHeight - FFullSizeView.Picture.Height) div 2);
  if (FFullSizeView.Picture.Width > FFullSizeForm.ClientWidth) or
    (FFullSizeView.Picture.Height > FFullSizeForm.ClientHeight) then
    FFullSizeView.Cursor := crSizeAll
  else
    FFullSizeView.Cursor := crHandPoint;
  FFullSizeForm.Show;
  FFullSizeForm.BringToFront;
  FFullSizeForm.SetFocus;
end;

procedure TMainForm.CloseFullSize(Deferred: Boolean);
var Form: TForm;
begin
  Form := FFullSizeForm;
  if not Assigned(Form) then Exit;
  FPanning := False;
  ReleaseCapture;
  FFullSizeForm := nil;
  FFullSizeView := nil;
  Form.Hide;
  if Deferred then Form.Release else Form.Free;
end;

procedure TMainForm.FullSizeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    CloseFullSize(True);
  end;
end;

procedure TMainForm.FullSizeFormDestroy(Sender: TObject);
begin
  if Sender = FFullSizeForm then
  begin
    FFullSizeForm := nil;
    FFullSizeView := nil;
  end;
end;

procedure TMainForm.FullSizeFormDeactivate(Sender: TObject);
begin
  CloseFullSize(True);
end;

function TMainForm.FullSizeImageContains(X, Y: Integer): Boolean;
begin
  Result := Assigned(FFullSizeView) and
    PtInRect(Rect(FFullSizeView.ImageLeft, FFullSizeView.ImageTop,
      FFullSizeView.ImageLeft + FFullSizeView.Picture.Width,
      FFullSizeView.ImageTop + FFullSizeView.Picture.Height), Point(X, Y));
end;

procedure TMainForm.SetFullSizeImagePosition(ALeft, ATop: Integer);
begin
  if not Assigned(FFullSizeView) then Exit;
  if FFullSizeView.Picture.Width <= FFullSizeForm.ClientWidth then
    ALeft := (FFullSizeForm.ClientWidth - FFullSizeView.Picture.Width) div 2
  else
    ALeft := EnsureRange(ALeft,
      FFullSizeForm.ClientWidth - FFullSizeView.Picture.Width, 0);
  if FFullSizeView.Picture.Height <= FFullSizeForm.ClientHeight then
    ATop := (FFullSizeForm.ClientHeight - FFullSizeView.Picture.Height) div 2
  else
    ATop := EnsureRange(ATop,
      FFullSizeForm.ClientHeight - FFullSizeView.Picture.Height, 0);
  FFullSizeView.SetPosition(ALeft, ATop);
end;

procedure TMainForm.FullSizeImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or not Assigned(FFullSizeView) then Exit;
  if not FullSizeImageContains(X, Y) then begin
    CloseFullSize(True);
    Exit;
  end;
  FPanning := True;
  FPanMoved := False;
  GetCursorPos(FPanStart);
  FPanImageStart := Point(FFullSizeView.ImageLeft, FFullSizeView.ImageTop);
  SetCapture(FFullSizeForm.Handle);
end;

procedure TMainForm.FullSizeImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var Current: TPoint; DX, DY: Integer;
begin
  if not FPanning or not Assigned(FFullSizeView) then Exit;
  GetCursorPos(Current);
  DX := Current.X - FPanStart.X;
  DY := Current.Y - FPanStart.Y;
  if (Abs(DX) > MulDiv(3, CurrentPPI, 96)) or
    (Abs(DY) > MulDiv(3, CurrentPPI, 96)) then FPanMoved := True;
  SetFullSizeImagePosition(FPanImageStart.X + DX, FPanImageStart.Y + DY);
end;

procedure TMainForm.FullSizeImageMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var WasMoved: Boolean;
begin
  if (Button <> mbLeft) or not FPanning then Exit;
  WasMoved := FPanMoved;
  FPanning := False;
  ReleaseCapture;
  if not WasMoved then CloseFullSize(True);
end;

function TMainForm.FullSizeVisible: Boolean;
begin
  Result := Assigned(FFullSizeForm) and FFullSizeForm.Visible;
end;

function TMainForm.FullSizeUsesNativeDimensions: Boolean;
begin
  Result := Assigned(FFullSizeView) and
    (FFullSizeView.Picture.Width > 0) and
    (FFullSizeView.Picture.Height > 0) and FFullSizeView.DoubleBuffered;
end;

procedure TMainForm.LoadPreview(Card: TPreviewCard; const Member: TGroupMember);
var Info: TImageInfo; MetricsText: string;
begin
  Info := Member.Info;
  Card.Image.Picture.Assign(nil);
  if Card.MemberIndex = 0 then
    MetricsText := 'Riferimento del gruppo'
  else
    MetricsText := Format('Distanza %d | RGB %.4f | SSIM %.4f | minimo %.4f',
      [Member.Metrics.Distance, Member.Metrics.RGBError,
       Member.Metrics.Structural, Member.Metrics.WorstStructural]);
  Card.Caption.Caption := ExtractFileName(Info.FileName) + sLineBreak +
    Dimensions(Info) + ' px | ' + FileSizeText(Info.Bytes) + ' | ' +
    DpiText(Info) + ' | ' +
    FormatDateTime('yyyy-mm-dd hh:nn:ss', Info.Modified) + sLineBreak +
    Format('Qualita %.1f/100 | nitidezza %.3f | rumore %.3f | artefatti %.3f',
      [Member.QualityScore, Info.Quality.Sharpness, Info.Quality.Noise,
       Info.Quality.BlockArtifacts]) + sLineBreak + MetricsText;
  Card.Caption.Hint := Info.FileName + sLineBreak + QualityDetailsText(Member);
  Card.Image.Hint := Card.Caption.Hint;
  try
    Card.Image.Picture.LoadFromFile(Info.FileName);
  except
    on E: Exception do begin
      Card.Image.Picture.Assign(nil);
      Card.Caption.Caption := Card.Caption.Caption + sLineBreak +
        'Anteprima non disponibile';
      Card.Caption.Hint := Info.FileName + sLineBreak + E.Message;
    end;
  end;
end;

procedure TMainForm.LayoutPreviews;
var
  Count, Cols, BestCols, Rows, Row, Col, Index, InRow: Integer;
  Gap, AvailableWidth, AvailableHeight, CardWidth, CardHeight,
    CaptionHeight, ImageWidth, ImageHeight: Integer;
  Scale, Score, BestScore: Double;
  Info: TImageInfo;
begin
  Count := FPreviewCards.Count;
  if (Count = 0) or (PreviewScroll.ClientWidth <= 0) or
    (PreviewScroll.ClientHeight <= 0) then Exit;
  Gap := MulDiv(8, CurrentPPI, 96);
  AvailableWidth := PreviewScroll.ClientWidth;
  AvailableHeight := PreviewScroll.ClientHeight;
  BestCols := 1;
  BestScore := -1;
  for Cols := 1 to Count do
  begin
    Rows := (Count + Cols - 1) div Cols;
    CardHeight := (AvailableHeight - (Rows + 1) * Gap) div Rows;
    CaptionHeight := EnsureRange(CardHeight div 3,
      MulDiv(44, CurrentPPI, 96), MulDiv(66, CurrentPPI, 96));
    Score := 0;
    Index := 0;
    for Row := 0 to Rows - 1 do
    begin
      InRow := Min(Cols, Count - Index);
      CardWidth := (AvailableWidth - (InRow + 1) * Gap) div InRow;
      for Col := 0 to InRow - 1 do
      begin
        Info := FGroups[FSelectedGroup].Members[Index].Info;
        ImageWidth := Max(1, CardWidth - Gap * 2);
        ImageHeight := Max(1, CardHeight - CaptionHeight - Gap * 2);
        Scale := Min(ImageWidth / Max(1, Info.Width),
          ImageHeight / Max(1, Info.Height));
        Score := Score + Info.Width * Scale * Info.Height * Scale;
        Inc(Index);
      end;
    end;
    if Score > BestScore then
    begin
      BestScore := Score;
      BestCols := Cols;
    end;
  end;

  Rows := (Count + BestCols - 1) div BestCols;
  CardHeight := Max(1, (AvailableHeight - (Rows + 1) * Gap) div Rows);
  CaptionHeight := EnsureRange(CardHeight div 3,
    MulDiv(44, CurrentPPI, 96), MulDiv(66, CurrentPPI, 96));
  Index := 0;
  for Row := 0 to Rows - 1 do
  begin
    InRow := Min(BestCols, Count - Index);
    CardWidth := Max(1, (AvailableWidth - (InRow + 1) * Gap) div InRow);
    for Col := 0 to InRow - 1 do
    begin
      FPreviewCards[Index].Caption.Height := CaptionHeight;
      FPreviewCards[Index].Panel.SetBounds(
        Gap + Col * (CardWidth + Gap),
        Gap + Row * (CardHeight + Gap), CardWidth, CardHeight);
      Inc(Index);
    end;
  end;
end;

procedure TMainForm.UpdatePreviewSelection;
var I: Integer; Selected: Boolean;
begin
  for I := 0 to FPreviewCards.Count - 1 do
  begin
    Selected := I = FSelectedMember;
    if Selected then
    begin
      FPreviewCards[I].Panel.Selected := True;
      FPreviewCards[I].Caption.Font.Style := [fsBold];
    end
    else
    begin
      FPreviewCards[I].Panel.Selected := False;
      FPreviewCards[I].Caption.Font.Style := [];
    end;
  end;
end;

function TMainForm.PreviewCardCount: Integer;
begin
  Result := FPreviewCards.Count;
end;

function TMainForm.PreviewCard(Index: Integer): TPreviewCard;
begin
  Result := FPreviewCards[Index];
end;


procedure TMainForm.SaveSessionToFile(const FileName: string);
var State: TSessionState; Selected: TList<string>; Pair: TPair<string, Boolean>;
begin
  State.Distance := DistanceEdit.Value;
  State.PixelError := DefaultMaxRGBError;
  State.ThreadCount := ThreadEdit.Value;
  State.ScannedFiles := FScannedFileCount;
  State.Roots := PathsMemo.Lines.ToStringArray;
  State.Recursive := RecursiveCheck.Checked;
  State.Groups := FGroups.ToArray;
  CaptureChecks;
  Selected := TList<string>.Create;
  try
    for Pair in FChecked do if Pair.Value then Selected.Add(Pair.Key);
    State.SelectedFiles := Selected.ToArray;
  finally
    Selected.Free;
  end;
  SaveSession(FileName, State);
end;

procedure TMainForm.LoadSessionFromFile(const FileName: string);
var State: TSessionState; G: TImageGroup; S: string;
begin
  if Assigned(FWorker) then
    raise EInvalidOperation.Create('Interrompi la scansione prima di caricare una sessione.');
  State := LoadSession(FileName);
    if (State.Distance < 0) or (State.Distance > 63) or
    (State.ThreadCount < 1) or (State.ThreadCount > 64) or
    (State.ScannedFiles < 0) then
    raise EConvertError.Create('Le soglie salvate non sono valide.');
  PathsMemo.Lines.BeginUpdate;
  try
    PathsMemo.Lines.Clear;
    for S in State.Roots do PathsMemo.Lines.Add(S);
  finally
    PathsMemo.Lines.EndUpdate;
  end;
  RecursiveCheck.Checked := State.Recursive;
  DistanceEdit.Value := State.Distance;
  ThreadEdit.Value := State.ThreadCount;
  FScannedFileCount := State.ScannedFiles;
  FGroups.Clear;
  for G in State.Groups do FGroups.Add(G);
  if FSortColumn = 0 then SortGroupsBySize(FSortAscending)
  else if FSortColumn > 0 then SortMembers(FSortColumn, FSortAscending);
  FChecked.Clear;
  for S in State.SelectedFiles do FChecked.AddOrSetValue(S, True);
  FErrors.Clear;
  ActionShowErrors.Enabled := False;
  FSelectedGroup := -1;
  FSelectedMember := -1;
  BuildTree(False);
  ActionSelectionOptions.Enabled := FGroups.Count > 0;
  ResultsLabel.Caption := Format('Sessione caricata - %d gruppi, %d file.',
    [FGroups.Count, ResultsTree.TotalCount - FGroups.Count]);
  StatusProgress.Style := pbstNormal;
  if FScannedFileCount > 0 then begin
    StatusProgress.Max := FScannedFileCount;
    StatusProgress.Position := FScannedFileCount;
    StatusProgress.Hint := Format('%d immagini analizzate nella sessione',
      [FScannedFileCount]);
  end else begin
    StatusProgress.Max := 100;
    StatusProgress.Position := 0;
    StatusProgress.Hint := 'Conteggio non disponibile nella sessione';
  end;
  SetStatusMessage(Format(
    'Sessione caricata | Analizzate: %d | Gruppi: %d | File: %d',
    [FScannedFileCount, FGroups.Count, ResultsTree.TotalCount - FGroups.Count]));
end;

procedure TMainForm.PreviewPanelResize(Sender: TObject);
begin
  if Assigned(FPreviewCards) then LayoutPreviews;
end;

procedure TMainForm.ErrorsButtonClick(Sender: TObject);
var Dialog: TForm; Memo: TMemo;
begin
  Dialog := TForm.CreateNew(Self);
  try
    Dialog.Caption := 'Errori di lettura (primi 200)';
    Dialog.Position := poOwnerFormCenter; Dialog.Width := 800; Dialog.Height := 400;
    Memo := TMemo.Create(Dialog); Memo.Parent := Dialog; Memo.Align := alClient;
    Memo.ReadOnly := True; Memo.ScrollBars := ssBoth; Memo.WordWrap := False;
    Memo.Lines.Assign(FErrors); Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FWorker) and not FDeleting;
  if FDeleting then Exit;
  if not CanClose then begin FClosePending := True; StopButtonClick(nil) end;
end;

end.




