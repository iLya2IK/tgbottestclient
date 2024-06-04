unit TgBotCurlClientControls;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ValEdit,
  ComCtrls, StdCtrls, tgbotmaincurlclient, Grids,
  JSONPropStorage;

type

  { TTGBClientPropStorage }

  TTGBClientPropStorage = class(TJSONPropStorage)
  private
    FDefaults : TStringList;
    function GetDefaults(aIndex : Integer) : String;
    function GetLangCode : String;
    function GetHostName : String;
    function GetLastName : String;
    function GetFirstName : String;
    function GetProxy : String;
    function GetCID : Int64;
    function GetUserName : String;
    function GetProp(aPropName : Integer) : String;
    function GetPropInt64(aPropName : Integer) : Int64;
    function GetVerifyTLS : Boolean;
    procedure SetDefaults(aIndex : Integer; AValue : String);
    procedure SetLangCode(AValue : String);
    procedure SetHostName(AValue : String);
    procedure SetLastName(AValue : String);
    procedure SetFirstName(AValue : String);
    procedure SetProxy(AValue : String);
    procedure SetCID(AValue : Int64);
    procedure SetUserName(AValue : String);
    procedure SetProp(aPropName : Integer; const aValue : String);
    procedure SetProp(aPropName : Integer; const aValue : Int64);
    procedure SetVerifyTLS(AValue : Boolean);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    property Defaults[aIndex : Integer] : String read GetDefaults write SetDefaults;

    const HOST_POS = 0;
    const PROXY_POS = 1;
    const USER_POS = 2;
    const FIRSTNAME_POS = 3;
    const LASTNAME_POS = 4;
    const LANGCODE_POS = 5;
    const CID_POS = 6;
    const MAX_PROPS = CID_POS;

    property HostName : String read GetHostName write SetHostName;
    property Proxy : String read GetProxy write SetProxy;
    property UserName : String read GetUserName write SetUserName;
    property FirstName : String read GetFirstName write SetFirstName;
    property LangCode : String read GetLangCode write SetLangCode;
    property LastName : String read GetLastName write SetLastName;
    property CID : Int64 read GetCID write SetCID;
    property VerifyTLS : Boolean read GetVerifyTLS write SetVerifyTLS;
  end;

  { TTGBClientConfigEditor }

  TTGBClientConfigEditor = class(TCustomControl)
  private
    FCURLClient : TTGBCURLClient;
    FProps : TTGBClientPropStorage;
    FValues : TValueListEditor;
    FVerifyTLS : TCheckBox;
    function GetLangCode : String;
    function GetHostName : String;
    function GetLastName : String;
    function GetFirstName : String;
    function GetProxy : String;
    function GetChatID : Int64;
    function GetUserName : String;
    function GetVerifyTLS : Boolean;
    procedure SetCURLClient(AValue : TTGBCURLClient);
    procedure SetLangCode(AValue : String);
    procedure SetHostName(AValue : String);
    procedure SetLastName(AValue : String);
    procedure SetFirstName(AValue : String);
    procedure SetProps(AValue : TTGBClientPropStorage);
    procedure SetProxy(AValue : String);
    procedure SetChatID(AValue : Int64);
    procedure SetUserName(AValue : String);

    procedure ValuesDrawCell(Sender : TObject; aCol, aRow : Integer;
          aRect : TRect; aState : TGridDrawState);

    procedure OptsEditingDone(Sender : TObject);
    procedure VerifyTSLCBChange(Sender : TObject);
    procedure SetVerifyTLS(AValue : Boolean);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    procedure Apply;
    procedure RestoreProps;
    procedure SaveProps;

    property Props : TTGBClientPropStorage read FProps write SetProps;
    property CURLClient : TTGBCURLClient read FCURLClient write SetCURLClient;

    property HostName : String read GetHostName write SetHostName;
    property Proxy : String read GetProxy write SetProxy;
    property UserName : String read GetUserName write SetUserName;
    property FirstName : String read GetFirstName write SetFirstName;
    property LangCode : String read GetLangCode write SetLangCode;
    property LastName : String read GetLastName write SetLastName;
    property ChatID : Int64 read GetChatID write SetChatID;
    property VerifyTLS : Boolean read GetVerifyTLS write SetVerifyTLS;
  end;

resourcestring
  rsServer    = 'Server';
  rsProxy     = 'Proxy';
  rsUser      = 'User name';
  rsPwrd      = 'FirstName';
  rsLangCode    = 'LangCode';
  rsMeta      = 'LastName';
  rsSID       = 'Session ID';
  rsVerifyTLS = 'Verify TLS';

implementation

const
  csServer    = 'Server';
  csProxy     = 'Proxy';
  csUser      = 'User';
  csPwrd      = 'FirstName';
  csLangCode    = 'LangCode';
  csMeta      = 'LastName';
  csSID       = 'SID';
  csVerifyTLS = 'VerifyTLS';

  PROPS_STR : Array [0..6] of String = (csServer, csProxy, csUser, csPwrd,
                                        csLangCode, csMeta, csSID);

{ TTGBClientConfigEditor }

procedure TTGBClientConfigEditor.SetCURLClient(AValue : TTGBCURLClient);
begin
  if FCURLClient = AValue then Exit;
  FCURLClient := AValue;
  Apply;
end;

function TTGBClientConfigEditor.GetLangCode : String;
begin
  Result := FValues.Cells[1, TTGBClientPropStorage.LANGCODE_POS];
end;

function TTGBClientConfigEditor.GetHostName : String;
begin
  Result := FValues.Cells[1, TTGBClientPropStorage.HOST_POS];
end;

function TTGBClientConfigEditor.GetLastName : String;
begin
  Result := FValues.Cells[1, TTGBClientPropStorage.LASTNAME_POS];
end;

function TTGBClientConfigEditor.GetFirstName : String;
begin
  Result := FValues.Cells[1, TTGBClientPropStorage.FIRSTNAME_POS];
end;

function TTGBClientConfigEditor.GetProxy : String;
begin
  Result := FValues.Cells[1, TTGBClientPropStorage.PROXY_POS];
end;

function TTGBClientConfigEditor.GetChatID : Int64;
begin
  if not TryStrToInt64(FValues.Cells[1, TTGBClientPropStorage.CID_POS], Result) then
    Result := 0;
end;

function TTGBClientConfigEditor.GetUserName : String;
begin
  Result := FValues.Cells[1, TTGBClientPropStorage.USER_POS];
end;

function TTGBClientConfigEditor.GetVerifyTLS : Boolean;
begin
  Result := FVerifyTLS.Checked;
end;

procedure TTGBClientConfigEditor.SetLangCode(AValue : String);
begin
  FValues.Cells[1, TTGBClientPropStorage.LANGCODE_POS] := AValue;
end;

procedure TTGBClientConfigEditor.SetHostName(AValue : String);
begin
  FValues.Cells[1, TTGBClientPropStorage.HOST_POS] := AValue;
end;

procedure TTGBClientConfigEditor.SetLastName(AValue : String);
begin
  FValues.Cells[1, TTGBClientPropStorage.LASTNAME_POS] := AValue;
end;

procedure TTGBClientConfigEditor.SetFirstName(AValue : String);
begin
  FValues.Cells[1, TTGBClientPropStorage.FIRSTNAME_POS] := AValue;
end;

procedure TTGBClientConfigEditor.SetProxy(AValue : String);
begin
  FValues.Cells[1, TTGBClientPropStorage.PROXY_POS] := AValue;
end;

procedure TTGBClientConfigEditor.SetChatID(AValue : Int64);
begin
  FValues.Cells[1, TTGBClientPropStorage.CID_POS] := IntToStr(AValue);
end;

procedure TTGBClientConfigEditor.SetUserName(AValue : String);
begin
  FValues.Cells[1, TTGBClientPropStorage.USER_POS] := AValue;
end;

procedure TTGBClientConfigEditor.ValuesDrawCell(Sender : TObject; aCol,
  aRow : Integer; aRect : TRect; aState : TGridDrawState);
var
  pen : TPen;
  br  : TBrush;
  fnt : TFont;
  ts : TTextStyle;
  S  : String;

  SG : TValueListEditor;
begin
  SG := TValueListEditor(Sender);
  S := SG.Cells[aCol, aRow];

  pen := SG.Canvas.Pen;
  br  := SG.Canvas.Brush;
  fnt := SG.Canvas.Font;

  ts := SG.Canvas.TextStyle;
  ts.Alignment := taLeftJustify;
  ts.Layout := tlCenter;
  ts.Wordbreak := True;
  ts.SingleLine := True;
  ts.Opaque := false;

  if aCol = 0 then
  begin
    br.Color := clBtnFace;
    Pen.Style := psClear;
    fnt.Color := clBtnText;
  end else
  begin
    br.Color := clWindow;
    if gdFixed in aState then br.Color := $DDDDDD;
    Pen.Style := psClear;
    fnt.Color := clWindowText;
    if gdSelected in aState then
    begin
      br.Color  := clHighlight;
      fnt.Color := clHighlightText;
      pen.Color := clHighlightText;
      pen.Style := psDot;
    end;
  end;
  SG.Canvas.Rectangle(aRect);
  fnt.Style := [];
  SG.Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, S, ts);
end;

procedure TTGBClientConfigEditor.SetProps(AValue : TTGBClientPropStorage);
begin
  if FProps = AValue then Exit;
  FProps := AValue;
  RestoreProps;
end;

procedure TTGBClientConfigEditor.OptsEditingDone(Sender : TObject);
begin
  Apply;
end;

procedure TTGBClientConfigEditor.VerifyTSLCBChange(Sender : TObject);
begin
  if Assigned(FCURLClient) then
    FCURLClient.VerifyTSL := FVerifyTLS.Checked;
end;

procedure TTGBClientConfigEditor.SetVerifyTLS(AValue : Boolean);
begin
  FVerifyTLS.Checked := AValue;
end;

constructor TTGBClientConfigEditor.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FCURLClient := nil;
  FValues := TValueListEditor.Create(Self);
  FValues.Parent := Self;
  FValues.Strings.AddPair(rsServer, '');
  FValues.Strings.AddPair(rsProxy, '');
  FValues.Strings.AddPair(rsUser, '');
  FValues.Strings.AddPair(csPwrd, '');
  FValues.Strings.AddPair(csLangCode, '');
  FValues.Strings.AddPair(csMeta, '');
  FValues.Strings.AddPair(csSID, '');
  FValues.DisplayOptions := [doAutoColResize, doKeyColFixed];
  FValues.OnEditingDone := @OptsEditingDone;
  FValues.OnDrawCell := @ValuesDrawCell;
  FValues.Align := alClient;

  FVerifyTLS := TCheckBox.Create(Self);
  FVerifyTLS.Parent := Self;
  FVerifyTLS.Caption := rsVerifyTLS;
  FVerifyTLS.Top := 100;
  FVerifyTLS.OnChange := @VerifyTSLCBChange;
  FVerifyTLS.Align := alBottom;
end;

destructor TTGBClientConfigEditor.Destroy;
begin
  inherited Destroy;
end;

procedure TTGBClientConfigEditor.Apply;
begin
  if Assigned(FCURLClient) then
  begin
    FCURLClient.Setts.UserName   := GetUserName;
    FCURLClient.Setts.FirstName  := GetFirstName;
    FCURLClient.Setts.LastName   := GetLastName;
    FCURLClient.Setts.LangCode   := GetLangCode;
    FCURLClient.Setts.SetProxy(GetProxy);
    FCURLClient.Setts.Host       := GetHostName;
    FCURLClient.Setts.ChatID     := GetChatID;
  end;
end;

procedure TTGBClientConfigEditor.RestoreProps;
var
  i : integer;
begin
  if Assigned(FProps) then
  begin
    for i := 0 to FProps.MAX_PROPS-1 do
      FValues.Cells[1, i] := FProps.GetProp(i);

    VerifyTLS := FProps.VerifyTLS;
  end;
end;

procedure TTGBClientConfigEditor.SaveProps;
var
  i : integer;
begin
  if Assigned(FProps) then
  begin
    for i := 0 to FProps.MAX_PROPS do
      FProps.SetProp(i, FValues.Cells[1, i]);

    FProps.VerifyTLS := VerifyTLS;
  end;
end;

{ TTGBClientPropStorage }

function TTGBClientPropStorage.GetDefaults(aIndex : Integer) : String;
begin
  if (aIndex >= 0) and (aIndex <= MAX_PROPS) then
    Result := FDefaults[aIndex] else
    Result := '';
end;

function TTGBClientPropStorage.GetLangCode : String;
begin
  Result := GetProp(LANGCODE_POS);
end;

function TTGBClientPropStorage.GetHostName : String;
begin
  Result := GetProp(HOST_POS);
end;

function TTGBClientPropStorage.GetLastName : String;
begin
  Result := GetProp(LASTNAME_POS);
end;

function TTGBClientPropStorage.GetFirstName : String;
begin
  Result := GetProp(FIRSTNAME_POS);
end;

function TTGBClientPropStorage.GetProxy : String;
begin
  Result := GetProp(PROXY_POS);
end;

function TTGBClientPropStorage.GetCID : Int64;
begin
  if not TryStrToInt64(GetProp(CID_POS), Result) then
    Result := 0;
end;

function TTGBClientPropStorage.GetUserName : String;
begin
  Result := GetProp(USER_POS);
end;

function TTGBClientPropStorage.GetProp(aPropName : Integer) : String;
begin
  Result := ReadString(PROPS_STR[aPropName], FDefaults[aPropName]);
end;

function TTGBClientPropStorage.GetPropInt64(aPropName: Integer): Int64;
begin
  Result := ReadInteger(PROPS_STR[aPropName], 0);
end;

function TTGBClientPropStorage.GetVerifyTLS : Boolean;
begin
  Result := ReadBoolean(csVerifyTLS, true);
end;

procedure TTGBClientPropStorage.SetDefaults(aIndex : Integer; AValue : String);
begin
  FDefaults[aIndex] := AValue;
end;

procedure TTGBClientPropStorage.SetLangCode(AValue : String);
begin
  SetProp(LANGCODE_POS, AValue);
end;

procedure TTGBClientPropStorage.SetHostName(AValue : String);
begin
  SetProp(HOST_POS, AValue);
end;

procedure TTGBClientPropStorage.SetLastName(AValue : String);
begin
  SetProp(LASTNAME_POS, AValue);
end;

procedure TTGBClientPropStorage.SetFirstName(AValue : String);
begin
  SetProp(FIRSTNAME_POS, AValue);
end;

procedure TTGBClientPropStorage.SetProxy(AValue : String);
begin
  SetProp(PROXY_POS, AValue);
end;

procedure TTGBClientPropStorage.SetCID(AValue : Int64);
begin
  SetProp(CID_POS, AValue);
end;

procedure TTGBClientPropStorage.SetUserName(AValue : String);
begin
  SetProp(USER_POS, AValue);
end;

procedure TTGBClientPropStorage.SetProp(aPropName : Integer;
  const aValue : String);
begin
  WriteString(PROPS_STR[aPropName], aValue);
end;

procedure TTGBClientPropStorage.SetProp(aPropName: Integer; const aValue: Int64
  );
begin
  WriteInteger(PROPS_STR[aPropName], aValue);
end;

procedure TTGBClientPropStorage.SetVerifyTLS(AValue : Boolean);
begin
  WriteBoolean(csVerifyTLS, AValue);
end;

constructor TTGBClientPropStorage.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FDefaults := TStringList.Create;
{
const HOST_POS = 0;
const PROXY_POS = 1;
const USER_POS = 2;
const FIRSTNAME_POS = 3;
const LASTNAME_POS = 4;
const LANGCODE_POS = 5;
const CID_POS = 6;
const MAX_PROPS = CID_POS;
}

  FDefaults.Add('https://localhost:9000');
  FDefaults.Add('');
  FDefaults.Add('user-tester');
  FDefaults.Add('user-tester');
  FDefaults.Add('');
  FDefaults.Add('en');
  FDefaults.Add('0');
end;

destructor TTGBClientPropStorage.Destroy;
begin
  FDefaults.Free;
  inherited Destroy;
end;

end.

