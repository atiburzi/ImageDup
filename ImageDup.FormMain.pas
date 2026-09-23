unit ImageDup.FormMain;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls,
  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnList, System.Actions, System.UITypes,
  Vcl.Menus, Vcl.FormTabsBar, Vcl.BaseImageCollection, Vcl.ImageCollection, System.ImageList, Vcl.ImgList,
  Vcl.VirtualImageList, ImageDup.Resource;

type
  TFormMain = class(TForm)
    ToolBar: TToolBar;
    ToolButtonNew: TToolButton;
    ToolButtonLoad: TToolButton;
    ToolButtonSave: TToolButton;
    ToolButtonFileSeparator: TToolButton;
    ToolButtonCascade: TToolButton;
    ToolButtonTileHorizontal: TToolButton;
    ToolButtonTileVertical: TToolButton;
    ToolButtonWindowSeparator: TToolButton;
    ToolButtonAbout: TToolButton;
    FormTabsBar: TFormTabsBar;
    ActionList: TActionList;
    ActionNewSession: TAction;
    ActionLoadSession: TAction;
    ActionSaveSession: TAction;
    ActionSaveSessionAs: TAction;
    ActionCloseSession: TAction;
    ActionExit: TAction;
    ActionCascade: TAction;
    ActionTileHorizontal: TAction;
    ActionTileVertical: TAction;
    ActionArrangeIcons: TAction;
    ActionAbout: TAction;
    OpenSessionDialog: TFileOpenDialog;
    SaveSessionDialog: TFileSaveDialog;
    MainMenu: TMainMenu;
    FileMenu: TMenuItem;
    NewSessionMenuItem: TMenuItem;
    LoadSessionMenuItem: TMenuItem;
    SaveSessionMenuItem: TMenuItem;
    SaveSessionAsMenuItem: TMenuItem;
    CloseSessionMenuItem: TMenuItem;
    FileSeparatorMenuItem: TMenuItem;
    ExitMenuItem: TMenuItem;
    WindowMenu: TMenuItem;
    CascadeMenuItem: TMenuItem;
    TileHorizontalMenuItem: TMenuItem;
    TileVerticalMenuItem: TMenuItem;
    HelpMenu: TMenuItem;
    AboutMenuItem: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure ActionNewSessionExecute(Sender: TObject);
    procedure ActionLoadSessionExecute(Sender: TObject);
    procedure ActionSaveSessionExecute(Sender: TObject);
    procedure ActionSaveSessionAsExecute(Sender: TObject);
    procedure ActionCloseSessionExecute(Sender: TObject);
    procedure ActionExitExecute(Sender: TObject);
    procedure ActionCascadeExecute(Sender: TObject);
    procedure ActionTileHorizontalExecute(Sender: TObject);
    procedure ActionTileVerticalExecute(Sender: TObject);
    procedure ActionArrangeIconsExecute(Sender: TObject);
    procedure ActionAboutExecute(Sender: TObject);
  private
    FNextSessionNumber: Integer;
    FStartupProcessed: Boolean;
    function ActiveSession: TForm;
    procedure SaveActiveSession(ForceFileName: Boolean);
    procedure OpenCommandLineSessions;
  public
    function CloseQuery: Boolean; override;
    function NewSession: TForm;
    function OpenSessionFile(const FileName: string): TForm;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  ImageDup.FormSession, ImageDup.FormAbout;

resourcestring
  rsUntitledSessionFmt='Session %d';
  rsSessionLoadedFileFmt='Session loaded: %s | Scanned: %d';
  rsSessionLoadErrorFmt='Unable to load the session:%s%s';
  rsSessionSavedFmt='Session saved: %s';
  rsSessionSaveErrorFmt='Unable to save the session:%s%s';
  rsCloseBusySessions='One or more sessions are busy. Stop the current operations before closing ImageDup.';

function TFormMain.CloseQuery: Boolean;
var
  I, J: Integer;
  Session: TFormSession;
begin
  Result := False;

  // Do not let VCL close only part of the MDI workspace. Validate every
  // session before inherited CloseQuery starts querying the child windows.
  for I := 0 to MDIChildCount - 1 do
    if (MDIChildren[I] is TFormSession) and
      TFormSession(MDIChildren[I]).IsBusy then
    begin
      MessageDlg(rsCloseBusySessions, mtWarning, [mbOK], 0);
      Exit;
    end;

  for I := 0 to MDIChildCount - 1 do
    if MDIChildren[I] is TFormSession then
    begin
      Session := TFormSession(MDIChildren[I]);
      if not Session.PrepareForClose then
      begin
        for J := 0 to MDIChildCount - 1 do
          if MDIChildren[J] is TFormSession then
            TFormSession(MDIChildren[J]).CancelPreparedClose;
        Exit;
      end;
    end;

  Result := inherited CloseQuery;
  if not Result then
    for I := 0 to MDIChildCount - 1 do
      if MDIChildren[I] is TFormSession then
        TFormSession(MDIChildren[I]).CancelPreparedClose;
end;

function TFormMain.ActiveSession: TForm;
begin
  Result := ActiveMDIChild;
  if not (Result is TFormSession) then
    Result := nil;
end;

function TFormMain.NewSession: TForm;
var
  Session: TFormSession;
begin
  Inc(FNextSessionNumber);
  Session := TFormSession.Create(Application);
  Session.InitializeUntitled(Format(rsUntitledSessionFmt, [FNextSessionNumber]));
  Session.Show;
  if MDIChildCount = 1 then
    Session.WindowState := wsMaximized;
  Session.BringToFront;
  Result := Session;
end;

function TFormMain.OpenSessionFile(const FileName: string): TForm;
var
  Session: TFormSession;
  FullName: string;
begin
  FullName := ExpandFileName(FileName);
  Session := TFormSession.Create(Application);
  try
    Session.LoadDocument(FullName);
    Session.Show;
    if MDIChildCount = 1 then
      Session.WindowState := wsMaximized;
    Session.BringToFront;
//    StatusBar.SimpleText := Format(rsSessionLoadedFileFmt,
//      [FullName, Session.ScannedFileCount]);
    Result := Session;
  except
    Session.Free;
    raise;
  end;
end;

procedure TFormMain.OpenCommandLineSessions;
var
  I: Integer;
  OpenedAny: Boolean;
begin
  OpenedAny := False;
  for I := 1 to ParamCount do
    if SameText(ExtractFileExt(ParamStr(I)), '.idup') then
    begin
      try
        OpenSessionFile(ParamStr(I));
        OpenedAny := True;
      except
        on E: Exception do
          MessageDlg(Format(rsSessionLoadErrorFmt,
            [sLineBreak, E.Message]), mtError, [mbOK], 0);
      end;
    end;
  if not OpenedAny then
    NewSession;
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  if FStartupProcessed then
    Exit;
  FStartupProcessed := True;
  OpenCommandLineSessions;
end;

procedure TFormMain.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
var
  Session: TFormSession;
  HasSession: Boolean;
begin
  Session := nil;
  if ActiveSession is TFormSession then
    Session := TFormSession(ActiveSession);
  HasSession := Assigned(Session);
  ActionSaveSession.Enabled := HasSession and Session.CanSaveDocument and
    Session.Modified;
  ActionSaveSessionAs.Enabled := HasSession and Session.CanSaveDocument;
  ActionCloseSession.Enabled := HasSession;
  ActionCascade.Enabled := MDIChildCount > 0;
  ActionTileHorizontal.Enabled := MDIChildCount > 0;
  ActionTileVertical.Enabled := MDIChildCount > 0;
  ActionArrangeIcons.Enabled := MDIChildCount > 0;
  Handled := True;
end;

procedure TFormMain.ActionNewSessionExecute(Sender: TObject);
begin
  NewSession;
end;

procedure TFormMain.ActionLoadSessionExecute(Sender: TObject);
var
  I: Integer;
begin
  if not OpenSessionDialog.Execute(Handle) then
    Exit;
  for I := 0 to OpenSessionDialog.Files.Count - 1 do
    try
      OpenSessionFile(OpenSessionDialog.Files[I]);
    except
      on E: Exception do
        MessageDlg(Format(rsSessionLoadErrorFmt,
          [sLineBreak, E.Message]), mtError, [mbOK], 0);
    end;
end;

procedure TFormMain.SaveActiveSession(ForceFileName: Boolean);
var
  Session: TFormSession;
  FileName: string;
begin
  if not (ActiveSession is TFormSession) then
    Exit;
  Session := TFormSession(ActiveSession);
  FileName := Session.SessionFileName;
  if ForceFileName or (FileName = '') then
  begin
    if FileName <> '' then
      SaveSessionDialog.FileName := FileName
    else
      SaveSessionDialog.FileName := ChangeFileExt(Session.Caption, '.idup');
    if not SaveSessionDialog.Execute(Handle) then
      Exit;
    FileName := SaveSessionDialog.FileName;
  end;
  try
    Session.SaveDocument(FileName);
//    StatusBar.SimpleText := Format(rsSessionSavedFmt, [FileName]);
  except
    on E: Exception do
      MessageDlg(Format(rsSessionSaveErrorFmt,
        [sLineBreak, E.Message]), mtError, [mbOK], 0);
  end;
end;

procedure TFormMain.ActionSaveSessionExecute(Sender: TObject);
begin
  SaveActiveSession(False);
end;

procedure TFormMain.ActionSaveSessionAsExecute(Sender: TObject);
begin
  SaveActiveSession(True);
end;

procedure TFormMain.ActionCloseSessionExecute(Sender: TObject);
var
  Session: TForm;
begin
  Session := ActiveSession;
  if Assigned(Session) then
    Session.Close;
end;

procedure TFormMain.ActionExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.ActionCascadeExecute(Sender: TObject);
begin
  Cascade;
end;

procedure TFormMain.ActionTileHorizontalExecute(Sender: TObject);
begin
  TileMode := tbHorizontal;
  Tile;
end;

procedure TFormMain.ActionTileVerticalExecute(Sender: TObject);
begin
  TileMode := tbVertical;
  Tile;
end;

procedure TFormMain.ActionArrangeIconsExecute(Sender: TObject);
begin
  ArrangeIcons;
end;

procedure TFormMain.ActionAboutExecute(Sender: TObject);
begin
  TFormAbout.Execute(Self);
end;

end.


