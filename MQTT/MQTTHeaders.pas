Unit MQTTHeaders;

{$MODE Delphi}

Interface

Uses
  SysUtils,
  Types,
  Classes;

Type

  TMQTTMessageType = (
    Reserved0,   //  0  Reserved
    CONNECT,     //  1  Client request to connect to Broker
    CONNACK,     //  2  Connect Acknowledgment
    PUBLISH,     //  3  Publish message
    PUBACK,      //  4  Publish Acknowledgment
    PUBREC,      //  5  Publish Received (assured delivery part 1)
    PUBREL,      //  6  Publish Release (assured delivery part 2)
    PUBCOMP,     //  7  Publish Complete (assured delivery part 3)
    SUBSCRIBE,   //  8  Client Subscribe request
    SUBACK,      //  9  Subscribe Acknowledgment
    UNSUBSCRIBE, // 10  Client Unsubscribe request
    UNSUBACK,    // 11  Unsubscribe Acknowledgment
    PINGREQ,     // 12  PING Request
    PINGRESP,    // 13  PING Response
    DISCONNECT,  // 14  Client is Disconnecting
    AUTH         // 15  Authentication exchange
    );

  TMQTTRecvState = (
    FixedHeaderByte,
    RemainingLength,
    Data,
    Error
    );

  {
  bit      7  6  5  4        3          2  1        0
  byte 1  Message Type  DUP flag  QoS level  RETAIN
  byte 2  Remaining Length
  }
  TMQTTFixedHeader = Packed Record
  private
    Function GetBits(Const aIndex: Integer): Integer;
    Procedure SetBits(Const aIndex: Integer; Const aValue: Integer);
  public
    Flags: Byte;
    Property Retain: Integer index $0001 read GetBits write SetBits;      // 1 bits at offset 0
    Property QoSLevel: Integer index $0102 read GetBits write SetBits;    // 2 bits at offset 1
    Property Duplicate: Integer index $0301 read GetBits write SetBits;   // 1 bits at offset 3
    Property MessageType: Integer index $0404 read GetBits write SetBits; // 4 bits at offset 4
  End;

  {
  Description      7  6  5  4  3  2  1  0
  Connect Flags
  byte 10          1  1  0  0  1  1  1  x
  Will RETAIN (0)
  Will QoS (01)
  Will flag (1)
  Clean Start (1)
  Username Flag (1)
  Password Flag (1)
  }
  TMQTTConnectFlags = Packed Record
  private
    Function GetBits(Const aIndex: Integer): Integer;
    Procedure SetBits(Const aIndex: Integer; Const aValue: Integer);
  public
    Flags: Byte;
    Property CleanStart: Integer index $0101 read GetBits write SetBits;    // 1 bit at offset 1
    Property WillFlag: Integer index $0201 read GetBits write SetBits;      // 1 bit at offset 2
    Property WillQoS: Integer index $0302 read GetBits write SetBits;       // 2 bits at offset 3
    Property WillRetain: Integer index $0501 read GetBits write SetBits;    // 1 bit at offset 5
    Property Password: Integer index $0601 read GetBits write SetBits;      // 1 bit at offset 6
    Property UserName: Integer index $0701 read GetBits write SetBits;      // 1 bit at offset 7
  End;

  TConnAckEvent = Procedure(Sender: TObject; ReturnCode: Integer) Of Object;
  TDisconnectEvent = Procedure(Sender: TObject) Of Object;
  TPublishEvent = Procedure(Sender: TObject; topic, payload: Utf8string; MessageID, QoS: Integer; Retain, Dup: Boolean) Of Object;
  TPingRespEvent = Procedure(Sender: TObject) Of Object;
  TPingReqEvent = Procedure(Sender: TObject) Of Object;
  TSubAckEvent = Procedure(Sender: TObject; MessageID, QoS: Integer) Of Object;
  TUnSubAckEvent = Procedure(Sender: TObject; MessageID: Integer) Of Object;
  TPubAckEvent = Procedure(Sender: TObject; MessageID: Integer) Of Object;
  TPubRelEvent = Procedure(Sender: TObject; MessageID: Integer) Of Object;
  TPubRecEvent = Procedure(Sender: TObject; MessageID: Integer) Of Object;
  TPubCompEvent = Procedure(Sender: TObject; MessageID: Integer) Of Object;

  TMQTTVariableHeader = Class
  private
    FBytes: TBytes;
  protected
    Procedure AddField(AByte: Byte); overload;
    Procedure AddField(ABytes: TBytes); overload;
    Procedure ClearField;
  public
    Constructor Create;
    Function ToBytes: TBytes; virtual;
  End;

  TMQTTConnectVarHeader = Class(TMQTTVariableHeader)
  Const
    PROTOCOL_ID = 'MQIsdp';
    PROTOCOL_VER = 3;


  private
    FConnectFlags: TMQTTConnectFlags;
    FKeepAlive: Integer;
    Function rebuildHeader: Boolean;
    Procedure setupDefaultValues;
    Function get_CleanStart: Integer;
    Function get_QoSLevel: Integer;
    Function get_Retain: Integer;
    Procedure set_CleanStart(Const Value: Integer);
    Procedure set_QoSLevel(Const Value: Integer);
    Procedure set_Retain(Const Value: Integer);
    Function get_WillFlag: Integer;
    Procedure set_WillFlag(Const Value: Integer);
    Function get_Username: Integer;
    Procedure set_Username(Const Value: Integer);
    Function get_Password: Integer;
    Procedure set_Password(Const Value: Integer);
  public
    Constructor Create(AKeepAlive: Integer); overload;
    Constructor Create; overload;
    Constructor Create(ACleanStart: Boolean); overload;
    Property KeepAlive: Integer read FKeepAlive write FKeepAlive;
    Property CleanStart: Integer read get_CleanStart write set_CleanStart;
    Property QoSLevel: Integer read get_QoSLevel write set_QoSLevel;
    Property Retain: Integer read get_Retain write set_Retain;
    Property Username: Integer read get_Username write set_Username;
    Property Password: Integer read get_Password write set_Password;
    Property WillFlag: Integer read get_WillFlag write set_WillFlag;
    Function ToBytes: TBytes; override;
  End;

  TMQTTPublishVarHeader = Class(TMQTTVariableHeader)
  private
    FTopic: Utf8string;
    FQoSLevel: Integer;
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Function get_QoSLevel: Integer;
    Procedure set_MessageID(Const Value: Integer);
    Procedure set_QoSLevel(Const Value: Integer);
    Function get_Topic: Utf8string;
    Procedure set_Topic(Const Value: Utf8string);
    Procedure rebuildHeader;
  public
    Constructor Create(QoSLevel: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Property QoSLevel: Integer read get_QoSLevel write set_QoSLevel;
    Property Topic: Utf8string read get_Topic write set_Topic;
    Function ToBytes: TBytes; override;
  End;

  TMQTTPubrelVarHeader = Class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Procedure set_MessageID(Const Value: Integer);
  public
    Constructor Create(MessageId: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Function ToBytes: TBytes; override;
  End;

  TMQTTPubackVarHeader = Class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Procedure set_MessageID(Const Value: Integer);
  public
    Constructor Create(MessageId: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Function ToBytes: TBytes; override;
  End;

  TMQTTPubrecVarHeader = Class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Procedure set_MessageID(Const Value: Integer);
  public
    Constructor Create(MessageId: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Function ToBytes: TBytes; override;
  End;

  TMQTTPubcompVarHeader = Class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Procedure set_MessageID(Const Value: Integer);
  public
    Constructor Create(MessageId: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Function ToBytes: TBytes; override;
  End;

  TMQTTSubscribeVarHeader = Class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Procedure set_MessageID(Const Value: Integer);
  public
    Constructor Create(MessageId: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Function ToBytes: TBytes; override;
  End;

  TMQTTUnsubscribeVarHeader = Class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    Function get_MessageID: Integer;
    Procedure set_MessageID(Const Value: Integer);
  public
    Constructor Create(MessageId: Integer); overload;
    Property MessageID: Integer read get_MessageID write set_MessageID;
    Function ToBytes: TBytes; override;
  End;

  TMQTTPayload = Class
  private
    FContents: TStringList;
    FContainsIntLiterals: Boolean;
    FPublishMessage: Boolean;
  public
    Constructor Create;
    Destructor Destroy; override;
    Function ToBytes: TBytes; overload;
    Function ToBytes(WithIntegerLiterals: Boolean): TBytes; overload;
    Property Contents: TStringList read FContents;
    Property ContainsIntLiterals: Boolean read FContainsIntLiterals write FContainsIntLiterals;
    Property PublishMessage: Boolean read FPublishMessage write FPublishMessage;
  End;

  TMQTTMessage = Class
  private
    FRemainingLength: Integer;
  public
    FixedHeader: TMQTTFixedHeader;
    VariableHeader: TMQTTVariableHeader;
    Payload: TMQTTPayload;
    Constructor Create;
    Destructor Destroy; override;
    Function ToBytes: TBytes;
    Property RemainingLength: Integer read FRemainingLength;
  End;

  TMQTTUtilities = Class
  public
    Class Function UTF8EncodeToBytes(AStrToEncode: Utf8string): TBytes;
    Class Function UTF8EncodeToBytesNoLength(AStrToEncode: Utf8string): TBytes;
    Class Function RLIntToBytes(ARlInt: Integer): TBytes;
    Class Function IntToMSBLSB(ANumber: Word): TBytes;
  End;

Implementation

Function GetDWordBits(Const Bits: Byte; Const aIndex: Integer): Integer;
Begin
  Result := (Bits Shr (aIndex Shr 8))       // offset
    And ((1 Shl Byte(aIndex)) - 1); // mask
End;

Procedure SetDWordBits(Var Bits: Byte; Const aIndex: Integer; Const aValue: Integer);
Var
  Offset: Byte;
  Mask: Integer;
Begin
  Mask := ((1 Shl Byte(aIndex)) - 1);
  Assert(aValue <= Mask);

  Offset := aIndex Shr 8;
  Bits := (Bits And (Not (Mask Shl Offset))) Or DWORD(aValue Shl Offset);
End;

Class Function TMQTTUtilities.IntToMSBLSB(ANumber: Word): TBytes;
Begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := ANumber Div 256;
  Result[1] := ANumber Mod 256;
End;

{ MSBLSBToInt is in the MQTTRecvThread unit }

Class Function TMQTTUtilities.UTF8EncodeToBytes(AStrToEncode: Utf8string): TBytes;
Var
  i: Integer;
Begin
  { This is a UTF-8 hack to give 2 Bytes of Length MSB-LSB followed by a Single-byte
  per character String. }
  Result := nil;
  SetLength(Result, Length(AStrToEncode) + 2);

  Result[0] := Length(AStrToEncode) Div 256;
  Result[1] := Length(AStrToEncode) Mod 256;

  For i := 0 To Length(AStrToEncode) - 1 Do
  Begin
    Result[i + 2] := Ord(AStrToEncode[i + 1]);
  End;
End;

Class Function TMQTTUtilities.UTF8EncodeToBytesNoLength(AStrToEncode: Utf8string): TBytes;
Var
  i: Integer;
Begin
  Result := nil;
  SetLength(Result, Length(AStrToEncode));
  For i := 0 To Length(AStrToEncode) - 1 Do
  Begin
    Result[i] := Ord(AStrToEncode[i + 1]);
  End;
End;

Procedure AppendToByteArray(ASourceBytes: TBytes; Var ATargetBytes: TBytes); overload;
Var
  iUpperBnd: Integer;
Begin
  If Length(ASourceBytes) > 0 Then
  Begin
    iUpperBnd := Length(ATargetBytes);
    SetLength(ATargetBytes, iUpperBnd + Length(ASourceBytes));
    Move(ASourceBytes[0], ATargetBytes[iUpperBnd], Length(ASourceBytes));
  End;
End;

Procedure AppendToByteArray(ASourceByte: Byte; Var ATargetBytes: TBytes); overload;
Var
  iUpperBnd: Integer;
Begin
  iUpperBnd := Length(ATargetBytes);
  SetLength(ATargetBytes, iUpperBnd + 1);
  ATargetBytes[iUpperBnd] := ASourceByte;
End;

Class Function TMQTTUtilities.RLIntToBytes(ARlInt: Integer): TBytes;
Var
  byteindex: Integer;
  digit: Integer;
Begin
  Result := nil;
  SetLength(Result, 1);
  byteindex := 0;
  While (ARlInt > 0) Do
  Begin
    digit := ARlInt Mod 128;
    ARlInt := ARlInt Div 128;
    If ARlInt > 0 Then
    Begin
      digit := digit Or $80;
    End;
    Result[byteindex] := digit;
    If ARlInt > 0 Then
    Begin
      Inc(byteindex);
      SetLength(Result, byteindex + 1);
    End;
  End;
End;

{ TMQTTFixedHeader }

Function TMQTTFixedHeader.GetBits(Const aIndex: Integer): Integer;
Begin
  Result := GetDWordBits(Flags, aIndex);
End;

Procedure TMQTTFixedHeader.SetBits(Const aIndex, aValue: Integer);
Begin
  SetDWordBits(Flags, aIndex, aValue);
End;

{ TMQTTMessage }

{ TMQTTVariableHeader }

Procedure TMQTTVariableHeader.AddField(AByte: Byte);
Var
  DestUpperBnd: Integer;
Begin
  DestUpperBnd := Length(FBytes);
  SetLength(FBytes, DestUpperBnd + SizeOf(AByte));
  Move(AByte, FBytes[DestUpperBnd], SizeOf(AByte));
End;

Procedure TMQTTVariableHeader.AddField(ABytes: TBytes);
Var
  DestUpperBnd: Integer;
Begin
  DestUpperBnd := Length(FBytes);
  SetLength(FBytes, DestUpperBnd + Length(ABytes));
  Move(ABytes[0], FBytes[DestUpperBnd], Length(ABytes));
End;

Procedure TMQTTVariableHeader.ClearField;
Begin
  FBytes := Nil;
  //SetLength(FBytes, 0);
End;

Constructor TMQTTVariableHeader.Create;
Begin
  Inherited Create;
  FBytes := Nil;
End;

Function TMQTTVariableHeader.ToBytes: TBytes;
Begin
  Result := FBytes;
End;

{ TMQTTConnectVarHeader }

Constructor TMQTTConnectVarHeader.Create(ACleanStart: Boolean);
Begin
  Inherited Create;
  setupDefaultValues;
  Self.FConnectFlags.CleanStart := Ord(ACleanStart);
End;

Function TMQTTConnectVarHeader.get_CleanStart: Integer;
Begin
  Result := Self.FConnectFlags.CleanStart;
End;

Function TMQTTConnectVarHeader.get_Password: Integer;
Begin
  Result := Self.FConnectFlags.Password;
End;

Function TMQTTConnectVarHeader.get_QoSLevel: Integer;
Begin
  Result := Self.FConnectFlags.WillQoS;
End;

Function TMQTTConnectVarHeader.get_Retain: Integer;
Begin
  Result := Self.FConnectFlags.WillRetain;
End;

Function TMQTTConnectVarHeader.get_Username: Integer;
Begin
  Result := Self.FConnectFlags.UserName;
End;

Function TMQTTConnectVarHeader.get_WillFlag: Integer;
Begin
  Result := Self.FConnectFlags.WillFlag;
End;

Constructor TMQTTConnectVarHeader.Create(AKeepAlive: Integer);
Begin
  Inherited Create;
  setupDefaultValues;
  Self.FKeepAlive := AKeepAlive;
End;

Constructor TMQTTConnectVarHeader.Create;
Begin
  Inherited Create;
  setupDefaultValues;
End;

Function TMQTTConnectVarHeader.rebuildHeader: Boolean;
Begin
  Try
    ClearField;
    AddField(TMQTTUtilities.UTF8EncodeToBytes(Self.PROTOCOL_ID));
    AddField(Byte(Self.PROTOCOL_VER));
    AddField(FConnectFlags.Flags);
    AddField(TMQTTUtilities.IntToMSBLSB(FKeepAlive));
  Except
    Result := False;
  End;
  Result := True;
End;

Procedure TMQTTConnectVarHeader.setupDefaultValues;
Begin
  Self.FConnectFlags.Flags := 0;
  Self.FConnectFlags.CleanStart := 1;
  Self.FConnectFlags.WillQoS := 1;
  Self.FConnectFlags.WillRetain := 0;
  Self.FConnectFlags.WillFlag := 1;
  Self.FConnectFlags.UserName := 0;
  Self.FConnectFlags.Password := 0;
  Self.FKeepAlive := 10;
End;

Procedure TMQTTConnectVarHeader.set_CleanStart(Const Value: Integer);
Begin
  Self.FConnectFlags.CleanStart := Value;
End;

Procedure TMQTTConnectVarHeader.set_Password(Const Value: Integer);
Begin
  Self.FConnectFlags.UserName := Value;
End;

Procedure TMQTTConnectVarHeader.set_QoSLevel(Const Value: Integer);
Begin
  Self.FConnectFlags.WillQoS := Value;
End;

Procedure TMQTTConnectVarHeader.set_Retain(Const Value: Integer);
Begin
  Self.FConnectFlags.WillRetain := Value;
End;

Procedure TMQTTConnectVarHeader.set_Username(Const Value: Integer);
Begin
  Self.FConnectFlags.Password := Value;
End;

Procedure TMQTTConnectVarHeader.set_WillFlag(Const Value: Integer);
Begin
  Self.FConnectFlags.WillFlag := Value;
End;

Function TMQTTConnectVarHeader.ToBytes: TBytes;
Begin
  Self.rebuildHeader;
  Result := FBytes;
End;

{ TMQTTConnectFlags }

Function TMQTTConnectFlags.GetBits(Const aIndex: Integer): Integer;
Begin
  Result := GetDWordBits(Flags, aIndex);
End;

Procedure TMQTTConnectFlags.SetBits(Const aIndex, aValue: Integer);
Begin
  SetDWordBits(Flags, aIndex, aValue);
End;

{ TMQTTPayload }

Constructor TMQTTPayload.Create;
Begin
  Inherited Create;
  FContents := TStringList.Create();
  FContainsIntLiterals := False;
  FPublishMessage := False;
End;

Destructor TMQTTPayload.Destroy;
Begin
  FreeAndNil(FContents);
  Inherited Destroy;
End;

Function TMQTTPayload.ToBytes(WithIntegerLiterals: Boolean): TBytes;
Var
  line: String;
  lineAsBytes: TBytes;
  lineAsInt: Integer;
Begin
  Result := nil;
  SetLength(Result, 0);
  For line In FContents Do
  Begin
    // This is really nasty and needs refactoring into subclasses
    If PublishMessage Then
    Begin
      lineAsBytes := TMQTTUtilities.UTF8EncodeToBytesNoLength(line);
      AppendToByteArray(lineAsBytes, Result);
    End Else Begin
      If (WithIntegerLiterals And TryStrToInt(line, lineAsInt)) Then
      Begin
        AppendToByteArray(Byte(lineAsInt And $FF), Result);
      End Else Begin
        lineAsBytes := TMQTTUtilities.UTF8EncodeToBytes(line);
        AppendToByteArray(lineAsBytes, Result);
      End;
    End;
  End;
End;

Function TMQTTPayload.ToBytes: TBytes;
Begin
  Result := ToBytes(FContainsIntLiterals);
End;

{ TMQTTMessage }

Constructor TMQTTMessage.Create;
Begin
  Inherited Create;
  FRemainingLength := 0;
  FixedHeader.Flags := 0;
  VariableHeader := nil;
  Payload := nil;
End;

Destructor TMQTTMessage.Destroy;
Begin
  If Assigned(VariableHeader) Then FreeAndNil(VariableHeader);
  If Assigned(Payload) Then FreeAndNil(Payload);
  Inherited Destroy;
End;

Function TMQTTMessage.ToBytes: TBytes;
Var
  iRemainingLength: Integer;
  bytesRemainingLength: TBytes;
Begin
  Result := nil;
  Try
    iRemainingLength := 0;
    If Assigned(VariableHeader) Then
      iRemainingLength := iRemainingLength + Length(VariableHeader.ToBytes);
    If Assigned(Payload) Then iRemainingLength := iRemainingLength + Length(Payload.ToBytes);

    FRemainingLength := iRemainingLength;
    bytesRemainingLength := TMQTTUtilities.RLIntToBytes(FRemainingLength);

    AppendToByteArray(FixedHeader.Flags, Result);
    AppendToByteArray(bytesRemainingLength, Result);
    If Assigned(VariableHeader) Then
      AppendToByteArray(VariableHeader.ToBytes, Result);
    If Assigned(Payload) Then AppendToByteArray(Payload.ToBytes, Result);
  Except
    on E: Exception Do
      Result := nil;
  End;
End;

{ TMQTTPublishVarHeader }

Constructor TMQTTPublishVarHeader.Create(QoSLevel: Integer);
Begin
  Inherited Create;
  FQosLevel := QoSLevel;
  FTopic := '';
  FMessageID := 0;
End;

Function TMQTTPublishVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Function TMQTTPublishVarHeader.get_QoSLevel: Integer;
Begin
  Result := FQoSLevel;
End;

Function TMQTTPublishVarHeader.get_Topic: Utf8string;
Begin
  Result := FTopic;
End;

Procedure TMQTTPublishVarHeader.rebuildHeader;
Begin
  ClearField;
  AddField(TMQTTUtilities.UTF8EncodeToBytes(FTopic));
  If (FQoSLevel > 0) Then
  Begin
    AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  End;
End;

Procedure TMQTTPublishVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Procedure TMQTTPublishVarHeader.set_QoSLevel(Const Value: Integer);
Begin
  FQoSLevel := Value;
End;

Procedure TMQTTPublishVarHeader.set_Topic(Const Value: Utf8string);
Begin
  FTopic := Value;
End;

Function TMQTTPublishVarHeader.ToBytes: TBytes;
Begin
  Self.rebuildHeader;
  Result := Self.FBytes;
End;

{ TMQTTPubrelVarHeader }

Constructor TMQTTPubrelVarHeader.Create(MessageId: Integer);
Begin
  Inherited Create;
  FMessageID := MessageId Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubrelVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Procedure TMQTTPubrelVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubrelVarHeader.ToBytes: TBytes;
Begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
End;

{ TMQTTPubackVarHeader }

Constructor TMQTTPubackVarHeader.Create(MessageId: Integer);
Begin
  Inherited Create;
  FMessageID := MessageId Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubackVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Procedure TMQTTPubackVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubackVarHeader.ToBytes: TBytes;
Begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
End;

{ TMQTTPubrecVarHeader }

Constructor TMQTTPubrecVarHeader.Create(MessageId: Integer);
Begin
  Inherited Create;
  FMessageID := MessageId Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubrecVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Procedure TMQTTPubrecVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubrecVarHeader.ToBytes: TBytes;
Begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
End;

{ TMQTTPubcompVarHeader }

Constructor TMQTTPubcompVarHeader.Create(MessageId: Integer);
Begin
  Inherited Create;
  FMessageID := MessageId Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubcompVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Procedure TMQTTPubcompVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTPubcompVarHeader.ToBytes: TBytes;
Begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
End;

{ TMQTTSubscribeVarHeader }

Constructor TMQTTSubscribeVarHeader.Create(MessageId: Integer);
Begin
  Inherited Create;
  FMessageID := MessageId Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTSubscribeVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Procedure TMQTTSubscribeVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTSubscribeVarHeader.ToBytes: TBytes;
Begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
End;

{ TMQTTUnsubscribeVarHeader }

Constructor TMQTTUnsubscribeVarHeader.Create(MessageId: Integer);
Begin
  Inherited Create;
  FMessageID := MessageId Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTUnsubscribeVarHeader.get_MessageID: Integer;
Begin
  Result := FMessageID;
End;

Procedure TMQTTUnsubscribeVarHeader.set_MessageID(Const Value: Integer);
Begin
  FMessageID := Value Mod 65536; // Message ID in correct 16 Bit range
End;

Function TMQTTUnsubscribeVarHeader.ToBytes: TBytes;
Begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
End;

End.
