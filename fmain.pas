Unit fMain;

{$mode objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, MQTT, IniFiles;

Type

  { TfrmMain }

  TfrmMain = Class(TForm)
    chkRetain: TCheckBox;
    chkLogPing: TCheckBox;
    chkDup: TCheckBox;
    edAddr: TEdit;
    edUser: TEdit;
    edClientID: TEdit;
    edSubscribe: TEdit;
    edPort: TEdit;
    edPublish: TEdit;
    edPwd: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    lbSendCnt: TLabel;
    lbRecCnt: TLabel;
    lbPort: TLabel;
    lbName: TLabel;
    memSub: TMemo;
    memPub: TMemo;
    panConnect: TPanel;
    Panel1: TPanel;
    panPublish: TPanel;
    panSubscribe: TPanel;
    rbSQoS0: TRadioButton;
    rbSQoS1: TRadioButton;
    rbSQoS2: TRadioButton;
    rbPQoS0: TRadioButton;
    rbPQoS1: TRadioButton;
    rbPQoS2: TRadioButton;
    spConnect: TSpeedButton;
    spDisconnect: TSpeedButton;
    spSubscribe: TSpeedButton;
    spPublish: TSpeedButton;
    spUnsubscribe: TSpeedButton;
    Splitter1: TSplitter;
    Procedure FormClose(Sender: TObject; Var CloseAction: TCloseAction);
    Procedure FormCreate(Sender: TObject);
    Procedure FormShow(Sender: TObject);
    Procedure spConnectClick(Sender: TObject);
    Procedure spDisconnectClick(Sender: TObject);
    Procedure spPublishClick(Sender: TObject);
    Procedure spSubscribeClick(Sender: TObject);
    Procedure spUnsubscribeClick(Sender: TObject);
  private
    ParIni: String;
    Procedure OnConnAck(Sender: TObject; ReturnCode: Integer);
    Procedure OnDisConn(Sender: TObject);
    Procedure OnPingResp(Sender: TObject);
    Procedure OnPingReq(Sender: TObject);
    Procedure OnSubAck(Sender: TObject; MessageID, QoS: Integer);
    Procedure OnUnSubAck(Sender: TObject; MessageID: Integer);
    Procedure OnPublish(Sender: TObject; topic, payload: Utf8string; MessageID, QoS: Integer; Retain, Dup: Boolean);
    Procedure OnPubAck(Sender: TObject; MessageID: Integer);
    Procedure OnPubRec(Sender: TObject; MessageID: Integer);
    Procedure OnPubRel(Sender: TObject; MessageID: Integer);
    Procedure OnPubComp(Sender: TObject; MessageID: Integer);
  public
    MQTTClient: TMQTT;
  End;

Var
  frmMain: TfrmMain;

Implementation

{$R *.lfm}

{ TfrmMain }

Procedure TfrmMain.spConnectClick(Sender: TObject);
Begin
  Screen.Cursor := crHourGlass;
  Try
    If Not Assigned(MQTTClient) Then
    Begin
      MQTTClient := TMQTT.Create(edAddr.Text, StrToIntDef(edPort.Text, 1883));
      MQTTClient.ClientID := edClientID.Text;
      MQTTClient.Username := edUser.Text;
      MQTTClient.Password := edPwd.Text;
      MQTTClient.OnConnAck := @OnConnAck;
      MQTTClient.OnDisconnect := @OnDisConn;
      MQTTClient.OnPingResp := @OnPingResp;
      MQTTClient.OnPingReq := @OnPingReq;
      MQTTClient.OnPublish := @OnPublish;
      MQTTClient.OnSubAck := @OnSubAck;
      MQTTClient.OnUnSubAck := @OnUnSubAck;
      MQTTClient.OnPubAck := @OnPubAck;
      MQTTClient.OnPubRec := @OnPubRec;
      MQTTClient.OnPubRel := @OnPubRel;
      MQTTClient.OnPubComp := @OnPubComp;
    End;
    If Not MQTTClient.Connect() Then
    Begin
      FreeAndNil(MQTTClient);
      memSub.Lines.Add('Connection failed.');
    End;
  Finally
    Screen.Cursor := crDefault;
  End;
End;

Procedure TfrmMain.spDisconnectClick(Sender: TObject);
Begin
  If Not Assigned(MQTTClient) Then Exit;
  MQTTClient.Unsubscribe(MQTTClient.Subscribed);
  MQTTClient.Disconnect;
  FreeAndNil(MQTTClient);
End;

Procedure TfrmMain.spPublishClick(Sender: TObject);
Var
  i: Integer;
Begin
  If Not Assigned(MQTTClient) Then Exit;
  If rbSQoS1.Checked Then
    i := 1
  Else If rbSQoS2.Checked Then
    i := 2
  Else i := 0;
  MQTTClient.Publish(edPublish.Text, memPub.Text, i, chkRetain.Checked, chkDup.Checked);
End;

Procedure TfrmMain.spSubscribeClick(Sender: TObject);
Var
  i: Integer;
Begin
  If Not Assigned(MQTTClient) Then Exit;
  i := 0;
  If rbSQoS1.Checked Then
    i := 1;
  If rbSQoS2.Checked Then
    i := 2;
  MQTTClient.Subscribe(edSubscribe.Text, i);
  memSub.Lines.Add('+ ' + edSubscribe.Text + ' [' + i.ToString + ']');
End;

Procedure TfrmMain.spUnsubscribeClick(Sender: TObject);
Begin
  If Not Assigned(MQTTClient) Then Exit;
  MQTTClient.Unsubscribe(edSubscribe.Text);
  memSub.Lines.Add('- ' + edSubscribe.Text);
End;

Procedure TfrmMain.FormCreate(Sender: TObject);
Var ini: TIniFile;
  i: Integer;
Begin
  MQTTClient := nil;
  spConnect.Enabled := True;
  spDisconnect.Enabled := False;
  memSub.Lines.Clear;
  ParIni := ChangeFileExt(Application.ExeName, '.ini');
  ini := TIniFile.Create(ParIni);
  Try
    edClientID.Text := ini.ReadString('Connection', 'ClientID', edClientID.Text);
    edAddr.Text := ini.ReadString('Connection', 'Host', edAddr.Text);
    edPort.Text := ini.ReadString('Connection', 'Port', edPort.Text);
    edUser.Text := ini.ReadString('Connection', 'User', edUser.Text);
    edPwd.Text := ini.ReadString('Connection', 'Password', edPwd.Text);
    edPublish.Text := ini.ReadString('Publish', 'Text', edPublish.Text);
    i := ini.ReadInteger('Publish', 'QoS', 0);
    Case i Of
    0: rbPQoS0.Checked := True;
    1: rbPQoS1.Checked := True;
    2: rbPQoS2.Checked := True;
    End;
    chkRetain.Checked := ini.ReadInteger('Publish', 'Retain', 0) <> 0;
    chkDup.Checked := ini.ReadInteger('Publish', 'Dup', 0) <> 0;
    edSubscribe.Text := ini.ReadString('Subscribe', 'Text', edSubscribe.Text);
    i := ini.ReadInteger('Subscribe', 'QoS', 0);
    Case i Of
    0: rbSQoS0.Checked := True;
    1: rbSQoS1.Checked := True;
    2: rbSQoS2.Checked := True;
    End;
  Finally
    FreeAndNil(ini);
  End;
End;

Procedure TfrmMain.FormShow(Sender: TObject);
Begin
  panConnect.Height := edUser.Top + edUser.Height + 8;
end;

Procedure TfrmMain.FormClose(Sender: TObject; Var CloseAction: TCloseAction);
Var ini: TIniFile;
  i: Integer;
Begin
  spDisconnectClick(nil);
  ini := TIniFile.Create(ParIni);
  Try
    ini.WriteString('Connection', 'ClientID', edClientID.Text);
    ini.WriteString('Connection', 'Host', edAddr.Text);
    ini.WriteString('Connection', 'Port', edPort.Text);
    ini.WriteString('Connection', 'User', edUser.Text);
    ini.WriteString('Connection', 'Password', edPwd.Text);
    ini.WriteString('Publish', 'Text', edPublish.Text);
    If rbPQoS1.Checked Then
      i := 1
    Else If rbPQoS2.Checked Then
      i := 2
    Else i := 0;
    ini.WriteInteger('Publish', 'QoS', i);
    If chkRetain.Checked Then
      ini.WriteInteger('Publish', 'Retain', 1)
    Else ini.WriteInteger('Publish', 'Retain', 0);
    If chkDup.Checked Then
      ini.WriteInteger('Publish', 'Dup', 1)
    Else ini.WriteInteger('Publish', 'Dup', 0);
    ini.WriteString('Subscribe', 'Text', edSubscribe.Text);
    If rbSQoS1.Checked Then
      i := 1
    Else If rbSQoS2.Checked Then
      i := 2
    Else i := 0;
    ini.WriteInteger('Subscribe', 'QoS', i);
  Finally
    FreeAndNil(ini);
  End;
End;

Procedure TfrmMain.OnConnAck(Sender: TObject; ReturnCode: Integer);
Begin
  memSub.Lines.Add('Rx: OnConnAck()');
  spConnect.Enabled := False;
  spDisconnect.Enabled := True;
  panPublish.Enabled := True;
  panSubscribe.Enabled := True;
End;

Procedure TfrmMain.OnDisConn(Sender: TObject);
Begin
  memSub.Lines.Add('Rx: OnDisconnect()');
  spConnect.Enabled := True;
  spDisconnect.Enabled := False;
  panPublish.Enabled := False;
  panSubscribe.Enabled := False;
  lbRecCnt.Caption := MQTTClient.RecvCounter.ToString;
  lbSendCnt.Caption := MQTTClient.SendCounter.ToString;
End;

Procedure TfrmMain.OnPingResp(Sender: TObject);
Begin
  If chkLogPing.Checked Then
    memSub.Lines.Add('Rx: OnPingResp()');
  lbRecCnt.Caption := MQTTClient.RecvCounter.ToString;
  lbSendCnt.Caption := MQTTClient.SendCounter.ToString;
End;

Procedure TfrmMain.OnPingReq(Sender: TObject);
Begin
  If chkLogPing.Checked Then
    memSub.Lines.Add('Rx: OnPingReq()');
End;

Procedure TfrmMain.OnSubAck(Sender: TObject; MessageID, QoS: Integer);
Begin
  memSub.Lines.Add('Rx: OnSubAck(' + MessageID.ToString + ',' + QoS.ToString + ')');
End;

Procedure TfrmMain.OnUnSubAck(Sender: TObject; MessageID: Integer);
Begin
  memSub.Lines.Add('Rx: OnUnSubAck(' + MessageID.ToString + ')');
End;

Procedure TfrmMain.OnPublish(Sender: TObject; topic, payload: Utf8string; MessageID: Integer; QoS: Integer; Retain, Dup: Boolean);
Begin
  memSub.Lines.Add('Rx: ' + Topic + '=' + PayLoad);
End;

Procedure TfrmMain.OnPubAck(Sender: TObject; MessageID: Integer);
Begin
  memSub.Lines.Add('Rx: OnPubAck(' + MessageID.ToString + ')');
End;

Procedure TfrmMain.OnPubRec(Sender: TObject; MessageID: Integer);
Begin
  memSub.Lines.Add('Rx: OnPubRec(' + MessageID.ToString + ')');
  MQTTClient.Pubrel(MessageID);
End;

Procedure TfrmMain.OnPubRel(Sender: TObject; MessageID: Integer);
Begin
  memSub.Lines.Add('Rx: OnPubRel(' + MessageID.ToString + ')');
End;

Procedure TfrmMain.OnPubComp(Sender: TObject; MessageID: Integer);
Begin
  memSub.Lines.Add('Rx: OnPubComp(' + MessageID.ToString + ')');
End;


End.
