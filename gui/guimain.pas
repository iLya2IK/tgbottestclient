unit guimain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, OGLFastList, fpjson, TgBotCurlClientControls,
  tgbotmaincurlclient;

type

  TIncomeList = class(specialize TFastBaseCollection<TJSONObject>);

  { TOutUpdate }

  TOutUpdate = class
  public
    function GenUpdate : TJSONObject; virtual;
  end;

  { TOutMessage }

  TOutMessage = class(TOutUpdate)
  private
    fReplyTo : Int64;
    fText : String;
  public
    constructor Create(const aText : String; aReplyTo : Int64);
    function GenUpdate : TJSONObject; override;
  end;

  { TOutCallbackQuery }

  TOutCallbackQuery = class(TOutUpdate)
  private
    fMsgId : Int64;
    fData, fURL : String;
  public
    constructor Create(aMsgId : Int64; const aData, aURL : String);
    function GenUpdate : TJSONObject; override;
  end;

  TOutRecieve = procedure (chunk : TOutUpdate) of object;

  TOutUpdateList = class(specialize TFastBaseCollection<TOutUpdate>);

  { TForm1 }

  TForm1 = class(TForm)
    AuthToServerBtn: TToolButton;
    Button1: TButton;
    DoSend: TButton;
    DisconnectBtn: TToolButton;
    JsonMsgText: TMemo;
    MessageText: TLabel;
    PopupMenu1: TPopupMenu;
    ReplyToIDBox: TPanel;
    ToSend: TEdit;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ListBox1: TListBox;
    LogMemo: TMemo;
    TaskTimer: TTimer;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    ScrollBox1: TScrollBox;
    LongTimer: TTimer;
    ToolBar1: TToolBar;
    procedure AuthToServerBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure DoSendClick(Sender: TObject);
    procedure DisconnectBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Label1Click(Sender: TObject);
    procedure ListBox1SelectionChange(Sender: TObject; User: boolean);
    procedure LongTimerTimer(Sender: TObject);
    procedure TaskTimerTimer(Sender: TObject);
  private
    CURLClient : TTGBCURLClient;
    AppConfig  : TTGBClientPropStorage;
    AuthOpts   : TTGBClientConfigEditor;
    Messages   : TIncomeList;
    Outgoing   : TOutUpdateList;
    ReplyId    : Int64;
    MessageId  : Int64;

    procedure CatchRecieve(chunk : TOutUpdate);
    procedure OnConnectedChanged(aValue : Boolean);
    procedure OnDisconnect(Sender : TObject);
    procedure AddLog(const aStr : String);
    procedure OnSuccessAuth({%H-}aTask : THTTP2BackgroundTask; {%H-}aObj : TJSONObject);
    procedure OnSuccessUpdates({%H-}aTask : THTTP2BackgroundTask; aArr : TJSONArray);
    procedure OnSuccessUpdateCommands({%H-}aTask : THTTP2BackgroundTask; aArr : TJSONArray);
    procedure OnSuccessSendUpdate({%H-}aTask : THTTP2BackgroundTask; {%H-}aObj : TJSONObject);

    procedure DoClickCommand(Sender : TObject);
  public

  end;

  TURLType = (urlCommand, urlExternal);

  { TURLLabel }

  TURLLabel = class(TLabel)
  private
    FURLType : TURLType;
    FRec : TOutRecieve;
    procedure Doclick(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent; const aText: String; aType: TURLType;
      aReciever: TOutRecieve);
  end;

  { TKBInlineRow }

  TKBInlineRow = class(TPanel)
  public
    constructor Create(TheOwner: TComponent); override;
  end;

  { TKBInlineButton }

  TKBInlineButton = class(TButton)
  private
    FCBData : String;
    FRec : TOutRecieve;
    FMsgID : Int64;
    procedure DoClick(Sender : TObject);
  public
    constructor Create(TheOwner: TComponent;
      aMsgId :Int64;
      const aCaption, aCBData: String;
      aReciever: TOutRecieve);
  end;

var
  Form1: TForm1;

implementation

uses tgbotconsts, lazutf8;

{$R *.lfm}

{ TKBInlineRow }

constructor TKBInlineRow.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Height := 64;
  Align:= alTop;
  Top := TheOwner.ComponentCount * 64;
  BevelOuter:= bvNone;
  BevelInner:= bvNone;
end;

{ TKBInlineButton }

procedure TKBInlineButton.DoClick(Sender: TObject);
begin
  FRec(TOutCallbackQuery.Create(FMsgID, FCBData, ''));
end;

constructor TKBInlineButton.Create(TheOwner: TComponent; aMsgId: Int64;
  const aCaption, aCBData: String; aReciever: TOutRecieve);
var sz : integer;
begin
  inherited Create(TheOwner);
  sz := Font.GetTextWidth( aCaption );
  if sz < 64 then sz := 64;
  Width := sz + 32;
  Align:= alLeft;
  Left := TheOwner.ComponentCount * 64;
  Caption := aCaption;
  FRec:= aReciever;
  FMsgID:= aMsgId;
  FCBData := aCBData;
  OnClick:= @DoClick;
end;

{ TOutUpdate }

function TOutUpdate.GenUpdate: TJSONObject;
begin
  Result := TJSONObject.Create([]);
end;

{ TOutCallbackQuery }

constructor TOutCallbackQuery.Create(aMsgId: Int64; const aData, aURL: String);
begin
  fMsgId:= aMsgId;
  fData:=aData;
  fURL:= aURL;
end;

function TOutCallbackQuery.GenUpdate: TJSONObject;
var
  payload : TJSONObject;
begin
  payload := TJSONObject.Create([cMID, fMsgId]);
  Result := TJSONObject.Create([cTYPE, cCALLBACK, cPAYLOAD, payload]);
  if length(fData) > 0 then
    payload.Add(cDATA, fData);
  if length(fURL) > 0 then
    payload.Add(cURL, fURL);
end;

{ TOutMessage }

constructor TOutMessage.Create(const aText: String; aReplyTo: Int64);
begin
  fText:= aText;
  fReplyTo:= aReplyTo;
end;

function TOutMessage.GenUpdate: TJSONObject;
var
  payload : TJSONObject;
begin
  payload := TJSONObject.Create([cTEXT, fText]);
  Result := TJSONObject.Create([cTYPE, cMESSAGE, cPAYLOAD, payload]);
  if fReplyTo > 0 then
    payload.Add(cREPLYPARAMS, TJSONObject.Create([cMID, fReplyTo]));
end;

{ TURLLabel }

constructor TURLLabel.Create(TheOwner: TComponent; const aText : String;
  aType: TURLType; aReciever : TOutRecieve);
begin
  inherited Create(TheOwner);
  Font.Color:= clHighlight;
  Font.Style:= [fsUnderline];
  Caption := AText;
  FURLType:= aType;
  OnClick:=@Doclick;
  FRec:= aReciever;
  Align := alTop;
  Cursor:= crHandPoint;
end;

procedure TURLLabel.Doclick(Sender : TObject);
begin
  if FURLType = urlCommand then
    FRec(TOutMessage.Create(Caption, -1));
  // else
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  CURLClient := TTGBCURLClient.Create;

//  CURLClient.OnInitCURL := @OnInitCURL;
  CURLClient.OnConnectedChanged := @OnConnectedChanged;
  CURLClient.OnDisconnect := @OnDisconnect;
  CURLClient.OnAddLog := @AddLog;
  CURLClient.OnSuccessAuth := @OnSuccessAuth;
  CURLClient.OnSuccessUpdates := @OnSuccessUpdates;
  CURLClient.OnSuccessUpdateCommands := @OnSuccessUpdateCommands;
  CURLClient.OnSuccessSendUpdate := @OnSuccessSendUpdate;
//  CURLClient.OnChatIDSetted := @OnSetChatID;

  Messages := TIncomeList.Create;
  Outgoing := TOutUpdateList.Create;

  AppConfig := TTGBClientPropStorage.Create(Self);
  AppConfig.JSONFileName := 'config.json';

  AuthOpts := TTGBClientConfigEditor.Create(Panel4);
  AuthOpts.Parent := Panel4;
  AuthOpts.Top := 64;
  AuthOpts.Left := 64;
  AuthOpts.Props := AppConfig;
  AuthOpts.CURLClient := CURLClient;
  AuthOpts.Align := alClient;
  AuthOpts.Apply;

  CURLClient.Start;
  LongTimer.Enabled:=false;
  TaskTimer.Enabled := true;
  ReplyId:= 0;
  MessageId :=0;

  OnConnectedChanged(false);
end;

procedure TForm1.AuthToServerBtnClick(Sender: TObject);
begin
  CURLClient.VerifyTSL := AuthOpts.VerifyTLS;
  CURLClient.Authorize();
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  p : TPoint;
begin
  if PopupMenu1.Items.Count > 0 then
  begin
    p := Button1.ClientToScreen(Button1.ClientRect.TopLeft);
    PopupMenu1.PopUp(p.x, p.y);
  end;
end;

procedure TForm1.DoSendClick(Sender: TObject);
begin
  if Length(ToSend.Text) > 0 then
  if CURLClient.Connected then
  begin
    CatchRecieve(TOutMessage.Create(ToSend.Text, ReplyId));
  end;
end;

procedure TForm1.DisconnectBtnClick(Sender: TObject);
begin
  CURLClient.Disconnect;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  AuthOpts.SaveProps;

  LongTimer.Enabled:=false;
  TaskTimer.Enabled := false;

  CURLClient.Free;
  Messages.Free;
  Outgoing.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if Key = 13 then
  begin
    if ToSend.Focused then
       DoSend.OnClick(Sender);
  end;
end;

procedure TForm1.Label1Click(Sender: TObject);
begin
  CURLClient.Disconnect;
end;

procedure TForm1.ListBox1SelectionChange(Sender: TObject; User: boolean);
var
  msg, obj : TJSONObject;
  data : TJSONData;
  arr, sub_arr : TJSONArray;
  i, j : integer;
  Item : TControl;
  row : TKBInlineRow;
  btn : TKBInlineButton;
  lab : TURLLabel;

  off, len : integer;

  str : String;
  txt : WideString;
begin
  ReplyId := 0;
  MessageId := 0;
  ReplyToIDBox.Visible:= false;

  if ListBox1.ItemIndex >= 0 then
  begin
    msg := Messages[ListBox1.ItemIndex];
    txt := WideString(msg.Get(cTEXT, ''));
    MessageText.Caption := UTF8Encode(txt);
    JsonMsgText.Lines.Text := msg.AsJSON;
    JsonMsgText.AdjustSize;

    while Scrollbox1.ControlCount > 0 do
      begin
        Item := Scrollbox1.controls[0];
        Item.Free;
      end;

    data := msg.Find(cENTITIES);
    MessageId := msg.Get(cMID, -1);
    if assigned(data) then
    begin
      arr := TJSONArray(data);
      for i := 0 to arr.Count-1 do
      begin
        obj := TJSONObject(arr[i]);
        str := obj.Get(cTYPE, '');
        if Length(str) > 0 then
        begin
          off := obj.Get(cOFFSET, 0) + 1;
          len := obj.Get(cLENGTH, 0);

          if str = cCOMMAND then
          begin
            lab := TURLLabel.Create(ScrollBox1, UTF8Encode(Copy(txt, off, len)),
                                                urlCommand,
                                                @CatchRecieve);
            lab.Parent := ScrollBox1;
          end else
          if str = cURL then
          begin
            str := obj.Get(cURL, '');
            off := UTF8Pos('?', str);
            if off > 0 then
            begin
              str := '/' + UTF8Copy(str, off + 1, Length(str));

              lab := TURLLabel.Create(ScrollBox1, str, urlCommand, @CatchRecieve);
              lab.Parent := ScrollBox1;
            end;
          end;
        end;
      end;
    end;

    data := msg.Find(cREPLYMARKUP);
    if assigned(data) then
    begin
      if data is TJSONObject then
      begin
        obj := TJSONObject(data);
        if Assigned(obj.Find(cFORCEREPLY)) then
        begin
          ReplyId := MessageId;
          if assigned(data) then
          begin
            ReplyToIDBox.Visible:= true;
            ToSend.SetFocus;
          end;
        end else begin
          data := obj.Find(cINLINEKBRD);
          if data is TJSONArray then
          begin
            arr := TJSONArray(data);
            for i := 0 to arr.Count-1 do
            begin
              row := TKBInlineRow.Create(ScrollBox1);
              row.Parent := ScrollBox1;
              sub_arr := TJSONArray(arr[i]);
              for j := 0 to sub_arr.Count-1 do
              begin
                obj := TJSONObject(sub_arr[j]);
                btn := TKBInlineButton.Create(row, MessageId,
                                                   obj.Get(cTEXT,''),
                                                   obj.Get(cCBCKDATA,''),
                                                   @CatchRecieve);
                btn.Parent := row;
              end;
              for j := 0 to row.ControlCount-1 do
              begin
                row.Controls[j].Width:= row.Width div row.ControlCount - 1;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TForm1.LongTimerTimer(Sender: TObject);
begin
  if CURLClient.Connected then
  begin
    CURLClient.NeedToUpdates := true;
    CURLClient.Proceed;
  end;
end;

procedure TForm1.TaskTimerTimer(Sender: TObject);
var
  i : integer;
  u : TJSONObject;
begin
  CURLClient.TasksProceed;

  if CURLClient.Connected then
  begin
    for i := 0 to Outgoing.Count-1 do
    begin
      u := Outgoing[i].GenUpdate;
      try
        CURLClient.SendUpdate(u);
      finally
        u.Free;
      end;
    end;
    Outgoing.Clear;
  end;
end;

procedure TForm1.CatchRecieve(chunk: TOutUpdate);
begin
  if CURLClient.Connected then
  begin
    Outgoing.Add(chunk);
  end else
    chunk.Free;
end;

procedure TForm1.OnConnectedChanged(aValue: Boolean);
begin
  AuthToServerBtn.Enabled:=not aValue;
  DisconnectBtn.Enabled:=aValue;
  Panel1.Enabled:=aValue;
end;

procedure TForm1.OnDisconnect(Sender: TObject);
begin
  Messages.Clear;
  Outgoing.Clear;
  ListBox1.Items.Clear;
  LongTimer.Enabled:=false;
  OnConnectedChanged(false);
end;

procedure TForm1.AddLog(const aStr: String);
begin
  LogMemo.Lines.Add('['+DateTimeToStr(Now)+'] '+aStr);
  CURLClient.Log.Clear;
end;

procedure TForm1.OnSuccessAuth(aTask: THTTP2BackgroundTask; aObj: TJSONObject);
begin
  LongTimer.Enabled := true;
end;

procedure TForm1.OnSuccessUpdates(aTask: THTTP2BackgroundTask; aArr: TJSONArray
  );
var
  i : integer;
  upd, msg : TJSONObject;
  lastselected : boolean;
begin
  lastselected:= (ListBox1.ItemIndex = (ListBox1.Items.Count-1));
  for i := 0 to aArr.Count-1 do
  begin
    upd := TJSONObject(aArr[i]);
    msg := TJSONObject(upd.Extract(cMESSAGE));
    if Assigned(msg) then
    begin
      Messages.Add(msg);
      ListBox1.Items.Add(msg.Get(cTEXT, '-empty-'));
    end;
  end;
  if (ListBox1.Items.Count > 0) and lastselected then
  begin
    ListBox1.ItemIndex := ListBox1.Items.Count-1;
  end;
end;

procedure TForm1.OnSuccessUpdateCommands(aTask: THTTP2BackgroundTask;
  aArr: TJSONArray);
var
  i : integer;
  c : TTgCommand;
  mi : TMenuItem;
begin
  CURLClient.Commands.Lock;
  try
    PopupMenu1.Items.Clear;
    for i := 0 to CURLClient.Commands.count-1 do
    begin
      c := CURLClient.Commands[i];
      mi := TMenuItem.Create(PopupMenu1);
      mi.Caption:= c.Value + #9 + c.Description;
      mi.OnClick:=@DoClickCommand;
      c := CURLClient.Commands[i];
      PopupMenu1.Items.Add(mi);
    end;
  finally
    CURLClient.Commands.UnLock;
  end;
end;

procedure TForm1.OnSuccessSendUpdate(aTask: THTTP2BackgroundTask; aObj: TJSONObject
  );
begin
  ToSend.Text := '';
  ReplyId := 0;
end;

procedure TForm1.DoClickCommand(Sender: TObject);
var
  msg : String;
  p : integer;
begin
  if Sender is TMenuItem then
  begin
    msg := TMenuItem(Sender).Caption;
    p := utf8pos(#9, msg);
    if p > 1 then
    begin
      msg := UTF8Copy(msg, 1, p-1);
      ToSend.Text:= msg;
    end;
  end;
end;

end.

