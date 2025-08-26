unit uWatcherKiller;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.TlHelp32,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms, Vcl.ExtCtrls, Vcl.Menus, Vcl.Controls, Vcl.Graphics;

type
  TEnumProcEvent = procedure(PID: Cardinal; const Exe: string) of object;

  TAntiMAXForm = class(TForm)
  private
    FTray: TTrayIcon;
    FTimer: TTimer;
    FSeenPIDs: TDictionary<Cardinal, Boolean>;
    FProcessName: string;
    FPopup: TPopupMenu;
    procedure TimerTick(Sender: TObject);
    procedure ShowBalloon(const Title, Text: string);
    procedure CreateTray;
    procedure ExitClick(Sender: TObject);
    procedure InitialScanProc(PID: Cardinal; const Exe: string);
    procedure TimerScanProc(PID: Cardinal; const Exe: string);
    procedure KillProcess(PID: Cardinal);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  AntiMAXForm: TAntiMAXForm;

implementation

{$R *.dfm}

procedure EnumProcesses(OnProc: TEnumProcEvent);
var
  Snap: THandle;
  PE: TProcessEntry32;
begin
  Snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snap = INVALID_HANDLE_VALUE then Exit;
  try
    ZeroMemory(@PE, SizeOf(PE));
    PE.dwSize := SizeOf(PE);
    if Process32First(Snap, PE) then
      repeat
        OnProc(PE.th32ProcessID, string(PE.szExeFile));
      until not Process32Next(Snap, PE);
  finally
    CloseHandle(Snap);
  end;
end;

constructor TAntiMAXForm.Create(AOwner: TComponent);
begin
  inherited;
  Visible := False;
  Application.ShowMainForm := False;

  FSeenPIDs := TDictionary<Cardinal, Boolean>.Create;
  FProcessName := 'MAX.exe';
  CreateTray;
  EnumProcesses(InitialScanProc);
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 1000; // 1 секунда
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := True;
end;

destructor TAntiMAXForm.Destroy;
begin
  FTimer.Free;
  FTray.Free;
  FPopup.Free;
  FSeenPIDs.Free;
  inherited;
end;

procedure TAntiMAXForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW;
end;

procedure TAntiMAXForm.CreateTray;
var
  MI: TMenuItem;
begin
  FPopup := TPopupMenu.Create(Self);
  MI := TMenuItem.Create(FPopup);
  MI.Caption := 'Выход';
  MI.OnClick := ExitClick;
  FPopup.Items.Add(MI);

  FTray := TTrayIcon.Create(Self);
  FTray.Visible := True;
  FTray.Hint := 'MAX Watcher';
  FTray.Icon := Application.Icon;
  FTray.PopupMenu := FPopup;
end;

procedure TAntiMAXForm.ExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TAntiMAXForm.ShowBalloon(const Title, Text: string);
begin
  if Assigned(FTray) then
  begin
    FTray.BalloonTitle := Title;
    FTray.BalloonHint  := Text;
    FTray.BalloonFlags := bfInfo;
    FTray.ShowBalloonHint;
  end;
end;

procedure TAntiMAXForm.InitialScanProc(PID: Cardinal; const Exe: string);
begin
  if SameText(Exe, FProcessName) then
    FSeenPIDs.TryAdd(PID, True);
end;

procedure TAntiMAXForm.TimerScanProc(PID: Cardinal; const Exe: string);
begin
  if SameText(Exe, FProcessName) then
    if not FSeenPIDs.ContainsKey(PID) then
    begin
      FSeenPIDs.Add(PID, True);
      // Показать предупреждение о наличии процесса
      // ShowBalloon('Обнаружен запуск', Format('%s (PID=%d)', [FProcessName, PID]));
      // "Убить процесс". Если не надо "убивать", закомментируйте одну строку ниже.
      KillProcess(PID);
    end;
end;

procedure TAntiMAXForm.TimerTick(Sender: TObject);
var
  Current: TDictionary<Cardinal, Boolean>;
  ToRemove: TList<Cardinal>;
begin
  Current := TDictionary<Cardinal, Boolean>.Create;
  try
    EnumProcesses(TimerScanProc);
    ToRemove := TList<Cardinal>.Create;
    try
      for var K in FSeenPIDs.Keys do
        if not Current.ContainsKey(K) then
          ToRemove.Add(K);

      for var PID in ToRemove do
        FSeenPIDs.Remove(PID);
    finally
      ToRemove.Free;
    end;
  finally
    Current.Free;
  end;
end;

procedure TAntiMAXForm.KillProcess(PID: Cardinal);
var
  exitcode: UINT;
  x: THandle;
begin
  x := OpenProcess(PROCESS_TERMINATE, False, PID);
  if x <> 0 then
  begin
    try
      GetExitCodeProcess(x, ExitCode);
      TerminateProcess(x, ExitCode);
    finally
      CloseHandle(x);
    end;
  end;
end;

end.

