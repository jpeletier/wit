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
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
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

Public Sub listen(port As Integer, Optional LocalAddress As String)
  With sckListen
  
  .localPort = port
  If LocalAddress <> "" Then
    .Bind LocalAddress, port
  End If
  .listen
  
  End With

End Sub

Private Sub Class_Terminate()
Terminate
End Sub


Public Sub Terminate()
On Error Resume Next
sckListen.Close
sckListen.Cleanup
Set sckListen = Nothing
End Sub
Private Sub sckListen_Accept(socketId As Integer)
Static Key As Long
Key = Key + 1
Dim wcn As New CWitConnect
negcl.Add wcn, "K" & Key
wcn.initialize Key, socketId, Me


End Sub


Public Sub removeWCn(Key As Long)
  On Error Resume Next
  negcl.Remove "K" & Key
End Sub

