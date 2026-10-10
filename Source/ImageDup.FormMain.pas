unit ImageDup.FormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ActnList,
  System.Actions, System.UITypes, Vcl.Menus, Vcl.FormTabsBar,
  Vcl.Themes, Vcl.TitleBarCtrls, Vcl.ToolWin;

const
  WM_REFRESH_HEADER = WM_APP + $120;
  WM_REFRESH_RECENT_FILES = WM_APP + $121;

type
  TFormMain = class(TForm)
    MenuBar: TToolBar;
    TitleBarPanel: TTitleBarPanel;
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
    ActionSettings: TAction;
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
    RecentSessionsSeparatorMenuItem: TMenuItem;
    RecentSession1MenuItem: TMenuItem;
    RecentSession2MenuItem: TMenuItem;
    RecentSession3MenuItem: TMenuItem;
    RecentSession4MenuItem: TMenuItem;
    RecentSession5MenuItem: TMenuItem;
    FileSeparatorMenuItem: TMenuItem;
    ExitMenuItem: TMenuItem;
    WindowMenu: TMenuItem;
    CascadeMenuItem: TMenuItem;
    TileHorizontalMenuItem: TMenuItem;
    TileVerticalMenuItem: TMenuItem;
    ToolsMenu: TMenuItem;
    SettingsMenuItem: TMenuItem;
    HelpMenu: TMenuItem;
    AboutMenuItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
    procedure ActionSettingsExecute(Sender: TObject);
    procedure ActionAboutExecute(Sender: TObject);
  private
    FNextSessionNumber: Integer;
    FRecentSessionFiles: TStringList;
    FStartupProcessed: Boolean;
    function ActiveSession: TForm;
    function RecentSessionMenuItem(Index: Integer): TMenuItem;
    procedure RefreshRecentSessionsMenu;
    procedure RemoveRecentSessionFile(const FileName: string);
    procedure RecentSessionClick(Sender: TObject);
    procedure SaveActiveSession(ForceFileName: Boolean);
    procedure OpenCommandLineSessions;
    function ApplyApplicationStyle(const StyleName,
      DisplayName: string): Boolean;
    procedure WMRefreshHeader(var Message: TMessage); message WM_REFRESH_HEADER;
    procedure WMRefreshRecentFiles(var Message: TMessage);
      message WM_REFRESH_RECENT_FILES;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    function CloseQuery: Boolean; override;
    function NewSession: TForm;
    function OpenSessionFile(const FileName: string): TForm;
    procedure RegisterRecentSessionFile(const FileName: string);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  ImageDup.FormSession, ImageDup.FormAbout, ImageDup.FormSettings,
  ImageDup.Settings;

resourcestring
  rsUntitledSessionFmt = 'Session %d';
  rsSessionLoadedFileFmt = 'Session loaded: %s | Scanned: %d';
  rsSessionLoadErrorFmt = 'Unable to load the session:%s%s';
  rsSessionSavedFmt = 'Session saved: %s';
  rsSessionSaveErrorFmt = 'Unable to save the session:%s%s';
  rsCloseBusySessions = 'One or more sessions are busy. Stop the current operations before closing ImageDup.';
  rsStyleUnavailable = 'The selected style is unavailable.';
  rsStyleChangeErrorFmt = 'Unable to apply GUI style %s:%s%s';
  rsRecentSessionMissingFmt =
    'The recent session file is no longer available and has been removed ' +
    'from the list:%s%s';

function TFormMain.CloseQuery: Boolean;
var
  I, J: Integer;
  Session: TFormSession;
begin
  Result := False;

  // Do not let VCL close only part of the MDI workspace. Validate every
  // session before inherited CloseQuery starts querying the child windows.
  for I := 0 to MDIChildCount - 1 do
    if (MDIChildren[I] is TFormSession) and TFormSession(MDIChildren[I]).IsBusy then
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
          MessageDlg(Format(rsSessionLoadErrorFmt, [sLineBreak, E.Message]), mtError, [mbOK], 0);
      end;
    end;
  if not OpenedAny then
    NewSession;
end;

procedure TFormMain.WndProc(var Message: TMessage);
var
  StyleChanged: Boolean;
begin
  StyleChanged := Message.Msg = CM_CUSTOMSTYLECHANGED;
  inherited WndProc(Message);
  // Let VCL finish rebuilding the MDI frame and broadcasting the new style
  // before repainting the custom title bar and menu.
  if StyleChanged and not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REFRESH_HEADER, 0, 0);
end;

procedure TFormMain.WMRefreshHeader(var Message: TMessage);
begin
  Message.Result := 0;
  if (csDestroying in ComponentState) or not Assigned(TitleBarPanel) then
    Exit;
  if CustomTitleBar.Enabled and (WindowState <> wsMinimized) then
  begin
    TitleBarPanel.Width := ClientWidth;
    TitleBarPanel.Repaint;
  end;
  MenuBar.Invalidate;
end;

procedure TFormMain.WMRefreshRecentFiles(var Message: TMessage);
begin
  Message.Result := 0;
  if not (csDestroying in ComponentState) then
    RefreshRecentSessionsMenu;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FRecentSessionFiles := TStringList.Create;
  FRecentSessionFiles.CaseSensitive := False;
  LoadRecentSessionFiles(FRecentSessionFiles);
  RefreshRecentSessionsMenu;
  if not CustomTitleBar.Enabled then
  begin
    GlassFrame.Enabled := False;
    GlassFrame.Top := 0;
    TitleBarPanel.Visible := False;
  end;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FRecentSessionFiles);
end;

procedure TFormMain.RefreshRecentSessionsMenu;
var
  FileName: string;
  I: Integer;
  Item: TMenuItem;
begin
  if not Assigned(FRecentSessionFiles) then
    Exit;
  RecentSessionsSeparatorMenuItem.Visible := FRecentSessionFiles.Count > 0;
  for I := 0 to MaxRecentSessionFiles - 1 do
  begin
    Item := RecentSessionMenuItem(I);
    Item.OnClick := RecentSessionClick;
    if I < FRecentSessionFiles.Count then
    begin
      FileName := FRecentSessionFiles[I];
      Item.Caption := Format('&%d %s', [I + 1,
        StringReplace(FileName, '&', '&&', [rfReplaceAll])]);
      Item.Hint := FileName;
      Item.Visible := True;
    end
    else
    begin
      Item.Hint := '';
      Item.Visible := False;
    end;
  end;
end;

function TFormMain.RecentSessionMenuItem(Index: Integer): TMenuItem;
begin
  case Index of
    0: Result := RecentSession1MenuItem;
    1: Result := RecentSession2MenuItem;
    2: Result := RecentSession3MenuItem;
    3: Result := RecentSession4MenuItem;
    4: Result := RecentSession5MenuItem;
  else
    Result := nil;
  end;
end;

procedure TFormMain.RegisterRecentSessionFile(const FileName: string);
var
  FullName: string;
  I: Integer;
begin
  if (FileName = '') or not Assigned(FRecentSessionFiles) then
    Exit;
  FullName := ExpandFileName(FileName);
  I := FRecentSessionFiles.IndexOf(FullName);
  if I >= 0 then
    FRecentSessionFiles.Delete(I);
  FRecentSessionFiles.Insert(0, FullName);
  while FRecentSessionFiles.Count > MaxRecentSessionFiles do
    FRecentSessionFiles.Delete(FRecentSessionFiles.Count - 1);
  SaveRecentSessionFiles(FRecentSessionFiles);
  if HandleAllocated then
    PostMessage(Handle, WM_REFRESH_RECENT_FILES, 0, 0);
end;

procedure TFormMain.RemoveRecentSessionFile(const FileName: string);
var
  I: Integer;
begin
  if not Assigned(FRecentSessionFiles) then
    Exit;
  I := FRecentSessionFiles.IndexOf(ExpandFileName(FileName));
  if I >= 0 then
  begin
    FRecentSessionFiles.Delete(I);
    SaveRecentSessionFiles(FRecentSessionFiles);
    if HandleAllocated then
      PostMessage(Handle, WM_REFRESH_RECENT_FILES, 0, 0);
  end;
end;

procedure TFormMain.RecentSessionClick(Sender: TObject);
var
  FileName: string;
  I: Integer;
begin
  if not (Sender is TMenuItem) or not Assigned(FRecentSessionFiles) then
    Exit;
  I := TMenuItem(Sender).Tag;
  if (I < 0) or (I >= FRecentSessionFiles.Count) then
    Exit;
  FileName := FRecentSessionFiles[I];
  if not FileExists(FileName) then
  begin
    RemoveRecentSessionFile(FileName);
    MessageDlg(Format(rsRecentSessionMissingFmt,
      [sLineBreak, FileName]), mtWarning, [mbOK], 0);
    Exit;
  end;
  try
    OpenSessionFile(FileName);
  except
    on E: Exception do
      MessageDlg(Format(rsSessionLoadErrorFmt,
        [sLineBreak, E.Message]), mtError, [mbOK], 0);
  end;
end;

resourcestring
  rsApplicationSettingsSaveErrorFmt = 'The settings were applied, but could not be saved:%s%s';

function TFormMain.ApplyApplicationStyle(const StyleName,
  DisplayName: string): Boolean;
var
  ErrorText: string;
begin
  if SameText(StyleName, TStyleManager.ActiveStyle.Name) then
    Exit(True);
  ErrorText := '';
  try
    if not TStyleManager.TrySetStyle(StyleName, False) then
      ErrorText := rsStyleUnavailable;
  except
    on E: Exception do
      ErrorText := E.Message;
  end;
  Result := ErrorText = '';
  if not Result then
    MessageDlg(Format(rsStyleChangeErrorFmt, [DisplayName, sLineBreak,
      ErrorText]), mtError, [mbOK], 0);
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  PostMessage(Handle, WM_REFRESH_HEADER, 0, 0);
  if FStartupProcessed then
    Exit;
  FStartupProcessed := True;
  OpenCommandLineSessions;
end;

procedure TFormMain.ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
var
  Session: TFormSession;
  HasSession: Boolean;
begin
  Session := nil;
  if ActiveSession is TFormSession then
    Session := TFormSession(ActiveSession);
  HasSession := Assigned(Session);
  ActionSaveSession.Enabled := HasSession and Session.CanSaveDocument and Session.Modified;
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
      MessageDlg(Format(rsSessionLoadErrorFmt, [sLineBreak, E.Message]), mtError, [mbOK], 0);
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
  except
    on E: Exception do
      MessageDlg(Format(rsSessionSaveErrorFmt, [sLineBreak, E.Message]), mtError, [mbOK], 0);
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

procedure TFormMain.ActionSettingsExecute(Sender: TObject);
var
  ActiveStyle, SelectedStyle: string;
  ThreadCount, SelectedThreadCount: Integer;
begin
  ActiveStyle := TStyleManager.ActiveStyle.Name;
  ThreadCount := LoadApplicationThreadCount;
  if not TFormSettings.Execute(Self, ActiveStyle, ThreadCount, SelectedStyle,
    SelectedThreadCount) then
    Exit;
  if not ApplyApplicationStyle(SelectedStyle,
    ApplicationStyleDisplayName(SelectedStyle)) then
    Exit;
  try
    SaveApplicationSettings(TStyleManager.ActiveStyle.Name,
      SelectedThreadCount);
  except
    on E: Exception do
      MessageDlg(Format(rsApplicationSettingsSaveErrorFmt,
        [sLineBreak, E.Message]), mtWarning, [mbOK], 0);
  end;
end;

procedure TFormMain.ActionAboutExecute(Sender: TObject);
begin
  TFormAbout.Execute(Self);
end;

end.

