VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "DccChat"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Private WithEvents Sock As Socket
Attribute Sock.VB_VarHelpID = -1
Private mgUsr As GlobalUser
Private mTimeOut As Integer

Private mRemoteAddress As String
Private mRemotePort As Long
Private WithEvents timeOutTimer As jTimerManager.CTimer
Attribute timeOutTimer.VB_VarHelpID = -1

Private OnConnectRaised As Boolean

Public Event OnMessage(text As String)
Public Event OnConnect()
Public Event OnDisconnect()
Public Event OnTimeout()


Property Let timeOut(x As Integer)
  mTimeOut = x
End Property
Property Get timeOut() As Integer
  timeOut = mTimeOut
End Property


Private Sub initializeSocket()

Set Sock = New Socket
Set timeOutTimer = New CTimer
timeOutTimer.TimeScale = TU_Seconds
timeOutTimer.Interval = mTimeOut

Sock.AddressFamily = AF_INET
Sock.Protocol = IPPROTO_IP
Sock.Binary = True
Sock.BufferSize = 1024
Sock.Blocking = False
Sock.KeepAlive = True

End Sub

Public Sub startDCC()

initializeSocket
Sock.localPort = 0
Sock.Listen

':^Zoltar^!er@**** NOTICE This :DCC Chat (****)
'DCC Chat (****)
':^Zoltar^!er@**** PRIVMSG This :DCC CHAT chat 3232235521 4615

Dim localIP As String

localIP = mgUsr.parent.localAddress

mgUsr.notice "DCC Chat (" & localIP & ")"

Dim nums() As String
nums = Split(localIP, ".")

localIP = "" & 256 ^ 3 * nums(0) + 256 ^ 2 * nums(1) + 256 * nums(2) + nums(3)

mgUsr.privateMessage "DCC CHAT chat " & localIP & " " & Sock.localPort & ""


End Sub

Friend Property Let remoteAddress(x As String)
  mRemoteAddress = x
End Property


Public Property Get remoteAddress() As String
  
  If Sock Is Nothing Then
    remoteAddress = mRemoteAddress
  Else
    remoteAddress = Sock.HostAddress
  End If
  
End Property

Public Property Get RemoteHost() As String
  If Sock Is Nothing Then
    RemoteHost = mRemoteAddress
  Else
    RemoteHost = Sock.hostName
  End If
End Property

Public Property Let remotePort(x As Long)
  mRemotePort = x
End Property

Public Property Get remotePort() As Long

If Sock Is Nothing Then
  remotePort = mRemotePort
Else
  remotePort = Sock.remotePort
End If

End Property

Public Property Set gUsr(x As GlobalUser)
  Set mgUsr = x
End Property

Public Property Get gUsr() As GlobalUser
  Set gUsr = mgUsr
End Property

Private Sub Class_Initialize()
mTimeOut = 30
End Sub

Private Sub Sock_Accept(SocketId As Integer)
  If Sock.Connected Then Exit Sub
  Sock.Accept = SocketId

  Set timeOutTimer = Nothing
  If Not OnConnectRaised Then
    OnConnectRaised = True
    RaiseEvent OnConnect
  End If

End Sub

Private Sub Sock_Connect()
  
  Set timeOutTimer = Nothing
  If Not OnConnectRaised Then
    OnConnectRaised = True
    RaiseEvent OnConnect
  End If
End Sub

Private Sub Sock_Disconnect()
RaiseEvent OnDisconnect
End Sub

Private Sub Sock_Read(DataLength As Integer, IsUrgent As Integer)
'Variable temporal:
Dim datos As String

'Variable para albergar las cadenas que llegan
Static InBuffer As String

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
    
    RaiseEvent OnMessage(datos)
  
  End If
Loop Until pos = 0 'Repetir hasta que ya no queden más mensajes en el buffer.
End Sub


Public Sub rawOutput(st As String)
  Sock.Write st, Len(st)
End Sub

Public Sub say(text As String)
  rawOutput text & vbCrLf
End Sub

Public Sub AcceptDccChat()
  initializeSocket
  
  Dim rm As Integer
  
  If mRemotePort > 32767 Then
    rm = -(mRemotePort And Not (32768)) - 1
  Else
    rm = mRemotePort
  End If
  
   
  Sock.remotePort = rm
  If IsNumeric(mRemoteAddress) Then
    Sock.HostAddress = mRemoteAddress
  Else
    Sock.hostName = mRemoteAddress
  End If
  
  If Not Sock.Connected Then
    Sock.Connect
  Else
    TRACE "DccChat::AcceptDccChat -> Attempt to connect an already connected socket."
  End If
End Sub

Private Sub timeOutTimer_ThatTime()
  timeOutTimer.Interval = 0
  Set timeOutTimer = Nothing
  RaiseEvent OnTimeout
End Sub

Public Property Get Connected() As Boolean
  If Sock Is Nothing Then
    Connected = False
  Else
    Connected = Sock.Connected
  End If
End Property
