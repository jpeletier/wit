VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CWitConnect"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private WithEvents sock As Socket
Attribute sock.VB_VarHelpID = -1
Private parent As CWCnServer
Private key As Long

Private wcl As New WitClient

Private protocolVer As String



Public Sub initialize(xKey As Long, socketId As Integer, xParent As CWCnServer)


Set sock = New Socket
Set parent = xParent
key = xKey

With sock

  .SocketType = SOCK_STREAM
  .AddressFamily = AF_INET
  .BufferSize = 1024
  .Binary = True
  .Protocol = IPPROTO_IP
  .Blocking = False
  
  .Accept = socketId
  

End With


  rawOutput "WELCOME peletier.com" & vbCrLf


End Sub

Private Sub rawOutput(st As String)
  sock.Write st, Len(st)
End Sub


Private Sub sock_Read(DataLength As Integer, IsUrgent As Integer)

Static InBuffer As String


If DataLength = -15 Then
  InBuffer = ""
  Exit Sub
End If
  

'Variable temporal:
Dim data As String

'Variable para albergar las cadenas que llegan

sock.Read data, DataLength
'Protocolo de texto simple. Llegan ráfagas de cadenas.
'Sabemos que un mensaje ha llegado del todo si existe
'un Avance de línea (VbLf)

'Añadir lo que acaba de llegar a nuestro buffer:
InBuffer = InBuffer & data

'Buscar VbLf:
Dim pos As Long
Do
  pos = InStr(1, InBuffer, vbLf)
  If pos > 0 Then
    'Si había un VbLf, es que por lo menos tenemos un mensaje
    'completo
    data = Replace(Left$(InBuffer, pos - 1), vbCr, "") 'Coge el mensaje y lo mete en datos
    InBuffer = Mid$(InBuffer, pos + 1) 'Recorta el buffer y quita ese trozo.
    
    processLine data
    
  
  End If
Loop Until pos = 0 'Repetir hasta que ya no queden más mensajes en el buffer.


End Sub


Private Sub processLine(data As String)

If data = "" Then Exit Sub

Dim cmd() As String

cmd = Split(data, " ")



Select Case cmd(0)

  Case "VERSION"
    Debug.Print "VERSION :" & cmd(1)
    If UBound(cmd) < 1 Then
      EndHandshake
      Exit Sub
    End If
    
    If protocolVer <> "" Then
      EndHandshake
      Exit Sub
    End If
    
    protocolVer = LCase(Trim(cmd(1)))
    
End Select
    
      

Select Case protocolVer
  Case "1.0"
    Protocol_1_0 cmd
  Case "1.1"
    Protocol_1_1 cmd
  Case Else
    EndHandshake
    Debug.Print "Unknown protocol version '" & protocolVer & "'"
End Select


End Sub

Private Sub Protocol_1_0(cmd() As String)

Select Case cmd(0)
    
  Case "VERSION"
    rawOutput "FORCECONNECT irc.irc-hispano.org 6667" & vbCrLf
    
  Case "CONNECTED"
    
      With wcl.IRC
        .nick = rndnick
        Debug.Print "WitSummon '" & .nick & "' connected"
        .AttachSocket sock
        frmWit.clients.Add wcl, "C" & Int(Rnd * 10000)
        
        EndHandshake
        
      End With
      
      Set wcl = Nothing
  
  Case "CHANNEL"
    If UBound(cmd) < 1 Then
      EndHandshake
      Exit Sub
    End If
     
     With wcl
     .OnJoinChannels.Add cmd(1)
     Debug.Print cmd(1)
     End With
     
  Case "DONE"
  
End Select



End Sub


Private Sub Protocol_1_1(cmd() As String)

Select Case cmd(0)

  Case "VERSION"
    rawOutput "START_CONNECTION" & vbCrLf
    
  Case Else
    Protocol_1_0 cmd

End Select





End Sub



Private Function rndnick() As String

Dim n As Long

Dim st As String
For n = 1 To 3
  st = st & Chr(Int(Rnd * 25) + Asc("A"))
Next

rndnick = st & "_Wit"

End Function

Private Sub EndHandshake()
  parent.removeWCn key
  sock_Read -15, 0
  Set sock = Nothing
End Sub
