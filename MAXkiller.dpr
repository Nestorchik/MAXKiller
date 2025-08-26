program MAXkiller;

uses
  Vcl.Forms,
  Windows,
  uWatcherKiller in 'uWatcherKiller.pas' {Form1};

{$R *.res}

var
  MutexHandle: THandle;

begin
  // Создаем уникальный семафор для приложения
  MutexHandle := CreateMutex(nil, True, 'Global\MyUniqueAppMutex');
  // Проверяем, существует ли уже такой семафор
  if (MutexHandle <> 0) then
  begin
    if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      // Если семафор уже существует - значит приложение уже запущено
      // раскомментировать строку ниже, если надо вывести сообщение.
      MessageBox(0, 'Программа уже запущена!', 'Предупреждение', MB_OK or MB_ICONWARNING);
      CloseHandle(MutexHandle);
      Halt; // Завершаем работу программы
    end;
  end
  else
  begin
    // Обработка ошибки создания семафора
    MessageBox(0, 'Ошибка создания семафора', 'Ошибка', MB_OK or MB_ICONERROR);
    Halt;
  end;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := False;  // скрыть главное окно
  Application.CreateForm(TAntiMAXForm, AntiMAXForm);
  Application.Run;
end.

