VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CIRCClient"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Member0" ,"Canales"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Private WithEvents Sock As Socket
Attribute Sock.VB_VarHelpID = -1
Private mvarChannels As channels
Private mvarNick As String
Private mKnownUsers As GlobalUsers
Public self As GlobalUser
Private mUserName As String
Private mRealName As String
Private mPassword As String
Private mServerName As String
Private mRemotePort As Integer
Private mProperties As CFairCollection

Private mObjectDestroyed As Boolean

Private mOutQueue As Collection
Private mOutputList As Collection

Private mMaxOutputDataRate As Long
Private WithEvents OutTmr As CTimer
Attribute OutTmr.VB_VarHelpID = -1
Private cmBytesSent As Long
Private tmrLastWrite As Long

Public Event LíneaRecibida(ByVal Línea As String)
Public Event OnJoin(nChannel As channel, gU As GlobalUser)
Public Event OnPart(nChannel As channel, gU As GlobalUser)
Public Event OnLeave(nChannel As channel, gU As GlobalUser, kickedBy As GlobalUser, reason As String)
Public Event OnInvite(cChannel As channel, cUser As GlobalUser)
Public Event OnUserQuit(who As GlobalUser, quitMessage As String)

Public Event OnServerPing(serverName As String, autoReply As Boolean)
Public Event OnUserPing(usr As GlobalUser, timeStamp As Long, autoReply As Boolean)
Public Event OnUserPingReply(usr As GlobalUser, secs As Long)
Public Event OnPrivateMessageUser(usr As GlobalUser, text As String)
Public Event OnPrivateMessageChannel(ch As channel, text As String)
Public Event OnNoticeChannel(usr As GlobalUser, text As String)
Public Event OnNoticeUser(usr As GlobalUser, text As String)
Public Event OnDccChatRequest(DccChatObject As DccChat)
Public Event OnTopicChange(ch As channel, newTopic As String)
Public Event OnWhoisReady(gU As GlobalUser)
Public Event OnNickChange(gU As GlobalUser, ByVal newNick As String)
Public Event OnEndOfMOTD()
Public Event OnDisconnect()
Public Event OnConnect()
Public Event OnKill(byWho As GlobalUser, why As String)
Public Event OnLineOut(line As String, cancel As Boolean)


Private Declare Function GetTickCount Lib "kernel32" () As Long

Public Sub destroy()

On Error Resume Next
Set Sock = Nothing

mvarChannels.clear
Set mvarChannels = Nothing

mKnownUsers.clear
Set mKnownUsers = Nothing

Set self = Nothing

Set mProperties = Nothing
Set OutTmr = Nothing
Set mOutQueue = Nothing
Set mOutputList = Nothing
Sock_Read -1, False 'Borrar el buffer

mObjectDestroyed = True

End Sub


Private Sub OutTmr_ThatTime()
If mOutputList Is Nothing Then Exit Sub
If mObjectDestroyed Then Exit Sub

Static cq As Long

If mOutputList.count = 0 Then Exit Sub


cq = cq + 1

If cq > mOutputList.count Then cq = 1


Dim cl As Collection

Set cl = mOutputList(cq)


Dim ln As Long
Dim sLine As String
Dim cancel As Boolean
  
  
If cl.count > 0 Then
  
  sLine = cl(1)
  cl.Remove 1
    
  ln = Len(sLine)
    
  RaiseEvent OnLineOut(sLine, cancel)
  
  If Not cancel Then
    Sock.Write sLine, ln
  End If
  
  If mOutputList Is Nothing Then Exit Sub
  If mObjectDestroyed Then Exit Sub
  
  If cl.count = 0 Then
    mOutputList.Remove cq
  End If

End If
  
  
'*********************************
  
Exit Sub
  
  
  cmBytesSent = cmBytesSent - mMaxOutputDataRate * OutTmr.Interval / 1000
  If cmBytesSent < 0 Then cmBytesSent = 0
  
  
  Do While (cmBytesSent < mMaxOutputDataRate) And (mOutQueue.count > 0)
    
    sLine = mOutQueue(1)
    mOutQueue.Remove 1
    
    ln = Len(sLine)
    
    
    RaiseEvent OnLineOut(sLine, cancel)
  
    If Not cancel Then
      Sock.Write sLine, ln
    
      cmBytesSent = cmBytesSent + ln
    
      tmrLastWrite = GetTickCount
    End If
    'trace  "ThatTime, cmBytesSent=" & cmBytesSent
  
  Loop
  
  If cmBytesSent < mMaxOutputDataRate / 2 And mOutQueue.count = 0 Then
    OutTmr.Interval = 0
  End If
  
End Sub


Public Sub rawOutput(Línea As String, Optional skipQueue As Boolean = False, Optional source As String)

If mObjectDestroyed Then Exit Sub
  
  
If OutTmr.Interval = 0 Then
  OutTmr.Interval = 2000
End If
  
  
If skipQueue Then
  Sock.Write Línea, Len(Línea)
  Exit Sub
End If
  

If source = "" Then source = "##Common##"
Dim cl As Collection
  
Set cl = ExistsInCollection(mOutputList, source)

If cl Is Nothing Then
  Set cl = New Collection
  mOutputList.Add cl, source
End If


cl.Add Línea



  
  
  
  
  
Exit Sub
  
  If OutTmr.Interval = 0 Then
  
    Dim tmr As Long
    Dim timeDif As Long
    
    
    tmr = GetTickCount
    If tmr < tmrLastWrite Then
      timeDif = 4294967296# - tmrLastWrite + tmr
    Else
      timeDif = tmr - tmrLastWrite
    End If
    
    cmBytesSent = cmBytesSent - timeDif / 1000 * mMaxOutputDataRate
    'trace  "subs = " & timeDif / 1000 * mMaxOutputDataRate
    If cmBytesSent < 0 Then cmBytesSent = 0
  End If
  
  If (cmBytesSent > mMaxOutputDataRate Or OutTmr.Interval <> 0) And Not skipQueue Then
    mOutQueue.Add Línea
    If OutTmr.Interval = 0 Then
      If mMaxOutputDataRate = 0 Then
        tmr = 0
      Else
        tmr = (cmBytesSent - mMaxOutputDataRate + 10) / mMaxOutputDataRate * 1000
      End If
      
      If tmr > 1000 Then tmr = 1000
      OutTmr.Interval = tmr
      'trace  "Timer on. Interval=" & tmr
      
    End If
  Else
    Dim ln As Long
    ln = Len(Línea)
    Sock.Write Línea, ln
    cmBytesSent = cmBytesSent + ln
    tmrLastWrite = GetTickCount
  End If
  
    'trace  "RawOutput, cmBytesSent=" & cmBytesSent
  
  
End Sub





Public Property Get knownUsers() As GlobalUsers
  Set knownUsers = mKnownUsers
End Property

Public Function getUser(nickName As String, Optional hostName As String = "", Optional userName As String = "") As GlobalUser
  Dim gU As GlobalUser
  
  Set gU = mKnownUsers.Item(nickName)
  If gU Is Nothing Then
    Set gU = mKnownUsers.Add(nickName)
    gU.setParent Me
  End If
  
  gU.hostName = hostName
  gU.userName = userName
  
  Set getUser = gU
  
End Function

Public Function getChannel(name As String) As channel
    Set getChannel = channels.Add(name)
End Function

Public Property Get channels() As channels
    Set channels = mvarChannels
End Property

Private Sub Class_Terminate()
'    Set mvarChannels = Nothing
'    If Sock.Connected Then
'      Sock.Blocking = True
'      rawOutput "QUIT" & vbLf
'      Sock.Disconnect
'    End If
'    Set Sock = Nothing
destroy

End Sub

Private Sub Class_Initialize()
  Set Sock = New Socket
  Sock.AddressFamily = AF_INET
  Sock.Protocol = IPPROTO_IP
  Sock.Binary = True
  Sock.BufferSize = 1024
  Sock.Blocking = False
  Sock.KeepAlive = True
  
  mUserName = "jirc"
  mRealName = "jIRC ActiveX DLL by J. Peletier, www.peletier.com"
  
  mMaxOutputDataRate = 1024
  
  Set mvarChannels = New channels
  Set mvarChannels.parent = Me
  Set mKnownUsers = New GlobalUsers
  Set mOutQueue = New Collection
  Set mOutputList = New Collection
  Set OutTmr = New CTimer
  
  Set mProperties = New CFairCollection
End Sub

Public Sub Connect(Optional RemoteHost As String, Optional Port As Integer, Optional bindAddress As String)
  
  If RemoteHost <> "" Then
    mServerName = RemoteHost
  End If
  
  If Port <> 0 Then
    mRemotePort = Port
  End If
  
  If bindAddress <> "" Then
    Sock.bindAddress = bindAddress
  End If
  
  
  Sock.hostName = mServerName
  Sock.remotePort = mRemotePort
  
  If Not Sock.Connected Then
    Sock.Connect
  Else
    TRACE "CIRCClient::Connect -> Attempt to connect an already connected socket."
  End If
End Sub

Public Property Get nick() As String
  nick = mvarNick
End Property

Public Property Let nick(ByVal vNewValue As String)
  If Sock.Connected Then
    rawOutput "NICK " & vNewValue & vbLf
  Else
    mvarNick = vNewValue
  End If

End Property


Private Sub Sock_Connect()
  
'  If mPassword <> "" Then
'    rawOutput "PASS " & mPassword & vbLf
'  End If
  
  Dim pwdText As String
  If mPassword <> "" Then
    pwdText = ":" & mPassword
  End If
  
  rawOutput "NICK " & mvarNick & pwdText & " " & mvarNick & "2" & vbLf
  rawOutput "USER " & mUserName & " openaccess openaccess :" & mRealName & vbLf
  
  'RawOutput "USER CLIENTE wendy hammond :El cliente de pruebas" & vbLf
  'RawOutput "SERVER jander 1 :The j server" & vbLf
  
  Set self = getUser(mvarNick, "")
  
  RaiseEvent OnConnect

End Sub


Public Property Get password() As String
  password = mPassword
End Property

Public Property Let password(newP As String)
  mPassword = newP
End Property


Public Sub GetIRCOperatorStatus(userName As String, password As String)
  rawOutput "OPER " & userName & " " & password & vbLf
End Sub

Public Sub quit(message As String)
  rawOutput "QUIT :" & message & vbLf
End Sub



Private Sub ProcesarLínea(Línea As String)
':jServerName 001 Perico :Welcome to the Internet Relay Network Perico
':jServerName 002 Perico :Your host is jServerName, running version 4.17-beta NOT-REGISTERED
':jServerName 003 Perico :This server was created on Jan 13 1997 12:58:26
':jServerName 004 Perico jServerName 4.17-beta oiwsn biklmnopstv
':jServerName 251 Perico :There are 1 users and 1 invisible on 1 servers
':jServerName 252 Perico 0 :operator(s) online
':jServerName 253 Perico 0 :unknown connection(s)
':jServerName 254 Perico 1 :Channels formed
':jServerName 255 Perico :I have 2 clients and 0 servers
':jServerName 250 Perico :Total connections 2
':jServerName 375 Perico :- jServerName Message of the day -
':jServerName 376 Perico :End of /MOTD command
':Perico!CLIENTE@127.0.0.1 JOIN :#peletier
':jServerName 353 Perico = #peletier :Perico @Fujur
':jServerName 366 Perico #peletier :End of /NAMES list
If Línea = "" Then Exit Sub

Dim cmd() As String
Dim CtrlSt As String
Dim ContSt As String
Dim DPPos As Long
Dim apos As Long

apos = 2
'Do Until DPPos > 7 Or apos = 10000
  DPPos = InStr(apos, Línea, ":")
'  apos = apos + 1
'Loop

If DPPos = 0 Then
  DPPos = Len(Línea) + 2
End If

If DPPos < 3 Then Exit Sub

CtrlSt = Mid$(Línea, 2, DPPos - 3)

cmd() = Split(CtrlSt, " ")
ContSt = Mid$(Línea, DPPos + 1)

If UBound(cmd) > 0 Then
  If Val(cmd(1)) <> 0 Then
    ProcesarMensajeServidor cmd(), ContSt
  Else
    ProcesarMensajeEstándar cmd(), ContSt
  End If
  
  Else
  If Left(Línea, 4) = "PING" Then
      Dim ar As Boolean
      ar = True
      RaiseEvent OnServerPing(ContSt, ar)
      If ar Then
        pongServer ContSt
      End If
  End If
End If
End Sub

Private Sub ProcesarMensajeServidor(cmd() As String, ContSt As String)

Dim ch As channel
Dim gU As GlobalUser
Dim cancel As Boolean
Dim maxp As Integer
maxp = UBound(cmd)

Select Case cmd(1)

  Case IRC_RPL_NAMREPLY 'NAMES
    If maxp < 4 Then Exit Sub
    Set ch = mvarChannels(cmd(4))
    If Not ch Is Nothing Then
      ch.ProcessUserList ContSt
    End If

  Case IRC_RPL_TOPIC 'TOPIC
    If maxp < 3 Then Exit Sub
    Set ch = mvarChannels(cmd(3))
    If Not ch Is Nothing Then
      ch.SetTopic ContSt, cancel
      If Not cancel Then RaiseEvent OnTopicChange(ch, ContSt)
    End If
  
  Case IRC_RPL_WHOISUSER
   If maxp < 5 Then Exit Sub
   Set gU = getUser(cmd(3))
   gU.hostName = cmd(4) & "@" & cmd(5)
   gU.realName = ContSt
    
  Case IRC_RPL_WHOISSERVER
    If maxp < 4 Then Exit Sub
    Set gU = getUser(cmd(3))
    gU.serverName = cmd(4)
    gU.serverDescription = ContSt
  
  Case IRC_RPL_AWAY
   If maxp < 3 Then Exit Sub
   Set gU = getUser(cmd(3))
    gU.away = True
    gU.awayMessage = ContSt

  Case IRC_RPL_WHOISIDLE
   If maxp < 4 Then Exit Sub
   Set gU = getUser(cmd(3))
   gU.secondsIdle = Val(cmd(4))
   
  Case IRC_RPL_WHOISCHANNELS
    If maxp < 3 Then Exit Sub
    Set gU = getUser(cmd(3))
    gU.processChannelList ContSt
  
  Case IRC_RPL_ENDOFWHOIS
    If maxp < 3 Then Exit Sub
    Set gU = getUser(cmd(3))
    gU.notifyOnWhoisReply cancel
    If Not cancel Then RaiseEvent OnWhoisReady(gU)
  Case IRC_RPL_CHANNELMODEIS
    If maxp < 3 Then Exit Sub
    Set ch = mvarChannels(cmd(3))
    If Not ch Is Nothing Then
      ch.parseModeString cmd, Nothing, 4
    End If
    
  Case IRC_RPL_CHANNELDATECREATED
    If maxp < 4 Then Exit Sub
    Set ch = mvarChannels(cmd(3))
    If Not ch Is Nothing Then
      ch.dateCreated = time.timestampToLocalTime(Val(cmd(4)))
    End If
    
  Case IRC_RPL_USERHOST
  
    Dim parm() As String
    parm = Split(ContSt, "=", 2)
    If UBound(parm) >= 1 Then
      Set gU = getUser(parm(0))
      parm = Split(parm(1), "@")
      gU.userName = Replace(Replace(parm(0), "-", ""), "+", "")
      gU.hostName = parm(1)
    Else
      TRACE "IRC_RPL_USERHOSY: " & ContSt & ")"
    End If
    
    
  Case IRC_RPL_ENDOFMOTD, IRC_ERR_NOMOTD
    RaiseEvent OnEndOfMOTD
    

End Select

End Sub

Private Sub ProcesarMensajeEstándar(cmd() As String, ContSt As String)

Dim nickName As String
Dim hostName As String
Dim userName As String
Dim nCh As channel
Dim gU As GlobalUser
Dim targetGU As GlobalUser
Dim cancel As Boolean

CnstIRC.splitUserLabel cmd(0), nickName, userName, hostName
Set gU = getUser(nickName, hostName, userName)


Select Case UCase(cmd(1))
  Case "JOIN"
    ':Perico!CLIENTE@127.0.0.1 JOIN :#peletier
    'If Nickname = self.Nickname Then
    Set nCh = getChannel(ContSt)

    nCh.NotifyNewUser gU, cancel
    If Not cancel Then RaiseEvent OnJoin(nCh, gU)
    
  Case "QUIT"
    ':juglar24!yo@83-MADR-X48.libre.retevision.es QUIT :Leaving
    Dim i As Long
    For i = 1 To mvarChannels.count
      mvarChannels(i).notifyOnQuit gU, ContSt
    Next
    
    gU.notifyOnQuit ContSt
    
    mKnownUsers.Remove gU.nickName
    
    RaiseEvent OnUserQuit(gU, ContSt)

      
  Case "PART"
    If UBound(cmd) < 2 Then
      Set nCh = channels(ContSt)
    Else
      Set nCh = channels(cmd(2))
    End If
    If Not nCh Is Nothing Then
      nCh.NotifyOnPart gU, cancel
      If Not cancel Then
        RaiseEvent OnPart(nCh, gU)
        RaiseEvent OnLeave(nCh, gU, Nothing, "")
      End If
    End If
  
  Case "KICK"
    Set nCh = channels(cmd(2))
    If Not nCh Is Nothing Then
      Dim kGU As GlobalUser
      'nCh.NotifyOnKick  gU, ContSt, cancel
      Set kGU = getUser(cmd(3))
      nCh.NotifyOnKick kGU, gU, ContSt, cancel
      If Not cancel Then
        RaiseEvent OnLeave(nCh, kGU, gU, ContSt)
      End If
    End If
  
  
  Case "PRIVMSG"
    ':Fujur!p@**** PRIVMSG #peletier :Qué Hay?
    Set nCh = mvarChannels(cmd(2))
    If Not nCh Is Nothing Then
      nCh.NotifyOnSpeak gU, ContSt, cancel
      If Not cancel Then RaiseEvent OnPrivateMessageChannel(nCh, ContSt)
    Else
      If Left(cmd(2), 1) <> "#" Then
        processPrivMsg gU, ContSt
      End If
    End If
    
  Case "NOTICE"
    Set nCh = mvarChannels(cmd(2))
    If Not nCh Is Nothing Then
      nCh.notifyOnNotice gU, ContSt, cancel
      If Not cancel Then RaiseEvent OnNoticeChannel(gU, ContSt)
    Else
      If Left(cmd(2), 1) <> "#" Then
        processNotice gU, ContSt
      End If
    End If
    
  Case "TOPIC"
    If Not channels(cmd(2)) Is Nothing Then
      Set nCh = channels(cmd(2))
      nCh.SetTopic ContSt, cancel
      If Not cancel Then RaiseEvent OnTopicChange(nCh, ContSt)
    End If
  
  Case "INVITE"
    Set nCh = getChannel(ContSt)
    RaiseEvent OnInvite(nCh, gU)
  
  Case "NICK"
    Dim oldNick As String
    oldNick = gU.nickName
    RaiseEvent OnNickChange(gU, ContSt)
    mKnownUsers.Remove gU.nickName
    mKnownUsers.Add ContSt, gU 'El nick se cambia al recibir el objeto global user el evento YourKey
    gU.notifyOnNickChange oldNick
    
    If gU Is self Then
      mvarNick = ContSt
    End If
  
  Case "MODE"
    
    If Left(cmd(2), 1) = "#" Then
      Set nCh = mvarChannels(cmd(2))
      If Not nCh Is Nothing Then
         nCh.parseModeString cmd(), gU, 3
      End If
    Else
      Set targetGU = knownUsers(cmd(2))
      If Not targetGU Is Nothing Then
        targetGU.parseModeString ContSt, gU
      End If
    
    End If
      
  Case "KILL"
    RaiseEvent OnKill(gU, ContSt)
    
    
End Select


End Sub

Private Sub processPrivMsg(gU As GlobalUser, st As String)

Dim cancel As Boolean
If Asc(Left(st, 1)) = 1 Then
  Dim cmd() As String
  cmd = Split(Mid(st, 2, Len(st) - 2), " ", 5)
  Select Case cmd(0)
    Case "PING" '
      Dim autoReply As Boolean
      Dim timeStamp As Long
      autoReply = True: Exit Sub
      timeStamp = Val(cmd(1))
      RaiseEvent OnUserPing(gU, timeStamp, autoReply)
      If autoReply Then
        pongUser gU, timeStamp
      End If
      
    Case "DCC"
      If UBound(cmd) < 1 Then Exit Sub
      Select Case cmd(1)
        Case "CHAT"
          If UBound(cmd) < 4 Then Exit Sub
          Dim dcc As DccChat
          Set dcc = New DccChat
          Set dcc.gUsr = gU
          dcc.remoteAddress = cmd(3)
          dcc.remotePort = Val(cmd(4))
          RaiseEvent OnDccChatRequest(dcc)
      End Select
      
  End Select
Else
  
  gU.notifyOnPrivateMessage st, cancel
  If Not cancel Then RaiseEvent OnPrivateMessageUser(gU, st)
End If
End Sub

Private Sub processNotice(gU As GlobalUser, st As String)

If Asc(Left(st, 1)) = 1 Then
  Dim cmd() As String
  cmd = Split(Mid(st, 2, Len(st) - 2), " ", 4)
  Select Case cmd(0)
    Case "PING"
      Dim t As Double
      Dim secs As Long
      t = Val(getTimeStamp)
      secs = t - Val(cmd(1))
      RaiseEvent OnUserPingReply(gU, secs)
    
      
      
  
  End Select
Else
  Dim cancel As Boolean
  gU.notifyOnPrivateMessage st, cancel
  If Not cancel Then RaiseEvent OnNoticeUser(gU, st)
End If
End Sub




'Private Sub SepararNombreUser(Cadena As String, nickname As String, hostName As String)
'On Error Resume Next
'Dim sts() As String
'Cadena = Cadena & "!"
'sts = Split(Cadena, "!")
'nickname = sts(0)
'hostName = sts(1)

'End Sub

Private Sub Sock_Disconnect()
  Sock.Disconnect
  'Set mvarChannels = New channels
  RaiseEvent OnDisconnect
End Sub

Private Sub Sock_LastError(ErrorCode As Integer, ErrorString As String, Response As Integer)

If Sock.Connected And ErrorCode = WSAECONNRESET Then
  Sock.Action = SOCKET_CLOSE
  Response = CONTROL_ERRIGNORE
  RaiseEvent OnDisconnect
End If
End Sub

Private Sub Sock_Read(DataLength As Integer, IsUrgent As Integer)
'Variable temporal:
Dim datos As String

'Variable para albergar las cadenas que llegan
Static InBuffer As String

If DataLength = -1 Then InBuffer = ""

Sock.Read datos, DataLength
'Protocolo de texto simple. Llegan ráfagas de cadenas.
'Sabemos que un mensaje ha llegado del todo si existe
'un Avance de línea (VbLf)

'Añadir lo que acaba de llegar a nuestro buffer:
InBuffer = InBuffer & datos

'Buscar VbLf:
Dim pos As Long
Do
  pos = InStr(1, InBuffer, vbLf)
  If pos > 0 Then
    'Si había un VbLf, es que por lo menos tenemos un mensaje
    'completo
    datos = Replace(Left$(InBuffer, pos - 1), vbCr, "") 'Coge el mensaje y lo mete en datos
    InBuffer = Mid$(InBuffer, pos + 1) 'Recorta el buffer y quita ese trozo.
    
    RaiseEvent LíneaRecibida(datos)
    ProcesarLínea datos
  
  End If
Loop Until pos = 0 'Repetir hasta que ya no queden más mensajes en el buffer.

End Sub

Public Sub changeTopic(newTopic As String, channelName As String)
  rawOutput "TOPIC " & channelName & " " & newTopic & vbLf
End Sub

Public Sub leaveChannel(cName As String, Optional message As String = "")
  
  Dim st As String
  
  st = "PART " & cName
  
  If message <> "" Then
    st = st & " :" & message
  End If
  
  rawOutput st & vbLf
End Sub

Public Sub joinChannel(cName As String, Optional password As String = "")
  rawOutput "JOIN " & cName & " " & password & vbLf
End Sub

Public Sub inviteToChannel(cChannelName As String, cUser As String)
  rawOutput "INVITE " & cUser & " " & cChannelName & vbLf
End Sub

Public Sub kickUser(cChannelName As String, cUser As String, cWhy As String)
  rawOutput "KICK " & cChannelName & " " & cUser & " :" & cWhy
End Sub



Public Sub privateMessage(cChUsr As String, text As String, Optional skipQueue As Boolean)

  rawOutput "PRIVMSG " & cChUsr & " :" & text & vbLf, skipQueue, cChUsr

End Sub

Public Sub whois(Parameters As String)
  rawOutput "WHOIS " & Parameters & vbCrLf
End Sub


Public Sub pongServer(srv As String)
  rawOutput "PONG " & srv & vbLf, True
End Sub

Public Sub pingServer(srv As String)
  rawOutput "PING " & srv & vbLf, True
End Sub

Public Sub pongUser(gU As GlobalUser, timeStamp As Long)
  noticeUser gU, Chr$(1) & "PING " & timeStamp & Chr$(1), True
End Sub

Public Sub pingUser(gU As GlobalUser)
  privateMessage gU.nickName, Chr$(1) & "PING " & time.getTimeStamp & Chr$(1), True

End Sub

Public Sub noticeUser(gU As GlobalUser, text As String, Optional skipQueue As Boolean)
  rawOutput "NOTICE " & gU.nickName & " :" & text & vbLf, skipQueue
End Sub

Public Sub noticeChannel(ch As channel, text As String)
  rawOutput "NOTICE " & ch.name & " :" & text & vbLf
End Sub


Public Property Get userName() As String
  userName = mUserName
End Property
Public Property Let userName(nv As String)
  If nv = "" Or Sock.Connected Then Exit Property
  mUserName = nv
End Property

Public Property Get realName() As String
  realName = mRealName
End Property

Public Property Let realName(nv As String)
  mRealName = nv
End Property

Public Sub getMode(cName As String)
  rawOutput "MODE " & cName & vbLf
End Sub

Public Sub setMode(cName As String, sign As Boolean, modeFlags As String, Optional userLimit As Long = 0, Optional secretKey As String, Optional parm3 As String, Optional parm4 As String, Optional parm5 As String, Optional parm6 As String, Optional parm7 As String)
  Dim strMode As String
  
  strMode = "MODE " & cName & " "
  
  If sign Then
    strMode = strMode & "+"
  Else
    strMode = strMode & "-"
  End If
  
  strMode = strMode & modeFlags
  
  If (userLimit > 0) And (InStr(1, modeFlags, "l") > 0) Then
    strMode = strMode & " " & userLimit
  End If
  
  If (secretKey <> "") And (InStr(1, modeFlags, "k") > 0) Then
    strMode = strMode & " " & secretKey
  End If
  
  If parm3 <> "" Then
    strMode = strMode & " " & parm3
  End If
  
  If parm4 <> "" Then
    strMode = strMode & " " & parm4
  End If
  
  If parm5 <> "" Then
    strMode = strMode & " " & parm5
  End If
  
  If parm6 <> "" Then
    strMode = strMode & " " & parm6
  End If
  
  If parm7 <> "" Then
    strMode = strMode & " " & parm7
  End If
  
  
  rawOutput strMode & vbLf
End Sub

Public Sub kill(gU As GlobalUser, why As String)
  rawOutput "KILL :" & gU.nickName & " " & why & vbLf
End Sub

Public Property Let awayMessage(message As String)

Dim st As String
st = "AWAY "

If message <> "" Then
  st = st & ":" & message
End If

rawOutput st & vbLf

self.awayMessage = message

End Property


Public Property Get awayMessage() As String
  awayMessage = self.awayMessage
End Property

Public Sub getUserHost(nick As String)
  rawOutput "USERHOST " & nick & vbLf
End Sub


Public Sub getChannelNames(cName As String)
  rawOutput "NAMES " & cName & vbLf
End Sub


Public Property Get MaxOutputDataRate() As Long
  MaxOutputDataRate = mMaxOutputDataRate
End Property


Public Property Let MaxOutputDataRate(dr As Long)
  
  mMaxOutputDataRate = dr
  
  If mMaxOutputDataRate < 0 Then
    dr = 0
  End If
  
End Property


Public Property Get serverName() As String
  serverName = mServerName
End Property

Public Property Let serverName(ns As String)
  mServerName = ns
End Property


Public Property Get remotePort() As Integer
  remotePort = mRemotePort
End Property

Public Property Let remotePort(ns As Integer)
  mRemotePort = ns
End Property

Public Property Get remoteAddress() As String
  remoteAddress = Sock.PeerAddress
End Property


Public Property Get Connected() As Boolean
  Connected = Sock.Connected
End Property

Public Property Get Properties() As CFairCollection
  If mProperties Is Nothing Then
    Set mProperties = New CFairCollection
  End If
  
  Set Properties = mProperties
End Property



Public Sub AttachSocket(sck As Socket)
  Set Sock = sck
  Sock_Connect
End Sub

Public Property Get localHost() As String
  localHost = Sock.LocalName
End Property

Public Property Get localAddress() As String
  localAddress = Sock.localAddress
End Property


Public Property Get localPort() As Integer

End Property
