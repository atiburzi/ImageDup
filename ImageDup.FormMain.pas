unit ImageDup.FormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ActnList,
  System.Actions, System.UITypes, Vcl.Menus, Vcl.FormTabsBar,
  Vcl.StdCtrls, Vcl.Themes, Vcl.TitleBarCtrls, Vcl.ToolWin;

const
  WM_UPDATE_HEADER = WM_APP + $120;

type
  TFormMain = class(TForm)
    ToolBar: TToolBar;
    MenuBar: TToolBar;
    ToolButtonNew: TToolButton;
    ToolButtonLoad: TToolButton;
    ToolButtonSave: TToolButton;
    ToolButtonFileSeparator: TToolButton;
    ToolButtonAbout: TToolButton;
    StyleComboBox: TComboBox;
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
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure StyleComboBoxChange(Sender: TObject);
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
    FUpdatingStyleCombo: Boolean;
    FStyleNames: TArray<string>;
    FUpdatingHeader: Boolean;
    function ActiveSession: TForm;
    procedure SaveActiveSession(ForceFileName: Boolean);
    procedure OpenCommandLineSessions;
    function ActiveStyleComboIndex: Integer;
    procedure UpdateStyleComboBounds;
    procedure WMUpdateHeader(var Message: TMessage); message WM_UPDATE_HEADER;
  protected
    procedure WndProc(var Message: TMessage); override;
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
  ImageDup.FormSession, ImageDup.FormAbout, ImageDup.Settings;

resourcestring
  rsUntitledSessionFmt = 'Session %d';
  rsSessionLoadedFileFmt = 'Session loaded: %s | Scanned: %d';
  rsSessionLoadErrorFmt = 'Unable to load the session:%s%s';
  rsSessionSavedFmt = 'Session saved: %s';
  rsSessionSaveErrorFmt = 'Unable to save the session:%s%s';
  rsCloseBusySessions = 'One or more sessions are busy. Stop the current operations before closing ImageDup.';
  rsStyleUnavailable = 'The selected style is unavailable.';
  rsStyleChangeErrorFmt = 'Unable to apply GUI style %s:%s%s';

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
  // before measuring the title bar. Do not recreate its controls a second time.
  if StyleChanged and not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_UPDATE_HEADER, 0, 0);
end;

procedure TFormMain.WMUpdateHeader(var Message: TMessage);
var
  UpdatingStyleCombo: Boolean;
begin
  Message.Result := 0;
  if (csDestroying in ComponentState) or FUpdatingHeader or not Assigned(TitleBarPanel) or not Assigned(StyleComboBox) then
    Exit;
  UpdatingStyleCombo := FUpdatingStyleCombo;
  FUpdatingStyleCombo := True;
  FUpdatingHeader := True;
  try
    if CustomTitleBar.Enabled and (WindowState <> wsMinimized) then
    begin
      TitleBarPanel.Width := ClientWidth;
      // TTitleBarPanel.Paint updates its bounds and caption buttons through
      // VCL's own UpdateAlign, including maximized-window and DPI offsets.
      TitleBarPanel.Repaint;
    end;
    UpdateStyleComboBounds;
    StyleComboBox.ItemIndex := ActiveStyleComboIndex;
    MenuBar.Invalidate;
  finally
    FUpdatingHeader := False;
    FUpdatingStyleCombo := UpdatingStyleCombo;
  end;
end;

resourcestring
  rsStyleLight = 'Light Theme';
  rsStyleBlue = 'Blue Theme';
  rsStyleDark = 'Dark Theme';
  rsStyleGreen = 'Green Theme';
  rsStylePurple = 'Purple Theme';
  rsStyleSlateGray = 'Slate Gray Theme';

function StyleDisplayName(const StyleName: string): string;
begin
  if SameText(StyleName, 'Windows10') then
    Result := rsStyleLight
  else if SameText(StyleName, 'Windows10 Blue') then
    Result := rsStyleBlue
  else if SameText(StyleName, 'Windows10 Dark') then
    Result := rsStyleDark
  else if SameText(StyleName, 'Windows10 Green') then
    Result := rsStyleGreen
  else if SameText(StyleName, 'Windows10 Purple') then
    Result := rsStylePurple
  else if SameText(StyleName, 'Windows10 SlateGray') then
    Result := rsStyleSlateGray
  else
    Result := StyleName;
end;

function TFormMain.ActiveStyleComboIndex: Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FStyleNames) do
    if SameText(FStyleNames[I], TStyleManager.ActiveStyle.Name) then
      Exit(I);
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  StyleName: string;
begin
  if not CustomTitleBar.Enabled then
  begin
    GlassFrame.Enabled := False;
    GlassFrame.Top := 0;
    TitleBarPanel.Visible := False;
  end;
  UpdateStyleComboBounds;
  FUpdatingStyleCombo := True;
  StyleComboBox.Items.BeginUpdate;
  try
    // Keep captions and internal VCL style names aligned by index.
    StyleComboBox.Sorted := False;
    StyleComboBox.Items.Clear;
    SetLength(FStyleNames, 0);
    for StyleName in TStyleManager.StyleNames do
      if StyleName <> 'Windows' then
      begin
        SetLength(FStyleNames, Length(FStyleNames) + 1);
        FStyleNames[High(FStyleNames)] := StyleName;
        StyleComboBox.Items.Add(StyleDisplayName(StyleName));
      end;
    StyleComboBox.ItemIndex := ActiveStyleComboIndex;
  finally
    StyleComboBox.Items.EndUpdate;
    FUpdatingStyleCombo := False;
  end;
end;

procedure TFormMain.UpdateStyleComboBounds;
var
  ButtonsRect: TRect;
  ParentWidth, ParentHeight, ButtonsLeft, ButtonWidth, Gap, ComboWidth, AvailableWidth, X, Y: Integer;

  procedure ReserveCaptionButton(Control: TControl);
  begin
    if Assigned(Control) and Control.Visible then
      Inc(ButtonWidth, Control.Width);
  end;

begin
  if not Assigned(StyleComboBox) or not Assigned(TitleBarPanel) or (StyleComboBox.Parent = nil) then
    Exit;
  ParentWidth := StyleComboBox.Parent.ClientWidth;
  ParentHeight := StyleComboBox.Parent.ClientHeight;
  // Handle recreation can temporarily report an empty client area. Preserve
  // visibility until the real dimensions are available after the style change.
  if (ParentWidth <= 0) or (ParentHeight <= 0) then
    Exit;
  Gap := MulDiv(10, CurrentPPI, 96);
  ComboWidth := MulDiv(150, CurrentPPI, 96);
  ButtonsLeft := ParentWidth;
  ButtonWidth := 0;
  if CustomTitleBar.Enabled then
  begin
    if not CustomTitleBar.SystemButtons then
    begin
      ReserveCaptionButton(TitleBarPanel.TitleButtonMin);
      ReserveCaptionButton(TitleBarPanel.TitleButtonRestore);
      ReserveCaptionButton(TitleBarPanel.TitleButtonClose);
      if ButtonWidth > 0 then
        ButtonsLeft := ParentWidth - ButtonWidth;
    end;
    if ButtonsLeft = ParentWidth then
    begin
      ButtonsRect := CustomTitleBar.CaptionButtonsRect;
      if ButtonsRect.Width > 0 then
        ButtonsLeft := ParentWidth - ButtonsRect.Width
      else
        ButtonsLeft := ParentWidth - MulDiv(138, CurrentPPI, 96);
    end;
  end;
  AvailableWidth := ButtonsLeft - 2 * Gap;
  StyleComboBox.Visible := AvailableWidth >= MulDiv(100, CurrentPPI, 96);
  if not StyleComboBox.Visible then
    Exit;
  if ComboWidth > AvailableWidth then
    ComboWidth := AvailableWidth;
  X := ButtonsLeft - Gap - ComboWidth;
  Y := (ParentHeight - StyleComboBox.Height) div 2;
  if Y < 0 then
    Y := 0;
  StyleComboBox.SetBounds(X, Y, ComboWidth, StyleComboBox.Height);
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  if FUpdatingHeader or FUpdatingStyleCombo or (csLoading in ComponentState) then
    Exit;
  UpdateStyleComboBounds;
end;

resourcestring
  rsStylePreferenceSaveErrorFmt = 'The GUI style was applied, but the preference could not be saved:%s%s';

procedure TFormMain.StyleComboBoxChange(Sender: TObject);
var
  StyleName, DisplayName, ErrorText: string;
begin
  if FUpdatingStyleCombo or (StyleComboBox.ItemIndex < 0) or (StyleComboBox.ItemIndex >= Length(FStyleNames)) then
    Exit;
  StyleName := FStyleNames[StyleComboBox.ItemIndex];
  DisplayName := StyleComboBox.Items[StyleComboBox.ItemIndex];
  if SameText(StyleName, TStyleManager.ActiveStyle.Name) then
    Exit;
  ErrorText := '';
  FUpdatingStyleCombo := True;
  try
    try
      if not TStyleManager.TrySetStyle(StyleName, False) then
        ErrorText := rsStyleUnavailable;
    except
      on E: Exception do
        ErrorText := E.Message;
    end;
    StyleComboBox.ItemIndex := ActiveStyleComboIndex;
  finally
    FUpdatingStyleCombo := False;
  end;
  // Successful switches are followed by CM_CUSTOMSTYLECHANGED; updating
  // here would still use the old HWND and can hide the combo during resize.
  if ErrorText <> '' then
    MessageDlg(Format(rsStyleChangeErrorFmt, [DisplayName, sLineBreak, ErrorText]), mtError, [mbOK], 0)
  else
    try
      SaveApplicationStyle(TStyleManager.ActiveStyle.Name);
    except
      on E: Exception do
        MessageDlg(Format(rsStylePreferenceSaveErrorFmt, [sLineBreak, E.Message]),
          mtWarning, [mbOK], 0);
    end;
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  PostMessage(Handle, WM_UPDATE_HEADER, 0, 0);
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

procedure TFormMain.ActionAboutExecute(Sender: TObject);
begin
  TFormAbout.Execute(Self);
end;

end.

