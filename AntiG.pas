unit AntiG;

interface

uses
  SysUtils, Classes, clHttp, ClHttpRequest;

function RecMemCaptcha(FileMem: TMemoryStream; AKey: String;
  MinLen: integer = 0; MaxLen: integer = 0; Numeric: integer = 0;
  Phrase: integer = 0; RegSense: integer = 0; Calc: integer = 0;
  IsRussian: integer = 0): string; overload;

function RecFileCaptcha(FileName: String; AKey: String; MinLen: integer = 0;
  MaxLen: integer = 0; Numeric: integer = 0; Phrase: integer = 0;
  RegSense: integer = 0; Calc: integer = 0; IsRussian: integer = 0)
  : string; overload;

function Balance(AKey: String): String;

function BadReport(AKey, ID: String): String;

implementation

function BadReport(AKey, ID: String): String;
var
  FHttp: TclHttp;
  buf: TStringStream;
begin
  Result := '';
  if AKey = '' then
    exit;

  FHttp := TclHttp.Create(nil);
  buf := TStringStream.Create;
  try
    FHttp.get('http://antigate.com/res.php?key=' + AKey +
      '&action=reportbad&id=' + ID, buf);

    Result := buf.datastring;;

  finally
    FHttp.Free;
    buf.Free;
  end;

end;

// Получить ваш текущий денежный баланс
function Balance(AKey: String): String;
var
  FHttp: TclHttp;
  buf: TStringStream;
begin
  Result := '';
  if AKey = '' then
    exit;

  FHttp := TclHttp.Create(nil);
  buf := TStringStream.Create;
  try
    FHttp.get('http://antigate.com/res.php?key=' + AKey +
      '&action=getbalance', buf);

    Result := buf.datastring

  finally
    FHttp.Free;
    buf.Free;
  end;

end;

(* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *)
// Распознать картинку из файла
function RecFileCaptcha(FileName: String; AKey: String; MinLen: integer = 0;
  MaxLen: integer = 0; Numeric: integer = 0; Phrase: integer = 0;
  RegSense: integer = 0; Calc: integer = 0; IsRussian: integer = 0)
  : string; overload;

var
  pic_mem: TMemoryStream;
begin
  pic_mem := TMemoryStream.Create;
  try
    pic_mem.LoadFromFile(FileName);

    Result := RecMemCaptcha(pic_mem, AKey, MinLen, MaxLen, Numeric, Phrase,
      RegSense, Calc, IsRussian);

  finally
    pic_mem.Free;
  end;
end;

function RecMemCaptcha(FileMem: TMemoryStream; AKey: String;
  MinLen: integer = 0; MaxLen: integer = 0; Numeric: integer = 0;
  Phrase: integer = 0; RegSense: integer = 0; Calc: integer = 0;
  IsRussian: integer = 0): string; overload;

var
  ContentType: String;
  s, ID: String;
  i: integer;
  pic_mem: TMemoryStream;
  FHttp: TclHttp;
  buf: TStringStream;
begin

  Result := '';
  ContentType := 'image/pjpeg';

  buf := TStringStream.Create;
  pic_mem := TMemoryStream.Create;
  pic_mem.LoadFromStream(FileMem);

  FHttp := TclHttp.Create(nil);
  FHttp.Request := TclHttpRequest.Create(nil);

  try

    FHttp.Request.AddFormField('key', AKey);
    FHttp.Request.AddFormField('min_len', IntToStr(MinLen));
    FHttp.Request.AddFormField('max_len', IntToStr(MaxLen));
    FHttp.Request.AddFormField('numeric', IntToStr(Numeric));
    FHttp.Request.AddFormField('phrase', IntToStr(Phrase));
    FHttp.Request.AddFormField('regsense', IntToStr(RegSense));
    FHttp.Request.AddFormField('calc', IntToStr(Calc));
    FHttp.Request.AddFormField('is_russian', IntToStr(IsRussian));
    FHttp.Request.AddSubmitFile('file', 'image', ContentType);

    FHttp.Request.Header.ContentType := 'multipart/form-data';

    FHttp.post('http://antigate.com/in.php', buf);

    s := buf.datastring;

    ID := '';
    if (Pos('ERROR_', s) < 1) then
    begin
      if (Pos('OK|', s) > 0) then
        ID := StringReplace(s, 'OK|', '', [rfReplaceAll]);
      if (ID <> '') then
      begin
        for i := 0 to 20 do
        begin
          Sleep(3000);
          FHttp.Request.Clear;
          buf.Clear;
          FHttp.get('http://antigate.com/res.php?key=' + AKey +
            '&action=get&id=' + ID, buf);
          begin
            s := buf.datastring;
            if (Pos('ERROR_', s) > 0) then
            begin
              Result := s;
              break;
            end;
            if (Pos('OK|', s) > 0) then
            begin
              Result := StringReplace(s, 'OK|', '', [rfReplaceAll]);
              break;
            end;
          end;
          Result := 'ERROR_TIMEOUT';
        end;
      end
      else
        Result := 'ERROR_BAD_CAPTCHA_ID';

    end
    else
      Result := 'ERROR_CONNECT';

  finally
    buf.Free;
    pic_mem.Free;
    FHttp.Free;
  end;

end;

(* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *)

end.
