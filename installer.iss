[Setup]
AppId={{E7A41C92-5D3B-4F18-9A6C-2B8D7E015F44}
AppName=MyNihongo!!!!!
AppVersion=0.4.7
AppPublisher=yuanzhe
AppPublisherURL=https://github.com/yuanzhe
DefaultDirName={autopf}\MyNihongo!!!!!
DefaultGroupName=MyNihongo!!!!!
UninstallDisplayIcon={app}\my_nihongo.exe
OutputDir=build\installer
#ifdef ARM64
OutputBaseFilename=MyNihongo_{#SetupSetting("AppVersion")}_arm64_Setup
#else
OutputBaseFilename=MyNihongo_{#SetupSetting("AppVersion")}_Setup
#endif
VersionInfoVersion=0.4.7.0
VersionInfoCompany=yuanzhe
VersionInfoDescription=MyNihongo!!!!! Installer
VersionInfoProductName=MyNihongo!!!!!
VersionInfoProductVersion=0.4.7
Compression=lzma2
SolidCompression=yes
#ifdef ARM64
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
#ifdef ARM64
Source: "build\windows\arm64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
#else
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
#endif

[Icons]
Name: "{group}\MyNihongo!!!!!"; Filename: "{app}\my_nihongo.exe"
Name: "{group}\{cm:UninstallProgram,MyNihongo!!!!!}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MyNihongo!!!!!"; Filename: "{app}\my_nihongo.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\my_nihongo.exe"; Description: "{cm:LaunchProgram,MyNihongo!!!!!}"; Flags: nowait postinstall skipifsilent
