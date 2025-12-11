; LM Light Inno Setup Script
; Requires Inno Setup 6.0 or later: https://jrsoftware.org/isinfo.php

#define MyAppName "LM Light"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Digital Base"
#define MyAppURL "https://digital-base.co.jp/services/localllm/lmlight-purchase"
#define MyAppExeName "lmlight-api.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
AppId={{A5D7E8F9-1234-5678-90AB-CDEF12345678}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\lmlight
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=LMLight-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
; SetupIconFile=..\assets\lmlight.ico  ; TODO: Convert LMLight.icns to lmlight.ico
; UninstallDisplayIcon={app}\bin\{#MyAppExeName}

[Languages]
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startmenu"; Description: "スタートメニューに追加"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Backend binary
Source: "..\releases\lmlight-api-windows-amd64.exe"; DestDir: "{app}\bin"; DestName: "lmlight-api.exe"; Flags: ignoreversion

; Frontend (extracted from tar.gz during build)
Source: "..\releases\frontend\*"; DestDir: "{app}\frontend"; Flags: ignoreversion recursesubdirs createallsubdirs

; Scripts
Source: "..\scripts\*.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

; Config template
Source: "..\templates\.env.example"; DestDir: "{app}"; DestName: ".env"; Flags: onlyifdoesntexist

; License
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{app}\logs"
Name: "{app}\data"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\scripts\toggle.ps1"""; Comment: "LM Light を起動/停止"
Name: "{group}\{#MyAppName} Start"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\start.ps1"""; Comment: "LM Light を起動"
Name: "{group}\{#MyAppName} Stop"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\stop.ps1"""; Comment: "LM Light を停止"
Name: "{group}\Web UI"; Filename: "http://localhost:3000"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\scripts\toggle.ps1"""; Tasks: desktopicon

[Run]
; Check dependencies after installation
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\check-dependencies.ps1"""; Flags: postinstall runhidden; Description: "依存関係をチェック"

[Code]
var
  DependenciesPage: TOutputMsgMemoWizardPage;
  NodeJSInstalled: Boolean;
  PostgreSQLInstalled: Boolean;
  OllamaInstalled: Boolean;
  TesseractInstalled: Boolean;

function CheckDependency(Command: String): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('powershell.exe', '-NoProfile -Command "Get-Command ' + Command + ' -ErrorAction SilentlyContinue"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InitializeWizard();
begin
  DependenciesPage := CreateOutputMsgMemoPage(wpSelectDir,
    '依存関係の確認',
    'LM Light の実行には以下のソフトウェアが必要です',
    'インストール後に各ソフトウェアをインストールしてください。',
    '');
end;

function GetRandomString(Len: Integer): String;
var
  I: Integer;
  Chars: String;
  CharIndex: Integer;
  CharsLen: Integer;
begin
  Chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  CharsLen := Length(Chars);
  Result := '';
  for I := 1 to Len do
  begin
    CharIndex := Random(CharsLen) + 1;
    Result := Result + Copy(Chars, CharIndex, 1);
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = wpSelectDir then
  begin
    // Check dependencies
    NodeJSInstalled := CheckDependency('node');
    PostgreSQLInstalled := CheckDependency('psql');
    OllamaInstalled := CheckDependency('ollama');
    TesseractInstalled := CheckDependency('tesseract');

    DependenciesPage.RichEditViewer.Clear;

    if NodeJSInstalled then
      DependenciesPage.RichEditViewer.Lines.Add('[✓] Node.js: インストール済み')
    else
      DependenciesPage.RichEditViewer.Lines.Add('[×] Node.js: 未インストール - winget install OpenJS.NodeJS.LTS');

    if PostgreSQLInstalled then
      DependenciesPage.RichEditViewer.Lines.Add('[✓] PostgreSQL: インストール済み')
    else
      DependenciesPage.RichEditViewer.Lines.Add('[×] PostgreSQL: 未インストール - winget install PostgreSQL.PostgreSQL');

    if OllamaInstalled then
      DependenciesPage.RichEditViewer.Lines.Add('[✓] Ollama: インストール済み')
    else
      DependenciesPage.RichEditViewer.Lines.Add('[×] Ollama: 未インストール - winget install Ollama.Ollama');

    if TesseractInstalled then
      DependenciesPage.RichEditViewer.Lines.Add('[✓] Tesseract OCR: インストール済み')
    else
      DependenciesPage.RichEditViewer.Lines.Add('[×] Tesseract OCR: 未インストール - https://github.com/UB-Mannheim/tesseract/wiki');

    DependenciesPage.RichEditViewer.Lines.Add('');
    DependenciesPage.RichEditViewer.Lines.Add('※ インストール後、不足しているソフトウェアをインストールしてください');
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  EnvContent: String;
  EnvFile: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Generate .env file if it doesn't exist
    EnvFile := ExpandConstant('{app}\.env');
    if not FileExists(EnvFile) then
    begin
      EnvContent := 'DATABASE_URL=postgresql://lmlight:lmlight@localhost:5432/lmlight' + #13#10 +
                    'OLLAMA_BASE_URL=http://localhost:11434' + #13#10 +
                    'LICENSE_FILE_PATH=' + ExpandConstant('{app}\license.lic') + #13#10 +
                    'NEXTAUTH_SECRET=' + GetRandomString(32) + #13#10 +
                    'NEXTAUTH_URL=http://localhost:3000' + #13#10 +
                    'NEXT_PUBLIC_API_URL=http://localhost:8000';
      SaveStringToFile(EnvFile, EnvContent, False);
    end;
  end;
end;