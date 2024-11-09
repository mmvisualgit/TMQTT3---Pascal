Unit MQTTReadThread;

{$MODE Delphi}

Interface

Uses
  Classes,
  SysUtils,
  {$IFDEF MSWINDOWS}
  LCLIntf, LCLType,
  {$ENDIF}
  MQTTHeaders,
  blcksock;

Type
  PTCPBlockSocket = ^TTCPBlockSocket;

  TMQTTRecvUtilities = Class
  public
    Class Function MSBLSBToInt(ALengthBytes: TBytes): Integer;
    Class Function RLBytesToInt(ARlBytes: TBytes): Integer;
  End;

  TUnparsedMsg = Record
  public
    FixedHeader: Byte;
    RL: TBytes;
    Data: TBytes;
  End;
  PUnparsedMsg = ^TUnparsedMsg;

  TMQTTReadThread = Class(TThread)
  private
    { Private declarations }
    FPSocket: TTCPBlockSocket;
    FTimeout: Integer;

    FCurrentMsg: TUnparsedMsg;

    FCurrentRecvState: TMQTTRecvState;
    // Events
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
    FTxMsgs: Array[0..999] Of TBytes;
    FTxMsgsIn, FTxMsgsOut: Integer;


    Procedure HandleMessage;
    Procedure HandeDisconnect;
    Function readSingleString(Const dataStream: TBytes; Const indexStartAt: Integer; Var stringRead: Utf8string): Integer;
    Function readMessageId(Const dataStream: TBytes; Const indexStartAt: Integer; Var messageId: Integer): Integer;
    Function readStringWithoutPrefix(Const dataStream: TBytes; Const indexStartAt: Integer; Var stringRead: Utf8string): Integer;
  protected
    Procedure CleanStart;
    Procedure Execute; override;
  public
    Running: Boolean;

    Constructor Create(Socket: TTCPBlockSocket);
    Function SocketWrite(Data: TBytes): Boolean;

    // Event properties.
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
    Property Timeout: Integer read FTimeout write FTimeout;
  End;

Implementation

Class Function TMQTTRecvUtilities.MSBLSBToInt(ALengthBytes: TBytes): Integer;
Begin
  Assert(ALengthBytes <> nil, 'Must not pass nil to this method');
  Assert(Length(ALengthBytes) = 2, 'The MSB-LSB 2 bytes structure must be 2 Bytes in length');

  Result := 0;
  Result := ALengthBytes[0] Shl 8;
  Result := Result + ALengthBytes[1];
End;

Class Function TMQTTRecvUtilities.RLBytesToInt(ARlBytes: TBytes): Integer;
Var
  multi: Integer;
  i: Integer;
  digit: Byte;
Begin
  Assert(ARlBytes <> nil, 'Must not pass nil to this method');

  multi := 1;
  i := 0;
  Result := 0;

  If ((Length(ARlBytes) > 0) And (Length(ARlBytes) <= 4)) Then
  Begin
    Repeat
      digit := ARlBytes[i];
      Result := Result + (digit And 127) * multi;
      multi := multi * 128;
      Inc(i);
    Until ((digit And 128) = 0);
  End;
End;

Procedure AppendBytes(Var DestArray: TBytes; Const NewBytes: TBytes);
Var
  DestLen: Integer;
Begin
  If Length(NewBytes) > 0 Then
  Begin
    DestLen := Length(DestArray);
    SetLength(DestArray, DestLen + Length(NewBytes));
    Move(NewBytes[0], DestArray[DestLen], Length(NewBytes));
  End;
End;

{ TMQTTReadThread }

Procedure TMQTTReadThread.CleanStart;
Begin
  FCurrentRecvState := TMQTTRecvState.FixedHeaderByte;
  FTxMsgsIn := 0;
  FTxMsgsOut := 0;
  FTxMsgs[0] := Nil;
End;

Constructor TMQTTReadThread.Create(Socket: TTCPBlockSocket);
Begin
  Inherited Create(False);
  FPSocket := Socket;
  FreeOnTerminate := False;
  FTimeout := 1000;
  CleanStart;
End;

Procedure TMQTTReadThread.Execute;
Var
  CurrentMessage: TUnparsedMsg;
  RLInt: Integer;
  Buffer: TBytes;
  i, iOut: Integer;
  Data: TBytes;
  sentData, attemptsToWrite: Integer;
Begin
  Running := True;
  Buffer := nil;
  While Not Terminated Do
  Begin
    Case FCurrentRecvState Of
      TMQTTRecvState.FixedHeaderByte:
      Begin
        CurrentMessage.FixedHeader := FPSocket.RecvByte(1);

        If ((FPSocket.LastError = 0) And (CurrentMessage.FixedHeader <> 0)) Then
          FCurrentRecvState := TMQTTRecvState.RemainingLength;
      End;
      TMQTTRecvState.RemainingLength:
      Begin
        RLInt := 0;

        SetLength(CurrentMessage.RL, 1);
        SetLength(Buffer, 1);
        CurrentMessage.RL[0] := FPSocket.RecvByte(FTimeout);

        If FPSocket.LastError <> 0 Then
          FCurrentRecvState := TMQTTRecvState.Error;

        For i := 1 To 4 Do
        Begin
          If ((CurrentMessage.RL[i - 1] And 128) <> 0) Then
          Begin
            Buffer[0] := FPSocket.PeekByte(FTimeout);
            AppendBytes(CurrentMessage.RL, Buffer);
          End Else
            Break;
        End;

        RLInt := TMQTTRecvUtilities.RLBytesToInt(CurrentMessage.RL);

        If (FPSocket.LastError = 0) Then
          FCurrentRecvState := TMQTTRecvState.Data;
      End;
      TMQTTRecvState.Data:
      Begin
        If (RLInt > 0) Then
        Begin
          SetLength(CurrentMessage.Data, RLInt);
          RLInt := RLInt - FPSocket.RecvBufferEx(Pointer(CurrentMessage.Data), RLInt, FTimeout);
        End;

        If ((FPSocket.LastError = 0) And (RLInt = 0)) Then
        Begin
          FCurrentMsg := CurrentMessage;
          Synchronize(HandleMessage);
          CurrentMessage := Default(TUnparsedMsg);
          FCurrentRecvState := TMQTTRecvState.FixedHeaderByte;
        End;
      End;
      TMQTTRecvState.Error:
      Begin
        // Quit the loop, terminating the thread.
        break;
      End;
    End;  // end of Recv state case
    // Send Data after receive
    If FPSocket.CanWrite(1) Then
    While (FTxMsgsIn <> FTxMsgsOut) Do
    Begin
      iOut := (FTxMsgsOut + 1) Mod Length(FTxMsgs);
      Data := FTxMsgs[iOut];
      If Assigned(Data) Then
      Begin
        attemptsToWrite := 1;
        sentData := 0;
        Repeat
          If FPSocket.CanWrite(500 * attemptsToWrite) Then
          Begin
            sentData := sentData + FPSocket.SendBuffer(Pointer(Copy(Data, sentData - 1, Length(Data) + 1)), Length(Data) - sentData);
            Inc(attemptsToWrite);
          End;
        Until ((attemptsToWrite = 3) Or (sentData = Length(Data)));
      End;
      FTxMsgsOut := iOut; // Write Out after handle the data
    End;
  End;
  Synchronize(HandeDisconnect);
  Running := False;
End;

Procedure TMQTTReadThread.HandeDisconnect;
Begin
  If Assigned(FDisconnectEvent) Then
    OnDisconnect(Self);
End;

Procedure TMQTTReadThread.HandleMessage;
Var
  NewMsg: TUnparsedMsg;
  FHCode: Byte;
  dataCaret, QoS, MsgID: Integer;
  strTopic, strPayload: Utf8string;
  Retain, Dup: Boolean;
Begin
  dataCaret := 0;

  NewMsg := FCurrentMsg;
  FHCode := NewMsg.FixedHeader Shr 4;
  Case FHCode Of
    Ord(TMQTTMessageType.CONNACK):
    Begin
      If Length(NewMsg.Data) > 0 Then
        If Assigned(FConnAckEvent) Then OnConnAck(Self, NewMsg.Data[0]);
    End;
    Ord(TMQTTMessageType.PINGREQ):
    Begin
      If Assigned(FPingReqEvent) Then OnPingReq(Self);
    End;
    Ord(TMQTTMessageType.PINGRESP):
    Begin
      If Assigned(FPingRespEvent) Then OnPingResp(Self);
    End;
    Ord(TMQTTMessageType.PUBLISH):
    Begin
      // Todo: This only applies for QoS level 0 messages.
      dataCaret := 0;
      strTopic := '';
      strPayload := '';
      Retain := (NewMsg.FixedHeader And 1) = 1;
      Dup := (NewMsg.FixedHeader And 8) = 8;
      QoS := (NewMsg.FixedHeader Shr 1) And 3;
      dataCaret := readSingleString(NewMsg.Data, dataCaret, strTopic);
      If QoS > 0 Then // QoS 1 or 2 has the MessageID field
      Begin
        MsgID := TMQTTRecvUtilities.MSBLSBToInt(Copy(NewMsg.Data, dataCaret + 2, 2));
        dataCaret += 2;
      End Else MsgID := -1;
      dataCaret := readStringWithoutPrefix(NewMsg.Data, dataCaret, strPayload);
      If Assigned(FPublishEvent) Then OnPublish(Self, strTopic, strPayload, MsgID, QoS, Retain, Dup);
    End;
    Ord(TMQTTMessageType.SUBACK):
    Begin
      If (Length(NewMsg.Data) > 2) Then
      Begin
        If Length(NewMsg.Data) >= 3 Then
          QoS := NewMsg.Data[2]
        Else QoS := $80; // Error-Code
        If Assigned(FSubAckEvent) Then
          OnSubAck(Self, TMQTTRecvUtilities.MSBLSBToInt(Copy(NewMsg.Data, 0, 2)), QoS);
      End;
    End;
    Ord(TMQTTMessageType.UNSUBACK):
    Begin
      If Length(NewMsg.Data) = 2 Then
        If Assigned(FUnSubAckEvent) Then
          OnUnSubAck(Self, TMQTTRecvUtilities.MSBLSBToInt(NewMsg.Data));
    End;
    Ord(TMQTTMessageType.PUBREC):
    Begin
      If Length(NewMsg.Data) = 2 Then
        If Assigned(FPubRecEvent) Then
          OnPubRec(Self, TMQTTRecvUtilities.MSBLSBToInt(NewMsg.Data));
    End;
    Ord(TMQTTMessageType.PUBREL):
    Begin
      If Length(NewMsg.Data) = 2 Then
        If Assigned(FPubRelEvent) Then
          OnPubRel(Self, TMQTTRecvUtilities.MSBLSBToInt(NewMsg.Data));
    End;
    Ord(TMQTTMessageType.PUBACK):
    Begin
      If Length(NewMsg.Data) = 2 Then
        If Assigned(FPubAckEvent) Then
          OnPubAck(Self, TMQTTRecvUtilities.MSBLSBToInt(NewMsg.Data));
    End;
    Ord(TMQTTMessageType.PUBCOMP):
    Begin
      If Length(NewMsg.Data) = 2 Then
        If Assigned(FPubCompEvent) Then
          OnPubComp(Self, TMQTTRecvUtilities.MSBLSBToInt(NewMsg.Data));
    End;
    Ord(TMQTTMessageType.AUTH):
    Begin
      // Not implemented in MQTT V3.x
    End;
  End;
End;

Function TMQTTReadThread.readMessageId(Const dataStream: TBytes; Const indexStartAt: Integer; Var messageId: Integer): Integer;
Begin
  messageId := TMQTTRecvUtilities.MSBLSBToInt(Copy(dataStream, indexStartAt, 2));
  Result := indexStartAt + 2;
End;

Function TMQTTReadThread.readStringWithoutPrefix(Const dataStream: TBytes; Const indexStartAt: Integer; Var stringRead: Utf8string): Integer;
Var
  strLength: Integer;
Begin
  strLength := Length(dataStream) - (indexStartAt + 1);
  If strLength > 0 Then
    SetString(stringRead, Pansichar(@dataStream[indexStartAt + 2]), (strLength - 1));
  Result := indexStartAt + strLength;
End;

Function TMQTTReadThread.readSingleString(Const dataStream: TBytes; Const indexStartAt: Integer; Var stringRead: Utf8string): Integer;
Var
  strLength: Integer;
Begin
  strLength := TMQTTRecvUtilities.MSBLSBToInt(Copy(dataStream, indexStartAt, 2));
  If strLength > 0 Then
    SetString(stringRead, Pansichar(@dataStream[indexStartAt + 2]), strLength);
  Result := indexStartAt + strLength;
End;

Function TMQTTReadThread.SocketWrite(Data: TBytes): Boolean;
Var iIn: Integer;
Begin
  Result := False;
  If Not Assigned(Data) Then
    Exit;
  iIn := (FTxMsgsIn + 1) Mod Length(FTxMsgs);
  If iIn <> FTxMsgsOut Then // Array not full
  Begin
    FTxMsgs[iIn] := Nil;
    SetLength(FTxMsgs[iIn], Length(Data));
    Move(Data[0], FTxMsgs[iIn][0], Length(Data)); // Copy the data, because the message will be free
    FTxMsgsIn := iIn; // Set the In position after copy the data
    Result := True;
  End;
End;

End.
