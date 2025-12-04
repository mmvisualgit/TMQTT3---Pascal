Unit MQTT;

{$MODE Delphi}

Interface

Uses
  SysUtils,
  Classes, Forms, dateutils,
  ExtCtrls,
  Generics.Collections,
  blcksock,
  MQTTHeaders,
  MQTTReadThread;

Type
  {$IF not declared(TBytes)}
    TBytes = array of Byte;
  {$IFEND}

  TMQTT = Class
  private
    { Private Declarations }
    FClientID: Utf8string;
    FHostname: String;
    FPort: Integer;
    FMessageID: Integer;
    FisConnected: Boolean;
    FAutoResponse: Boolean;
    FTimeout: Integer;
    FTag: PtrInt;
    FRecvThread: TMQTTReadThread;

    FWillMsg: Utf8string;
    FWillTopic: Utf8string;
    FUsername: Utf8string;
    FPassword: Utf8string;

    FCleanStart: Boolean;
    FWillFlag: Boolean;
    FWillQoS: Integer;
    FWillRetain: Boolean;

    FSocket: TTCPBlockSocket;
    FKeepAliveTimer: TTimer;
    FKeepAlive: TDateTime;

    // Event Fields
    FConnAckEvent: TConnAckEvent;
    FDisconnectEvent: TDisconnectEvent;
    FPublishEvent: TPublishEvent;
    FPingRespEvent: TPingRespEvent;
    FPingReqEvent: TPingReqEvent;
    FSubAckEvent: TSubAckEvent;
    FUnSubAckEvent: TUnSubAckEvent;
    FPubAckEvent: TPubAckEvent;
    FPubRelEvent: TPubRelEvent;
    FPubRecEvent: TPubRecEvent;
    FPubCompEvent: TPubCompEvent;

    Function WriteData(AData: TBytes): Boolean;
    Function hasWill: Boolean;
    Function getNextMessageId: Integer;
    Function createAndResumeRecvThread(Socket: TTCPBlockSocket): Boolean;

    // TMQTTMessage Factory Methods.
    Function ConnectMessage: TMQTTMessage;
    Function DisconnectMessage: TMQTTMessage;
    Function PublishMessage: TMQTTMessage;
    Function PubrelMessage: TMQTTMessage;
    Function PubackMessage: TMQTTMessage;
    Function PubrecMessage: TMQTTMessage;
    Function PubcompMessage: TMQTTMessage;
    Function PingReqMessage: TMQTTMessage;
    Function SubscribeMessage: TMQTTMessage;
    Function UnsubscribeMessage: TMQTTMessage;

    // Our Keep Alive Ping Timer Event
    Procedure KeepAliveTimer_Event(Sender: TObject);

    // Recv Thread Event Handling Procedures.
    Procedure GotConnAck(Sender: TObject; ReturnCode: Integer);
    Procedure GotDisconnect(Sender: TObject);
    Procedure GotPingResp(Sender: TObject);
    Procedure GotPingReq(Sender: TObject);
    Procedure GotSubAck(Sender: TObject; MessageID: Integer; QoS: Integer);
    Procedure GotUnSubAck(Sender: TObject; MessageID: Integer);
    Procedure GotPub(Sender: TObject; topic, payload: Utf8string; MessageID: Integer; QoS: Integer; Retain, Dup: Boolean);
    Procedure GotPubAck(Sender: TObject; MessageID: Integer);
    Procedure GotPubRec(Sender: TObject; MessageID: Integer);
    Procedure GotPubRel(Sender: TObject; MessageID: Integer);
    Procedure GotPubComp(Sender: TObject; MessageID: Integer);

    Procedure GotConnAckAsyncQueue(Data: PtrInt);
    Procedure GotDisconnectAsyncQueue(Data: PtrInt);
    Procedure GotPingRespAsyncQueue(Data: PtrInt);
    Procedure GotPingReqAsyncQueue(Data: PtrInt);
    Procedure GotSubAckAsyncQueue(Data: PtrInt);
    Procedure GotUnSubAckAsyncQueue(Data: PtrInt);
    Procedure GotPubAsyncQueue(Data: PtrInt);
    Procedure GotPubAckAsyncQueue(Data: PtrInt);
    Procedure GotPubRecAsyncQueue(Data: PtrInt);
    Procedure GotPubRelAsyncQueue(Data: PtrInt);
    Procedure GotPubCompAsyncQueue(Data: PtrInt);

    Procedure SetTimeout(Value: Integer);
    Procedure SetWillQoS(Value: Integer);
    Function GetRecvCounter(): int64;
    Function GetSendCounter(): int64;
  public
    { Public Declarations }
    Subscribed: TStringList; // List with all subscribed, as TObject is the MessageID

    Function Connect: Boolean;
    Function Disconnect: Boolean;
    Function Publish(Topic: Utf8string; sPayload: Utf8string): Integer; overload;
    Function Publish(Topic: Utf8string; sPayload: Utf8string; Retain: Boolean): Integer; overload;
    Function Publish(Topic: Utf8string; sPayload: Utf8string; QoS: Integer; Retain: Boolean = False; Dup: Boolean = False): Integer; overload;
    Function Pubrel(MessageID: Integer): Integer;
    Function Puback(MessageID: Integer): Integer;
    Function Pubrec(MessageID: Integer): Integer;
    Function Pubcomp(MessageID: Integer): Integer;
    Function Subscribe(Topic: Utf8string; RequestQoS: Integer): Integer; overload;
    Function Subscribe(Topics: TDictionary<Utf8string, Integer>): Integer; overload;
    Function Unsubscribe(Topic: Utf8string): Integer; overload;
    Function Unsubscribe(Topics: TStringList): Integer; overload;
    Function PingReq: Boolean;
    Constructor Create(hostName: String; port: Integer);
    Destructor Destroy; override;

    Property WillTopic: Utf8string read FWillTopic write FWillTopic;
    Property WillMsg: Utf8string read FWillMsg write FWillMsg;

    Property CleanStart: Boolean read FCleanStart write FCleanStart;
    Property WillFlag: Boolean read FWillFlag write FWillFlag;
    Property WillQoS: Integer read FWillQoS write SetWillQoS;
    Property WillRetain: Boolean read FWillRetain write FWillRetain;

    Property Username: Utf8string read FUsername write FUsername;
    Property Password: Utf8string read FPassword write FPassword;
    // Client ID is our Client Identifier.
    Property ClientID: Utf8string read FClientID write FClientID;
    Property isConnected: Boolean read FisConnected;
    Property AutoResponse: Boolean read FAutoResponse write FAutoResponse;
    Property Timeout: Integer read FTimeout write SetTimeout;
    property RecvCounter: int64 read GetRecvCounter;
    property SendCounter: int64 read GetSendCounter;
    property Tag: PtrInt read FTag write FTag;

    // Event Handlers
    Property OnConnAck: TConnAckEvent read FConnAckEvent write FConnAckEvent;
    Property OnDisconnect: TDisconnectEvent read FDisconnectEvent write FDisconnectEvent;
    Property OnPublish: TPublishEvent read FPublishEvent write FPublishEvent;
    Property OnPingResp: TPingRespEvent read FPingRespEvent write FPingRespEvent;
    Property OnPingReq: TPingRespEvent read FPingReqEvent write FPingReqEvent;
    Property OnSubAck: TSubAckEvent read FSubAckEvent write FSubAckEvent;
    Property OnUnSubAck: TUnSubAckEvent read FUnSubAckEvent write FUnSubAckEvent;
    Property OnPubAck: TPubAckEvent read FPubAckEvent write FPubAckEvent;
    Property OnPubRec: TPubRecEvent read FPubRecEvent write FPubRecEvent;
    Property OnPubRel: TPubRelEvent read FPubRelEvent write FPubRelEvent;
    Property OnPubComp: TPubCompEvent read FPubCompEvent write FPubCompEvent;
  End;

Implementation

Type
  TMqttAsyncMsg = Record
  public
    Sender: TObject;
    MessageID: Integer;
    QoS: Integer;
    ReturnCode: Integer;
    Retain: Boolean;
    Dup: Boolean;
    topic: Utf8string;
    payload: Utf8string;
  End;
  PMqttAsyncMsg = ^TMqttAsyncMsg;


{ TMQTTClient }

Procedure TMQTT.GotConnAck(Sender: TObject; ReturnCode: Integer);
var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If Assigned(FConnAckEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.ReturnCode := ReturnCode;
    Application.QueueAsyncCall(GotConnAckAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotConnAckAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FConnAckEvent) Then
      OnConnAck(Self, MqttAsyncMsg.ReturnCode);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Procedure TMQTT.GotDisconnect(Sender: TObject);
Begin
  FisConnected := False;
  If Assigned(FDisconnectEvent) Then
    Application.QueueAsyncCall(GotDisconnectAsyncQueue, 0);
End;

Procedure TMQTT.GotDisconnectAsyncQueue(Data: PtrInt);
Begin
  Try
    If Assigned(FDisconnectEvent) Then
      OnDisconnect(Self);
  Finally
  End;
End;

Function TMQTT.Connect: Boolean;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  // Create socket and connect.
  Result := False;
  FSocket := TTCPBlockSocket.Create;
  Try
    FSocket.SetTimeout(FTimeout);
    FSocket.ConnectionTimeout := FTimeout;
    FSocket.nonBlockMode := True;
    FSocket.NonblockSendTimeout := 1;
    FSocket.Connect(Self.FHostname, IntToStr(Self.FPort));
    FisConnected := FSocket.LastError = 0;
    If FSocket.LastError <> 0 Then
      FreeAndNil(FSocket);
  Except
    // If we encounter an exception upon connection then reraise it, free the socket
    // and reset our isConnected flag.
    on E: Exception Do
    Begin
      Raise;
      FisConnected := False;
      FreeAndNil(FSocket);
    End;
  End;

  If FisConnected Then
  Begin
    Msg := ConnectMessage;
    Try
      Msg.Payload.Contents.Clear;
      Msg.Payload.Contents.Add(Self.FClientID);
      (Msg.VariableHeader As TMQTTConnectVarHeader).WillFlag := Ord(hasWill);

      (Msg.VariableHeader As TMQTTConnectVarHeader).CleanStart := Ord(FCleanStart);
      (Msg.VariableHeader As TMQTTConnectVarHeader).WillFlag := Ord(FWillFlag);
      (Msg.VariableHeader As TMQTTConnectVarHeader).QoSLevel := FWillQoS;
      (Msg.VariableHeader As TMQTTConnectVarHeader).Retain := Ord(FWillRetain);

      If hasWill Then
      Begin
        Msg.Payload.Contents.Add(Self.FWillTopic);
        Msg.Payload.Contents.Add(Self.FWillMsg);
      End;

      If Length(FUsername) >= 1 Then
      Begin
        Msg.Payload.Contents.Add(FUsername);
        (Msg.VariableHeader As TMQTTConnectVarHeader).Username := 1;
        If Length(FPassword) >= 1 Then
        Begin
          Msg.Payload.Contents.Add(FPassword);
          (Msg.VariableHeader As TMQTTConnectVarHeader).Password := 1;
        End;
      End;

      Data := Msg.ToBytes;
      Result := createAndResumeRecvThread(FSocket);
      Result := Result And WriteData(Data);
      // Start our Receive thread.
      If Result Then
      Begin
        // Use the KeepAlive that we just sent to determine our ping timer.
        FKeepAliveTimer.Interval := (Round((Msg.VariableHeader As TMQTTConnectVarHeader).KeepAlive * 0.80)) * 1000;
        FKeepAliveTimer.Enabled := True;
        FKeepAlive := Now;
      End;
    Finally
      FreeAndNil(Msg);
    End;
  End;
End;

Function TMQTT.ConnectMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.VariableHeader := TMQTTConnectVarHeader.Create;
  Result.Payload := TMQTTPayload.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.CONNECT);
  Result.FixedHeader.Retain := 0;
  Result.FixedHeader.QoSLevel := 0;
  Result.FixedHeader.Duplicate := 0;
End;

Constructor TMQTT.Create(hostName: String; port: Integer);
Begin
  Inherited Create;

  Self.FisConnected := False;
  Self.FAutoResponse := True;
  Self.FHostname := Hostname;
  Self.FPort := Port;
  Self.FMessageID := 1;
  Self.FTimeout := 1000;
  Self.FCleanStart := True;
  // Create a Default ClientID as a default. Can be overridden with TMQTT.ClientID any time before connection.
  Self.FClientID := 'TMQTT' + IntToStr(DateTimeToUnix(Time));

  Subscribed := TStringList.Create;

  // Create the timer responsible for pinging.
  FKeepAliveTimer := TTimer.Create(nil);
  FKeepAliveTimer.Enabled := False;
  FKeepAliveTimer.OnTimer := KeepAliveTimer_Event;
End;

Function TMQTT.createAndResumeRecvThread(Socket: TTCPBlockSocket): Boolean;
Var DisconEv: TDisconnectEvent;
Begin
  Result := False;
  Try
    If Assigned(FRecvThread) Then // Kill the Thread
    Begin
      If FRecvThread.Running Then
      Begin
        DisconEv := FDisconnectEvent;
        FDisconnectEvent := Nil;
        FRecvThread.Terminate;
        While FRecvThread.Running Do
          Application.ProcessMessages;
        FDisconnectEvent := DisconEv;
      End;
      FreeAndNil(FRecvThread);
    End;

    FRecvThread := TMQTTReadThread.Create(Socket);
    FRecvThread.Timeout := FTimeout;

    { Todo: Assign Event Handlers here.   }
    FRecvThread.OnConnAck := Self.GotConnAck;
    FRecvThread.OnDisconnect := Self.GotDisconnect;
    FRecvThread.OnPublish := Self.GotPub;
    FRecvThread.OnPingResp := Self.GotPingResp;
    FRecvThread.OnPingReq := Self.GotPingReq;
    FRecvThread.OnSubAck := Self.GotSubAck;
    FRecvThread.OnUnSubAck := Self.GotUnSubAck;
    FRecvThread.OnPubAck := Self.GotPubAck;
    FRecvThread.OnPubRec := Self.GotPubRec;
    FRecvThread.OnPubRel := Self.GotPubRel;
    FRecvThread.OnPubComp := Self.GotPubComp;
    Result := True;
  Except
    Result := False;
  End;
End;

Destructor TMQTT.Destroy;
Begin
  If Assigned(FSocket) Then
  Begin
    Disconnect;
  End;
  If Assigned(FKeepAliveTimer) Then
  Begin
    FreeAndNil(FKeepAliveTimer);
  End;
  If Assigned(FRecvThread) Then
  Begin
    FRecvThread.Destroy;
    While FRecvThread.Running Do
      Application.ProcessMessages;
    FreeAndNil(FRecvThread);
  End;

  FreeAndNil(Subscribed);
  Inherited Destroy;
End;

Function TMQTT.Disconnect: Boolean;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  Result := False;
  If FisConnected Then
  Begin
    FKeepAliveTimer.Enabled := False;
    Msg := DisconnectMessage;
    Data := Msg.ToBytes;
    FreeAndNil(Msg);
    Result := WriteData(Data);
    // Terminate our socket receive thread.
    If Assigned(FRecvThread) Then
    Begin
      FRecvThread.Terminate;
      While FRecvThread.Running Do
        Application.ProcessMessages;
      FreeAndNil(FRecvThread);
    End;

    // Close our socket.
    If Assigned(FSocket) Then
    Begin
      FSocket.CloseSocket;
      FreeAndNil(FSocket);
    End;
    FisConnected := False;
  End;
End;

Function TMQTT.DisconnectMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.DISCONNECT);
End;

Procedure TMQTT.SetTimeout(Value: Integer);
Begin
  FTimeout := Value;
  If Assigned(FRecvThread) Then
    FRecvThread.Timeout := FTimeout;
  If Assigned(FSocket) Then
    FSocket.SetTimeout(FTimeout);
End;

Procedure TMQTT.SetWillQoS(Value: Integer);
Begin
  If Value < 0 Then Value := 0;
  If Value > 2 Then Value := 2;
  FWillQoS := Value;
End;

Function TMQTT.GetRecvCounter(): int64;
Begin
  If Assigned(FSocket) Then
    Result := FSocket.RecvCounter
  Else Result := 0;
End;

Function TMQTT.GetSendCounter(): int64;
Begin
  If Assigned(FSocket) Then
    Result := FSocket.SendCounter
  Else Result := 0;
End;

Function TMQTT.getNextMessageId: Integer;
Begin
  // Return our current message Id (Range 1...65535)
  Result := (FMessageID Mod 65535) + 1; // Message ID in correct 16 Bit range
  // Increment message Id
  FMessageID := (FMessageID + 1) Mod 65535;
End;

Function TMQTT.hasWill: Boolean;
Begin
  If ((Length(FWillTopic) < 1) And (Length(FWillMsg) < 1)) Then
  Begin
    Result := False;
  End Else
    Result := True;
End;

Procedure TMQTT.KeepAliveTimer_Event(Sender: TObject);
Begin
  If Self.isConnected Then
  Begin                 // 4 times of missing ping request
    If FKeepAlive < (Now - ((FKeepAliveTimer.Interval * 4) / 86400000)) Then
      Disconnect // Timeout after 30 seconds, do disconnect
    Else PingReq;
  End;
End;

Function TMQTT.PingReq: Boolean;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  Result := False;
  If isConnected Then
  Begin
    Msg := PingReqMessage;
    Data := Msg.ToBytes;
    Result := WriteData(Data);
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.PingReqMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.PINGREQ);
End;

Procedure TMQTT.GotPingResp(Sender: TObject);
Begin
  FKeepAlive := Now;
  If Assigned(FPingRespEvent) Then
    Application.QueueAsyncCall(GotPingRespAsyncQueue, 0);
End;

Procedure TMQTT.GotPingRespAsyncQueue(Data: PtrInt);
Begin
  If Assigned(FPingRespEvent) Then
    OnPingResp(Self);
End;

Procedure TMQTT.GotPingReq(Sender: TObject);
Begin
  If Assigned(FPingReqEvent) Then
    Application.QueueAsyncCall(GotPingReqAsyncQueue, 0);
End;

Procedure TMQTT.GotPingReqAsyncQueue(Data: PtrInt);
Begin
  If Assigned(FPingReqEvent) Then
    OnPingReq(Self);
End;

Function TMQTT.Publish(Topic, sPayload: Utf8string; Retain: Boolean): Integer;
Begin
  Result := Publish(Topic, sPayload, 0, Retain, False);
End;

Function TMQTT.Publish(Topic, sPayload: Utf8string): Integer;
Begin
  Result := Publish(Topic, sPayload, 0, False, False);
End;

Function TMQTT.Publish(Topic, sPayload: Utf8string; QoS: Integer; Retain: Boolean = False; Dup: Boolean = False): Integer;
Var Msg: TMQTTMessage;
  Data: TBytes;
  Function IIF(b: Boolean): LongInt;
  Begin
    If b Then
      Result := 1
    Else Result := 0;
  End;

Begin
  Result := -1;
  If ((QoS >= 0) And (QoS <= 2)) Then
  Begin
    If isConnected Then
    Begin
      Msg := PublishMessage;
      Msg.FixedHeader.Retain := IIF(Retain);
      Msg.FixedHeader.QoSLevel := QoS;
      Msg.FixedHeader.Duplicate := IIF(Dup);
      (Msg.VariableHeader As TMQTTPublishVarHeader).QoSLevel := QoS;
      (Msg.VariableHeader As TMQTTPublishVarHeader).Topic := Topic;
      If (QoS > 0) Then
      Begin
        Result := getNextMessageId;
        (Msg.VariableHeader As TMQTTPublishVarHeader).MessageID := Result;
      End Else
        Result := 0;
      Msg.Payload.Contents.Clear;
      Msg.Payload.Contents.Add(sPayload);
      Msg.Payload.PublishMessage := True;
      Data := Msg.ToBytes;
      If Not WriteData(Data) Then
        Result := -1;
      FreeAndNil(Msg);
    End;
  End Else
    Raise EInvalidOp.Create('QoS level can only be equal to or between 0 and 2.');
End;

Function TMQTT.PublishMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.PUBLISH);
  Result.VariableHeader := TMQTTPublishVarHeader.Create(0);
  Result.Payload := TMQTTPayload.Create;
End;

Function TMQTT.Pubrel(MessageID: Integer): Integer;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  Result := -1;
  If isConnected Then
  Begin
    Msg := PubrelMessage;
    (Msg.VariableHeader As TMQTTPubrelVarHeader).MessageID := MessageID;
    Data := Msg.ToBytes;
    If WriteData(Data) Then
      Result := MessageID;
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.PubrelMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.PUBREL);
  Result.VariableHeader := TMQTTPubrelVarHeader.Create(0);
End;

Function TMQTT.Puback(MessageID: Integer): Integer;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  Result := -1;
  If isConnected Then
  Begin
    Msg := PubackMessage;
    (Msg.VariableHeader As TMQTTPubackVarHeader).MessageID := MessageID;
    Data := Msg.ToBytes;
    If WriteData(Data) Then
      Result := MessageID;
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.PubackMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.PUBACK);
  Result.VariableHeader := TMQTTPubackVarHeader.Create(0);
End;

Function TMQTT.Pubrec(MessageID: Integer): Integer;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  Result := -1;
  If isConnected Then
  Begin
    Msg := PubrecMessage;
    (Msg.VariableHeader As TMQTTPubrecVarHeader).MessageID := MessageID;
    Data := Msg.ToBytes;
    If WriteData(Data) Then
      Result := MessageID;
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.PubrecMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.PUBREC);
  Result.VariableHeader := TMQTTPubrecVarHeader.Create(0);
End;

Function TMQTT.Pubcomp(MessageID: Integer): Integer;
Var Msg: TMQTTMessage;
  Data: TBytes;
Begin
  Result := -1;
  If isConnected Then
  Begin
    Msg := PubcompMessage;
    (Msg.VariableHeader As TMQTTPubcompVarHeader).MessageID := MessageID;
    Data := Msg.ToBytes;
    If WriteData(Data) Then
      Result := MessageID;
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.PubcompMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.PUBCOMP);
  Result.VariableHeader := TMQTTPubcompVarHeader.Create(0);
End;

Procedure TMQTT.GotPubRec(Sender: TObject; MessageID: Integer);
Var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If Assigned(FPubAckEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    Application.QueueAsyncCall(GotPubRecAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotPubRecAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FPubRecEvent) Then
      OnPubRec(Self, MqttAsyncMsg.MessageID);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Procedure TMQTT.GotPubRel(Sender: TObject; MessageID: Integer);
Var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If FAutoResponse Then
  Begin
    Pubcomp(MessageID);
  End;
  If Assigned(FPubRelEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    Application.QueueAsyncCall(GotPubRelAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotPubRelAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FPubRelEvent) Then
      OnPubRel(Self, MqttAsyncMsg.MessageID);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Function TMQTT.Subscribe(Topic: Utf8string; RequestQoS: Integer): Integer;
Var
  dTopics: TDictionary<Utf8string, Integer>;
Begin
  dTopics := TDictionary<Utf8string, Integer>.Create;
  dTopics.Add(Topic, RequestQoS);
  Result := Subscribe(dTopics);
  FreeAndNil(dTopics);
End;

Procedure TMQTT.GotSubAck(Sender: TObject; MessageID: Integer; QoS: Integer);
var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If Assigned(FSubAckEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    MqttAsyncMsg^.QoS := QoS;
    Application.QueueAsyncCall(GotSubAckAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotSubAckAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FSubAckEvent) Then
      OnSubAck(Self, MqttAsyncMsg.MessageID, MqttAsyncMsg.QoS);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Function TMQTT.Subscribe(Topics: TDictionary<Utf8string, Integer>): Integer;
Var Msg: TMQTTMessage;
  i, MsgId: Integer;
  sTopic: Utf8string;
  Data: TBytes;
Begin
  Result := -1;
  If isConnected Then
  Begin
    Msg := SubscribeMessage;
    MsgId := getNextMessageId;
    (Msg.VariableHeader As TMQTTSubscribeVarHeader).MessageID := MsgId;
    Msg.Payload.Contents.Clear;
    For sTopic In Topics.Keys Do
    Begin
      i := Subscribed.IndexOf(sTopic);
      If i < 0 Then
        Subscribed.AddObject(sTopic, TObject(PtrInt(MsgId)))
      Else Subscribed.Objects[i] := TObject(PtrInt(MsgId));
      Msg.Payload.Contents.Add(sTopic);
      Msg.Payload.Contents.Add(IntToStr(Topics.Items[sTopic]));
    End;
    // the subscribe message contains integer literals not encoded as strings.
    Msg.Payload.ContainsIntLiterals := True;

    Data := Msg.ToBytes;
    If WriteData(Data) Then
      Result := MsgId;
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.SubscribeMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.SUBSCRIBE);
  Result.FixedHeader.QoSLevel := 1;
  Result.VariableHeader := TMQTTSubscribeVarHeader.Create(0);
  Result.Payload := TMQTTPayload.Create;
End;

Function TMQTT.Unsubscribe(Topic: Utf8string): Integer;
Var
  slTopics: TStringList;
Begin
  slTopics := TStringList.Create;
  slTopics.Add(Topic);
  Result := Unsubscribe(slTopics);
  FreeAndNil(slTopics);
End;

Procedure TMQTT.GotUnSubAck(Sender: TObject; MessageID: Integer);
Var i: Integer;
    MqttAsyncMsg: PMqttAsyncMsg;
Begin
  i := Subscribed.IndexOfObject(TObject(PtrInt(MessageID)));
  While i >= 0 Do
  Begin
    Subscribed.Delete(i);
    i := Subscribed.IndexOfObject(TObject(PtrInt(MessageID)));
  End;
  If Assigned(FUnSubAckEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    Application.QueueAsyncCall(GotUnSubAckAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotUnSubAckAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FUnSubAckEvent) Then
      OnUnSubAck(Self, MqttAsyncMsg.MessageID);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Function TMQTT.Unsubscribe(Topics: TStringList): Integer;
Var Msg: TMQTTMessage;
  i, k, MsgId: Integer;
  Data: TBytes;
Begin
  Result := -1;
  If isConnected Then
  Begin
    Msg := UnsubscribeMessage;
    MsgId := getNextMessageId;
    (Msg.VariableHeader As TMQTTUnsubscribeVarHeader).MessageID := MsgId;
    Msg.Payload.Contents.Clear;
    Msg.Payload.Contents.AddStrings(Topics);
    For i := 0 To Topics.Count - 1 Do
    Begin
      k := Subscribed.IndexOf(Topics[i]);
      If k >= 0 Then
        Subscribed.Objects[k] := TObject(PtrInt(MsgId));
    End;
    Data := Msg.ToBytes;
    If WriteData(Data) Then
      Result := MsgId;
    FreeAndNil(Msg);
  End;
End;

Function TMQTT.UnsubscribeMessage: TMQTTMessage;
Begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := Ord(TMQTTMessageType.UNSUBSCRIBE);
  Result.FixedHeader.QoSLevel := 1;
  Result.VariableHeader := TMQTTUnsubscribeVarHeader.Create(0);
  Result.Payload := TMQTTPayload.Create;
End;

Function TMQTT.WriteData(AData: TBytes): Boolean;
Begin
  Result := FRecvThread.SocketWrite(AData);
  FisConnected := Result;
  If Not FisConnected Then
    If Assigned(FDisconnectEvent) Then
      OnDisconnect(Self);
End;

Procedure TMQTT.GotPub(Sender: TObject; topic, payload: Utf8string; MessageID: Integer; QoS: Integer; Retain, Dup: Boolean);
Var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If FAutoResponse Then
  Begin
    Case QoS Of
    1: Puback(MessageID);
    2: Pubrec(MessageID);
    End;
  End;
  If Assigned(FPublishEvent) Then
    OnPublish(Self, topic, payload, MessageID, QoS, Retain, Dup);

  If Assigned(FPublishEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    MqttAsyncMsg^.QoS := QoS;
    MqttAsyncMsg^.Retain := Retain;
    MqttAsyncMsg^.Dup := Dup;
    MqttAsyncMsg^.topic := topic;
    MqttAsyncMsg^.payload := payload;
    Application.QueueAsyncCall(GotPubAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotPubAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FPublishEvent) Then
      OnPublish(Self, MqttAsyncMsg.topic, MqttAsyncMsg.payload, MqttAsyncMsg.MessageID, MqttAsyncMsg.QoS, MqttAsyncMsg.Retain, MqttAsyncMsg.Dup);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Procedure TMQTT.GotPubAck(Sender: TObject; MessageID: Integer);
Var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If Assigned(FPubAckEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    Application.QueueAsyncCall(GotPubAckAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotPubAckAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FPubAckEvent) Then
      OnPubAck(Self, MqttAsyncMsg.MessageID);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

Procedure TMQTT.GotPubComp(Sender: TObject; MessageID: Integer);
Var MqttAsyncMsg: PMqttAsyncMsg;
Begin
  If Assigned(FPubCompEvent) Then
  Begin
    New(MqttAsyncMsg);
    MqttAsyncMsg^.Sender := Sender;
    MqttAsyncMsg^.MessageID := MessageID;
    Application.QueueAsyncCall(GotPubCompAsyncQueue, {%H-}PtrInt(MqttAsyncMsg));
  End;
End;

Procedure TMQTT.GotPubCompAsyncQueue(Data: PtrInt);
Var MqttAsyncMsg: TMqttAsyncMsg;
Begin
  MqttAsyncMsg := {%H-}PMqttAsyncMsg(Data)^;
  Try
    If Assigned(FPubCompEvent) Then
      OnPubComp(Self, MqttAsyncMsg.MessageID);
  Finally
    Dispose({%H-}PMqttAsyncMsg(Data));
  End;
End;

End.
