unit ImageDup.FormSession;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl, System.SysUtils, System.Classes, System.Types, System.Generics.Collections, System.UITypes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, VirtualTrees, VirtualTrees.Types, ImageDup.Scan, ImageDup.FormMain,
  ImageDup.Groups, VirtualTrees.BaseTree, System.Actions, Vcl.ActnList,
  Vcl.ImgList, Vcl.ToolWin, VirtualTrees.BaseAncestorVCL,
  VirtualTrees.AncestorVCL;

type
  TNodeKind = (nkGroup, nkFile);

  TReferenceCriterion = (rcHighestQuality, rcHighestResolution,
    rcLargestFile, rcNewest, rcLowestQuality, rcLowestResolution,
    rcSmallestFile, rcOldest);
  TGroupSelectionCriterion = (gscAllExceptReference,
    gscIdenticalToReference, gscDifferentFromReference);

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
    FImageLeft, FImageTop, FImageWidth, FImageHeight: Integer;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetImageBounds(ALeft, ATop, AWidth, AHeight: Integer);
    procedure SetPosition(ALeft, ATop: Integer);
    property Picture: TPicture read FPicture;
    property ImageLeft: Integer read FImageLeft;
    property ImageTop: Integer read FImageTop;
    property ImageWidth: Integer read FImageWidth;
    property ImageHeight: Integer read FImageHeight;
  end;

  TFormSession = class(TForm)
    SetupPanel: TPanel;
    PathsLabel: TLabel;
    PathsMemo: TMemo;
    BrowseButton: TButton;
    ResultsPanel: TPanel;
    ResultsLabel: TLabel;
    ResultsTree: TVirtualStringTree;
    PreviewSplitter: TSplitter;
    PreviewPanel: TPanel;
    PreviewScroll: TScrollBox;
    PollTimer: TTimer;
    OpenSessionDialog: TFileOpenDialog;
    SaveSessionDialog: TFileSaveDialog;
    ExportExcelDialog: TFileSaveDialog;
    MoveFolderDialog: TFileOpenDialog;
    FileOperationMenu: TPopupMenu;
    RecycleSelectedItem: TMenuItem;
    MoveSelectedItem: TMenuItem;
    SelectionMenu: TPopupMenu;
    SetCurrentAsReferenceItem: TMenuItem;
    OpenInExplorerItem: TMenuItem;
    NewSessionFromFolderItem: TMenuItem;
    ContextReferenceSeparatorItem: TMenuItem;
    SetReferenceItem: TMenuItem;
    ReferenceHighestQualityItem: TMenuItem;
    ReferenceHighestResolutionItem: TMenuItem;
    ReferenceLargestFileItem: TMenuItem;
    ReferenceNewestItem: TMenuItem;
    ReferenceLowestQualityItem: TMenuItem;
    ReferenceLowestResolutionItem: TMenuItem;
    ReferenceSmallestFileItem: TMenuItem;
    ReferenceOldestItem: TMenuItem;
    SelectionSeparatorItem: TMenuItem;
    SelectAllExceptReferenceItem: TMenuItem;
    SelectIdenticalToReferenceItem: TMenuItem;
    SelectDifferentFromReferenceItem: TMenuItem;
    ContextSelectionSeparatorItem: TMenuItem;
    SelectOtherGroupsSameFolderItem: TMenuItem;
    SelectOtherGroupsDifferentFolderItem: TMenuItem;
    SafetySelectionSeparatorItem: TMenuItem;
    EnsureUnselectedItem: TMenuItem;
    ClearSelectionsItem: TMenuItem;
    ActionList: TActionList;
    ActionNewSession: TAction;
    ActionSaveSession: TAction;
    ActionLoadSession: TAction;
    ActionBrowse: TAction;
    ActionStartScan: TAction;
    ActionStopScan: TAction;
    ActionShowErrors: TAction;
    ActionDeleteSelected: TAction;
    ActionMoveSelected: TAction;
    ActionSelectionOptions: TAction;
    ActionOptions: TAction;
    ActionExportExcel: TAction;
    ActionAbout: TAction;
    ActionSetCurrentAsReference: TAction;
    ActionOpenInExplorer: TAction;
    ActionNewSessionFromFolder: TAction;
    ActionReferenceHighestQuality: TAction;
    ActionReferenceHighestResolution: TAction;
    ActionReferenceLargestFile: TAction;
    ActionReferenceNewest: TAction;
    ActionReferenceLowestQuality: TAction;
    ActionReferenceLowestResolution: TAction;
    ActionReferenceSmallestFile: TAction;
    ActionReferenceOldest: TAction;
    ActionSelectAllExceptReference: TAction;
    ActionSelectIdenticalToReference: TAction;
    ActionSelectDifferentFromReference: TAction;
    ActionSelectOtherGroupsSameFolder: TAction;
    ActionSelectOtherGroupsDifferentFolder: TAction;
    ActionEnsureUnselected: TAction;
    ActionClearSelections: TAction;
    ToolBar: TToolBar;
    ToolButtonNewSession: TToolButton;
    ToolButtonSep1: TToolButton;
    ToolButtonLooadSession: TToolButton;
    ToolButtonSaveSession: TToolButton;
    ToolButtonSep2: TToolButton;
    ToolButtonStartSearch: TToolButton;
    ToolButtonSelectionOptions: TToolButton;
    ToolButtonSep3: TToolButton;
    ToolButtonStopSearch: TToolButton;
    ToolButtonSep4: TToolButton;
    ToolButtonDeleteSelected: TToolButton;
    ToolButtonSep5: TToolButton;
    ToolButtonErrorDetails: TToolButton;
    ToolButtonOptions: TToolButton;
    ToolButtonSep6: TToolButton;
    ToolButtonSep7: TToolButton;
    ToolButtonExportExcel: TToolButton;
    StatusBar: TStatusBar;
    StatusProgress: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActionBrowseExecute(Sender: TObject);
    procedure PathsMemoChange(Sender: TObject);
    procedure ActionStartScanExecute(Sender: TObject);
    procedure ActionStopScanExecute(Sender: TObject);
    procedure PollTimerTimer(Sender: TObject);
    procedure PreviewPanelResize(Sender: TObject);
    procedure ActionShowErrorsExecute(Sender: TObject);
    procedure ResultsTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ResultsTreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var
      ImageIndex: System.UITypes.TImageIndex);
    procedure ResultsTreeHeaderClick(Sender: TVTHeader; const HitInfo: TVTHeaderHitInfo);
    procedure ResultsTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ResultsTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ResultsTreeNodeDblClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
    procedure ResultsTreeMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ResultsTreeMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure SelectionMenuPopup(Sender: TObject);
    procedure PreviewImageClick(Sender: TObject);
    procedure FullSizeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FullSizeFormDestroy(Sender: TObject);
    procedure FullSizeFormDeactivate(Sender: TObject);
    procedure FullSizeImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FullSizeImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FullSizeImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ActionSelectionOptionsExecute(Sender: TObject);
    procedure ActionDeleteSelectedExecute(Sender: TObject);
    procedure ActionMoveSelectedExecute(Sender: TObject);
    procedure ActionSetCurrentAsReferenceExecute(Sender: TObject);
    procedure ActionOpenInExplorerExecute(Sender: TObject);
    procedure ActionNewSessionFromFolderExecute(Sender: TObject);
    procedure PreviewContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure ActionReferenceHighestQualityExecute(Sender: TObject);
    procedure ActionReferenceHighestResolutionExecute(Sender: TObject);
    procedure ActionReferenceLargestFileExecute(Sender: TObject);
    procedure ActionReferenceNewestExecute(Sender: TObject);
    procedure ActionReferenceLowestQualityExecute(Sender: TObject);
    procedure ActionReferenceLowestResolutionExecute(Sender: TObject);
    procedure ActionReferenceSmallestFileExecute(Sender: TObject);
    procedure ActionReferenceOldestExecute(Sender: TObject);
    procedure ActionSelectAllExceptReferenceExecute(Sender: TObject);
    procedure ActionSelectIdenticalToReferenceExecute(Sender: TObject);
    procedure ActionSelectDifferentFromReferenceExecute(Sender: TObject);
    procedure ActionSelectOtherGroupsSameFolderExecute(Sender: TObject);
    procedure ActionSelectOtherGroupsDifferentFolderExecute(Sender: TObject);
    procedure ActionEnsureUnselectedExecute(Sender: TObject);
    procedure ActionClearSelectionsExecute(Sender: TObject);
    procedure ActionNewSessionExecute(Sender: TObject);
    procedure ActionSaveSessionExecute(Sender: TObject);
    procedure ActionLoadSessionExecute(Sender: TObject);
    procedure ActionOptionsExecute(Sender: TObject);
    procedure ActionExportExcelExecute(Sender: TObject);
    procedure ActionAboutExecute(Sender: TObject);
  private
    FWorker: TImageScan;
    FGroups: TList<TImageGroup>;
    FChecked: TDictionary<string, Boolean>;
    FMetricReferences: TDictionary<Integer, string>;
    FErrors: TStringList;
    FPreviewCards: TObjectList<TPreviewCard>;
    FFullSizeForm: TForm;
    FFullSizeView: TFullSizeView;
    FFullSizeClosing, FFullSizeNative, FZoomCursorAvailable: Boolean;
    FPanStart, FPanImageStart: TPoint;
    FPanning, FPanMoved: Boolean;
    FClosePending, FUpdatingTree, FModified, FCloseApproved: Boolean;
    FSelectedGroup, FSelectedMember: Integer;
    FPreviewMemberCount: Integer;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    FDeleting, FStopping: Boolean;
    FScannedFileCount: Integer;
    FStatusMessage: string;
    FSelectionContextFileName: string;
    FSessionFileName: string;
    FComparisonQuality, FThreadCount: Integer;
    FRecursiveSearch: Boolean;
    FIncludeSingletons: Boolean;
    procedure RefreshActionStates;
    function HasSearchRoots: Boolean;
    function HasSessionContent: Boolean;
    procedure BuildTree(CaptureCurrent: Boolean = True; const FocusFileOverride: string = '');
    procedure CaptureChecks;
    function FocusedFileName: string;
    procedure ShowNode(Node: PVirtualNode);
    procedure ClearPreviews;
    procedure BuildPreviews(GroupIndex: Integer);
    procedure LayoutPreviews;
    procedure UpdatePreviewSelection;
    procedure LoadPreview(Card: TPreviewCard; const Member: TGroupMember);
    procedure CloseFullSize(Deferred: Boolean);
    procedure SetFullSizeMode(NativeSize: Boolean);
    procedure SetFullSizeImagePosition(ALeft, ATop: Integer);
    function FullSizeImageContains(X, Y: Integer): Boolean;
    procedure ApplyReferenceCriterion(Criterion: TReferenceCriterion);
    procedure ApplyGroupSelection(Criterion: TGroupSelectionCriterion);
    procedure ApplyFolderSelection(SameFolder: Boolean);
    procedure RecalculateReferenceMetrics(var Group: TImageGroup);
    function ResolveSelectionContext(out GroupIndex, MemberIndex: Integer): Boolean;
    function SelectionContextValid: Boolean;
    procedure ShowSelectionMenuAt(const ScreenPoint: TPoint;
      ContextGroup, ContextMember: Integer);
    procedure SortGroupsBySize(Ascending: Boolean);
    procedure SortMembers(Column: Integer; Ascending: Boolean);
    function HasCheckedFiles: Boolean;
    function CheckedFileBytes: Int64;
    function CheckedFileCount: Integer;
    procedure UpdateCheckedSizeStatus;
    procedure SetStatusMessage(const Value: string);
    procedure SetModified(Value: Boolean);
    procedure InitializeStatusBar;
    procedure SetProgressVisible(Value: Boolean);
    procedure UpdateStatusBarLayout;
    procedure RemoveRecycledFiles(const FileNames: TArray<string>);
    function SelectedFiles: TArray<string>;
    procedure UpdateMovedFiles(const MovedFiles: TDictionary<string, string>);
  public
    procedure SetSearchOptions(AQuality, AThreadCount: Integer;
      ARecursive: Boolean; AIncludeSingletons: Boolean = False);
    property Worker: TImageScan read FWorker;
    property ScannedFileCount: Integer read FScannedFileCount;
    property SelectedFileBytes: Int64 read CheckedFileBytes;
    property SelectedFileCount: Integer read CheckedFileCount;
    property ComparisonQuality: Integer read FComparisonQuality;
    property ProcessingThreadCount: Integer read FThreadCount;
    property RecursiveSearch: Boolean read FRecursiveSearch;
    function PreviewCardCount: Integer;
    function PreviewCard(Index: Integer): TPreviewCard;
    function FullSizeVisible: Boolean;
    function FullSizeUsesNativeDimensions: Boolean;
    function FullSizeUsesZoomCursor: Boolean;
    procedure SaveSessionToFile(const FileName: string);
    procedure LoadSessionFromFile(const FileName: string);
    procedure ExportResultsToFile(const FileName: string);
    procedure SetReferenceFile(const FileName: string);
    procedure InitializeUntitled(const ACaption: string);
    procedure LoadDocument(const FileName: string);
    procedure SaveDocument(const FileName: string);
    function CanSaveDocument: Boolean;
    function IsBusy: Boolean;
    function PrepareForClose: Boolean;
    procedure CancelPreparedClose;
    property Modified: Boolean read FModified;
    property SessionFileName: string read FSessionFileName;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.Math, ImageDup.Session, ImageDup.Core, ImageDup.Recycle,
  ImageDup.Options, ImageDup.ExcelExport, ImageDup.FormAbout,
  ImageDup.FileMove, Winapi.ShlObj, Winapi.ActiveX,
  Vcl.Imaging.pngimage;

const
  crImageZoomIn = TCursor(1);
  ZoomInCursorResource = 'ZOOM_IN_CURSOR';

resourcestring
  rsFileUnavailable='File is not available.';
  rsExplorerOpenFailedFmt='Unable to show the file in File Explorer (error 0x%.8x).';
  rsUnknown='unknown';
  rsImageListResourceErrorFmt='Unable to add resource %d (%dx%d) to the image list.';
  rsDimensionsFmt='%d x %d';
  rsBytesFmt='%d B';
  rsKiBNumberFormat='0.0 KiB';
  rsMiBNumberFormat='0.00 MiB';
  rsUnknownDpi='DPI unknown';
  rsSingleDpiFmt='%.0f DPI';
  rsDoubleDpiFmt='%.0f x %.0f DPI';
  rsNo='no';
  rsYes='yes';
  rsQualityDetailsFmt='Quality: %.1f/100%sSharpness: %.3f | noise: %.3f | artifacts: %.3f%sClipping: %.3f | banding: %.3f | upscaling risk: %.3f%sBit depth: %d bits/channel | ICC profile: %s | chroma: %s | color mode: %s';
  rsGiBNumberFormat='0.00 GB';
  rsMBNumberFormat='0.00 MB';
  rsKBNumberFormat='0.00 KB';
  rsByteCountFmt='%d bytes';
  rsReady='Ready';
  rsSelectedStatusFmt='%s | Selected: %d files, %s';
  rsAddFolderTitle='Add folders to the search';
  rsFolderNotFoundFmt='Folder does not exist: %s';
  rsFolderRequired='Add at least one folder.';
  rsScanInProgress='Search in progress - groups will appear here';
  rsStartingScanFmt='Starting scan with %d threads...';
  rsStoppingScan='Stopping; waiting for the current image to finish...';
  rsProgressImagesFmt='%d / %d images';
  rsScanFailed='Scan failed';
  rsScanCancelled='Scan cancelled';
  rsScanCompletedWithErrors='Completed with errors';
  rsScanCompleted='Scan completed';
  rsNoGroupsFoundFmt='%s - no groups found';
  rsGroupsFoundFmt='%s - %d groups, %d grouped files.';
  rsScanSummaryFmt='%s | Scanned: %d | Groups: %d | Files: %d | Errors: %d';
  rsScanProgressFmt='Threads: %d | Files: %d / %d | Groups: %d | Errors: %d | %s';
  rsScanProgressCalculatingFmt='Threads: %d | Files scanned: %d | Total: calculating | Groups: %d | Errors: %d | %s';
  rsGroupCaptionFmt='Group %d  (%d images)';
  rsRecycleConfirmFmt='Move the %d selected files to the Windows Recycle Bin?';
  rsMovingToRecycleBinFmt='Moving to the Recycle Bin: %s';
  rsResultsUpdatedFmt='Results updated - %d groups, %d files.';
  rsRecycleSummaryFmt='In the Recycle Bin: %d | Not moved: %d';
  rsRecycleFailuresFmt='%d files could not be moved and remain selected.%sSee Error details for the reasons.';
  rsMoveFolderDialogTitle='Move selected files to a folder';
  rsMoveConfirmFmt='Move the %d selected files to "%s" while preserving their folder structure?';
  rsMovingToFolderFmt='Moving to folder: %s';
  rsMoveSummaryFmt='Moved: %d | Not moved: %d';
  rsMoveFailuresFmt='%d files could not be moved and remain selected.%sSee Error details for the reasons.';
  rsSessionLoadedFileFmt='Session loaded: %s | Scanned: %d';
  rsSessionLoadErrorFmt='Unable to load the session:%s%s';
  rsInitialResultsCaption='Similar image groups - add folders and start the search';
  rsSessionCleared='Session cleared.';
  rsOptionsUpdated='Search options updated.';
  rsExcelExportCompletedFmt='Excel export created: %s';
  rsExcelExportErrorFmt='Unable to export to Excel:%s%s';
  rsSessionSavedFmt='Session saved: %s';
  rsSessionSaveErrorFmt='Unable to save the session:%s%s';
  rsSaveChangesPromptFmt='Save changes to "%s" before closing?';
  rsAutoSelectionApplied='Automatic selection applied to all groups.';
  rsReferencesUpdated='The reference file has been updated in every group.';
  rsReferenceFileUpdatedFmt='Reference file set: %s';
  rsFolderSelectionApplied='Folder-based selection has been applied to the other groups.';
  rsGroupKeepsUnselectedFile='Each group retains at least one unselected file.';
  rsAllSelectionsCleared='All selections have been cleared.';
  rsGroupReference='Group reference';
  rsComparisonMetricsFmt='Distance %d | RGB %.4f | SSIM %.4f | minimum %.4f';
  rsDateTimeFormat='yyyy-mm-dd hh:nn:ss';
  rsPreviewCaptionFmt='%s%s%s px | %s | %s | %s%sQuality %.1f/100 | sharpness %.3f | noise %.3f | artifacts %.3f%s%s';
  rsPreviewUnavailable='Preview unavailable';
  rsStopScanBeforeLoading='Stop the scan before loading a session.';
  rsInvalidSavedCriteria='The saved criteria are invalid.';
  rsSessionLoadedResultsFmt='Session loaded - %d groups, %d files.';
  rsSessionImagesHintFmt='%d images scanned in this session';
  rsSessionCountUnavailable='Image count is unavailable in this session';
  rsSessionStatusFmt='Session loaded | Scanned: %d | Groups: %d | Files: %d';
  rsReadErrorsCaption='Read errors (first 200)';

procedure AddPngResource(Images: TImageList; ResourceId: Integer);
var
  Stream: TResourceStream;
  Png: TPngImage;
  Bitmap: TBitmap;
  AddedIndex: Integer;
begin
  Stream := TResourceStream.CreateFromID(HInstance, ResourceId, RT_RCDATA);
  try
    Png := TPngImage.Create;
    try
      Png.LoadFromStream(Stream);
      Bitmap := TBitmap.Create;
      try
        Bitmap.Assign(Png);
        Bitmap.AlphaFormat := afDefined;
        AddedIndex := Images.Add(Bitmap, nil);
        if AddedIndex < 0 then
          raise Exception.CreateFmt(rsImageListResourceErrorFmt, [ResourceId, Bitmap.Width, Bitmap.Height]);
      finally
        Bitmap.Free;
      end;
    finally
      Png.Free;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TPreviewPanel.SetSelected(Value: Boolean);
begin
  if FSelected = Value then
    Exit;
  FSelected := Value;
  if Value then
    Color := $00FFE8D8
  else
    Color := clWindow;
  Invalidate;
end;

procedure TPreviewPanel.Paint;
var
  I: Integer;
  R: TRect;
begin
  inherited;
  if not FSelected then
    Exit;
  R := ClientRect;
  for I := 0 to 4 do
  begin
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
var
  PreviousMode: Integer;
begin
  Canvas.Brush.Color := clBlack;
  Canvas.FillRect(ClientRect);
  if not Assigned(FPicture.Graphic) or FPicture.Graphic.Empty or
    (FImageWidth <= 0) or (FImageHeight <= 0) then
    Exit;
  if (FImageWidth = FPicture.Width) and (FImageHeight = FPicture.Height) then
    Canvas.Draw(FImageLeft, FImageTop, FPicture.Graphic)
  else
  begin
    PreviousMode := SetStretchBltMode(Canvas.Handle, HALFTONE);
    try
      SetBrushOrgEx(Canvas.Handle, 0, 0, nil);
      Canvas.StretchDraw(Rect(FImageLeft, FImageTop,
        FImageLeft + FImageWidth, FImageTop + FImageHeight), FPicture.Graphic);
    finally
      SetStretchBltMode(Canvas.Handle, PreviousMode);
    end;
  end;
end;

procedure TFullSizeView.SetImageBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  if (FImageLeft = ALeft) and (FImageTop = ATop) and
    (FImageWidth = AWidth) and (FImageHeight = AHeight) then
    Exit;
  FImageLeft := ALeft;
  FImageTop := ATop;
  FImageWidth := AWidth;
  FImageHeight := AHeight;
  Invalidate;
end;

procedure TFullSizeView.SetPosition(ALeft, ATop: Integer);
begin
  SetImageBounds(ALeft, ATop, FImageWidth, FImageHeight);
end;

destructor TPreviewCard.Destroy;
begin
  Panel.Free;
  inherited;
end;

function Dimensions(const Info: TImageInfo): string;
begin
  Result := Format(rsDimensionsFmt, [Info.Width, Info.Height]);
end;

function FileSizeText(Bytes: Int64): string;
begin
  if Bytes < 1024 then
    Result := Format(rsBytesFmt, [Bytes])
  else if Bytes < 1024 * 1024 then
    Result := FormatFloat(rsKiBNumberFormat, Bytes / 1024)
  else
    Result := FormatFloat(rsMiBNumberFormat, Bytes / (1024 * 1024));
end;

function DpiText(const Info: TImageInfo): string;
begin
  if (Info.DpiX <= 0) and (Info.DpiY <= 0) then
    Result := rsUnknownDpi
  else if (Info.DpiX > 0) and (Info.DpiY > 0) and SameValue(Info.DpiX, Info.DpiY, 0.05) then
    Result := Format(rsSingleDpiFmt, [Info.DpiX])
  else
    Result := Format(rsDoubleDpiFmt, [Info.DpiX, Info.DpiY]);
end;

function QualityDetailsText(const Member: TGroupMember): string;
var
  ProfileText: string;
begin
  if Member.Info.Quality.HasColorProfile then
    ProfileText := rsYes
  else
    ProfileText := rsNo;
  Result := Format(rsQualityDetailsFmt, [Member.QualityScore, sLineBreak,
    Member.Info.Quality.Sharpness, Member.Info.Quality.Noise,
    Member.Info.Quality.BlockArtifacts, sLineBreak,
    Member.Info.Quality.Clipping, Member.Info.Quality.Banding,
    Member.Info.Quality.UpscaleRisk, sLineBreak, Member.Info.Quality.BitDepth,
    ProfileText, ChromaSubsamplingText(Member.Info.Quality.ChromaSubsampling),
    ImageColorModeText(Member.Info.Quality.ColorMode)]);
end;

procedure TFormSession.FormCreate(Sender: TObject);
var
  ZoomCursor: HCURSOR;
begin
  FGroups := TList<TImageGroup>.Create;
  FChecked := TDictionary<string, Boolean>.Create;
  FMetricReferences := TDictionary<Integer, string>.Create;
  FErrors := TStringList.Create;
  FPreviewCards := TObjectList<TPreviewCard>.Create(True);
  FSelectedGroup := -1;
  FSelectedMember := -1;
  FPreviewMemberCount := 0;
  FSortColumn := -1;
  FSortAscending := True;
  SetSearchOptions(8, 3, True);
  ZoomCursor := LoadCursor(HInstance, PChar(ZoomInCursorResource));
  if ZoomCursor = 0 then
    ZoomCursor := LoadImage(0, PChar(TPath.GetFullPath(
      TPath.Combine('assets', 'cursors\zoom-in.cur'))), IMAGE_CURSOR, 0, 0,
      LR_LOADFROMFILE or LR_DEFAULTSIZE);
  FZoomCursorAvailable := ZoomCursor <> 0;
  if FZoomCursorAvailable then
    Screen.Cursors[crImageZoomIn] := ZoomCursor;
//  FTreeImages := TImageList.Create(nil);
//  FTreeImages.ColorDepth := cd32Bit;
//  FTreeImages.DrawingStyle := dsTransparent;
//  FTreeImages.Width := 20;
//  FTreeImages.Height := 20;
//  AddPngResource(FTreeImages, TreeResourceReference);
//  AddPngResource(FTreeImages, TreeResourceIdentical);
//  AddPngResource(FTreeImages, TreeResourceDifferent);
//  ResultsTree.Images := FTreeImages;
  ResultsTree.NodeDataSize := SizeOf(TNodeData);
  InitializeStatusBar;
  PreviewPanelResize(nil);
  RefreshActionStates;
  FStatusMessage := rsReady;
  UpdateCheckedSizeStatus;
  ActionNewSession.Visible := False;
  ActionLoadSession.Visible := False;
  ActionSaveSession.Visible := False;
  ActionAbout.Visible := False;
  ToolButtonNewSession.Visible := False;
  ToolButtonLooadSession.Visible := False;
  ToolButtonSaveSession.Visible := False;
  ToolButtonSep1.Visible := False;
  ToolButtonSep2.Visible := False;
end;

procedure TFormSession.FormShow(Sender: TObject);
begin
  // The initial DPI pass can recreate a runtime image-list handle and clear
  // its contents. Restore the three identity icons after that pass.
//  if FTreeImages.Count <> 3 then
//  begin
//    FTreeImages.Clear;
//    AddPngResource(FTreeImages, TreeResourceReference);
//    AddPngResource(FTreeImages, TreeResourceIdentical);
//    AddPngResource(FTreeImages, TreeResourceDifferent);
//  end;
//  ResultsTree.Images := FTreeImages;
end;

function TFormSession.CheckedFileBytes: Int64;
var
  G, M: Integer;
  IsChecked: Boolean;
begin
  Result := 0;
  if not Assigned(FGroups) or not Assigned(FChecked) then
    Exit;
  for G := 0 to FGroups.Count - 1 do
    for M := 0 to High(FGroups[G].Members) do
    begin
      IsChecked := False;
      if FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName, IsChecked) and IsChecked then
        Inc(Result, FGroups[G].Members[M].Info.Bytes);
    end;
end;

function TFormSession.CheckedFileCount: Integer;
var
  G, M: Integer;
  IsChecked: Boolean;
begin
  Result := 0;
  if not Assigned(FGroups) or not Assigned(FChecked) then
    Exit;
  for G := 0 to FGroups.Count - 1 do
    for M := 0 to High(FGroups[G].Members) do
    begin
      IsChecked := False;
      if FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName, IsChecked) and IsChecked then
        Inc(Result);
    end;
end;

procedure TFormSession.UpdateCheckedSizeStatus;
var
  Bytes: Int64;
  SizeText: string;
begin
  Bytes := CheckedFileBytes;
  if Bytes >= Int64(1024) * 1024 * 1024 then
    SizeText := FormatFloat(rsGiBNumberFormat, Bytes / (Int64(1024) * 1024 * 1024))
  else if Bytes >= Int64(1024) * 1024 then
    SizeText := FormatFloat(rsMBNumberFormat, Bytes / (Int64(1024) * 1024))
  else if Bytes >= 1024 then
    SizeText := FormatFloat(rsKBNumberFormat, Bytes / 1024)
  else
    SizeText := Format(rsByteCountFmt, [Bytes]);
  if Assigned(StatusBar) and (StatusBar.Panels.Count > 0) then
    StatusBar.Panels[0].Text := Format(rsSelectedStatusFmt,
      [FStatusMessage, CheckedFileCount, SizeText]);
end;

procedure TFormSession.SetStatusMessage(const Value: string);
begin
  FStatusMessage := Value;
  UpdateCheckedSizeStatus;
end;

procedure TFormSession.SetModified(Value: Boolean);
begin
  FModified := Value;
end;

procedure TFormSession.InitializeStatusBar;
var
  Panel: TStatusPanel;
begin
  StatusBar.Panels.Clear;

  Panel := StatusBar.Panels.Add;
  Panel.Width := MulDiv(400, CurrentPPI, 96);
  Panel.Text := rsReady;

  Panel := StatusBar.Panels.Add;
  Panel.Width := MulDiv(280, CurrentPPI, 96);
  Panel.Style := psOwnerDraw;

  StatusProgress := TProgressBar.Create(Self);
  StatusProgress.Parent := StatusBar;
  StatusProgress.Min := 0;
  StatusProgress.Max := 100;
  StatusProgress.Position := 0;
  StatusProgress.Smooth := True;
  StatusProgress.ParentShowHint := False;
  StatusProgress.ShowHint := True;
  StatusProgress.Visible := False;
  UpdateStatusBarLayout;
end;

procedure TFormSession.SetProgressVisible(Value: Boolean);
begin
  if not Assigned(StatusProgress) then
    Exit;
  StatusProgress.Visible := Value;
  UpdateStatusBarLayout;
end;

procedure TFormSession.UpdateStatusBarLayout;
var
  R: TRect;
  ProgressWidth, MinTextWidth, Padding, TotalWidth: Integer;
begin
  if not Assigned(StatusBar) or not Assigned(StatusProgress) or
    (StatusBar.Panels.Count < 2) or not StatusBar.HandleAllocated then
    Exit;

  TotalWidth := StatusBar.ClientWidth;
  if StatusProgress.Visible then
  begin
    MinTextWidth := MulDiv(240, CurrentPPI, 96);
    ProgressWidth := MulDiv(280, CurrentPPI, 96);
    if TotalWidth < MinTextWidth + ProgressWidth then
      ProgressWidth := Max(MulDiv(120, CurrentPPI, 96), TotalWidth div 3);
  end
  else
    ProgressWidth := 0;

  StatusBar.Panels[0].Width := Max(0, TotalWidth - ProgressWidth);
  StatusBar.Panels[1].Width := ProgressWidth;

  if not StatusProgress.Visible or
    (StatusBar.Perform(SB_GETRECT, 1, LPARAM(@R)) = 0) then
    Exit;
  Padding := Max(1, MulDiv(2, CurrentPPI, 96));
  InflateRect(R, -Padding, -Padding);
  StatusProgress.BoundsRect := R;
end;

procedure TFormSession.FormDestroy(Sender: TObject);
begin
  PollTimer.Enabled := False;
  if Assigned(FWorker) then
  begin
    FWorker.Terminate;
    FWorker.Free
  end;
  CloseFullSize(False);
  ResultsTree.Images := nil;
//  FTreeImages.Free;
  FPreviewCards.Free;
  FErrors.Free;
  FChecked.Free;
  FMetricReferences.Free;
  FGroups.Free;
end;

procedure TFormSession.FormResize(Sender: TObject);
var
  Available: Integer;
begin
  UpdateStatusBarLayout;
  if not Assigned(PreviewPanel) or not Assigned(SetupPanel) or
    not Assigned(StatusBar) or not Assigned(PreviewSplitter) then
    Exit;
  Available := ClientHeight - SetupPanel.Height - StatusBar.Height -
    PreviewSplitter.Height - MulDiv(150, CurrentPPI, 96);
  PreviewPanel.Height := Min(PreviewPanel.Height,
    Max(PreviewPanel.Constraints.MinHeight, Available));
end;

function TFormSession.HasSearchRoots: Boolean;
var
  Path: string;
begin
  Result := False;
  if not Assigned(PathsMemo) then
    Exit;
  for Path in PathsMemo.Lines do
    if Trim(Path) <> '' then
      Exit(True);
end;

function TFormSession.HasSessionContent: Boolean;
begin
  Result := HasSearchRoots or (FScannedFileCount > 0) or
    (Assigned(FGroups) and (FGroups.Count > 0)) or
    (Assigned(FErrors) and (FErrors.Count > 0)) or HasCheckedFiles;
end;

procedure TFormSession.RefreshActionStates;
var
  Busy, CanStop, HasGroups, HasSelection, HasRoots, ContextValid,
    ContextIsReference: Boolean;
  ContextGroup, ContextMember: Integer;
begin
  Busy := Assigned(FWorker) or FDeleting;
  HasRoots := HasSearchRoots;
  HasGroups := Assigned(FGroups) and (FGroups.Count > 0);
  HasSelection := HasCheckedFiles;
  CanStop := Assigned(FWorker) and (not FDeleting) and (not FStopping);
  ContextValid := ResolveSelectionContext(ContextGroup, ContextMember);
  ContextIsReference := ContextValid and
    FGroups[ContextGroup].Members[ContextMember].IsReference;

  PathsMemo.Enabled := not Busy;

  ActionBrowse.Enabled := not Busy;
  ActionOptions.Enabled := not Busy;
  ActionExportExcel.Enabled := (not Busy) and HasGroups;
  ActionAbout.Enabled := not FDeleting;
  ActionStartScan.Enabled := (not Busy) and HasRoots;
  ActionStopScan.Enabled := CanStop;
  ActionLoadSession.Enabled := not Busy;
  ActionSaveSession.Enabled := (not Busy) and HasSessionContent;
  ActionNewSession.Enabled := not Busy;
  ActionShowErrors.Enabled := (not Busy) and Assigned(FErrors) and
    (FErrors.Count > 0);
  ActionSelectionOptions.Enabled := (not Busy) and HasGroups;
  ActionDeleteSelected.Enabled := (not Busy) and HasSelection;
  ActionMoveSelected.Enabled := (not Busy) and HasSelection;

  ActionSetCurrentAsReference.Visible := ContextValid;
  ActionSetCurrentAsReference.Enabled := (not Busy) and ContextValid and
    not ContextIsReference;
  ActionNewSessionFromFolder.Visible := ContextValid;
  ActionNewSessionFromFolder.Enabled := False;
  if ContextValid and not FDeleting and (Application.MainForm is TFormMain) then
    ActionNewSessionFromFolder.Enabled := DirectoryExists(
      ExtractFilePath(FGroups[ContextGroup].Members[ContextMember].Info.FileName));
  NewSessionFromFolderItem.Visible := ContextValid;
  ActionOpenInExplorer.Visible := ContextValid;
  ActionOpenInExplorer.Enabled := (not Busy) and ContextValid and
    FileExists(FGroups[ContextGroup].Members[ContextMember].Info.FileName);
  SetCurrentAsReferenceItem.Visible := ContextValid;
  OpenInExplorerItem.Visible := ContextValid;
  ContextReferenceSeparatorItem.Visible := ContextValid;
  ActionReferenceHighestQuality.Enabled := (not Busy) and HasGroups;
  ActionReferenceHighestResolution.Enabled := (not Busy) and HasGroups;
  ActionReferenceLargestFile.Enabled := (not Busy) and HasGroups;
  ActionReferenceNewest.Enabled := (not Busy) and HasGroups;
  ActionReferenceLowestQuality.Enabled := (not Busy) and HasGroups;
  ActionReferenceLowestResolution.Enabled := (not Busy) and HasGroups;
  ActionReferenceSmallestFile.Enabled := (not Busy) and HasGroups;
  ActionReferenceOldest.Enabled := (not Busy) and HasGroups;
  ActionSelectAllExceptReference.Enabled := (not Busy) and HasGroups;
  ActionSelectIdenticalToReference.Enabled := (not Busy) and HasGroups;
  ActionSelectDifferentFromReference.Enabled := (not Busy) and HasGroups;
  ActionSelectOtherGroupsSameFolder.Visible := SelectionContextValid;
  ActionSelectOtherGroupsDifferentFolder.Visible := SelectionContextValid;
  ActionSelectOtherGroupsSameFolder.Enabled := (not Busy) and
    SelectionContextValid;
  ActionSelectOtherGroupsDifferentFolder.Enabled := (not Busy) and
    SelectionContextValid;
  ContextSelectionSeparatorItem.Visible := SelectionContextValid;
  ActionEnsureUnselected.Enabled := (not Busy) and HasGroups and HasSelection;
  ActionClearSelections.Enabled := (not Busy) and HasSelection;
end;

function TFormSession.HasCheckedFiles: Boolean;
var
  Pair: TPair<string, Boolean>;
begin
  Result := False;
  if not Assigned(FChecked) then
    Exit;
  for Pair in FChecked do
    if Pair.Value then
      Exit(True);
end;

procedure TFormSession.SetSearchOptions(AQuality, AThreadCount: Integer;
  ARecursive: Boolean; AIncludeSingletons: Boolean);
var
  NewQuality, NewThreadCount: Integer;
  Changed: Boolean;
begin
  NewQuality := EnsureRange(AQuality, MinComparisonQuality,
    MaxComparisonQuality);
  NewThreadCount := EnsureRange(AThreadCount, 1, 64);
  Changed := (FComparisonQuality <> NewQuality) or
    (FThreadCount <> NewThreadCount) or
    (FRecursiveSearch <> ARecursive) or (FIncludeSingletons <> AIncludeSingletons);
  FComparisonQuality := NewQuality;
  FThreadCount := NewThreadCount;
  FRecursiveSearch := ARecursive;
  FIncludeSingletons := AIncludeSingletons;
  if Changed then
    SetModified(True);
end;

procedure TFormSession.ActionOptionsExecute(Sender: TObject);
var
  Quality, ThreadCount: Integer;
  Recursive, IncludeSingletons: Boolean;
begin
  Quality := FComparisonQuality;
  ThreadCount := FThreadCount;
  Recursive := FRecursiveSearch;
  IncludeSingletons := FIncludeSingletons;
  if TOptionsForm.Execute(Self, Quality, ThreadCount, Recursive, IncludeSingletons) then
  begin
    SetSearchOptions(Quality, ThreadCount, Recursive, IncludeSingletons);
    SetStatusMessage(rsOptionsUpdated);
  end;
end;

procedure TFormSession.ExportResultsToFile(const FileName: string);
begin
  CaptureChecks;
  ExportGroupsToXlsx(FileName, FGroups.ToArray, FChecked);
end;

procedure TFormSession.ActionExportExcelExecute(Sender: TObject);
begin
  if not ExportExcelDialog.Execute(Handle) then
    Exit;
  try
    ExportResultsToFile(ExportExcelDialog.FileName);
    SetStatusMessage(Format(rsExcelExportCompletedFmt,
      [ExportExcelDialog.FileName]));
  except
    on E: Exception do
      MessageDlg(Format(rsExcelExportErrorFmt, [sLineBreak, E.Message]),
        mtError, [mbOK], 0);
  end;
end;

procedure TFormSession.ActionAboutExecute(Sender: TObject);
begin
  TFormAbout.Execute(Self);
end;

procedure TFormSession.ActionBrowseExecute(Sender: TObject);
var
  Dialog: TFileOpenDialog;
  Path, ExistingPath, NormalizedPath: string;
  AlreadyPresent: Boolean;

  function NormalizeFolder(const Value: string): string;
  var
    Root: string;
  begin
    Result := TPath.GetFullPath(Trim(Value));
    Root := TPath.GetPathRoot(Result);
    if not SameText(Result, Root) then
      Result := ExcludeTrailingPathDelimiter(Result);
  end;

begin
  Dialog := TFileOpenDialog.Create(Self);
  try
    Dialog.Title := rsAddFolderTitle;
    Dialog.Options := [fdoPickFolders, fdoAllowMultiSelect,
      fdoPathMustExist, fdoForceFileSystem];
    if Dialog.Execute(Handle) then
    begin
      PathsMemo.Lines.BeginUpdate;
      try
        for Path in Dialog.Files do
        begin
          NormalizedPath := NormalizeFolder(Path);
          AlreadyPresent := False;
          for ExistingPath in PathsMemo.Lines do
            if (Trim(ExistingPath) <> '') and
              SameText(NormalizeFolder(ExistingPath), NormalizedPath) then
            begin
              AlreadyPresent := True;
              Break;
            end;
          if not AlreadyPresent then
            PathsMemo.Lines.Add(NormalizedPath);
        end;
      finally
        PathsMemo.Lines.EndUpdate;
      end;
      RefreshActionStates;
    end;
  finally
    Dialog.Free;
  end;
end;


procedure TFormSession.PathsMemoChange(Sender: TObject);
begin
  SetModified(True);
  RefreshActionStates;
end;

procedure TFormSession.ActionStartScanExecute(Sender: TObject);
var
  Roots: TList<string>;
  Path, Root: string;
  DistanceLimit: Integer;
begin
  if Assigned(FWorker) then
    Exit;
  Roots := TList<string>.Create;
  try
    try
      for Path in PathsMemo.Lines do
        if Trim(Path) <> '' then
        begin
          Root := TPath.GetFullPath(Trim(Path));
          if not DirectoryExists(Root) then
            raise EArgumentException.CreateFmt(rsFolderNotFoundFmt, [Root]);
          Roots.Add(Root);
        end;
      if Roots.Count = 0 then
        raise EArgumentException.Create(rsFolderRequired);
      DistanceLimit := ComparisonQualityToDistance(FComparisonQuality);
      FWorker := TImageScan.Create(Roots.ToArray, FRecursiveSearch, DistanceLimit, DefaultMaxRGBError,
        FThreadCount, FIncludeSingletons);
    except
      on E: Exception do
      begin
        MessageDlg(E.Message, mtError, [mbOK], 0);
        Exit
      end;
    end;
    SetModified(True);
    FGroups.Clear;
    FMetricReferences.Clear;
    FScannedFileCount := 0;
    FChecked.Clear;
    FErrors.Clear;
    ResultsTree.Clear;
    FSelectedGroup := -1;
    FSelectedMember := -1;
    ClearPreviews;
    ResultsLabel.Caption := rsScanInProgress;
    SetStatusMessage(Format(rsStartingScanFmt, [FThreadCount]));
    StatusProgress.Style := pbstMarquee;
    StatusProgress.Position := 0;
    SetProgressVisible(True);
    RefreshActionStates;
    FWorker.Start;
    PollTimer.Enabled := True;
  finally
    Roots.Free;
  end;
end;

procedure TFormSession.ActionStopScanExecute(Sender: TObject);
begin
  if Assigned(FWorker) and not FStopping then
  begin
    FStopping := True;
    FWorker.Terminate;
    RefreshActionStates;
    SetStatusMessage(rsStoppingScan);
  end;
end;

procedure TFormSession.CaptureChecks;
var
  Node: PVirtualNode;
  Data: PNodeData;
begin
  if FUpdatingTree then
    Exit;
  Node := ResultsTree.GetFirst;
  while Assigned(Node) do
  begin
    Data := ResultsTree.GetNodeData(Node);
    if Assigned(Data) and (Data.Kind = nkFile) and (Data.GroupIndex < FGroups.Count) and (Data.MemberIndex < Length(FGroups[Data.GroupIndex].Members)) then
      FChecked.AddOrSetValue(FGroups[Data.GroupIndex].Members[Data.MemberIndex].Info.FileName, ResultsTree.CheckState[Node] = csCheckedNormal);
    Node := ResultsTree.GetNext(Node);
  end;
end;

function TFormSession.FocusedFileName: string;
var
  Data: PNodeData;
begin
  Result := '';
  if not Assigned(ResultsTree.FocusedNode) then
    Exit;
  Data := ResultsTree.GetNodeData(ResultsTree.FocusedNode);
  if Assigned(Data) and (Data.Kind = nkFile) and (Data.GroupIndex >= 0) and (Data.GroupIndex < FGroups.Count) and (Data.MemberIndex >= 0) and (Data.MemberIndex
    < Length(FGroups[Data.GroupIndex].Members)) then
    Result := FGroups[Data.GroupIndex].Members[Data.MemberIndex].Info.FileName;
end;

procedure TFormSession.BuildTree(CaptureCurrent: Boolean; const FocusFileOverride: string);
var
  G, M: Integer;
  GroupNode, FileNode, FocusNode: PVirtualNode;
  Data: PNodeData;
  FocusFile: string;
  IsChecked: Boolean;
begin
  FocusFile := FocusFileOverride;
  if FocusFile = '' then
    FocusFile := FocusedFileName;
  if CaptureCurrent then
    CaptureChecks;
  FUpdatingTree := True;
  ResultsTree.BeginUpdate;
  try
    ResultsTree.Clear;
    FocusNode := nil;
    for G := 0 to FGroups.Count - 1 do
    begin
      GroupNode := ResultsTree.AddChild(nil);
      Data := ResultsTree.GetNodeData(GroupNode);
      Data.Kind := nkGroup;
      Data.GroupIndex := G;
      Data.MemberIndex := -1;
      ResultsTree.CheckType[GroupNode] := ctNone;
      for M := 0 to High(FGroups[G].Members) do
      begin
        FileNode := ResultsTree.AddChild(GroupNode);
        Data := ResultsTree.GetNodeData(FileNode);
        Data.Kind := nkFile;
        Data.GroupIndex := G;
        Data.MemberIndex := M;
        ResultsTree.CheckType[FileNode] := ctCheckBox;
        IsChecked := False;
        FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName, IsChecked);
        if IsChecked then
          ResultsTree.CheckState[FileNode] := csCheckedNormal
        else
          ResultsTree.CheckState[FileNode] := csUncheckedNormal;
        if (FocusFile <> '') and SameText(FocusFile, FGroups[G].Members[M].Info.FileName) then
          FocusNode := FileNode;
        if FocusNode = nil then
          FocusNode := FileNode;
      end;
      ResultsTree.Expanded[GroupNode] := True;
    end;
    if Assigned(FocusNode) then
    begin
      ResultsTree.FocusedNode := FocusNode;
      ResultsTree.Selected[FocusNode] := True;
    end;
  finally
    ResultsTree.EndUpdate;
    FUpdatingTree := False;
  end;
  RefreshActionStates;
  UpdateCheckedSizeStatus;
end;

procedure TFormSession.PollTimerTimer(Sender: TObject);
var
  Update: TScanUpdate;
  Group: TImageGroup;
  I, Found: Integer;
  Phase, FocusFile: string;
begin
  if not Assigned(FWorker) then
    Exit;
  Update := FWorker.Drain;
  FScannedFileCount := Update.Scanned;
  if Update.TotalImages > 0 then
  begin
    StatusProgress.Style := pbstNormal;
    StatusProgress.Max := Update.TotalImages;
    StatusProgress.Position := Min(Update.Scanned, Update.TotalImages);
    StatusProgress.Hint := Format(rsProgressImagesFmt, [Update.Scanned, Update.TotalImages]);
  end;
  FErrors.AddStrings(Update.Errors);
  RefreshActionStates;
  if Length(Update.Groups) > 0 then
  begin
    FocusFile := FocusedFileName;
    CaptureChecks;
    for Group in Update.Groups do
    begin
      Found := -1;
      for I := 0 to FGroups.Count - 1 do
        if FGroups[I].Id = Group.Id then
        begin
          Found := I;
          Break
        end;
      if Found < 0 then
        FGroups.Add(Group)
      else
        FGroups[Found] := Group;
    end;
    if FSortColumn = 0 then
      SortGroupsBySize(FSortAscending)
    else if FSortColumn > 0 then
      SortMembers(FSortColumn, FSortAscending);
    BuildTree(False, FocusFile);
  end;
  if Update.Done then
  begin
    PollTimer.Enabled := False;
    FreeAndNil(FWorker);
    RefreshActionStates;
    StatusProgress.Style := pbstNormal;
    SetProgressVisible(False);
    if (Update.FatalError = '') and not Update.Cancelled then
    begin
      if Update.TotalImages > 0 then
      begin
        StatusProgress.Max := Update.TotalImages;
        StatusProgress.Position := Update.TotalImages;
      end
      else
      begin
        StatusProgress.Max := 100;
        StatusProgress.Position := 100;
      end;
    end;
    if Update.FatalError <> '' then
      Phase := rsScanFailed
    else if Update.Cancelled then
      Phase := rsScanCancelled
    else if Update.ErrorCount > 0 then
      Phase := rsScanCompletedWithErrors
    else
      Phase := rsScanCompleted;
    if FGroups.Count = 0 then
      ResultsLabel.Caption := Format(rsNoGroupsFoundFmt, [Phase])
    else
      ResultsLabel.Caption := Format(rsGroupsFoundFmt, [Phase, FGroups.Count, Update.GroupedFiles]);
    SetStatusMessage(Format(rsScanSummaryFmt, [Phase, Update.Scanned,
      FGroups.Count, Update.GroupedFiles, Update.ErrorCount]));
    if not FClosePending and Assigned(ResultsTree.FocusedNode) then
      ShowNode(ResultsTree.FocusedNode);
    if FClosePending then
      Close;
  end
  else if ActionStopScan.Enabled then
  begin
    if Update.TotalImages > 0 then
      SetStatusMessage(Format(rsScanProgressFmt, [FWorker.ThreadCount, Update.Scanned, Update.TotalImages, FGroups.Count, Update.ErrorCount, Update.CurrentFile]))
    else
      SetStatusMessage(Format(rsScanProgressCalculatingFmt, [FWorker.ThreadCount, Update.Scanned, FGroups.Count, Update.ErrorCount, Update.CurrentFile]));
  end;
end;

procedure TFormSession.ResultsTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Data: PNodeData;
  G: TImageGroup;
  M: TGroupMember;
begin
  CellText := '';
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) or (Data.GroupIndex < 0) or (Data.GroupIndex >= FGroups.Count) then
    Exit;
  G := FGroups[Data.GroupIndex];
  if Data.Kind = nkGroup then
  begin
    if Column = 0 then
      CellText := Format(rsGroupCaptionFmt, [Data.GroupIndex + 1, Length(G.Members)]);
    Exit;
  end;
  if (Data.MemberIndex < 0) or (Data.MemberIndex >= Length(G.Members)) then
    Exit;
  M := G.Members[Data.MemberIndex];
  case Column of
    0:
      CellText := M.Info.FileName;
    1:
      CellText := Dimensions(M.Info);
    2:
      CellText := FormatFloat('#,##0', M.Info.Bytes);

    3:
      CellText := FormatDateTime(rsDateTimeFormat, M.Info.Modified);
    4:
      CellText := FormatFloat('0.0', M.QualityScore);
  end;
end;

procedure TFormSession.ResultsTreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var
  ImageIndex: System.UITypes.TImageIndex);
var
  Data: PNodeData;
  Member: TGroupMember;
  ReferenceIndex: Integer;
begin
  ImageIndex := -1;
  Ghosted := False;
  if (Column <> 0) or not (Kind in [ikNormal, ikSelected]) or
    not Assigned(ResultsTree.Images) then
    Exit;
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) or (Data.Kind <> nkFile) or
    (Data.GroupIndex < 0) or (Data.GroupIndex >= FGroups.Count) or
    (Data.MemberIndex < 0) or
    (Data.MemberIndex >= Length(FGroups[Data.GroupIndex].Members)) then
    Exit;
  Member := FGroups[Data.GroupIndex].Members[Data.MemberIndex];
  ReferenceIndex := ReferenceMemberIndex(FGroups[Data.GroupIndex]);
  if Member.IsReference then
    ImageIndex := ResultsTree.Images.GetIndexByName('file-reference')
  else if (ReferenceIndex >= 0) and (Member.ExactClass =
    FGroups[Data.GroupIndex].Members[ReferenceIndex].ExactClass) then
    ImageIndex := ResultsTree.Images.GetIndexByName('file-identical')
  else
    ImageIndex := ResultsTree.Images.GetIndexByName('file-different');
end;

procedure TFormSession.SortGroupsBySize(Ascending: Boolean);
var
  I, J: Integer;
  Item: TImageGroup;
  Move: Boolean;
begin
  for I := 1 to FGroups.Count - 1 do
  begin
    Item := FGroups[I];
    J := I - 1;
    repeat
      if J < 0 then
        Break;
      if Ascending then
        Move := Length(FGroups[J].Members) > Length(Item.Members)
      else
        Move := Length(FGroups[J].Members) < Length(Item.Members);
      if not Move then
        Break;
      FGroups[J + 1] := FGroups[J];
      Dec(J);
    until False;
    FGroups[J + 1] := Item;
  end;
end;

procedure TFormSession.SortMembers(Column: Integer; Ascending: Boolean);
var
  G, I, J, Comparison: Integer;
  Item: TGroupMember;
  Group: TImageGroup;
  LeftPixels, RightPixels: Int64;
begin
  for G := 0 to FGroups.Count - 1 do
  begin
    Group := FGroups[G];
    for I := 1 to High(Group.Members) do
    begin
      Item := Group.Members[I];
      J := I - 1;
      while J >= 0 do
      begin
        Comparison := 0;
        case Column of
          1:
            begin
              LeftPixels := Int64(Group.Members[J].Info.Width) * Group.Members[J].Info.Height;
              RightPixels := Int64(Item.Info.Width) * Item.Info.Height;
              if LeftPixels < RightPixels then
                Comparison := -1
              else if LeftPixels > RightPixels then
                Comparison := 1;
            end;
          2:
            if Group.Members[J].Info.Bytes < Item.Info.Bytes then
              Comparison := -1
            else if Group.Members[J].Info.Bytes > Item.Info.Bytes then
              Comparison := 1;
          3:
            if Group.Members[J].Info.Modified < Item.Info.Modified then
              Comparison := -1
            else if Group.Members[J].Info.Modified > Item.Info.Modified then
              Comparison := 1;
          4:
            if Group.Members[J].QualityScore < Item.QualityScore then
              Comparison := -1
            else if Group.Members[J].QualityScore > Item.QualityScore then
              Comparison := 1;
        end;
        if (Ascending and (Comparison <= 0)) or ((not Ascending) and (Comparison >= 0)) then
          Break;
        Group.Members[J + 1] := Group.Members[J];
        Dec(J);
      end;
      Group.Members[J + 1] := Item;
    end;
    FGroups[G] := Group;
  end;
end;

procedure TFormSession.ResultsTreeHeaderClick(Sender: TVTHeader; const HitInfo: TVTHeaderHitInfo);
var
  FocusFile: string;
begin
  if (HitInfo.Column < 0) or (HitInfo.Column >= ResultsTree.Header.Columns.Count) then
    Exit;
  FocusFile := FocusedFileName;
  CaptureChecks;
  if FSortColumn = HitInfo.Column then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := HitInfo.Column;
    FSortAscending := True;
  end;
  ResultsTree.Header.SortColumn := FSortColumn;
  if FSortAscending then
    ResultsTree.Header.SortDirection := sdAscending
  else
    ResultsTree.Header.SortDirection := sdDescending;
  if FSortColumn = 0 then
    SortGroupsBySize(FSortAscending)
  else
    SortMembers(FSortColumn, FSortAscending);
  BuildTree(False, FocusFile);
end;

function TFormSession.ResolveSelectionContext(out GroupIndex,
  MemberIndex: Integer): Boolean;
var
  G, M: Integer;
begin
  GroupIndex := -1;
  MemberIndex := -1;
  Result := Assigned(FGroups) and (FSelectionContextFileName <> '');
  if not Result then
    Exit;
  for G := 0 to FGroups.Count - 1 do
    for M := 0 to High(FGroups[G].Members) do
      if SameText(FGroups[G].Members[M].Info.FileName,
        FSelectionContextFileName) then
      begin
        GroupIndex := G;
        MemberIndex := M;
        Exit(True);
      end;
  Result := False;
end;

function TFormSession.SelectionContextValid: Boolean;
var
  GroupIndex, MemberIndex: Integer;
begin
  Result := ResolveSelectionContext(GroupIndex, MemberIndex);
end;

procedure TFormSession.SelectionMenuPopup(Sender: TObject);
begin
  RefreshActionStates;
end;

procedure TFormSession.ShowSelectionMenuAt(const ScreenPoint: TPoint;
  ContextGroup, ContextMember: Integer);
begin
  FSelectionContextFileName := '';
  if Assigned(FGroups) and (ContextGroup >= 0) and
    (ContextGroup < FGroups.Count) and (ContextMember >= 0) and
    (ContextMember < Length(FGroups[ContextGroup].Members)) then
    FSelectionContextFileName :=
      FGroups[ContextGroup].Members[ContextMember].Info.FileName;
  RefreshActionStates;
  SelectionMenu.Popup(ScreenPoint.X, ScreenPoint.Y);
end;

procedure TFormSession.ActionSelectionOptionsExecute(Sender: TObject);
var
  P: TPoint;
begin
  P := ToolButtonSelectionOptions.ClientToScreen(
    Point(0, ToolButtonSelectionOptions.Height));
  ShowSelectionMenuAt(P, -1, -1);
end;

procedure TFormSession.ResultsTreeMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
var
  CurrentNode, GroupNode, TargetNode: PVirtualNode;
  Data: PNodeData;
begin
  Handled := False;
  if not (ssShift in Shift) or (WheelDelta = 0) or FUpdatingTree then
    Exit;

  CurrentNode := ResultsTree.FocusedNode;
  if not Assigned(CurrentNode) then
    Exit;
  Data := ResultsTree.GetNodeData(CurrentNode);
  if not Assigned(Data) then
    Exit;
  if Data.Kind = nkFile then
    GroupNode := CurrentNode.Parent
  else
    GroupNode := CurrentNode;
  if not Assigned(GroupNode) or (GroupNode = ResultsTree.RootNode) then
    Exit;

  if WheelDelta < 0 then
    TargetNode := ResultsTree.GetNextSibling(GroupNode)
  else
    TargetNode := ResultsTree.GetPreviousSibling(GroupNode);
  Handled := True;
  if not Assigned(TargetNode) then
    Exit;

  ResultsTree.FocusedNode := TargetNode;
  ResultsTree.Selected[TargetNode] := True;
  ResultsTree.ScrollIntoView(TargetNode, False);
end;

procedure TFormSession.ResultsTreeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Node: PVirtualNode;
  Data: PNodeData;
  P: TPoint;
begin
  if (Button <> mbRight) or Assigned(FWorker) or FDeleting then
    Exit;
  Node := ResultsTree.GetNodeAt(X, Y);
  if not Assigned(Node) then
    Exit;
  Data := ResultsTree.GetNodeData(Node);
  if not Assigned(Data) or (Data.Kind <> nkFile) then
    Exit;
  ResultsTree.ClearSelection;
  ResultsTree.FocusedNode := Node;
  ResultsTree.Selected[Node] := True;
  P := ResultsTree.ClientToScreen(Point(X, Y));
  ShowSelectionMenuAt(P, Data.GroupIndex, Data.MemberIndex);
end;

procedure TFormSession.RemoveRecycledFiles(const FileNames: TArray<string>);
var
  Removed: TDictionary<string, Boolean>;
  ClassCounts: TDictionary<Integer, Integer>;
  Members: TList<TGroupMember>;
  Group: TImageGroup;
  Member: TGroupMember;
  G, I, Count: Integer;
  FileName, FocusFile: string;
  Changed, ReferenceRemoved: Boolean;
begin
  if Length(FileNames) = 0 then
    Exit;
  FocusFile := FocusedFileName;
  Removed := TDictionary<string, Boolean>.Create;
  ClassCounts := TDictionary<Integer, Integer>.Create;
  Members := TList<TGroupMember>.Create;
  try
    for FileName in FileNames do
    begin
      Removed.AddOrSetValue(FileName, True);
      FChecked.Remove(FileName);
    end;
    for G := FGroups.Count - 1 downto 0 do
    begin
      Group := FGroups[G];
      Members.Clear;
      Changed := False;
      ReferenceRemoved := False;
      for Member in Group.Members do
        if Removed.ContainsKey(Member.Info.FileName) then
        begin
          Changed := True;
          ReferenceRemoved := ReferenceRemoved or Member.IsReference;
        end
        else
          Members.Add(Member);
      if not Changed then
        Continue;
      if Members.Count = 0 then
      begin
        FMetricReferences.Remove(Group.Id);
        FGroups.Delete(G);
        Continue;
      end;
      Group.Members := Members.ToArray;
      CalculateGroupQuality(Group);

      // ExactClass was established during the scan. Removing members cannot
      // change the equivalence of the remaining files, so no image decoding
      // or pairwise comparison is needed here.
      ClassCounts.Clear;
      for Member in Group.Members do
      begin
        Count := 0;
        ClassCounts.TryGetValue(Member.ExactClass, Count);
        ClassCounts.AddOrSetValue(Member.ExactClass, Count + 1);
      end;
      for I := 0 to High(Group.Members) do
      begin
        Count := 0;
        ClassCounts.TryGetValue(Group.Members[I].ExactClass, Count);
        Group.Members[I].HasIdenticalPeer := Count > 1;
        if ReferenceRemoved then
          Group.Members[I].Metrics := Default(TComparison);
      end;
      if ReferenceRemoved then
        FMetricReferences.Remove(Group.Id);
      FGroups[G] := Group;
    end;
    if FSortColumn = 0 then
      SortGroupsBySize(FSortAscending)
    else if FSortColumn > 0 then
      SortMembers(FSortColumn, FSortAscending);
    ClearPreviews;
    BuildTree(False, FocusFile);
    SetModified(True);
  finally
    Members.Free;
    ClassCounts.Free;
    Removed.Free;
  end;
end;

function TFormSession.SelectedFiles: TArray<string>;
var
  Selected: TList<string>;
  Group: TImageGroup;
  Member: TGroupMember;
  IsChecked: Boolean;
begin
  CaptureChecks;
  Selected := TList<string>.Create;
  try
    for Group in FGroups do
      for Member in Group.Members do
        if FChecked.TryGetValue(Member.Info.FileName, IsChecked) and IsChecked and
          (Selected.IndexOf(Member.Info.FileName) < 0) then
          Selected.Add(Member.Info.FileName);
    Result := Selected.ToArray;
  finally
    Selected.Free;
  end;
end;

procedure TFormSession.UpdateMovedFiles(
  const MovedFiles: TDictionary<string, string>);
var
  Group: TImageGroup;
  G, M: Integer;
  OldName, NewName, FocusFile: string;
begin
  FocusFile := FocusedFileName;
  for G := 0 to FGroups.Count - 1 do
  begin
    Group := FGroups[G];
    for M := 0 to High(Group.Members) do
    begin
      OldName := Group.Members[M].Info.FileName;
      if MovedFiles.TryGetValue(OldName, NewName) then
      begin
        Group.Members[M].Info.FileName := NewName;
        FChecked.Remove(OldName);
        if SameText(FocusFile, OldName) then
          FocusFile := NewName;
      end;
    end;
    FGroups[G] := Group;
  end;
  ClearPreviews;
  BuildTree(False, FocusFile);
  if MovedFiles.Count > 0 then
    SetModified(True);
end;

procedure TFormSession.ActionDeleteSelectedExecute(Sender: TObject);
var
  Selected, Recycled: TList<string>;
  FileName, ErrorText: string;
  Failures: Integer;
begin
  if Assigned(FWorker) or FDeleting then
    Exit;
  Selected := TList<string>.Create;
  Recycled := TList<string>.Create;
  try
    Selected.AddRange(SelectedFiles);
    if Selected.Count = 0 then
      Exit;
    if MessageDlg(Format(rsRecycleConfirmFmt, [Selected.Count]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    FDeleting := True;
    RefreshActionStates;
    ResultsTree.Enabled := False;
    CloseFullSize(False);
    Failures := 0;
    try
      for FileName in Selected do
      begin
        SetStatusMessage(Format(rsMovingToRecycleBinFmt, [FileName]));
        if RecycleFile(Handle, FileName, ErrorText) then
          Recycled.Add(FileName)
        else
        begin
          Inc(Failures);
          FErrors.Add(FileName + ': ' + ErrorText);
        end;
      end;
      RemoveRecycledFiles(Recycled.ToArray);
      ResultsLabel.Caption := Format(rsResultsUpdatedFmt, [FGroups.Count, Integer(ResultsTree.TotalCount) - FGroups.Count]);
      SetStatusMessage(Format(rsRecycleSummaryFmt, [Recycled.Count, Failures]));
      if Failures > 0 then
        MessageDlg(Format(rsRecycleFailuresFmt, [Failures, sLineBreak]),
          mtWarning, [mbOK], 0);
    finally
      FDeleting := False;
      ResultsTree.Enabled := True;
      RefreshActionStates;
    end;
  finally
    Recycled.Free;
    Selected.Free;
  end;
end;

procedure TFormSession.ActionMoveSelectedExecute(Sender: TObject);
var
  Selected: TArray<string>;
  MovedFiles: TDictionary<string, string>;
  SourceFile, DestinationFile, ErrorText, DestinationRoot, SearchRoot: string;
  Failures: Integer;
begin
  if Assigned(FWorker) or FDeleting then
    Exit;
  Selected := SelectedFiles;
  if Length(Selected) = 0 then
    Exit;
  MoveFolderDialog.Title := rsMoveFolderDialogTitle;
  if not MoveFolderDialog.Execute(Handle) then
    Exit;
  DestinationRoot := MoveFolderDialog.FileName;
  if MessageDlg(Format(rsMoveConfirmFmt,
    [Length(Selected), DestinationRoot]), mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then
    Exit;

  SearchRoot := CommonSearchRoot(PathsMemo.Lines);
  MovedFiles := TDictionary<string, string>.Create;
  FDeleting := True;
  RefreshActionStates;
  ResultsTree.Enabled := False;
  CloseFullSize(False);
  Failures := 0;
  try
    for SourceFile in Selected do
    begin
      SetStatusMessage(Format(rsMovingToFolderFmt, [SourceFile]));
      if MoveFilePreservingStructure(SourceFile, SearchRoot,
        DestinationRoot, DestinationFile, ErrorText) then
        MovedFiles.Add(SourceFile, DestinationFile)
      else
      begin
        Inc(Failures);
        FErrors.Add(SourceFile + ': ' + ErrorText);
      end;
    end;
    UpdateMovedFiles(MovedFiles);
    ResultsLabel.Caption := Format(rsResultsUpdatedFmt,
      [FGroups.Count, Integer(ResultsTree.TotalCount) - FGroups.Count]);
    SetStatusMessage(Format(rsMoveSummaryFmt,
      [MovedFiles.Count, Failures]));
    if Failures > 0 then
      MessageDlg(Format(rsMoveFailuresFmt, [Failures, sLineBreak]),
        mtWarning, [mbOK], 0);
  finally
    FDeleting := False;
    ResultsTree.Enabled := True;
    MovedFiles.Free;
    RefreshActionStates;
  end;
end;

procedure TFormSession.ActionLoadSessionExecute(Sender: TObject);
begin
  if not OpenSessionDialog.Execute(Handle) then
    Exit;
  try
    LoadDocument(OpenSessionDialog.FileName);
  except
    on E: Exception do
      MessageDlg(Format(rsSessionLoadErrorFmt, [sLineBreak, E.Message]), mtError, [mbOK], 0);
  end;
end;

procedure TFormSession.ActionNewSessionExecute(Sender: TObject);
begin
  if Assigned(FWorker) then
    Exit;
  CloseFullSize(False);
  PathsMemo.Clear;
  SetSearchOptions(8, 3, True);
  FGroups.Clear;
  FMetricReferences.Clear;
  FScannedFileCount := 0;
  FChecked.Clear;
  FErrors.Clear;
  ResultsTree.Clear;
  ClearPreviews;
  ResultsLabel.Caption := rsInitialResultsCaption;
  SetModified(True);
  SetStatusMessage(rsSessionCleared);
  StatusProgress.Style := pbstNormal;
  StatusProgress.Max := 100;
  StatusProgress.Position := 0;
  SetProgressVisible(False);
  RefreshActionStates;
end;

procedure TFormSession.ActionSaveSessionExecute(Sender: TObject);
begin
  try
    if SaveSessionDialog.Execute(Handle) then
    begin
      SaveDocument(SaveSessionDialog.FileName);
    end;
  except
    on E: Exception do
      MessageDlg(Format(rsSessionSaveErrorFmt, [sLineBreak, E.Message]), mtError, [mbOK], 0);
  end;
end;

procedure TFormSession.RecalculateReferenceMetrics(var Group: TImageGroup);
var
  ReferenceSignature, MemberSignature: TImageSignature;
  ReferenceIndex, M: Integer;
begin
  ReferenceIndex := ReferenceMemberIndex(Group);
  if ReferenceIndex < 0 then
    Exit;
  for M := 0 to High(Group.Members) do
    Group.Members[M].Metrics := Default(TComparison);
  try
    ReferenceSignature := LoadSignature(
      Group.Members[ReferenceIndex].Info.FileName);
  except
    on E: Exception do
    begin
      FErrors.Add(Group.Members[ReferenceIndex].Info.FileName + ': ' +
        E.Message);
      Exit;
    end;
  end;
  for M := 0 to High(Group.Members) do
  begin
    if M = ReferenceIndex then
    begin
      Group.Members[M].Metrics.Structural := 1;
      Group.Members[M].Metrics.WorstStructural := 1;
      Continue;
    end;
    try
      MemberSignature := LoadSignature(Group.Members[M].Info.FileName);
      StructuralMetrics(ReferenceSignature, MemberSignature,
        Group.Members[M].Metrics);
    except
      on E: Exception do
        FErrors.Add(Group.Members[M].Info.FileName + ': ' + E.Message);
    end;
  end;
end;

procedure TFormSession.SetReferenceFile(const FileName: string);
var
  G, M, TargetMember: Integer;
  Group: TImageGroup;
  FocusFile: string;
begin
  if Assigned(FWorker) or FDeleting or (FileName = '') then
    Exit;
  CaptureChecks;
  FocusFile := FileName;
  for G := 0 to FGroups.Count - 1 do
  begin
    Group := FGroups[G];
    TargetMember := -1;
    for M := 0 to High(Group.Members) do
      if SameText(Group.Members[M].Info.FileName, FileName) then
      begin
        TargetMember := M;
        Break;
      end;
    if TargetMember < 0 then
      Continue;
    for M := 0 to High(Group.Members) do
      Group.Members[M].IsReference := M = TargetMember;
    FGroups[G] := Group;
    FMetricReferences.Remove(Group.Id);
    ClearPreviews;
    BuildTree(False, FocusFile);
    if Assigned(ResultsTree.FocusedNode) then
      ShowNode(ResultsTree.FocusedNode);
    SetModified(True);
    SetStatusMessage(Format(rsReferenceFileUpdatedFmt, [FileName]));
    Exit;
  end;
end;

procedure TFormSession.ActionSetCurrentAsReferenceExecute(Sender: TObject);
var
  GroupIndex, MemberIndex: Integer;
  FileName: string;
begin
  try
    if not ResolveSelectionContext(GroupIndex, MemberIndex) then
      Exit;
    FileName := FGroups[GroupIndex].Members[MemberIndex].Info.FileName;
    SetReferenceFile(FileName);
  finally
    FSelectionContextFileName := '';
    RefreshActionStates;
  end;
end;

function NativeSHOpenFolderAndSelectItems(pidlFolder: PItemIDList;
  cidl: UINT; apidl: Pointer; dwFlags: DWORD): HRESULT; stdcall;
  external 'shell32.dll' name 'SHOpenFolderAndSelectItems';

function OpenFolderAndSelectFile(const FileName: string): HRESULT;
var
  FullPidl, FolderPidl, ChildPidl: PItemIDList;
  ChildPidls: array[0..0] of PItemIDList;
  InitResult: HRESULT;
  UninitializeCOM: Boolean;
begin
  InitResult := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  UninitializeCOM := Succeeded(InitResult);
  if Failed(InitResult) and (InitResult <> RPC_E_CHANGED_MODE) then
    Exit(InitResult);
  FullPidl := nil;
  FolderPidl := nil;
  ChildPidl := nil;
  try
    FullPidl := ILCreateFromPath(PChar(FileName));
    if not Assigned(FullPidl) then
      Exit(E_FAIL);
    FolderPidl := ILClone(FullPidl);
    ChildPidl := ILClone(ILFindLastID(FullPidl));
    if not Assigned(FolderPidl) or not Assigned(ChildPidl) then
      Exit(E_OUTOFMEMORY);
    if not ILRemoveLastID(FolderPidl) then
      Exit(E_FAIL);
    ChildPidls[0] := ChildPidl;
    Result := NativeSHOpenFolderAndSelectItems(FolderPidl, Length(ChildPidls),
      @ChildPidls[0], 0);
  finally
    if Assigned(ChildPidl) then
      ILFree(ChildPidl);
    if Assigned(FolderPidl) then
      ILFree(FolderPidl);
    if Assigned(FullPidl) then
      ILFree(FullPidl);
    if UninitializeCOM then
      CoUninitialize;
  end;
end;

procedure TFormSession.ActionNewSessionFromFolderExecute(Sender: TObject);
var
  GroupIndex, MemberIndex: Integer;
  Folder: string;
  Session: TFormSession;
begin
  try
    if FDeleting or not ResolveSelectionContext(GroupIndex, MemberIndex) then
      Exit;
    Folder := ExtractFilePath(
      ExpandFileName(FGroups[GroupIndex].Members[MemberIndex].Info.FileName));
    if not DirectoryExists(Folder) then
    begin
      MessageDlg(Format(rsFolderNotFoundFmt, [Folder]), mtError, [mbOK], 0);
      Exit;
    end;
    if not (Application.MainForm is TFormMain) then
      Exit;
    Session := TFormSession(TFormMain(Application.MainForm).NewSession);
    Session.PathsMemo.Lines.Text := Folder;
  finally
    FSelectionContextFileName := '';
    RefreshActionStates;
  end;
end;

procedure TFormSession.PreviewContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  Card: TPreviewCard;
  ScreenPoint: TPoint;
begin
  Handled := True;
  if FullSizeVisible then
  begin
    CloseFullSize(True);
    Exit;
  end;
  for Card in FPreviewCards do
    if (Sender = Card.Image) or (Sender = Card.Caption) or
      (Sender = Card.Panel) then
    begin
      if (MousePos.X = -1) and (MousePos.Y = -1) then
        ScreenPoint := Card.Image.ClientToScreen(Point(0, 0))
      else
        ScreenPoint := TControl(Sender).ClientToScreen(MousePos);
      ShowSelectionMenuAt(ScreenPoint, FSelectedGroup, Card.MemberIndex);
      Exit;
    end;
end;

procedure TFormSession.ActionOpenInExplorerExecute(Sender: TObject);
var
  GroupIndex, MemberIndex: Integer;
  FileName: string;
  OpenResult: HRESULT;
begin
  try
    if not ResolveSelectionContext(GroupIndex, MemberIndex) then
      Exit;
    FileName := FGroups[GroupIndex].Members[MemberIndex].Info.FileName;
    if not FileExists(FileName) then
    begin
      MessageDlg(rsFileUnavailable, mtError, [mbOK], 0);
      Exit;
    end;
    OpenResult := OpenFolderAndSelectFile(FileName);
    if Failed(OpenResult) then
      MessageDlg(Format(rsExplorerOpenFailedFmt,
        [Cardinal(OpenResult)]), mtError, [mbOK], 0);
  finally
    FSelectionContextFileName := '';
    RefreshActionStates;
  end;
end;

procedure TFormSession.ApplyReferenceCriterion(Criterion: TReferenceCriterion);
var
  G, M, Best: Integer;
  Group: TImageGroup;
  FocusFile: string;

  function IsBetter(const Candidate, Current: TGroupMember): Boolean;
  var
    CandidatePixels, CurrentPixels: Int64;
  begin
    CandidatePixels := Int64(Candidate.Info.Width) * Candidate.Info.Height;
    CurrentPixels := Int64(Current.Info.Width) * Current.Info.Height;
    case Criterion of
      rcHighestQuality:
        Result := Candidate.QualityScore > Current.QualityScore;
      rcHighestResolution:
        Result := CandidatePixels > CurrentPixels;
      rcLargestFile:
        Result := Candidate.Info.Bytes > Current.Info.Bytes;
      rcNewest:
        Result := Candidate.Info.Modified > Current.Info.Modified;
      rcLowestQuality:
        Result := Candidate.QualityScore < Current.QualityScore;
      rcLowestResolution:
        Result := CandidatePixels < CurrentPixels;
      rcSmallestFile:
        Result := Candidate.Info.Bytes < Current.Info.Bytes;
      rcOldest:
        Result := Candidate.Info.Modified < Current.Info.Modified;
    else
      Result := False;
    end;
  end;

begin
  CaptureChecks;
  FocusFile := FocusedFileName;
  for G := 0 to FGroups.Count - 1 do
  begin
    Group := FGroups[G];
    if Length(Group.Members) = 0 then
      Continue;
    Best := 0;
    for M := 1 to High(Group.Members) do
      if IsBetter(Group.Members[M], Group.Members[Best]) then
        Best := M;
    for M := 0 to High(Group.Members) do
      Group.Members[M].IsReference := M = Best;
    // Recomputing every image in every group here made this action
    // proportional to the entire library and blocked the UI. Metrics
    // are refreshed once, on demand, when a group is previewed.
    FGroups[G] := Group;
  end;
  ClearPreviews;
  BuildTree(False, FocusFile);
  if Assigned(ResultsTree.FocusedNode) then
    ShowNode(ResultsTree.FocusedNode);
  SetModified(True);
  SetStatusMessage(rsReferencesUpdated);
end;

procedure TFormSession.ApplyGroupSelection(
  Criterion: TGroupSelectionCriterion);
var
  G, M, ReferenceIndex, ReferenceClass: Integer;
  SelectMember: Boolean;
  FocusFile: string;
begin
  CaptureChecks;
  FocusFile := FocusedFileName;
  FChecked.Clear;
  for G := 0 to FGroups.Count - 1 do
  begin
    ReferenceIndex := ReferenceMemberIndex(FGroups[G]);
    if ReferenceIndex < 0 then
      Continue;
    ReferenceClass := FGroups[G].Members[ReferenceIndex].ExactClass;
    for M := 0 to High(FGroups[G].Members) do
    begin
      SelectMember := False;
      case Criterion of
        gscAllExceptReference:
          SelectMember := M <> ReferenceIndex;
        gscIdenticalToReference:
          SelectMember := (M <> ReferenceIndex) and
            (FGroups[G].Members[M].ExactClass = ReferenceClass);
        gscDifferentFromReference:
          SelectMember := (M <> ReferenceIndex) and
            (FGroups[G].Members[M].ExactClass <> ReferenceClass);
      end;
      if SelectMember then
        FChecked.AddOrSetValue(
          FGroups[G].Members[M].Info.FileName, True);
    end;
  end;
  BuildTree(False, FocusFile);
  SetModified(True);
  SetStatusMessage(rsAutoSelectionApplied);
end;

procedure TFormSession.ApplyFolderSelection(SameFolder: Boolean);
var
  G, M, ContextGroup: Integer;
  ContextFolder, CandidateFolder, FocusFile: string;
begin
  if not ResolveSelectionContext(ContextGroup, M) then
    Exit;
  ContextFolder := ExcludeTrailingPathDelimiter(ExpandFileName(
    ExtractFilePath(FGroups[ContextGroup].Members[M].Info.FileName)));
  FocusFile := FocusedFileName;
  CaptureChecks;
  FChecked.Clear;
  for G := 0 to FGroups.Count - 1 do
  begin
    if G = ContextGroup then
      Continue;
    for M := 0 to High(FGroups[G].Members) do
    begin
      CandidateFolder := ExcludeTrailingPathDelimiter(ExpandFileName(
        ExtractFilePath(FGroups[G].Members[M].Info.FileName)));
      if SameText(CandidateFolder, ContextFolder) = SameFolder then
        FChecked.AddOrSetValue(
          FGroups[G].Members[M].Info.FileName, True);
    end;
  end;
  BuildTree(False, FocusFile);
  SetModified(True);
  SetStatusMessage(rsFolderSelectionApplied);
end;

procedure TFormSession.ActionReferenceHighestQualityExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcHighestQuality);
end;

procedure TFormSession.ActionReferenceHighestResolutionExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcHighestResolution);
end;

procedure TFormSession.ActionReferenceLargestFileExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcLargestFile);
end;

procedure TFormSession.ActionReferenceNewestExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcNewest);
end;

procedure TFormSession.ActionReferenceLowestQualityExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcLowestQuality);
end;

procedure TFormSession.ActionReferenceLowestResolutionExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcLowestResolution);
end;

procedure TFormSession.ActionReferenceSmallestFileExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcSmallestFile);
end;

procedure TFormSession.ActionReferenceOldestExecute(Sender: TObject);
begin
  ApplyReferenceCriterion(rcOldest);
end;

procedure TFormSession.ActionSelectAllExceptReferenceExecute(Sender: TObject);
begin
  ApplyGroupSelection(gscAllExceptReference);
end;

procedure TFormSession.ActionSelectIdenticalToReferenceExecute(Sender: TObject);
begin
  ApplyGroupSelection(gscIdenticalToReference);
end;

procedure TFormSession.ActionSelectDifferentFromReferenceExecute(Sender: TObject);
begin
  ApplyGroupSelection(gscDifferentFromReference);
end;

procedure TFormSession.ActionSelectOtherGroupsSameFolderExecute(Sender: TObject);
begin
  try
    ApplyFolderSelection(True);
  finally
    FSelectionContextFileName := '';
  end;
end;

procedure TFormSession.ActionSelectOtherGroupsDifferentFolderExecute(
  Sender: TObject);
begin
  try
    ApplyFolderSelection(False);
  finally
    FSelectionContextFileName := '';
  end;
end;

procedure TFormSession.ActionEnsureUnselectedExecute(Sender: TObject);
var
  G, M: Integer;
  AllSelected, IsSelected: Boolean;
begin
  CaptureChecks;
  for G := 0 to FGroups.Count - 1 do
  begin
    AllSelected := Length(FGroups[G].Members) > 0;
    for M := 0 to High(FGroups[G].Members) do
    begin
      IsSelected := False;
      FChecked.TryGetValue(FGroups[G].Members[M].Info.FileName, IsSelected);
      if not IsSelected then
      begin
        AllSelected := False;
        Break
      end;
    end;
    if AllSelected then
    begin
      for M := 0 to High(FGroups[G].Members) do
        if FGroups[G].Members[M].IsReference then
        begin
          FChecked.AddOrSetValue(FGroups[G].Members[M].Info.FileName, False);
          Break;
        end;
    end;
  end;
  BuildTree(False);
  SetModified(True);
  SetStatusMessage(rsGroupKeepsUnselectedFile);
end;

procedure TFormSession.ActionClearSelectionsExecute(Sender: TObject);
begin
  FChecked.Clear;
  BuildTree(False);
  SetModified(True);
  SetStatusMessage(rsAllSelectionsCleared);
end;

procedure TFormSession.ResultsTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if not FUpdatingTree then
    ShowNode(Node);
end;

procedure TFormSession.ResultsTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PNodeData;
  FileName: string;
  WasChecked, IsChecked: Boolean;
begin
  if FUpdatingTree or not Assigned(Node) then
    Exit;
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) and (Data.Kind = nkFile) and
    (Data.GroupIndex < FGroups.Count) and
    (Data.MemberIndex < Length(FGroups[Data.GroupIndex].Members)) then
  begin
    FileName := FGroups[Data.GroupIndex].Members[Data.MemberIndex].Info.FileName;
    WasChecked := False;
    FChecked.TryGetValue(FileName, WasChecked);
    IsChecked := Sender.CheckState[Node] = csCheckedNormal;
    FChecked.AddOrSetValue(FileName, IsChecked);
    if WasChecked <> IsChecked then
      SetModified(True);
  end;
  RefreshActionStates;
  UpdateCheckedSizeStatus;
end;

procedure TFormSession.ResultsTreeNodeDblClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
var
  Data: PNodeData;
begin
  if not Assigned(HitInfo.HitNode) then
    Exit;
  Data := ResultsTree.GetNodeData(HitInfo.HitNode);
  if not Assigned(Data) or (Data.Kind <> nkFile) or (Data.GroupIndex < 0) or (Data.GroupIndex >= FGroups.Count) or (Data.MemberIndex < 0) or (Data.MemberIndex
    >= Length(FGroups[Data.GroupIndex].Members)) then
    Exit;
  ShowNode(HitInfo.HitNode);
  if (Data.MemberIndex < FPreviewCards.Count) then
    PreviewImageClick(FPreviewCards[Data.MemberIndex].Image);
end;

procedure TFormSession.ShowNode(Node: PVirtualNode);
var
  Data: PNodeData;
  GroupIndex, MemberIndex: Integer;
  G: TImageGroup;
begin
  if not Assigned(Node) then
    Exit;
  Data := ResultsTree.GetNodeData(Node);
  if not Assigned(Data) then
    Exit;
  GroupIndex := Data.GroupIndex;
  if (GroupIndex < 0) or (GroupIndex >= FGroups.Count) then
    Exit;
  G := FGroups[GroupIndex];
  if Length(G.Members) < 1 then
    Exit;
  if Data.Kind = nkGroup then
    MemberIndex := 0
  else
    MemberIndex := Data.MemberIndex;
  if (FSelectedGroup <> GroupIndex) or (FPreviewMemberCount <> Length(G.Members)) then
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

procedure TFormSession.ClearPreviews;
begin
  FPreviewCards.Clear;
  FSelectedGroup := -1;
  FSelectedMember := -1;
  FPreviewMemberCount := 0;
end;

procedure TFormSession.BuildPreviews(GroupIndex: Integer);
var
  I, ReferenceIndex: Integer;
  Card: TPreviewCard;
  Group: TImageGroup;
  ReferenceFile, CachedReference: string;
begin
  FPreviewCards.Clear;
  if (GroupIndex < 0) or (GroupIndex >= FGroups.Count) then
    Exit;
  Group := FGroups[GroupIndex];
  ReferenceIndex := ReferenceMemberIndex(Group);
  if ReferenceIndex >= 0 then
  begin
    ReferenceFile := Group.Members[ReferenceIndex].Info.FileName;
    if (not FMetricReferences.TryGetValue(Group.Id, CachedReference)) or
      (not SameText(CachedReference, ReferenceFile)) then
    begin
      RecalculateReferenceMetrics(Group);
      FGroups[GroupIndex] := Group;
      FMetricReferences.AddOrSetValue(Group.Id, ReferenceFile);
    end;
  end;
  for I := 0 to High(Group.Members) do
  begin
    Card := TPreviewCard.Create(Self, PreviewScroll);
    Card.MemberIndex := I;
    Card.Image.Cursor := crHandPoint;
    Card.Image.OnClick := PreviewImageClick;
    Card.Image.OnContextPopup := PreviewContextPopup;
    Card.Caption.OnContextPopup := PreviewContextPopup;
    Card.Panel.OnContextPopup := PreviewContextPopup;
    FPreviewCards.Add(Card);
    LoadPreview(Card, Group.Members[I]);
  end;
  FPreviewMemberCount := FPreviewCards.Count;
  LayoutPreviews;
end;

procedure TFormSession.PreviewImageClick(Sender: TObject);
var
  I: Integer;
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
  if not Assigned(Card) or (Card.Image.Picture.Graphic = nil) then
    Exit;

  FFullSizeForm := TForm.CreateNew(Self);
  FFullSizeForm.BorderStyle := bsNone;
  FFullSizeForm.Caption := Card.Caption.Hint;
  FFullSizeForm.Color := clBlack;
  FFullSizeForm.FormStyle := fsStayOnTop;
  FFullSizeForm.KeyPreview := True;
  FFullSizeForm.Scaled := False;
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

  Bounds := Monitor.BoundsRect;
  FFullSizeForm.SetBounds(Bounds.Left, Bounds.Top, Bounds.Width, Bounds.Height);
  SetFullSizeMode((FFullSizeView.Picture.Width <= FFullSizeForm.ClientWidth) and
    (FFullSizeView.Picture.Height <= FFullSizeForm.ClientHeight));
  FFullSizeForm.Show;
  FFullSizeForm.BringToFront;
  FFullSizeForm.SetFocus;
end;

procedure TFormSession.CloseFullSize(Deferred: Boolean);
var
  Form: TForm;
begin
  Form := FFullSizeForm;
  if not Assigned(Form) or FFullSizeClosing then
    Exit;
  FPanning := False;
  ReleaseCapture;
  Form.Hide;
  if Deferred then
  begin
    FFullSizeClosing := True;
    Form.Release;
  end
  else
  begin
    FFullSizeForm := nil;
    FFullSizeView := nil;
    Form.Free;
  end;
end;

procedure TFormSession.SetFullSizeMode(NativeSize: Boolean);
var
  Scale: Double;
  DisplayWidth, DisplayHeight: Integer;
begin
  if not Assigned(FFullSizeForm) or not Assigned(FFullSizeView) or
    not Assigned(FFullSizeView.Picture.Graphic) or
    (FFullSizeView.Picture.Width <= 0) or (FFullSizeView.Picture.Height <= 0) then
    Exit;
  FFullSizeNative := NativeSize;
  if NativeSize then
  begin
    DisplayWidth := FFullSizeView.Picture.Width;
    DisplayHeight := FFullSizeView.Picture.Height;
  end
  else
  begin
    Scale := Min(FFullSizeForm.ClientWidth / FFullSizeView.Picture.Width,
      FFullSizeForm.ClientHeight / FFullSizeView.Picture.Height);
    DisplayWidth := Max(1, Round(FFullSizeView.Picture.Width * Scale));
    DisplayHeight := Max(1, Round(FFullSizeView.Picture.Height * Scale));
  end;
  FFullSizeView.SetImageBounds(
    (FFullSizeForm.ClientWidth - DisplayWidth) div 2,
    (FFullSizeForm.ClientHeight - DisplayHeight) div 2,
    DisplayWidth, DisplayHeight);
  if not NativeSize and FZoomCursorAvailable then
    FFullSizeView.Cursor := crImageZoomIn
  else if not NativeSize then
    FFullSizeView.Cursor := crHandPoint
  else if NativeSize and ((DisplayWidth > FFullSizeForm.ClientWidth) or
    (DisplayHeight > FFullSizeForm.ClientHeight)) then
    FFullSizeView.Cursor := crSizeAll
  else
    FFullSizeView.Cursor := crHandPoint;
end;

procedure TFormSession.FullSizeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    CloseFullSize(True);
  end;
end;

procedure TFormSession.FullSizeFormDestroy(Sender: TObject);
begin
  if Sender = FFullSizeForm then
  begin
    FFullSizeForm := nil;
    FFullSizeView := nil;
    FFullSizeClosing := False;
    FFullSizeNative := False;
  end;
end;

procedure TFormSession.FullSizeFormDeactivate(Sender: TObject);
begin
  CloseFullSize(True);
end;

function TFormSession.FullSizeImageContains(X, Y: Integer): Boolean;
begin
  Result := Assigned(FFullSizeView) and
    PtInRect(Rect(FFullSizeView.ImageLeft, FFullSizeView.ImageTop,
      FFullSizeView.ImageLeft + FFullSizeView.ImageWidth,
      FFullSizeView.ImageTop + FFullSizeView.ImageHeight), Point(X, Y));
end;

procedure TFormSession.SetFullSizeImagePosition(ALeft, ATop: Integer);
begin
  if not Assigned(FFullSizeView) then
    Exit;
  if FFullSizeView.ImageWidth <= FFullSizeForm.ClientWidth then
    ALeft := (FFullSizeForm.ClientWidth - FFullSizeView.ImageWidth) div 2
  else
    ALeft := EnsureRange(ALeft,
      FFullSizeForm.ClientWidth - FFullSizeView.ImageWidth, 0);
  if FFullSizeView.ImageHeight <= FFullSizeForm.ClientHeight then
    ATop := (FFullSizeForm.ClientHeight - FFullSizeView.ImageHeight) div 2
  else
    ATop := EnsureRange(ATop,
      FFullSizeForm.ClientHeight - FFullSizeView.ImageHeight, 0);
  FFullSizeView.SetPosition(ALeft, ATop);
end;

procedure TFormSession.FullSizeImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not Assigned(FFullSizeView) then
    Exit;
  if Button = mbRight then
  begin
    CloseFullSize(True);
    Exit;
  end;
  if Button <> mbLeft then
    Exit;
  if not FullSizeImageContains(X, Y) then
  begin
    CloseFullSize(True);
    Exit;
  end;
  FPanning := True;
  FPanMoved := False;
  GetCursorPos(FPanStart);
  FPanImageStart := Point(FFullSizeView.ImageLeft, FFullSizeView.ImageTop);
  SetCapture(FFullSizeForm.Handle);
end;

procedure TFormSession.FullSizeImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  Current: TPoint;
  DX, DY: Integer;
begin
  if not FPanning or not Assigned(FFullSizeView) then
    Exit;
  GetCursorPos(Current);
  DX := Current.X - FPanStart.X;
  DY := Current.Y - FPanStart.Y;
  if (Abs(DX) > MulDiv(3, CurrentPPI, 96)) or
    (Abs(DY) > MulDiv(3, CurrentPPI, 96)) then
    FPanMoved := True;
  if FFullSizeNative then
    SetFullSizeImagePosition(FPanImageStart.X + DX, FPanImageStart.Y + DY);
end;

procedure TFormSession.FullSizeImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  WasMoved: Boolean;
begin
  if (Button <> mbLeft) or not FPanning then
    Exit;
  WasMoved := FPanMoved;
  FPanning := False;
  ReleaseCapture;
  if not WasMoved then
    if FFullSizeNative then
      CloseFullSize(True)
    else
      SetFullSizeMode(True);
end;

function TFormSession.FullSizeVisible: Boolean;
begin
  Result := Assigned(FFullSizeForm) and FFullSizeForm.Visible;
end;

function TFormSession.FullSizeUsesNativeDimensions: Boolean;
begin
  Result := Assigned(FFullSizeView) and FFullSizeNative and
    (FFullSizeView.ImageWidth = FFullSizeView.Picture.Width) and
    (FFullSizeView.ImageHeight = FFullSizeView.Picture.Height);
end;

function TFormSession.FullSizeUsesZoomCursor: Boolean;
begin
  Result := Assigned(FFullSizeView) and not FFullSizeNative and
    FZoomCursorAvailable and (FFullSizeView.Cursor = crImageZoomIn);
end;

procedure TFormSession.LoadPreview(Card: TPreviewCard; const Member: TGroupMember);
var
  Info: TImageInfo;
  MetricsText: string;
begin
  Info := Member.Info;
  Card.Image.Picture.Assign(nil);
  if Member.IsReference then
    MetricsText := rsGroupReference
  else
    MetricsText := Format(rsComparisonMetricsFmt, [Member.Metrics.Distance, Member.Metrics.RGBError, Member.Metrics.Structural,
      Member.Metrics.WorstStructural]);
  Card.Caption.Caption := Format(rsPreviewCaptionFmt, [ExtractFileName(Info.FileName),
    sLineBreak, Dimensions(Info), FileSizeText(Info.Bytes), DpiText(Info),
    FormatDateTime(rsDateTimeFormat, Info.Modified), sLineBreak,
    Member.QualityScore, Info.Quality.Sharpness, Info.Quality.Noise,
    Info.Quality.BlockArtifacts, sLineBreak, MetricsText]);
  Card.Caption.Hint := Info.FileName + sLineBreak + QualityDetailsText(Member);
  Card.Image.Hint := Card.Caption.Hint;
  try
    LoadImagePreview(Info.FileName, Card.Image.Picture);
  except
    on E: Exception do
    begin
      Card.Image.Picture.Assign(nil);
      Card.Caption.Caption := Card.Caption.Caption + sLineBreak + rsPreviewUnavailable;
      Card.Caption.Hint := Info.FileName + sLineBreak + E.Message;
    end;
  end;
end;

procedure TFormSession.LayoutPreviews;
var
  Count, Cols, BestCols, Rows, Row, Col, Index, InRow: Integer;
  Gap, AvailableWidth, AvailableHeight, CardWidth, CardHeight, CaptionHeight, ImageWidth, ImageHeight: Integer;
  Scale, Score, BestScore: Double;
  Info: TImageInfo;
begin
  Count := FPreviewCards.Count;
  if (Count = 0) or (PreviewScroll.ClientWidth <= 0) or (PreviewScroll.ClientHeight <= 0) then
    Exit;
  Gap := MulDiv(8, CurrentPPI, 96);
  AvailableWidth := PreviewScroll.ClientWidth;
  AvailableHeight := PreviewScroll.ClientHeight;
  BestCols := 1;
  BestScore := -1;
  for Cols := 1 to Count do
  begin
    Rows := (Count + Cols - 1) div Cols;
    CardHeight := (AvailableHeight - (Rows + 1) * Gap) div Rows;
    CaptionHeight := EnsureRange(CardHeight div 3, MulDiv(44, CurrentPPI, 96), MulDiv(66, CurrentPPI, 96));
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
        Scale := Min(ImageWidth / Max(1, Info.Width), ImageHeight / Max(1, Info.Height));
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
  CaptionHeight := EnsureRange(CardHeight div 3, MulDiv(44, CurrentPPI, 96), MulDiv(66, CurrentPPI, 96));
  Index := 0;
  for Row := 0 to Rows - 1 do
  begin
    InRow := Min(BestCols, Count - Index);
    CardWidth := Max(1, (AvailableWidth - (InRow + 1) * Gap) div InRow);
    for Col := 0 to InRow - 1 do
    begin
      FPreviewCards[Index].Caption.Height := CaptionHeight;
      FPreviewCards[Index].Panel.SetBounds(Gap + Col * (CardWidth + Gap), Gap + Row * (CardHeight + Gap), CardWidth, CardHeight);
      Inc(Index);
    end;
  end;
end;

procedure TFormSession.UpdatePreviewSelection;
var
  I: Integer;
  Selected: Boolean;
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

function TFormSession.PreviewCardCount: Integer;
begin
  Result := FPreviewCards.Count;
end;

function TFormSession.PreviewCard(Index: Integer): TPreviewCard;
begin
  Result := FPreviewCards[Index];
end;

procedure TFormSession.SaveSessionToFile(const FileName: string);
var
  State: TSessionState;
  Selected: TList<string>;
  Pair: TPair<string, Boolean>;
begin
  State.Quality := FComparisonQuality;
  State.PixelError := DefaultMaxRGBError;
  State.ThreadCount := FThreadCount;
  State.ScannedFiles := FScannedFileCount;
  State.Roots := PathsMemo.Lines.ToStringArray;
  State.Recursive := FRecursiveSearch;
  State.IncludeSingletons := FIncludeSingletons;
  State.Groups := FGroups.ToArray;
  CaptureChecks;
  Selected := TList<string>.Create;
  try
    for Pair in FChecked do
      if Pair.Value then
        Selected.Add(Pair.Key);
    State.SelectedFiles := Selected.ToArray;
  finally
    Selected.Free;
  end;
  SaveSession(FileName, State);
end;

procedure TFormSession.LoadSessionFromFile(const FileName: string);
var
  State: TSessionState;
  G: TImageGroup;
  S: string;
begin
  if Assigned(FWorker) then
    raise EInvalidOperation.Create(rsStopScanBeforeLoading);
  State := LoadSession(FileName);
  if (State.Quality < MinComparisonQuality) or
    (State.Quality > MaxComparisonQuality) or
    (State.ThreadCount < 1) or (State.ThreadCount > 64) or
    (State.ScannedFiles < 0) then
    raise EConvertError.Create(rsInvalidSavedCriteria);
  PathsMemo.Lines.BeginUpdate;
  try
    PathsMemo.Lines.Clear;
    for S in State.Roots do
      PathsMemo.Lines.Add(S);
  finally
    PathsMemo.Lines.EndUpdate;
  end;
  SetSearchOptions(State.Quality, State.ThreadCount, State.Recursive, State.IncludeSingletons);
  FScannedFileCount := State.ScannedFiles;
  FGroups.Clear;
  FMetricReferences.Clear;
  for G in State.Groups do
    FGroups.Add(G);
  if FSortColumn = 0 then
    SortGroupsBySize(FSortAscending)
  else if FSortColumn > 0 then
    SortMembers(FSortColumn, FSortAscending);
  FChecked.Clear;
  for S in State.SelectedFiles do
    FChecked.AddOrSetValue(S, True);
  FErrors.Clear;
  ClearPreviews;
  BuildTree(False);
  if Assigned(ResultsTree.FocusedNode) then
    ShowNode(ResultsTree.FocusedNode);
  RefreshActionStates;
  ResultsLabel.Caption := Format(rsSessionLoadedResultsFmt, [FGroups.Count, Integer(ResultsTree.TotalCount) - FGroups.Count]);
  StatusProgress.Style := pbstNormal;
  SetProgressVisible(False);
  if FScannedFileCount > 0 then
  begin
    StatusProgress.Max := FScannedFileCount;
    StatusProgress.Position := FScannedFileCount;
    StatusProgress.Hint := Format(rsSessionImagesHintFmt, [FScannedFileCount]);
  end
  else
  begin
    StatusProgress.Max := 100;
    StatusProgress.Position := 0;
    StatusProgress.Hint := rsSessionCountUnavailable;
  end;
  SetStatusMessage(Format(rsSessionStatusFmt, [FScannedFileCount, FGroups.Count, Integer(ResultsTree.TotalCount) - FGroups.Count]));
  RefreshActionStates;
end;

procedure TFormSession.PreviewPanelResize(Sender: TObject);
begin
  if Assigned(FPreviewCards) then
    LayoutPreviews;
end;

procedure TFormSession.ActionShowErrorsExecute(Sender: TObject);
var
  Dialog: TForm;
  Memo: TMemo;
begin
  Dialog := TForm.CreateNew(Self);
  try
    Dialog.Caption := rsReadErrorsCaption;
    Dialog.Position := poOwnerFormCenter;
    Dialog.Width := 800;
    Dialog.Height := 400;
    Memo := TMemo.Create(Dialog);
    Memo.Parent := Dialog;
    Memo.Align := alClient;
    Memo.ReadOnly := True;
    Memo.ScrollBars := ssBoth;
    Memo.WordWrap := False;
    Memo.Lines.Assign(FErrors);
    Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
end;

function TFormSession.PrepareForClose: Boolean;
var
  FileName: string;
  DialogResult: TModalResult;
begin
  if FCloseApproved then
    Exit(True);
  Result := False;
  if IsBusy then
    Exit;
  if not FModified then
  begin
    FCloseApproved := True;
    Exit(True);
  end;

  DialogResult := MessageDlg(Format(rsSaveChangesPromptFmt, [Caption]),
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  case DialogResult of
    mrYes:
      begin
        FileName := FSessionFileName;
        if FileName = '' then
        begin
          SaveSessionDialog.FileName := ChangeFileExt(Caption, '.idup');
          if not SaveSessionDialog.Execute(Handle) then
            Exit;
          FileName := SaveSessionDialog.FileName;
        end;
        try
          SaveDocument(FileName);
        except
          on E: Exception do
          begin
            MessageDlg(Format(rsSessionSaveErrorFmt,
              [sLineBreak, E.Message]), mtError, [mbOK], 0);
            Exit;
          end;
        end;
      end;
    mrNo:
      ;
  else
    Exit;
  end;
  FCloseApproved := True;
  Result := True;
end;

procedure TFormSession.CancelPreparedClose;
begin
  FCloseApproved := False;
end;

procedure TFormSession.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  if FDeleting then
    Exit;
  if Assigned(FWorker) then
  begin
    FClosePending := True;
    ActionStopScan.Execute;
    Exit;
  end;
  FClosePending := False;
  CanClose := PrepareForClose;
  if CanClose then
    FCloseApproved := False;
end;

procedure TFormSession.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFormSession.InitializeUntitled(const ACaption: string);
begin
  FSessionFileName := '';
  Caption := ACaption;
  SetModified(False);
end;

procedure TFormSession.LoadDocument(const FileName: string);
begin
  LoadSessionFromFile(FileName);
  FSessionFileName := ExpandFileName(FileName);
  Caption := ExtractFileName(FSessionFileName);
  SetModified(False);
  SetStatusMessage(Format(rsSessionLoadedFileFmt,
    [FSessionFileName, FScannedFileCount]));
end;

procedure TFormSession.SaveDocument(const FileName: string);
begin
  SaveSessionToFile(FileName);
  FSessionFileName := ExpandFileName(FileName);
  Caption := ExtractFileName(FSessionFileName);
  SetModified(False);
  SetStatusMessage(Format(rsSessionSavedFmt, [FSessionFileName]));
end;

function TFormSession.CanSaveDocument: Boolean;
begin
  Result := not IsBusy and HasSessionContent;
end;

function TFormSession.IsBusy: Boolean;
begin
  Result := Assigned(FWorker) or FDeleting;
end;

end.


