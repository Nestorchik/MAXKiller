program MAXkiller;

uses
  Vcl.Forms,
  Windows,
  uWatcherKiller in 'uWatcherKiller.pas' {Form1};

{$R *.res}

var
  MutexHandle: THandle;

begin
  // ������� ���������� ������� ��� ����������
  MutexHandle := CreateMutex(nil, True, 'Global\MyUniqueAppMutex');
  // ���������, ���������� �� ��� ����� �������
  if (MutexHandle <> 0) then
  begin
    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      // ���� ������� ��� ���������� - ������ ���������� ��� ��������
      // ����������������� ������ ����, ���� ���� ������� ���������.
      MessageBox(0, '��������� ��� ��������!', '��������������', MB_OK or MB_ICONWARNING);
      CloseHandle(MutexHandle);
      Halt; // ��������� ������ ���������
    end;
  end
  else
  begin
    // ��������� ������ �������� ��������
    MessageBox(0, '������ �������� ��������', '������', MB_OK or MB_ICONERROR);
    Halt;
  end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := False;  // ������ ������� ����
  Application.CreateForm(TAntiMAXForm, AntiMAXForm);
  Application.Run;
end.

