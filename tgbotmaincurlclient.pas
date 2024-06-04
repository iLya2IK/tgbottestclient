unit tgbotmaincurlclient;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  libpascurl,
  extmemorystream, fpjson, jsonparser, ECommonObjs;

type

  THTTP2BackgroundTask = class;
  THTTP2BackgroundTasks = class;

  TTaskNotify = procedure (aTask : THTTP2BackgroundTask) of object;
  TOnHTTP2Finish = TTaskNotify;
  TCURLNotifyEvent = procedure (aTask : THTTP2BackgroundTask; aObj : TJSONObject) of object;
  TCURLArrNotifyEvent = procedure (aTask : THTTP2BackgroundTask; aArr : TJSONArray) of object;
  TStringNotify = procedure (const aStr : String) of object;
  TInt64Notify = procedure (aValue : Int64) of object;
  TConnNotifyEvent = procedure (aValue : Boolean) of object;
  TDataNotifyEvent = procedure (aData : TCustomMemoryStream) of object;


  { TTgCommand }

  TTgCommand = class
  private
    FValue : String;
    FDescr : String;
  public
    constructor Create(const aValue, aDescr : String);

    property Value : String read FValue;
    property Description : String read FDescr;
  end;

  TThreadCommandList = class(specialize TThreadSafeFastBaseCollection<TTgCommand>);

  { THTTP2SettingsIntf }

  THTTP2SettingsIntf = class(TThreadSafeObject)
  private
    FHost, FUserName, FFirstName, FLastName, FLangCode : String;
    FChatID : Int64;
    FProxyProtocol, FProxyHost, FProxyPort, FProxyUser, FProxyPwrd : String;
    FVerifyTSL : Boolean;
    function GetUserName : String;
    function GetFirstName : String;
    function GetLastName : String;
    function GetLangCode : String;
    function GetHost : String;
    function GetChatID : Int64;
    function GetProxyAddress : String;
    function GetProxyAuth : String;
    function GetVerifyTSL : Boolean;
    procedure SetUserName(const AValue : String);
    procedure SetHost(const AValue : String);
    procedure SetFirstName(const AValue : String);
    procedure SetLastName(const AValue : String);
    procedure SetLangCode(const AValue : String);
    procedure SetChatID(AValue : Int64);
    procedure SetProxyProt(const AValue : String);
    procedure SetProxyHost(const AValue : String);
    procedure SetProxyPort(const AValue : String);
    procedure SetProxyUser(const AValue : String);
    procedure SetProxyPwrd(const AValue : String);
    procedure SetVerifyTSL(AValue : Boolean);
  public
    constructor Create;
    property VerifyTSL : Boolean read GetVerifyTSL write SetVerifyTSL;
    property ChatID : Int64 read GetChatID write SetChatID;
    property Host : String read GetHost write SetHost;
    property UserName : String read GetUserName write SetUserName;
    property FirstName : String read GetFirstName write SetFirstName;
    property LastName : String read GetLastName write SetLastName;
    property LangCode : String read GetLangCode write SetLangCode;
    property ProxyAddress : String read GetProxyAddress;
    property ProxyAuth : String read GetProxyAuth;
    procedure SetProxy(const aValue : String);
    function HasProxy : Boolean;
    function HasProxyAuth : Boolean;
    function HasProxyAuthPwrd : Boolean;
  end;

  { THTTP2BackgroundTask }

  THTTP2BackgroundTask = class(TThreadSafeObject)
  private
    FErrorBuffer : array [0 .. CURL_ERROR_SIZE] of char;
    FPath : String;
    FOnSuccess : TOnHTTP2Finish;
    FResponseCode : Longint;
    FErrorCode, FErrorSubCode : Longint;
    FPool : THTTP2BackgroundTasks;
    FCURL : CURL;
    FResponse : TMemoryStream;
    FRequest : TCustomMemoryStream;
    FOnFinish : TOnHTTP2Finish;
    FIsSilent : Boolean;
    headers : pcurl_slist;
    FState : Byte;
    FSettings : THTTP2SettingsIntf;
    FData : TObject;
    function GetErrorStr : String;
    function GetState : Byte;
    procedure SetState(aState : Byte);
    procedure Finalize;
    procedure AttachToPool;
    procedure DoError(err : Integer); overload;
    procedure DoError(err, subcode : Integer); overload;
    procedure ConfigCURL(aSz, aFSz : Int64; meth : Byte; isRead, isSeek : Boolean);
  public
    constructor Create(aPool : THTTP2BackgroundTasks; Settings : THTTP2SettingsIntf;
      aIsSilent : Boolean);
    destructor Destroy; override;
    function doPost(const aPath : String; aContent : Pointer;
      aContentSize : Int64; stack : Boolean) : Boolean;
    function Seek(offset: curl_off_t; origin: LongInt) : LongInt; virtual;
    function Write(ptr: Pointer; size: LongWord; nmemb: LongWord) : LongWord; virtual;
    function Read(ptr: Pointer; size: LongWord; nmemb: LongWord) : LongWord; virtual;

    procedure DoIdle; virtual;

    procedure Terminate;
    procedure Close; virtual;
    function Finished : Boolean;

    property OnFinish : TOnHTTP2Finish read FOnFinish write FOnFinish;
    property OnSuccess : TOnHTTP2Finish read FOnSuccess write FOnSuccess;

    property Path : String read FPath;
    property State : Byte read GetState write SetState;
    property IsSilent : Boolean read FIsSilent;
    property ResponseCode : Longint read FResponseCode;
    property ErrorCode : Longint read FErrorCode;
    property ErrorSubCode : Longint read FErrorSubCode;
    property ErrorString : String read GetErrorStr;

    property Request : TCustomMemoryStream read FRequest;
    property Response : TMemoryStream read FResponse;

    property Data : TObject read FData write FData;
  end;

  { TThreadsafeCURLM }

  TThreadsafeCURLM = class(TThreadSafeObject)
  private
    FValue : CURLM;
    function getValue : CURLM;
  public
    constructor Create;
    destructor Destroy; override;
    procedure InitCURLM;
    procedure DoneCURLM;
    property Value : CURLM read getValue;
  end;

  THTTP2BackgroundTasksProto = class (specialize TThreadSafeFastBaseSeq<THTTP2BackgroundTask>);

  { THTTP2BackgroundTasks }

  THTTP2BackgroundTasks = class (THTTP2BackgroundTasksProto)
  private
    FCURLM : TThreadsafeCURLM;
    FOnMultiError : TNotifyEvent;
    procedure IdleTask(aStrm : TObject);
    procedure TerminateTask(aStrm : TObject);
    function IsTaskFinished(aStrm : TObject; {%H-}data : pointer) : Boolean;
    procedure SetTaskFinished(aStrm : TObject; data : pointer);
    procedure SetMultiPollError(aStrm : TObject; data : pointer);
    procedure AfterTaskExtract(aStrm: TObject);
    procedure DoMultiError(code : integer);
    function DoInitMultiPipeling : Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property  CURLMv : TThreadsafeCURLM read FCURLM;
    procedure DoIdle;
    procedure Terminate;

    function Ready : Boolean;

    property OnMultiError : TNotifyEvent read FOnMultiError write FOnMultiError;
  end;

  { THTTP2AsyncBackground }

  THTTP2AsyncBackground = class(TThread)
  private
    FTasks : THTTP2BackgroundTasks;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Execute; override;
    procedure AddTask(aTask : THTTP2BackgroundTask);

    function Ready : Boolean;

    property Tasks : THTTP2BackgroundTasks read FTasks;
  end;

  { TTGBCURLClient }

  TTGBCURLClient = class(TThreadSafeObject)
  private
    FSynchroFinishedTasks : THTTP2BackgroundTasksProto;
    FTaskPool : THTTP2AsyncBackground;
    FSetts : THTTP2SettingsIntf;
    FInitialized : Boolean;

    FCommands : TThreadCommandList;
    FLog : TThreadStringList;

    function DoInitMultiPipeling : Boolean;
  protected
    procedure SuccessAuth(ATask : THTTP2BackgroundTask); virtual;

    procedure SetConnected(AValue : Boolean); virtual;
    procedure SuccessSendUpdate(ATask : THTTP2BackgroundTask); virtual;
    procedure SuccessUpdates(ATask : THTTP2BackgroundTask); virtual;
    procedure SuccessUpdateCommands(ATask : THTTP2BackgroundTask); virtual;
    procedure TaskFinished(ATask : THTTP2BackgroundTask); virtual;
    procedure SynchroFinishTasks; virtual;

    function  ConsumeResponseToObj(ATask : THTTP2BackgroundTask) : TJSONData; virtual;
  private
    FConnected,
    FNeedToUpdates : Boolean;
    FNeedToUpdateCommands : Boolean;
    FOnSynchroUpdateTask : TTaskNotify;
    FOnDisconnect : TNotifyEvent;
    FOnAddLog : TStringNotify;
    FOnSuccessUpdates : TCURLArrNotifyEvent;
    FOnSuccessUpdateCommands : TCURLArrNotifyEvent;
    FOnSuccessSendUpdate : TCURLNotifyEvent;
    FOnInitCURL : TNotifyEvent;
    FOnConnected : TConnNotifyEvent;
    FOnSuccessAuth : TCURLNotifyEvent;
    FOnChatIDSetted : TInt64Notify;
    LastUpdate : Int64;

    function GetConnected : Boolean;
    function GetNeedToUpdateCommands: Boolean;
    function GetUserName : String;
    function GetFirstName : String;
    function GetLastName : String;
    function GetLangCode : String;
    function GetHost : String;
    function GetNeedToUpdates : Boolean;
    function GetProxy : String;
    function GetChatID : Int64;
    function GetVerifyTSL : Boolean;
    procedure SetNeedToUpdateCommands(AValue: Boolean);
    procedure SetNeedToUpdates(AValue : Boolean);
    procedure SetProxy(const AValue : String);
    procedure SetChatID(AValue : Int64);
    procedure SetVerifyTSL(AValue : Boolean);
  public
    constructor Create;
    procedure Start;
    procedure TasksProceed; virtual;
    procedure Proceed; virtual;
    procedure Disconnect; virtual;
    destructor Destroy; override;

    procedure Authorize;
    procedure doPost(const aPath, aContent : String;
      OnSuccess : TOnHTTP2Finish; silent : Boolean = true);
    procedure doPost(const aPath : String; aContent : Pointer;
      aContentSize : Int64; OnSuccess : TOnHTTP2Finish; stack : boolean;
      silent : Boolean = true);

    procedure AddLog(const STR : String); virtual;

    procedure GetUpdates;
    procedure GetBotCommands;
    procedure SendUpdate(aMsg : TJSONObject);

    property Commands : TThreadCommandList read FCommands;
    property Log : TThreadStringList read FLog;

    property ChatID : Int64 read GetChatID write SetChatID;
    property Host : String read GetHost;
    property UserName : String read GetUserName;
    property FirstName : String read GetFirstName;
    property LastName : String read GetLastName;
    property LangCode : String read GetLangCode;
    property VerifyTSL : Boolean read GetVerifyTSL write SetVerifyTSL;

    property OnInitCURL : TNotifyEvent read FOnInitCURL write FOnInitCURL;
    property OnConnectedChanged : TConnNotifyEvent read FOnConnected write FOnConnected;
    property OnDisconnect : TNotifyEvent read FOnDisconnect write FOnDisconnect;
    property OnAddLog : TStringNotify read FOnAddLog write FOnAddLog;
    property OnSuccessAuth : TCURLNotifyEvent read FOnSuccessAuth write FOnSuccessAuth;
    property OnSuccessUpdates : TCURLArrNotifyEvent read FOnSuccessUpdates write FOnSuccessUpdates;
    property OnSuccessUpdateCommands : TCURLArrNotifyEvent read FOnSuccessUpdateCommands write FOnSuccessUpdateCommands;
    property OnSuccessSendUpdate : TCURLNotifyEvent read FOnSuccessSendUpdate write FOnSuccessSendUpdate;
    property OnChatIDSetted : TInt64Notify read FOnChatIDSetted write FOnChatIDSetted;
    property OnSynchroUpdateTask : TTaskNotify read FOnSynchroUpdateTask write FOnSynchroUpdateTask;

    property Connected : Boolean read GetConnected write SetConnected;
    property NeedToUpdates : Boolean read GetNeedToUpdates write SetNeedToUpdates;
    property NeedToUpdateCommands : Boolean read GetNeedToUpdateCommands write SetNeedToUpdateCommands;

    property Setts : THTTP2SettingsIntf read FSetts;
  end;


implementation

uses tgbotconsts;

function WriteFunctionCallback(ptr: Pointer; size: LongWord;
  nmemb: LongWord; data: Pointer): LongWord; cdecl;
begin
  Result := THTTP2BackgroundTask(data).Write(ptr, size, nmemb);
end;

function SeekFunctionCallback(ptr: Pointer; offset: curl_off_t;
  origin: LongInt): LongInt; cdecl;
begin
  Result := THTTP2BackgroundTask(ptr).Seek(offset, origin);
end;

function ReadFunctionCallback(ptr: Pointer; size: LongWord;
  nmemb: LongWord; data: Pointer): LongWord; cdecl;
begin
  Result := THTTP2BackgroundTask(data).Read(ptr, size, nmemb);
end;

function HTTPEncode(const AStr: String): String;

const
  HTTPAllowed = ['A'..'Z','a'..'z',
                 '*','@','.','_','-',
                 '0'..'9',
                 '$','!','''','(',')'];

var
  SS,S,R: PChar;
  H : String[2];
  L : Integer;

begin
  L:=Length(AStr);
  Result:='';
  if (L=0) then exit;

  SetLength(Result,L*3); // Worst case scenario
  R:=PChar(Result);
  S:=PChar(AStr);
  SS:=S; // Avoid #0 limit !!
  while ((S-SS)<L) do
    begin
    if S^ in HTTPAllowed then
      R^:=S^
    else if (S^=' ') then
      R^:='+'
    else
      begin
      R^:='%';
      H:=HexStr(Ord(S^),2);
      Inc(R);
      R^:=H[1];
      Inc(R);
      R^:=H[2];
      end;
    Inc(R);
    Inc(S);
    end;
  SetLength(Result,R-PChar(Result));
end;

{ TTgCommand }

constructor TTgCommand.Create(const aValue, aDescr: String);
begin
  FValue := aValue;
  FDescr := aDescr;
end;

{ TThreadsafeCURLM }

function TThreadsafeCURLM.getValue : CURLM;
begin
  Lock;
  try
    Result := FValue;
  finally
    UnLock;
  end;
end;

constructor TThreadsafeCURLM.Create;
begin
  inherited Create;
  FValue := nil;
end;

destructor TThreadsafeCURLM.Destroy;
begin
  DoneCURLM;
  inherited Destroy;
end;

procedure TThreadsafeCURLM.InitCURLM;
begin
  Lock;
  try
    FValue := curl_multi_init();
    if Assigned(FValue) then
      curl_multi_setopt(FValue, CURLMOPT_PIPELINING, CURLPIPE_MULTIPLEX);
  finally
    UnLock;
  end;
end;

procedure TThreadsafeCURLM.DoneCURLM;
begin
  Lock;
  try
    if assigned(FValue) then
      curl_multi_cleanup(FValue);
    FValue := nil;
  finally
    UnLock;
  end;
end;

{ THTTP2AsyncBackground }

constructor THTTP2AsyncBackground.Create;
begin
  inherited Create(true);
  FreeOnTerminate := false;
  FTasks := THTTP2BackgroundTasks.Create;
end;

destructor THTTP2AsyncBackground.Destroy;
begin
  FTasks.Free;
  inherited Destroy;
end;

procedure THTTP2AsyncBackground.Execute;
begin
  while not Terminated do
  begin
    Tasks.DoIdle;
    Sleep(100);
  end;
  Tasks.Terminate;
end;

procedure THTTP2AsyncBackground.AddTask(aTask : THTTP2BackgroundTask);
begin
  FTasks.Push_back(aTask);
end;

function THTTP2AsyncBackground.Ready : Boolean;
begin
  Result := Tasks.Ready;
end;

{ THTTP2SettingsIntf }

function THTTP2SettingsIntf.GetUserName : String;
begin
  Lock;
  try
    Result := FUserName;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetHost : String;
begin
  Lock;
  try
    Result := FHost;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetFirstName : String;
begin
  Lock;
  try
    Result := FFirstName;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetLastName : String;
begin
  Lock;
  try
    Result := FLastName;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetLangCode: String;
begin
  Lock;
  try
    Result := FLangCode;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetChatID : Int64;
begin
  Lock;
  try
    Result := FChatID;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetProxyAddress : String;
begin
  Lock;
  try
    Result := FProxyProtocol + FProxyHost;
    if Length(FProxyPort) > 0 then
       Result := Result + ':' + FProxyPort;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetProxyAuth : String;
begin
  Lock;
  try
    Result := FProxyUser;
    if Length(FProxyPwrd) > 0 then
       Result := Result + ':' + FProxyPwrd;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.GetVerifyTSL : Boolean;
begin
  Lock;
  try
    Result := FVerifyTSL;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetUserName(const AValue : String);
begin
  Lock;
  try
    FUserName := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetFirstName(const AValue : String);
begin
  Lock;
  try
    FFirstName := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetLastName(const AValue : String);
begin
  Lock;
  try
    FLastName := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetLangCode(const AValue: String);
begin
  Lock;
  try
    FLangCode := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetHost(const AValue : String);
begin
  Lock;
  try
    FHost := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetChatID(AValue : Int64);
begin
  Lock;
  try
    FChatID := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetProxyProt(const AValue : String);
begin
  Lock;
  try
    FProxyProtocol := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetProxyHost(const AValue : String);
begin
  Lock;
  try
    FProxyHost := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetProxyPort(const AValue : String);
begin
  Lock;
  try
    FProxyPort := AValue;
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetProxyUser(const AValue : String);
begin
  Lock;
  try
    FProxyUser := HTTPEncode(AValue);
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetProxyPwrd(const AValue : String);
begin
  Lock;
  try
    FProxyPwrd := HTTPEncode(AValue);
  finally
    UnLock;
  end;
end;

procedure THTTP2SettingsIntf.SetVerifyTSL(AValue : Boolean);
begin
  Lock;
  try
    FVerifyTSL := AValue;
  finally
    UnLock;
  end;
end;

constructor THTTP2SettingsIntf.Create;
begin
  inherited Create;
  FProxyProtocol := 'http://';
end;

procedure THTTP2SettingsIntf.SetProxy(const aValue : String);
var
  S, SS, R : PChar;
  Res : PChar;
  SL : TStringList;
  UP, address_len : Integer;
  L : Integer;
begin
  Lock;
  try
    if Length(AValue) > 0 then
    begin
      FProxyPwrd := '';
      FProxyPort := '';
      FProxyUser := '';
      FProxyHost := '';
      Exit;
    end;

    S := PChar(@(aValue[1]));
    SS := S;
    L := Length(S);
    Res := GetMem(L+1);
    try
      R := Res;
      UP := 0;
      SL := TStringList.Create;
      try
        while ((SS - S) < L) do
        begin
          if (SS^ in [':', '@']) then
          begin
            R^ := #0;
            SL.Add(StrPas(Res));
            R := Res;
            if SS^ = '@' then UP := SL.Count;
          end else
          begin
            R^ := SS^;
            Inc(R);
          end;
          Inc(SS);
        end;
        if (R > Res) then
        begin
          R^ := #0;
          SL.Add(StrPas(Res));
        end;

        case UP of
          1 : begin
            FProxyUser := SL[0];
            FProxyPwrd := '';
          end;
          2 : begin
            FProxyUser := SL[0];
            FProxyPwrd := SL[1];
          end;
        else
          FProxyUser := '';
          FProxyPwrd := '';
        end;

        address_len := SL.Count - UP;

        case (address_len) of
        1 : begin
                FProxyHost := SL[SL.Count-1];
                FProxyPort := '';
            end;
        2, 3 : begin
                if (TryStrToInt(SL[SL.Count-1], L)) then
                begin
                    FProxyPort := SL[SL.Count-1];
                    dec(address_len);
                end else begin
                    FProxyPort := '';
                end;
                if (address_len > 1) then begin
                    FProxyProtocol := SL[UP] + '://';
                    FProxyHost := SL[UP+1];
                    while ((Length(FProxyHost) > 0) and (FProxyHost[1] = '/')) do
                        Delete(FProxyHost, 1, 1);
                end else begin
                    FProxyHost := SL[UP];
                end;
            end;
        else
            FProxyHost := '';
            FProxyPort := '';
        end;

      finally
        SL.Free;
      end;
    finally
      FreeMem(Res);
    end;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.HasProxy : Boolean;
begin
  Lock;
  try
    Result := Length(FProxyHost) > 0;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.HasProxyAuth : Boolean;
begin
  Lock;
  try
    Result := Length(FProxyUser) > 0;
  finally
    UnLock;
  end;
end;

function THTTP2SettingsIntf.HasProxyAuthPwrd : Boolean;
begin
  Lock;
  try
    Result := Length(FProxyPwrd) > 0;
  finally
    UnLock;
  end;
end;

{ THTTP2BackgroundTask }

function THTTP2BackgroundTask.GetState : Byte;
begin
  Lock;
  try
    Result := FState;
  finally
    UnLock;
  end;
end;

function THTTP2BackgroundTask.GetErrorStr : String;
begin
  Result := StrPas(FErrorBuffer);
end;

procedure THTTP2BackgroundTask.SetState(aState : Byte);
begin
  Lock;
  try
    FState := aState;
  finally
    UnLock;
  end;
end;

procedure THTTP2BackgroundTask.Finalize;
begin
  if Assigned(FCURL) then
  begin
    FPool.CURLMv.Lock;
    try
      try
        curl_multi_remove_handle(FPool.CURLMv.FValue, FCURL);
      except
        //do nothing
      end;
    finally
      FPool.CURLMv.UnLock;
    end;
    if Assigned(headers) then
      curl_slist_free_all(headers);
    curl_easy_cleanup(FCURL);
    FCURL := nil;
  end;
end;

procedure THTTP2BackgroundTask.AttachToPool;
begin
  FPool.CURLMv.Lock;
  try
    FErrorSubCode := Integer(curl_multi_add_handle(FPool.CURLMv.FValue, FCURL));
    if FErrorSubCode <> Integer( CURLE_OK ) then
      DoError(TASK_ERROR_ATTACH_REQ, FErrorSubCode);
  finally
    FPool.CURLMv.UnLock;
  end;
end;

procedure THTTP2BackgroundTask.DoError(err : Integer);
begin
  DoError(err, 0);
end;

procedure THTTP2BackgroundTask.DoError(err, subcode : Integer);
begin
  Lock;
  try
    FErrorCode := err;
    FErrorSubCode := subcode;
  finally
    UnLock;
  end;
  State := STATE_FINISHED;
end;

procedure THTTP2BackgroundTask.ConfigCURL(aSz, aFSz : Int64; meth : Byte;
  isRead, isSeek : Boolean);
begin
  curl_easy_setopt(FCURL, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);
  curl_easy_setopt(FCURL, CURLOPT_URL, PChar(FSettings.Host + FPath));
  case meth of
    METH_POST: curl_easy_setopt(FCURL, CURLOPT_POST, Longint(1));
    METH_UPLOAD: curl_easy_setopt(FCURL, CURLOPT_UPLOAD, Longint(1));
  end;

  if not FSettings.VerifyTSL then
  begin
    curl_easy_setopt(FCURL, CURLOPT_SSL_VERIFYPEER, Longint(0));
    curl_easy_setopt(FCURL, CURLOPT_SSL_VERIFYHOST, Longint(0));
  end;

  if FSettings.HasProxy then
  begin
   curl_easy_setopt(FCURL, CURLOPT_PROXY, PChar(FSettings.ProxyAddress));
    if  FSettings.HasProxyAuth then
    begin
      curl_easy_setopt(FCURL, CURLOPT_PROXYAUTH, CURLAUTH_ANYSAFE);
      if  FSettings.HasProxyAuthPwrd then
        curl_easy_setopt(FCURL, CURLOPT_PROXYUSERPWD, PChar(FSettings.ProxyAuth)) else
        curl_easy_setopt(FCURL, CURLOPT_PROXYUSERNAME, PChar(FSettings.ProxyAuth));
    end;
  end;

  curl_easy_setopt(FCURL, CURLOPT_WRITEDATA, Pointer(Self));
  curl_easy_setopt(FCURL, CURLOPT_WRITEFUNCTION, @WriteFunctionCallback);
  headers := nil;
  headers := curl_slist_append(headers, Pchar('content-length: ' + inttostr(aSz)));
  headers := curl_slist_append(headers, Pchar('content-type: application/json'));
  curl_easy_setopt(FCURL, CURLOPT_HTTPHEADER, headers);
  curl_easy_setopt(FCURL, CURLOPT_PIPEWAIT, Longint(1));
  curl_easy_setopt(FCURL, CURLOPT_NOSIGNAL, Longint(1));

  if isSeek then begin
     curl_easy_setopt(FCURL, CURLOPT_SEEKDATA, Pointer(Self));
     curl_easy_setopt(FCURL, CURLOPT_SEEKFUNCTION,  @SeekFunctionCallback);
  end;

  if isRead then begin
     curl_easy_setopt(FCURL, CURLOPT_READDATA, Pointer(Self));
     curl_easy_setopt(FCURL, CURLOPT_READFUNCTION,  @ReadFunctionCallback);
     curl_easy_setopt(FCURL, CURLOPT_INFILESIZE, Longint(aFSz));
     curl_easy_setopt(FCURL, CURLOPT_INFILESIZE_LARGE, Int64(aFSz));
  end;

  curl_easy_setopt(FCURL, CURLOPT_ERRORBUFFER, PChar(FErrorBuffer));
  FillChar(FErrorBuffer, CURL_ERROR_SIZE, #0);
end;

constructor THTTP2BackgroundTask.Create(aPool : THTTP2BackgroundTasks;
  Settings : THTTP2SettingsIntf; aIsSilent : Boolean);
begin
  inherited Create;
  FCURL := nil;
  FPool := aPool;
  FSettings := Settings;
  FErrorCode := TASK_NO_ERROR;
  FErrorSubCode := 0;
  FState := STATE_INIT;
  FIsSilent := aIsSilent;

  FResponse := TMemoryStream.Create;
  FRequest := nil;
end;

destructor THTTP2BackgroundTask.Destroy;
begin
  Finalize;
  if Assigned(FResponse) then  FResponse.Free;
  if Assigned(FRequest) then  FRequest.Free;
  inherited Destroy;
end;

function THTTP2BackgroundTask.doPost(const aPath : String;
  aContent : Pointer; aContentSize : Int64; stack : Boolean) : Boolean;
begin
  Result := false;

  if FPool.Ready then
  begin
    FCURL := curl_easy_init;
    if Assigned(FCurl) then
    begin
      FResponse.Position := 0;
      FResponse.Size := 0;
      FPath := aPath;
      ConfigCURL(aContentSize, aContentSize, METH_POST, (aContentSize > 0), false);

      if (aContentSize > 0) then begin
        if stack then
        begin
          FRequest := TMemoryStream.Create;
          FRequest.Write(aContent^,  aContentSize);
          FRequest.Position := 0;
        end else
        begin
          FRequest := TExtMemoryStream.Create;
          TExtMemoryStream(FRequest).SetPtr(aContent,  aContentSize);
        end;
      end;

      AttachToPool;
      Result := true;
    end else
      DoError(TASK_ERROR_CANT_EASY_CURL);
  end;
end;

function THTTP2BackgroundTask.Seek(offset : curl_off_t; origin : LongInt
  ) : LongInt;
var origin_v : TSeekOrigin;
begin
  Lock;
  try
    case origin of
      0 : origin_v := soBeginning;
      1 : origin_v := soCurrent;
      2 : origin_v := soEnd;
    end;
    FRequest.Seek(offset, origin_v);

    Result := CURL_SEEKFUNC_OK;
  finally
    UnLock;
  end;
end;

function THTTP2BackgroundTask.Write(ptr : Pointer; size : LongWord; nmemb : LongWord
  ) : LongWord;
begin
  if Finished then Exit(0);

  Result := FResponse.Write(ptr^, size * nmemb);
end;

function THTTP2BackgroundTask.Read(ptr : Pointer; size : LongWord; nmemb : LongWord
  ) : LongWord;
begin
  if Finished then Exit(CURL_READFUNC_ABORT);

  if assigned(FRequest) then
    Result := FRequest.Read(ptr^, nmemb * size) else
    Result := 0;
end;

procedure THTTP2BackgroundTask.DoIdle;
begin
  //
end;

procedure THTTP2BackgroundTask.Terminate;
begin
  State := STATE_TERMINATED;
end;

procedure THTTP2BackgroundTask.Close;
begin
  Terminate;
end;

function THTTP2BackgroundTask.Finished : Boolean;
begin
  Lock;
  try
    Result := FState >= STATE_FINISHED;
  finally
    UnLock;
  end;
end;

{ THTTP2BackgroundTasks }

function THTTP2BackgroundTasks.IsTaskFinished(aStrm : TObject; {%H-}data : pointer
  ) : Boolean;
begin
  Result := THTTP2BackgroundTask(aStrm).Finished;
end;

procedure THTTP2BackgroundTasks.SetTaskFinished(aStrm : TObject; data : pointer
  );
var rc, sb : integer;
begin
  if THTTP2BackgroundTask(aStrm).FCURL = pCURLMsg_rec(data)^.easy_handle then
  begin
    THTTP2BackgroundTask(aStrm).State := STATE_FINISHED;
    if pCURLMsg_rec(data)^.result <> CURLE_OK then
    begin
      THTTP2BackgroundTask(aStrm).DoError(TASK_ERROR_CURL,
                                          integer(pCURLMsg_rec(data)^.result));
    end else
    begin
      sb := Longint(curl_easy_getinfo(pCURLMsg_rec(data)^.easy_handle,
                                                 CURLINFO_RESPONSE_CODE,
                                                 @rc));
      if sb = Longint(CURLE_OK) then
        THTTP2BackgroundTask(aStrm).FResponseCode := rc
      else
        THTTP2BackgroundTask(aStrm).DoError(TASK_ERROR_GET_INFO, sb);
    end;
  end;
end;

procedure THTTP2BackgroundTasks.SetMultiPollError(aStrm : TObject;
  data : pointer);
begin
  THTTP2BackgroundTask(aStrm).DoError(TASK_ERROR_CURL, pInteger(data)^);
end;

procedure THTTP2BackgroundTasks.IdleTask(aStrm : TObject);
begin
  THTTP2BackgroundTask(aStrm).DoIdle;
end;

procedure THTTP2BackgroundTasks.TerminateTask(aStrm : TObject);
begin
  THTTP2BackgroundTask(aStrm).Terminate;
end;

procedure THTTP2BackgroundTasks.AfterTaskExtract(aStrm : TObject);
begin
  if assigned(THTTP2BackgroundTask(aStrm).OnFinish) then
    THTTP2BackgroundTask(aStrm).OnFinish(THTTP2BackgroundTask(aStrm)) else
    aStrm.Free;
end;

procedure THTTP2BackgroundTasks.DoMultiError(code : integer);
begin
  DoForAllEx(@SetMultiPollError, @code);
  Lock;
  try
    if Assigned(FCURLM) then
      FreeAndNil(FCURLM);
  finally
    UnLock;
  end;
  if assigned(OnMultiError) then
    OnMultiError(Self);
end;

function THTTP2BackgroundTasks.DoInitMultiPipeling : Boolean;
begin
  CURLMv.Lock;
  try
    if Assigned(CURLMv.FValue) then Exit(true);
    CURLMv.InitCURLM;

    Result := Assigned(CURLMv.FValue);
  finally
    CURLMv.UnLock;
  end;
end;

constructor THTTP2BackgroundTasks.Create;
begin
  inherited Create;
  FCURLM := TThreadsafeCURLM.Create;
  FOnMultiError := nil;
end;

destructor THTTP2BackgroundTasks.Destroy;
begin
  inherited Destroy;
  if Assigned(FCURLM) then FCURLM.Free;
end;

procedure THTTP2BackgroundTasks.DoIdle;
var response_code, still_running, msgq : integer;
    m : pCURLMsg_rec;
begin
  try
    CURLMv.Lock;
    try
      if Ready then
      begin
        response_code := Integer(curl_multi_perform(CURLMv.FValue, @still_running));

        if (response_code = Integer( CURLE_OK )) then
        begin
         repeat
           m := curl_multi_info_read(CURLMv.FValue, @msgq);
           if (assigned(m) and (m^.msg = CURLMSG_DONE)) then
             DoForAllEx(@SetTaskFinished, m);
         until not Assigned(m);

         if (still_running > 0) then
           response_code := Integer(curl_multi_poll(CURLMv.FValue, [], 0, 200, nil));
        end;
      end else
        response_code := 0;
    finally
      CURLMv.UnLock;
    end;
  except
    response_code := -1;
  end;
  if (response_code <> Integer( CURLE_OK )) then
    DoMultiError(response_code);

  DoForAll(@IdleTask);
  ExtractObjectsByCriteria(@IsTaskFinished, @AfterTaskExtract, nil);
end;

procedure THTTP2BackgroundTasks.Terminate;
begin
  DoForAll(@TerminateTask);
end;

function THTTP2BackgroundTasks.Ready : Boolean;
begin
  Result := Assigned(CURLMv.FValue);
end;

{ TTGBCURLClient }

function TTGBCURLClient.DoInitMultiPipeling : Boolean;
begin
  Result := FTaskPool.Tasks.DoInitMultiPipeling;

  if Result then
  begin
    if (not FInitialized) and Assigned(OnInitCURL) then
      OnInitCURL(FTaskPool.Tasks);

    FInitialized := true;
  end else FInitialized := false;
end;

procedure TTGBCURLClient.SuccessAuth(ATask : THTTP2BackgroundTask);
var
  jObj : TJSONObject;
  jData : TJSONData;
begin
  if ATask.ErrorCode = TASK_NO_ERROR then
  begin
    jObj := TJSONObject(ConsumeResponseToObj(ATask));
    if Assigned(jObj) then
    begin
      if jObj.Find(cCID, jData) then
      begin
        ChatID := jData.AsInt64;

        Connected := true;
        NeedToUpdates := true;
        NeedToUpdateCommands := true;
        if Assigned(OnSuccessAuth) then
          OnSuccessAuth(ATask, jObj);
      end;
      FreeAndNil(jObj);
    end;
  end else
      Disconnect;
end;

procedure TTGBCURLClient.SetConnected(AValue : Boolean);
begin
  Lock;
  try
    if FConnected = AValue then Exit;
    FConnected := AValue;
  finally
    UnLock;
  end;

  if Assigned(OnConnectedChanged) then
    OnConnectedChanged(AValue);
end;

procedure TTGBCURLClient.SuccessSendUpdate(ATask : THTTP2BackgroundTask);
var
  jObj : TJSONObject;
begin
  if ATask.ErrorCode = TASK_NO_ERROR then
  begin
    jObj := TJSONObject(ConsumeResponseToObj(ATask));
    if Assigned(jObj) then
    begin
      if Assigned(OnSuccessSendUpdate) then
        OnSuccessSendUpdate(ATask, jObj);

      FreeAndNil(jObj);
    end;
  end else
    Disconnect;
end;

procedure TTGBCURLClient.SuccessUpdates(ATask : THTTP2BackgroundTask);
var i : integer;
  d : TJSONData;
  jEl, jNotify : TJSONObject;
  jArr : TJSONArray;
begin
  if ATask.ErrorCode = TASK_NO_ERROR then
  begin
    jArr := TJSONArray(ConsumeResponseToObj(ATask));
    if Assigned(jArr) then
    try
      if Assigned(OnSuccessUpdates) then
        OnSuccessUpdates(ATask, jArr);
      if jArr.Count > 0 then
      begin
        for i := 0 to jArr.Count-1 do
        if jArr[i] is TJSONObject then
        begin
          jEl := TJSONObject(jArr[i]);

          d := jEl.Find(CUPDID);
          if Assigned(d) then
            LastUpdate := d.AsInt64 + 1;
          d := jEl.Find(cNOTIFY);
          if Assigned(d) and (d is TJSONObject) then
          begin
            jNotify := TJSONObject(d);
            d := jNotify.Find(cTYPE);
            if Assigned(d) then
            begin
              if d.AsString = cCMDNOTIFY then
              begin
                NeedToUpdateCommands := true;
              end;
            end;
          end;
        end;
      end;
    finally
      jArr.Free;
    end;
  end else
    Disconnect;
end;

procedure TTGBCURLClient.SuccessUpdateCommands(ATask: THTTP2BackgroundTask);
var i : integer;
  jEl : TJSONObject;
  jArr : TJSONArray;
  aValue, aDescr : String;
begin
  if ATask.ErrorCode = TASK_NO_ERROR then
  begin
    jArr := TJSONArray(ConsumeResponseToObj(ATask));
    if Assigned(jArr) then
    try
      FCommands.Clear;
      for i := 0 to jArr.Count-1 do
      if jArr[i] is TJSONObject then
      begin
        jEl := TJSONObject(jArr[i]);

        aValue := jEl.Get(cECOMMAND, '');
        aDescr := jEl.Get(cDESCR, '');
        FCommands.Add(TTgCommand.Create(aValue, aDescr));
      end;
      if Assigned(OnSuccessUpdateCommands) then
        OnSuccessUpdateCommands(ATask, jArr);
    finally
      jArr.Free;
    end;
  end else
    Disconnect;
end;

procedure TTGBCURLClient.TaskFinished(ATask : THTTP2BackgroundTask);
begin
  FSynchroFinishedTasks.Push_back(ATask);
end;

procedure TTGBCURLClient.SynchroFinishTasks;
var
  Tsk : THTTP2BackgroundTask;
begin
  while true do
  begin
    Tsk := FSynchroFinishedTasks.PopValue;
    if assigned(Tsk) then
    begin
      try
        if Length(Tsk.ErrorString) > 0 then
          AddLog(Tsk.ErrorString);

        case Tsk.ErrorCode of
        Integer( CURLE_OK) :
          if (not Tsk.IsSilent) or (Tsk.ResponseCode <> 200) then
            AddLog(Format('HTTP2 "%s". Code - %d', [Tsk.Path, Tsk.ResponseCode]));
        TASK_ERROR_ATTACH_REQ :
          AddLog(Format('Cant attach easy req to multi. Code - %d',
                              [Tsk.ErrorSubCode]));
        TASK_ERROR_CANT_EASY_CURL :
          AddLog(Format('Cant create easy req. Code - %d', [Tsk.ErrorSubCode]));
        else
          AddLog(Format('HTTP2 "%s" FAIL. Code - %d. Subcode - %d', [Tsk.Path,
                                              Tsk.ErrorCode, Tsk.ErrorSubCode]));
        end;

        if Length(Tsk.ErrorString) > 0 then
          AddLog(Tsk.ErrorString);

        if Assigned(Tsk.OnSuccess) then
          Tsk.OnSuccess(Tsk);

      finally
        Tsk.Free;
      end;
    end else
      Break;
  end;
end;

function TTGBCURLClient.ConsumeResponseToObj(ATask : THTTP2BackgroundTask
  ) : TJSONData;
var jData : TJSONData;
    aIsOk : Boolean;
    aCode : String;
begin
  Result := nil;
  aCode := '';
  aIsOk := false;
  ATask.Response.Position := 0;
  try
    if ATask.Response.Size > 0 then
    begin
      try
        Result := GetJSON(ATask.Response);
        if (Result is TJSONObject) then
        begin
          if TJSONObject(Result).Find(cOK, jData) then
          begin
            aIsOk := jData.AsBoolean;
            if not aIsOk then
            begin
              if TJSONObject(Result).Find(cRESULT, jData) then
                aCode := jData.AsString;
              FreeAndNil(Result);
            end else
            begin
              TJSONObject(Result).Find(cRESULT, Result);
              aCode := '';
            end;
          end else begin
            aIsOk := false;
            FreeAndNil(Result);
          end;
        end else
          if assigned(Result) then FreeAndNil(Result);
      except
        Result := nil;
        aIsOk := false;
      end;
    end;
  finally
    if (length(aCode) > 0) or (not ATask.IsSilent) then
    begin
      AddLog(Format('HTTP2 JSON Req result code [%s]', [aCode]));
    end;
  end;
end;

function TTGBCURLClient.GetConnected : Boolean;
begin
  Lock;
  try
    Result := FConnected;
  finally
    UnLock;
  end;
end;

function TTGBCURLClient.GetNeedToUpdateCommands: Boolean;
begin
  Lock;
  try
    Result := FNeedToUpdateCommands;
  finally
    UnLock;
  end;
end;

function TTGBCURLClient.GetUserName : String;
begin
  Result := FSetts.UserName;
end;

function TTGBCURLClient.GetFirstName : String;
begin
  Result := FSetts.FirstName;
end;

function TTGBCURLClient.GetLastName: String;
begin
  Result := FSetts.LastName;
end;

function TTGBCURLClient.GetLangCode: String;
begin
  Result := FSetts.LangCode;
end;

function TTGBCURLClient.GetHost : String;
begin
  Result := FSetts.Host;
end;

function TTGBCURLClient.GetNeedToUpdates : Boolean;
begin
  Lock;
  try
    Result := FNeedToUpdates;
  finally
    UnLock;
  end;
end;

function TTGBCURLClient.GetProxy : String;
begin
  Result := FSetts.ProxyAddress;
end;

function TTGBCURLClient.GetChatID : Int64;
begin
  Result := FSetts.ChatID;
end;

function TTGBCURLClient.GetVerifyTSL : Boolean;
begin
  Result := FSetts.VerifyTSL;
end;

procedure TTGBCURLClient.SetNeedToUpdateCommands(AValue: Boolean);
begin
  Lock;
  try
    FNeedToUpdateCommands := AValue;
  finally
    UnLock;
  end;
end;

procedure TTGBCURLClient.SetNeedToUpdates(AValue : Boolean);
begin
  Lock;
  try
    FNeedToUpdates := AValue;
  finally
    UnLock;
  end;
end;

procedure TTGBCURLClient.SetProxy(const AValue : String);
begin
  FSetts.SetProxy(AValue);
end;

procedure TTGBCURLClient.SetChatID(AValue : Int64);
begin
  FSetts.ChatID := AValue;
  if Assigned(OnChatIDSetted) then
    OnChatIDSetted(aValue);
end;

procedure TTGBCURLClient.SetVerifyTSL(AValue : Boolean);
begin
  FSetts.VerifyTSL := AValue;
end;

constructor TTGBCURLClient.Create;
begin
  inherited Create;
  FInitialized := false;
  FLog := TThreadStringList.Create;
  FSynchroFinishedTasks := THTTP2BackgroundTasksProto.Create();
  FTaskPool := THTTP2AsyncBackground.Create;

  FSetts := THTTP2SettingsIntf.Create;

  FCommands := TThreadCommandList.Create;

  TJSONData.CompressedJSON := true;
  curl_global_init(CURL_GLOBAL_ALL);
  FConnected := true;
  FNeedToUpdates := false;
  FNeedToUpdateCommands := false;
  Disconnect;
end;

procedure TTGBCURLClient.Start;
begin
  FTaskPool.Start;
end;

procedure TTGBCURLClient.TasksProceed;
begin
  SynchroFinishTasks;
end;

procedure TTGBCURLClient.Proceed;
begin
  if Connected then
  begin
    if NeedToUpdates then
      GetUpdates;
    if NeedToUpdateCommands then
      GetBotCommands;
  end;
end;

destructor TTGBCURLClient.Destroy;
begin
  FTaskPool.Terminate;
  FTaskPool.WaitFor;

  curl_global_cleanup();

  FSetts.Free;
  FSynchroFinishedTasks.Free;
  FTaskPool.Free;

  FLog.Free;
  FCommands.Free;

  inherited Destroy;
end;

procedure TTGBCURLClient.Authorize;
var
  jObj : TJSONObject;
  aStr : String;
begin
  jObj := TJSONObject.Create([cUSERNAME,  UserName,
                              cFIRSTNAME, FirstName,
                              cLASTNAME,  LastName,
                              cLANG,      LangCode]);
  try
    aStr := jObj.AsJSON;
  finally
    jObj.Free;
  end;
  Disconnect;
  doPost('/authClient.json',  aStr, @SuccessAuth, false);
end;

procedure TTGBCURLClient.doPost(const aPath, aContent : String;
  OnSuccess : TOnHTTP2Finish; silent : Boolean);
var ptr : pointer;
begin
  if Length(aContent) > 0 then ptr := @(aContent[1]) else ptr := nil;
  doPost(aPath, ptr, Length(aContent), OnSuccess,
                          true, silent);
end;

procedure TTGBCURLClient.doPost(const aPath : String; aContent : Pointer;
  aContentSize : Int64; OnSuccess : TOnHTTP2Finish; stack : boolean;
  silent : Boolean);
var
  Tsk : THTTP2BackgroundTask;
begin
  if DoInitMultiPipeling then
  begin
    Tsk := THTTP2BackgroundTask.Create(FTaskPool.Tasks, FSetts, silent);
    Tsk.OnFinish := @TaskFinished;
    Tsk.OnSuccess := OnSuccess;
    Tsk.doPost(aPath, aContent, aContentSize, stack);
    FTaskPool.AddTask(Tsk);
  end;
end;

procedure TTGBCURLClient.AddLog(const STR : String);
begin
  FLog.Add('['+DateTimeToStr(Now)+'] '+Str);

  if Assigned(OnAddLog) then
    OnAddLog(Str);
end;

procedure TTGBCURLClient.GetUpdates;
var
  jObj : TJSONObject;
  aStr : String;
begin
  NeedToUpdates := false;
  jObj := TJSONObject.Create([cCID,    ChatID,
                              cOFFSET, LastUpdate,
                              cLIMIT,  32]);
  try
    aStr := jObj.AsJSON;
  finally
    jObj.Free;
  end;
  doPost('/clientGetUpdates.json',aStr,@SuccessUpdates)
end;

procedure TTGBCURLClient.GetBotCommands;
var
  jObj : TJSONObject;
  aStr : String;
begin
  NeedToUpdateCommands := false;
  jObj := TJSONObject.Create([cCID, ChatID]);
  try
    aStr := jObj.AsJSON;
  finally
    jObj.Free;
  end;
  doPost('/clientGetCommands.json',aStr,@SuccessUpdateCommands)
end;

procedure TTGBCURLClient.Disconnect;
begin
  FTaskPool.Tasks.Terminate;
  Lock;
  try
    FConnected := false;
    FNeedToUpdates := false;
    FNeedToUpdateCommands := false;
  finally
    UnLock;
  end;

  SynchroFinishTasks;

  if Assigned(OnDisconnect) then
    OnDisconnect(Self);

  LastUpdate := 0;
  ChatID := 0;
end;

procedure TTGBCURLClient.SendUpdate(aMsg : TJSONObject);
begin
  if assigned(aMsg) then begin
    aMsg.Add(cCID, ChatID);
    doPost('/clientSendUpdate.json', aMsg.AsJSON, @SuccessSendUpdate);
  end;
end;

end.

