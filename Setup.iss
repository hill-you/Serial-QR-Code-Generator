[Setup]
AppName=Serial QR Code Generator
AppId=SerialQRCodeGenerator
AppVerName={cm:MyAppName} v1.1.1.1
DefaultDirName={localappdata}\{cm:MyDirName}
DefaultGroupName={cm:MyAppName}
UninstallDisplayIcon="{app}\SerialQRCodeGenerator.EXE"
VersionInfoDescription=Serial QR Code Generator Setup
VersionInfoVersion=1.1.1.1
VersionInfoProductName=Serial QR Code Generator
OutputBaseFilename=SerialQRCodeGeneratorSetup
DisableWelcomePage=no
;Uninstallable=no 

[CustomMessages]
MyAppName=Serial QR Code Generator
MyDirName=SerialQRCodeGenerator

[Dirs] 
Name: "{app}"
Name: "{app}\Template"; Flags: uninsneveruninstall;

[Files]
Source: "SerialQRCodeGenerator.exe"; DestDir: "{app}"; Flags: replacesameversion  ignoreversion
Source: "Template\*"; DestDir: "{app}\Template\"; Flags: uninsneveruninstall onlyifdoesntexist

[Icons]
Name: "{group}\{cm:MyAppName}"; Filename: "{app}\SerialQRCodeGenerator.exe"
Name: "{group}\Template"; Filename: "{app}\Template"
Name: "{group}\Uninstall {cm:MyAppName}"; Filename: "{uninstallexe}"     

[Run]
Filename: "{app}\SerialQRCodeGenerator.EXE";  Description: "Run {cm:MyAppName}"; Flags: postinstall nowait  skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{group}"
Type: files; Name: "{app}"