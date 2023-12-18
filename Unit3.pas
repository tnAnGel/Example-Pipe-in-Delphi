unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdDNSResolver, Winapi.WinSock,
  System.Win.ScktComp, StrUtils, System.RegularExpressions;

type
  TForm3 = class(TForm)
    Edit1: TEdit;
    Memo1: TMemo;
    Button1: TButton;
    Memo2: TMemo;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

function ExecuteFindomain(Target: string): TStringList;
var
  SecurityAttr: TSecurityAttributes;
  StdOutRead, StdOutWrite: THandle;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  BytesRead: Cardinal;
  Buffer: array[0..255] of AnsiChar;
  ReturnValue, ReturnClearValue: TStringList;
  I: Integer;
begin
  SecurityAttr.nLength := SizeOf(SecurityAttr);
  SecurityAttr.bInheritHandle := True;
  SecurityAttr.lpSecurityDescriptor := nil;

  if not CreatePipe(StdOutRead, StdOutWrite, @SecurityAttr, 0) then
    raise Exception.Create('Could not create output pipe for Findomain process');

  try
    FillChar(StartupInfo, Sizeof(TStartupInfo), 0);
    FillChar(ProcessInfo, Sizeof(TProcessInformation), 0);
    StartupInfo.cb := Sizeof(TStartupInfo);
    StartupInfo.hStdOutput := StdOutWrite;
    StartupInfo.hStdError := StdOutWrite;
    StartupInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;

    if not CreateProcess(nil, PChar('findomain.exe -t ' + Target), nil, nil, True, 0, nil, nil, StartupInfo, ProcessInfo) then
      raise Exception.Create('Could not execute Findomain');

    CloseHandle(StdOutWrite);
    ReturnValue := TStringList.Create;

    repeat
      ReadFile(StdOutRead, Buffer[0], Length(Buffer), BytesRead, nil);
      ReturnValue.Text := ReturnValue.Text + string(AnsiString(Copy(Buffer, 0, BytesRead)));
    until BytesRead = 0;

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(StdOutRead);

    ReturnClearValue := TStringList.Create;
    try
      ReturnClearValue.Duplicates := dupIgnore;
      for I := 0 to ReturnValue.Count-1 do
        if (Pos(Target, ReturnValue[i]) <> 0) and (Pos('Target ==>', ReturnValue[i]) = 0) then
           ReturnClearValue.Add(ReturnValue[i]);
    finally

    end;

  except
    ReturnValue.Free;
    raise;
  end;

  Result := ReturnClearValue;
end;

function ResolveDomainToIP(const domain: string): string;
var
  wsaData: TWSAData;
  addr: PHostEnt;
  ip: PAnsiChar;
begin
  if WSAStartup(MakeWord(2, 2), wsaData) = 0 then
  begin
    try
      addr := gethostbyname(PAnsiChar(AnsiString(domain))); // выполняем DNS-запрос для домена
      if addr <> nil then
      begin
        ip := inet_ntoa(PInAddr(addr^.h_addr_list^)^); // преобразуем IP-адрес в строку
        Result := string(ip);
      end
      else
      begin
        Result := 'IP адрес не найден'; // Можно задать другое сообщение об ошибке
      end;
    finally
      WSACleanup;
    end;
  end
  else
  begin
    Result := 'Ошибка инициализации Winsock';
  end;
end;

function RunNmap(const AParams: string): string;
var
  SecurityAttributes: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  BytesRead: Cardinal;
  Buffer: array [0..255] of AnsiChar;
  AppRunning: DWord;
begin
  Result := '';
  // Создание анонимного канала
  SecurityAttributes.nLength := SizeOf(TSecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;
  if not CreatePipe(ReadPipe, WritePipe, @SecurityAttributes, 0) then
    Exit;

  try
    // Инициализация структуры STARTUPINFO
    FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
    StartupInfo.cb := SizeOf(TStartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdOutput := WritePipe;

    // Запуск nmap
    if CreateProcess(nil, PWideChar('C:\Program Files (x86)\Nmap\nmap.exe ' + AParams), nil, nil, True, NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then
    begin
      CloseHandle(WritePipe); // Закрыть дескриптор записи, так как он больше не нужен

      repeat
        AppRunning := WaitForSingleObject(ProcessInfo.hProcess, 100);
        repeat
          BytesRead := 0;
          if not ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) then
            Break;
          Buffer[BytesRead] := #0;
          Result := Result + string(Buffer);
        until (BytesRead < SizeOf(Buffer));
      until (AppRunning <> WAIT_TIMEOUT);

      CloseHandle(ProcessInfo.hThread);
      CloseHandle(ProcessInfo.hProcess);
    end;
  finally
    CloseHandle(ReadPipe); // Закрыть дескриптор чтения
  end;
end;

function ExtractPorts(const Input: string): TStringList;
var
  PortsList: TStringList;
  Regex: TRegEx;
  Matches: TMatchCollection;
  Match: TMatch;
  i: Integer;
begin
  PortsList := TStringList.Create;
  try
    // Создаем регулярное выражение для поиска портов
    Regex := TRegEx.Create('\d{1,5}(?=/tcp)', [roIgnoreCase]);

    // Находим все соответствия в строке и добавляем их в список портов
    Matches := Regex.Matches(Input);
    for i := 0 to Matches.Count - 1 do
    begin
      Match := Matches.Item[i];
      PortsList.Add(Match.Value);
    end;

    Result := PortsList;
  except
    PortsList.Free;
    raise;
  end;
end;

procedure TForm3.Button1Click(Sender: TObject);
var i: Integer;
begin
  Memo1.Lines.Text := TStringList(ExecuteFindomain(Edit1.Text)).Text;
  for I := 0 to Memo1.Lines.Count-1 do
    if Length(Memo1.Lines[i]) > 0 then
      Memo2.Lines.Add(Memo1.Lines[i] + ' --> ' + ResolveDomainToIP(Memo1.Lines[i]));
end;

procedure TForm3.Button2Click(Sender: TObject);
var
  ScanResult: string;
  Output: string;
  PortsList: TStringList;
  i: integer;
begin
  // Запуск сканирования с указанными параметрами
  //  -p 1-65535  nmap -p 80 --script http-enum <целевой IP-адрес>
  ScanResult := RunNmap(' --open --defeat-rst-ratelimit localhost -p 1-65535 ');
  // Обработка результатов сканирования
  // Например, отображение результатов в Memo1
  Memo1.Lines.Add(ScanResult);
  // Предположим, что вам уже доступен вывод от nmap
  Output := ScanResult; // ваш вывод от nmap

  // Получение списка портов
  PortsList := TStringList.Create;
  PortsList := ExtractPorts(Output);

  // Использование списка портов
  for i := 0 to PortsList.Count - 1 do
    Memo2.Lines.Add(PortsList[i]);

  // Освобождение списка портов
  PortsList.Free;
end;

end.
