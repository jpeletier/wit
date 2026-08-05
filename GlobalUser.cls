VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "GlobalUser"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Implements jGhostRef.IGhostRef

Public Event OnPrivateMessage(text As String, cancel As Boolean)
Public Event OnWhoisReply(cancel As Boolean)
Public Event OnIsOnReply(isOn As Boolean)
Public Event OnModeChange(modeFlag As String, byWho As GlobalUser)
Public Event OnQuit(message As String)
Public Event OnChannelPart(ch As channel, cancel As Boolean)
Public Event OnChannelLeave(ch As channel, kickedBy As GlobalUser, reason As String, cancel As Boolean)
Public Event OnDCCMessage(text As String)
Public Event OnDCCConnect()
Public Event OnDCCDisconnect()
Public Event OnDCCTimeout()


Public Event OnNickChange(oldNick As String)


Private mGRC As jGhostRef.GRCollection

Private mNickName As String
Private mHostName As String
Private mUserName As String
Private mAway As Boolean
Private mAwayMessage As String
Private mRealName As String
Private mServerName As String
Private mServerDescription As String
Private mSecondsIdle As Long
Private mChannels As ChannelsPersistCol
Private mParent As CIRCClient
Private mProperties As CFairCollection
Private WithEvents mDCC As DccChat
Attribute mDCC.VB_VarHelpID = -1

Private flagModeParsed As Boolean
Private flagDoneWhois As Boolean

Private mIsOn As Boolean


Dim modes(26) As Byte


Private Function readMode(modeFlag As String) As Boolean
  readMode = modes(Asc(LCase(modeFlag)) - 97)
End Function

Public Property Get mode(modeFlag As String) As Boolean
  'On Error Resume Next
  
'  If Not flagModeParsed Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    mParent.getMode Me.nickName
'    msgLoop.WaitFor 10000, True, "NICKMODE_" & Me.nickName
'  End If
    
  
   
  mode = readMode(modeFlag)
  
End Property

Friend Property Let mode(modeFlag As String, Value As Boolean)
  On Error Resume Next
  modes(Asc(LCase(modeFlag)) - 97) = Value
  
End Property


Public Sub setMode(sign As Boolean, modeFlags As String, Optional parm3 As String, Optional parm4 As String, Optional parm5 As String, Optional parm6 As String, Optional parm7 As String)

mParent.setMode mNickName, sign, modeFlags, , , parm3, parm4, parm5, parm6, parm7

End Sub

Public Sub parseModeString(modeString As String, gU As GlobalUser)

Dim sign As Boolean

Dim c As String * 1
Dim lencmd As Long
lencmd = Len(modeString)

Dim n As Long
For n = 1 To lencmd
  c = Mid(modeString, n, 1)
  
  Select Case c
    Case "a" To "z"
      If readMode(c) <> sign Then
        mode(c) = sign
        RaiseEvent OnModeChange(c, gU)
      End If
    Case "+", "-"
      sign = c = "+"
  End Select

Next

flagModeParsed = True
'postMsg "NICKMODE_" & Me.nickName

End Sub

Public Property Let modeInvisible(v As Boolean)
  mode("i") = v
  setMode v, "i"
End Property

Public Property Get modeInvisible() As Boolean
  modeInvisible = mode("i")
End Property

Public Property Let modeReceiveServerNotices(v As Boolean)
  mode("s") = v
  setMode v, "s"
End Property

Public Property Get modeReceiveServerNotices() As Boolean
  modeReceiveServerNotices = mode("s")
End Property

Public Property Let modeReceiveWallOps(v As Boolean)
  mode("w") = v
  setMode v, "w"
End Property

Public Property Get modeReceiveWallOps() As Boolean
  modeReceiveWallOps = mode("w")
End Property

Public Property Let modeIRCOperator(v As Boolean)
  mode("o") = v
  setMode v, "o"
End Property

Public Property Get modeIRCOperator() As Boolean
  modeIRCOperator = mode("o")
End Property

Friend Sub setParent(p As CIRCClient)
  Set mParent = p
End Sub

Public Property Get parent() As CIRCClient
  Set parent = mParent
End Property

Public Property Get away() As Boolean
  away = mAway
End Property

Friend Property Let away(nv As Boolean)
  mAway = nv
End Property

Public Property Get awayMessage() As String
  awayMessage = mAwayMessage
End Property

Friend Property Let awayMessage(nv As String)
  mAwayMessage = nv
End Property

Public Property Get realName() As String
  realName = mRealName
End Property

Friend Property Let realName(nv As String)
  mRealName = nv
End Property

Public Property Get serverName() As String
  serverName = mServerName
End Property

Friend Property Let serverName(nv As String)
  mServerName = nv
End Property

Public Property Get serverDescription() As String
  serverDescription = mServerDescription
End Property

Friend Property Let serverDescription(nv As String)
  mServerDescription = nv
End Property

Public Property Get secondsIdle() As Long
  secondsIdle = mSecondsIdle
End Property

Friend Property Let secondsIdle(nv As Long)
  mSecondsIdle = nv
End Property

Public Property Get channels() As ChannelsPersistCol
  If mChannels Is Nothing Then Set mChannels = New ChannelsPersistCol
  Set channels = mChannels
End Property

Friend Sub notifyOnWhoisReply(cancel As Boolean)
  RaiseEvent OnWhoisReply(cancel)
  'postMsg "WHOIS_" & mNickName
  'flagDoneWhois = True
End Sub

Friend Sub notifyOnPrivateMessage(text As String, cancel As Boolean)
  RaiseEvent OnPrivateMessage(text, cancel)
End Sub


Friend Property Let hostName(nv As String)
  If nv = "" Or mHostName <> "" Then Exit Property

  mHostName = nv
  'postMsg "USERHOST_" & mNickName
End Property

Public Property Get hostName() As String
  
  If mHostName = "" Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    mParent.getUserHost Me
'    msgLoop.WaitFor 10000, True, "USERHOST_" & mNickName
  End If
  
  
  
  hostName = mHostName
End Property

Friend Property Let userName(nv As String)
  If nv = "" Or mUserName <> "" Then Exit Property
  mUserName = nv
End Property

Public Property Get userName() As String
  If mUserName = "" Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    mParent.getUserHost Me
'    msgLoop.WaitFor 10000, True, "USERHOST_" & mNickName
  End If
  
  userName = mUserName
End Property


Private Sub Class_Initialize()
  mHostName = ""
End Sub

Public Property Get nickName() As String
Attribute nickName.VB_UserMemId = 0
  nickName = mNickName
End Property



Private Sub Class_Terminate()
  If Not mGRC Is Nothing Then
    mGRC.Remove mNickName
  End If
End Sub

Private Sub IGhostRef_YourKey(GRC As jGhostRef.GRCollection, Key As String)
  mNickName = Key
  Set mGRC = GRC
End Sub

Public Sub processChannelList(list As String)

Dim chn() As String

chn = Split(Trim(list), " ")

Dim n As Long

For n = 0 To UBound(chn)
  If Mid(chn(n), 1, 1) = "@" Then
    chn(n) = Mid(chn(n), 2)
  End If
  
  channels.Add mParent.getChannel(chn(n))
  
Next

End Sub

Friend Sub notifyOnNickChange(oldNick As String)
  RaiseEvent OnNickChange(oldNick)
End Sub

Friend Sub notifyOnQuit(message As String)
  RaiseEvent OnQuit(message)
End Sub

Friend Sub notifyOnChannelPart(ch As channel, cancel As Boolean)
  RaiseEvent OnChannelPart(ch, cancel)
End Sub

Friend Sub notifyOnChannelLeave(ch As channel, kickedBy As GlobalUser, reason As String, cancel As Boolean)
  RaiseEvent OnChannelLeave(ch, kickedBy, reason, cancel)
End Sub

Public Sub notice(text As String)
  mParent.noticeUser Me, text
End Sub

Public Sub privateMessage(text As String)
  mParent.privateMessage Me, text
End Sub

Public Sub DCCMessage(text As String, Optional OnNoDCCPrivmsg = False)
  
  If DCCConnected Then
    dcc.say text
  ElseIf OnNoDCCPrivmsg Then
    privateMessage text
  End If
  
  
End Sub



Public Property Get Properties() As CFairCollection
  If mProperties Is Nothing Then
    Set mProperties = New CFairCollection
  End If
  
  Set Properties = mProperties
End Property

Public Sub whois()

  mParent.whois Me.nickName
'  If Wait > 0 And Not flagDoneWhois Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    msgLoop.WaitFor Wait, True, "WHOIS_" & mNickName
'  End If

End Sub

Property Get dcc() As DccChat

If mDCC Is Nothing Then
  Set mDCC = New DccChat
  Set mDCC.gUsr = Me
End If

  Set dcc = mDCC
End Property
Property Set dcc(x As DccChat)
  If Not x.gUsr Is Me Then Exit Property
  
  Set dcc = x
  
End Property



Public Sub isOn()

End Sub


Public Property Get DCCConnected() As Boolean
  If mDCC Is Nothing Then
    DCCConnected = False
  Else
    DCCConnected = mDCC.Connected
  End If
  
End Property

Private Sub mDCC_OnConnect()
  RaiseEvent OnDCCConnect
End Sub

Private Sub mDCC_OnDisconnect()
  RaiseEvent OnDCCDisconnect
  Set mDCC = Nothing
End Sub

Private Sub mDCC_OnMessage(text As String)
  RaiseEvent OnDCCMessage(text)
End Sub

Private Sub mDCC_OnTimeout()
  RaiseEvent OnDCCTimeout
  Set mDCC = Nothing
End Sub
