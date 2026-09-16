unit ImageDup.Recycle;

interface

uses Winapi.Windows;

function RecycleFile(OwnerWindow: HWND; const FileName: string;
  out ErrorText: string): Boolean;

implementation

uses System.SysUtils, System.IOUtils, System.Win.ComObj,
  Winapi.ActiveX, Winapi.ShlObj, Winapi.ShellAPI;

const
  RecycleOnDelete = $00080000; // FOFX_RECYCLEONDELETE (Windows 8+).
  AddUndoRecord = $20000000; // FOFX_ADDUNDORECORD.

type
  TRecycleSink = class(TInterfacedObject, IFileOperationProgressSink)
  public
    Recycled, RefusedPermanentDelete: Boolean;
    DeleteResult: HRESULT;
    function StartOperations: HRESULT; stdcall;
    function FinishOperations(hrResult: HRESULT): HRESULT; stdcall;
    function PreRenameItem(dwFlags: DWORD; const psiItem: IShellItem;
      pszNewName: LPCWSTR): HRESULT; stdcall;
    function PostRenameItem(dwFlags: DWORD; const psiItem: IShellItem;
      pszNewName: LPCWSTR; hrRename: HRESULT;
      const psiNewlyCreated: IShellItem): HRESULT; stdcall;
    function PreMoveItem(dwFlags: DWORD; const psiItem: IShellItem;
      const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR): HRESULT; stdcall;
    function PostMoveItem(dwFlags: DWORD; const psiItem: IShellItem;
      const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR;
      hrMove: HRESULT; const psiNewlyCreated: IShellItem): HRESULT; stdcall;
    function PreCopyItem(dwFlags: DWORD; const psiItem: IShellItem;
      const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR): HRESULT; stdcall;
    function PostCopyItem(dwFlags: DWORD; const psiItem: IShellItem;
      const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR;
      hrCopy: HRESULT; const psiNewlyCreated: IShellItem): HRESULT; stdcall;
    function PreDeleteItem(dwFlags: DWORD; const psiItem: IShellItem): HRESULT; stdcall;
    function PostDeleteItem(dwFlags: DWORD; const psiItem: IShellItem;
      hrDelete: HRESULT; const psiNewlyCreated: IShellItem): HRESULT; stdcall;
    function PreNewItem(dwFlags: DWORD; const psiDestinationFolder: IShellItem;
      pszNewName: LPCWSTR): HRESULT; stdcall;
    function PostNewItem(dwFlags: DWORD; const psiDestinationFolder: IShellItem;
      pszNewName, pszTemplateName: LPCWSTR; dwFileAttributes: DWORD;
      hrNew: HRESULT; const psiNewItem: IShellItem): HRESULT; stdcall;
    function UpdateProgress(iWorkTotal, iWorkSoFar: UINT): HRESULT; stdcall;
    function ResetTimer: HRESULT; stdcall;
    function PauseTimer: HRESULT; stdcall;
    function ResumeTimer: HRESULT; stdcall;
  end;

function TRecycleSink.StartOperations: HRESULT;
begin Result := S_OK end;
function TRecycleSink.FinishOperations(hrResult: HRESULT): HRESULT;
begin Result := S_OK end;
function TRecycleSink.PreRenameItem(dwFlags: DWORD; const psiItem: IShellItem;
  pszNewName: LPCWSTR): HRESULT;
begin Result := E_NOTIMPL end;
function TRecycleSink.PostRenameItem(dwFlags: DWORD; const psiItem: IShellItem;
  pszNewName: LPCWSTR; hrRename: HRESULT;
  const psiNewlyCreated: IShellItem): HRESULT;
begin Result := S_OK end;
function TRecycleSink.PreMoveItem(dwFlags: DWORD; const psiItem: IShellItem;
  const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR): HRESULT;
begin Result := E_NOTIMPL end;
function TRecycleSink.PostMoveItem(dwFlags: DWORD; const psiItem: IShellItem;
  const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR;
  hrMove: HRESULT; const psiNewlyCreated: IShellItem): HRESULT;
begin Result := S_OK end;
function TRecycleSink.PreCopyItem(dwFlags: DWORD; const psiItem: IShellItem;
  const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR): HRESULT;
begin Result := E_NOTIMPL end;
function TRecycleSink.PostCopyItem(dwFlags: DWORD; const psiItem: IShellItem;
  const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR;
  hrCopy: HRESULT; const psiNewlyCreated: IShellItem): HRESULT;
begin Result := S_OK end;
function TRecycleSink.PreDeleteItem(dwFlags: DWORD;
  const psiItem: IShellItem): HRESULT;
begin
  RefusedPermanentDelete := (dwFlags and TSF_DELETE_RECYCLE_IF_POSSIBLE) = 0;
  if RefusedPermanentDelete then Result := E_ABORT else Result := S_OK;
end;
function TRecycleSink.PostDeleteItem(dwFlags: DWORD; const psiItem: IShellItem;
  hrDelete: HRESULT; const psiNewlyCreated: IShellItem): HRESULT;
begin
  DeleteResult := hrDelete;
  Recycled := Succeeded(hrDelete) and Assigned(psiNewlyCreated);
  Result := S_OK;
end;
function TRecycleSink.PreNewItem(dwFlags: DWORD;
  const psiDestinationFolder: IShellItem; pszNewName: LPCWSTR): HRESULT;
begin Result := E_NOTIMPL end;
function TRecycleSink.PostNewItem(dwFlags: DWORD;
  const psiDestinationFolder: IShellItem; pszNewName, pszTemplateName: LPCWSTR;
  dwFileAttributes: DWORD; hrNew: HRESULT; const psiNewItem: IShellItem): HRESULT;
begin Result := S_OK end;
function TRecycleSink.UpdateProgress(iWorkTotal, iWorkSoFar: UINT): HRESULT;
begin Result := S_OK end;
function TRecycleSink.ResetTimer: HRESULT;
begin Result := S_OK end;
function TRecycleSink.PauseTimer: HRESULT;
begin Result := S_OK end;
function TRecycleSink.ResumeTimer: HRESULT;
begin Result := S_OK end;

function RecycleFile(OwnerWindow: HWND; const FileName: string;
  out ErrorText: string): Boolean;
var
  Operation: IFileOperation;
  Item: IShellItem;
  Sink: TRecycleSink;
  SinkIntf: IFileOperationProgressSink;
  InitResult, OperationResult: HRESULT;
  Aborted: BOOL;
  FullPath: string;
begin
  Result := False;
  ErrorText := '';
  InitResult := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  if Failed(InitResult) then begin
    ErrorText := 'Impossibile inizializzare le operazioni del Cestino.';
    Exit;
  end;
  try
    try
      FullPath := TPath.GetFullPath(FileName);
      if not FileExists(FullPath) then
        raise EFileNotFoundException.Create('File non disponibile.');
      Operation := CreateComObject(CLSID_FileOperation) as IFileOperation;
      OleCheck(Operation.SetOwnerWindow(OwnerWindow));
      OleCheck(Operation.SetOperationFlags(RecycleOnDelete or AddUndoRecord or
        FOF_NOERRORUI or FOF_NOCONFIRMATION or FOF_NO_CONNECTED_ELEMENTS));
      OleCheck(SHCreateItemFromParsingName(PWideChar(FullPath), nil,
        IID_IShellItem, Item));
      Sink := TRecycleSink.Create;
      Sink.DeleteResult := E_FAIL;
      SinkIntf := Sink;
      OleCheck(Operation.DeleteItem(Item, SinkIntf));
      OperationResult := Operation.PerformOperations;
      Aborted := False;
      OleCheck(Operation.GetAnyOperationsAborted(Aborted));
      Result := Sink.Recycled and not FileExists(FullPath);
      if not Result then begin
        if Sink.RefusedPermanentDelete then
          ErrorText := 'Cestino non disponibile: cancellazione definitiva bloccata.'
        else if Aborted then ErrorText := 'Operazione annullata o non completata.'
        else if Failed(OperationResult) then
          ErrorText := Format('Errore Windows 0x%.8x.', [Cardinal(OperationResult)])
        else
          ErrorText := Format('File non spostato nel Cestino (0x%.8x).',
            [Cardinal(Sink.DeleteResult)]);
      end;
    except
      on E: Exception do ErrorText := E.Message;
    end;
  finally
    SinkIntf := nil;
    Item := nil;
    Operation := nil;
    CoUninitialize;
  end;
end;

end.
