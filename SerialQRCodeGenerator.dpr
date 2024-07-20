program SerialQRCodeGenerator;

uses
  Vcl.Forms,
  UnitMain in 'UnitMain.pas' {FormMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Smokey Quartz Kamri');
  Application.Title := 'Serial QR Code Generator';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
