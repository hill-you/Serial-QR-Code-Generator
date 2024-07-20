unit UnitMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, PRINTERS,
  DelphiZXIngQRCode, Vcl.FileCtrl, JvDriveCtrls, System.IniFiles, Vcl.ComCtrls,System.StrUtils,
  Vcl.AppEvnts, System.RegularExpressions;


type
  TFormMain = class(TForm)
    Preview: TImage;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Label1: TLabel;
    Templates: TJvFileListBox;
    Splitter2: TSplitter;
    Panel4: TPanel;
    Label2: TLabel;
    Edit1: TEdit;
    No: TUpDown;
    ButtonPrint: TButton;
    Label3: TLabel;
    Edit2: TEdit;
    Count: TUpDown;
    DateFrom: TDateTimePicker;
    Label4: TLabel;
    TimeFrom: TDateTimePicker;
    TimeTo: TDateTimePicker;
    Label5: TLabel;
    Label6: TLabel;
    Bevel1: TBevel;
    PrintLabel1: TLabel;
    PrintLabel: TLabel;
    ApplicationEvents1: TApplicationEvents;
    Printed: TLabel;
    TimerPrinted: TTimer;
    procedure Print(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TemplatesChange(Sender: TObject);
    procedure FormaChange(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure TimerPrintedTimer(Sender: TObject);
  private
    { Private declarations }
    FQRCode: TDelphiZXingQRCode;
    config: TIniFile;
    Printing: boolean;
    PrintCheckIndex: integer;
    procedure RemakeQR(section: string);
    procedure PaintLine(section: string);
    procedure FullReduildRecript;
    function RandomReplaceEvaluator(const Match: TMatch): string;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses
  QRGraphics, QR_Win1251, QR_URL, Math, DateUtils;

{$R *.dfm}

procedure AngleTextOut(ACanvas: TCanvas; Angle, X, Y: Integer; Str: string; lfWidth: Integer = 0);
var
  LogRec: TLogFont;
  OldFontHandle,
  NewFontHandle: hFont;
begin
  GetObject(ACanvas.Font.Handle, SizeOf(LogRec), Addr(LogRec));
  LogRec.lfEscapement := Angle*10;
  if lfWidth > 0 then LogRec.lfWidth := lfWidth;
  NewFontHandle := CreateFontIndirect(LogRec);
  OldFontHandle := SelectObject(ACanvas.Handle, NewFontHandle);
  ACanvas.TextOut(X, Y, Str);
  NewFontHandle := SelectObject(ACanvas.Handle, OldFontHandle);
  DeleteObject(NewFontHandle);
end;

function RandomString(const ALength: Integer; CharType: string = ''): String;
var
  i: Integer;
  LCharType: Integer;
  types: array of integer;
begin
  Result := '';

  if CharType = '' then CharType := 'Aa0';
  if Pos('A', CharType) > 0 then begin SetLength(types, Length(types)+1); types[Length(types)-1] := 1; end;
  if Pos('a', CharType) > 0 then begin SetLength(types, Length(types)+1); types[Length(types)-1] := 0; end;
  if Pos('0', CharType) > 0 then begin SetLength(types, Length(types)+1); types[Length(types)-1] := 2; end;

  if Length(types) <= 0 then exit;

  for i := 1 to ALength do
  begin
  //  LCharType := IfThen(CharType = -3, Random(3), IfThen(CharType = -2, Random(2), CharType));
    case types[Random(Length(types))] of
      0: Result := Result + Chr(ord('a') + Random(26));
      1: Result := Result + Chr(ord('A') + Random(26));
      2: Result := Result + Chr(ord('0') + Random(10));
    end;
  end;
end;

procedure TFormMain.Print(Sender: TObject);
begin
  if Templates.ItemIndex < 0 then
    raise Exception.Create('Select Template!');

  if Printing then begin
    Printer.Abort;
    Printing := false;
    exit;
  end;

  try
    Printing := true;
    PrintCheckIndex := 0;
    ButtonPrint.Caption := 'Stop print';
    PrintLabel.Visible := true;
    PrintLabel1.Visible := true;
    TimerPrinted.Enabled := false;
    Printed.Visible := false;

    Printer.BeginDoc;
    while Printing and (PrintCheckIndex < Count.Position) do begin
      PrintLabel.Caption := IntToStr(PrintCheckIndex+1) + '/' + IntToStr(Count.Position);
      FullReduildRecript;
      Printer.Canvas.StretchDraw(Rect(0, 0, Preview.picture.Width, Preview.Picture.Height ), Preview.Picture.Graphic);

      inc(PrintCheckIndex);
      if PrintCheckIndex < Count.Position then
        Printer.NewPage;
    end;

  finally
    PrintLabel.Visible := false;
    PrintLabel1.Visible := false;
    ButtonPrint.Caption := 'Print';
    Printer.EndDoc;
  //  if Printing then
    //  Application.MessageBox('Success!',PWideChar(Application.Title), MB_ICONINFORMATION );
    Printing := false;

    TimerPrinted.Enabled := true;
    Printed.Visible := true;
  end;
end;

procedure TFormMain.ApplicationEvents1Exception(Sender: TObject; E: Exception);
begin
  if E.Message = 'Printer is not currently printing' then
    ShowMessage('Print Stoped!')
  else
    Application.ShowException(E);
end;

procedure TFormMain.FormaChange(Sender: TObject);
begin
  FullReduildRecript;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Printing := false;
  PrintCheckIndex := 0;
  DateFrom.DateTime := Date();

  FQRCode := nil;
  Templates.Directory := Templates.Directory + '\Template';

  FQRCode := TDelphiZXingQRCode.Create;
  FQRCode.RegisterEncoder(ENCODING_WIN1251, TWin1251Encoder);
  FQRCode.RegisterEncoder(ENCODING_URL, TURLEncoder);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FQRCode.Free;
  if Assigned(config) then config.Free;
end;

procedure TFormMain.TemplatesChange(Sender: TObject);
begin
  FullReduildRecript;
end;

procedure TFormMain.TimerPrintedTimer(Sender: TObject);
begin
  TimerPrinted.Enabled := false;
  Printed.Visible := false;
end;

procedure TFormMain.FullReduildRecript;
var i:integer;
begin
  if Templates.ItemIndex < 0 then exit;

  Preview.Transparent := false;
  Preview.Picture.LoadFromFile(ChangeFileExt(Templates.FileName, '.bmp'));

  if Assigned(config) then config.Free;
  config := TIniFile.Create(ChangeFileExt(Templates.FileName, '.ini'));

  for I := 1 to 1000 do
  if config.SectionExists('QR' + IntToStr(i)) then
    RemakeQR('QR' + IntToStr(i))
  else break;

  for I := 1 to 1000 do
    if config.SectionExists('Line' + IntToStr(i)) then
      PaintLine('Line' + IntToStr(i))
    else break;
end;

procedure TFormMain.PaintLine(section: string);
var text:String;
    RegEx: TRegEx;
begin
  text := config.ReadString(section, 'Text', '');
  if text = '' then exit;

  if ContainsText(text, '{__number__}') then
    text := StringReplace(text, '{__number__}', Format( config.ReadString(section, 'NumberFormat', '%d'), [No.Position + PrintCheckIndex]), [rfReplaceAll]);
  if ContainsText(text, '{__datetime__}') then
    text := StringReplace(text, '{__datetime__}', FormatDateTime( config.ReadString(section, 'DateTimeFormat', 'dd.mm.yyyy hh:nn:ss'),
             IncSecond(DateFrom.Date, SecondsBetween( (TimeTo.Time - TimeFrom.Time)*PrintCheckIndex/IfThen(Count.Position=1, 1, Count.Position-1) + TimeFrom.Time, 0))
            ), [rfReplaceAll]);
  if ContainsText(text, '{__date__}') then
    text := StringReplace(text, '{__date__}', FormatDateTime( config.ReadString(section, 'DateFormat', 'dd.mm.yyyy'), DateFrom.Date), [rfReplaceAll]);
  if ContainsText(text, '{__time__}') then
    text := StringReplace(text, '{__time__}', FormatDateTime( config.ReadString(section, 'TimeFormat', 'hh:nn:ss'),
            (TimeTo.Time - TimeFrom.Time)*PrintCheckIndex/IfThen(Count.Position=1, 1, Count.Position-1) + TimeFrom.Time
            ), [rfReplaceAll]);

  text := RegEx.Replace(text,'{__rand:(\d+),?(\w{0,3})__}',RandomReplaceEvaluator);

  Preview.Canvas.Font.Size := config.ReadInteger(section, 'FontSize', 10);
  Preview.Canvas.Font.Name := config.ReadString(section, 'FontName', 'Arial');    //   MS PGothic
  Preview.Canvas.Brush.Style:=bsClear;

  AngleTextOut(Preview.Canvas, config.ReadInteger(section, 'Angle', 0),
    config.ReadInteger(section, 'Left', 38),
    config.ReadInteger(section, 'Top', 378),
    text,
    config.ReadInteger(section, 'SymbolWidth', 0));
end;

procedure TFormMain.RemakeQR(section: string);
// QR-code generation
var text:String;
    RegEx: TRegEx;
begin
  text := config.ReadString(section, 'Text', '');
  if text = '' then exit;

  if ContainsText(text, '{__number__}') then
    text := StringReplace(text, '{__number__}', Format( config.ReadString(section, 'NumberFormat', '%d'), [No.Position + PrintCheckIndex]), [rfReplaceAll]);
  if ContainsText(text, '{__datetime__}') then
    text := StringReplace(text, '{__datetime__}', FormatDateTime( config.ReadString(section, 'DateTimeFormat', 'dd.mm.yyyy hh:nn:ss'),
             IncSecond(DateFrom.Date, SecondsBetween( (TimeTo.Time - TimeFrom.Time)*PrintCheckIndex/IfThen(Count.Position=1, 1, Count.Position-1) + TimeFrom.Time, 0))
            ), [rfReplaceAll]);
  if ContainsText(text, '{__date__}') then
    text := StringReplace(text, '{__date__}', FormatDateTime( config.ReadString(section, 'DateFormat', 'dd.mm.yyyy'), DateFrom.Date), [rfReplaceAll]);
  if ContainsText(text, '{__time__}') then
    text := StringReplace(text, '{__time__}', FormatDateTime( config.ReadString(section, 'TimeFormat', 'hh:nn:ss'),
            (TimeTo.Time - TimeFrom.Time)*PrintCheckIndex/IfThen(Count.Position=1, 1, Count.Position-1) + TimeFrom.Time
            ), [rfReplaceAll]);

  text := RegEx.Replace(text,'{__rand:(\d+),?(\w{0,3})__}',RandomReplaceEvaluator);

  with FQRCode do
  try
    BeginUpdate;
    Data := text;
    Encoding := 0;
//    ErrorCorrectionOrdinal := TErrorCorrectionOrdinal
//    (cbbErrorCorrectionLevel.ItemIndex);
    QuietZone := 0;
    EndUpdate(True);
  finally
    //Preview.Canvas.Pen.Color := $00454545;
    //Preview.Canvas.Brush.Color := clrbxBackground.Selected;

    DrawQR(Preview.Canvas
      ,Rect(
        config.ReadInteger(section, 'Left', 119),
        config.ReadInteger(section, 'Top', 408),
        config.ReadInteger(section, 'Right', 119+142),
        config.ReadInteger(section, 'Bottom', 408+142)
      )
      , FQRCode, 0, TQRDrawingMode(0 div 2), Boolean(1 - 0 mod 2));
  end;
end;

function TFormMain.RandomReplaceEvaluator(const Match: TMatch): string;
begin
  Result:=RandomString(StrToInt(Match.Groups[1].Value),Match.Groups[2].Value);
end;


end.
