VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CWCnServer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private WithEvents sckListen As Socket
Attribute sckListen.VB_VarHelpID = -1

Private negcl As Collection


Private Sub Class_Initialize()

Set sckListen = New Socket
Set negcl = New Collection

With sckListen
  .SocketType = SOCK_STREAM
  .AddressFamily = AF_INET
  .BufferSize = 1024
  .Binary = True
  .Protocol = IPPROTO_IP
  .Blocking = False
  
End With

End Sub

Public Sub listen(port As Integer)
  With sckListen
  
  .LocalPort = port
  .listen
  
  End With

End Sub

Private Sub sckListen_Accept(socketId As Integer)
Static key As Long
key = key + 1
Dim wcn As New CWitConnect

wcn.initialize key, socketId, Me
negcl.Add wcn, "K" & key

End Sub


Public Sub removeWCn(key As Long)
  On Error Resume Next
  negcl.Remove "K" & key
End Sub

