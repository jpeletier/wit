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
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
Private Const MAX_CONNECTIONS = 50


Private WithEvents sock As Socket
Attribute sock.VB_VarHelpID = -1
Private parent As CWCnServer
Private Key As Long
Private nick As String
Private password As String

Private wcl As WitClient

Private protocolVer As String

Private secretCodeOK As Boolean
Private scid As Long



Public Sub initialize(xKey As Long, socketId As Integer, xParent As CWCnServer)

On Error GoTo init_err
Set sock = New Socket
Set parent = xParent
Key = xKey

With sock

  .SocketType = SOCK_STREAM
  .AddressFamily = AF_INET
  .BufferSize = 1024
  .Binary = True
  .Protocol = IPPROTO_IP
  .Blocking = False
  
  
  If .IsBlocked Then
    EndHandshake
    Exit Sub
  End If
  .Accept = socketId
  
  Dim ble As IPBanListEntry
  Set ble = frmWit.ipBanList.getBanStatus(.PeerAddress)
  If Not ble Is Nothing Then
    
    LogLine "CWitconnect::Initialize", "Connection denied to banned IP=" & .PeerAddress & ". Reason: " & ble.Reason
    EndHandshake
    Exit Sub
  End If
  

End With


  rawOutput "WELCOME peletier.com" & vbCrLf
  
  If frmWit.clients.Count >= MAX_CONNECTIONS Then
    WSMessage "El servidor ha alcanzado el máximo de conexiones. Prueba con otro WitServer o solicita tu bot en #WitClub. Gracias." & vbCrLf, True
    Debug.Print "Too many connections. " & Now

  End If
  
  
  'rawOutput "MSG ¡Contra el no-expire y la prepotencia del IRC-Hispano. ¡No te conectes el día 1 de Febrero!" & vbCrLf
  'Debug.Print "intento " & Now
  'Wait 1000
  'EndHandshake
  
  
init_exit:
  Exit Sub

init_err:
EndHandshake
Resume init_exit

End Sub

Private Sub rawOutput(st As String)
  sock.Write st, Len(st)
End Sub


Private Sub Class_Initialize()
Set wcl = New WitClient
Set wcl.Network = MultiNetwork.getNetworkFromID(IDN_IRC_HISPANO)
End Sub

Private Sub sock_Read(DataLength As Integer, IsUrgent As Integer)

Static InBuffer As String
If wcl Is Nothing Then Exit Sub

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
    If UBound(cmd) < 1 Then
     
      EndHandshake
      Exit Sub
    End If
    Debug.Print "VERSION :" & cmd(1)

    
    If protocolVer <> "" Then
      EndHandshake
      Exit Sub
    End If
    
    protocolVer = LCase(Trim(cmd(1)))
    
End Select
    
      

Select Case protocolVer
  Case "1.0"
    'Protocol_1_0 cmd
    WSMessage "Por favor, actualiza tu bot en http://www.peletier.com/trivial/witSummon", True
  Case "1.1"
    Protocol_1_1 cmd
  Case Else
    EndHandshake
    Debug.Print "Unknown protocol version '" & protocolVer & "'"
End Select


End Sub

Private Sub Protocol_1_0(cmd() As String)

If wcl.IRC Is Nothing Then
  EndHandshake
  Exit Sub
End If
  

Select Case cmd(0)
    
  Case "VERSION"
    rawOutput "FORCECONNECT irc.irc-hispano.org 6667" & vbCrLf
    
  Case "CONNECTED"
  

    
      With wcl.IRC
        If nick = "" Then
          nick = rndnick
        Else
          Dim w As WitClient
          For Each w In frmWit.clients
            If LCase(w.IRC.nick) = nick Then
              w.nick = nick
            End If
          Next
       
        End If
        
        .nick = nick
        
        If password <> "" Then
          .password = password
        End If
        
        Debug.Print "WitSummon '" & .nick & "' connected"
        LogLine "CWitConnect::Protocol_1_0", .nick & "=" & sock.PeerAddress & ", SCID=" & scid
        .AttachSocket sock
        frmWit.clients.Add wcl, "C" & Int(Rnd * 10000000)
        
        EndHandshake
        
      End With
      
      Set wcl = Nothing
  
  Case "CHANNEL"
    If UBound(cmd) < 1 Then
      EndHandshake
      Exit Sub
    End If
    If (Trim(cmd(1)) = "") Then
      EndHandshake
      Exit Sub
    End If
     
    Dim st() As String
    st = Split(cmd(1), ",")
    st(0) = Trim(st(0))
    
    Dim ble As BanListEntry
    Set ble = frmWit.BanList.Item(st(0), 1)
    If Not ble Is Nothing Then
      If ble.DateEnd < Now Then
        Set ble = Nothing
      End If
    End If
    
    If Not ble Is Nothing Then
      WSMessage "No puedo entrar en el canal " & ble.channelName & ". El canal tiene un WIT-BAN hasta el " & ble.DateEnd & ". Hora actual: " & Now & vbCrLf, True

      Exit Sub
    End If
    
    Debug.Print cmd(1)
    
    With wcl
      If .exclusive And .OnJoinChannels.Count < 2 Then
        .OnJoinChannels.Add st(0)
        Exit Sub
      End If
      
      If .OnJoinChannels.Count < 1 Then
        .OnJoinChannels.Add st(0)
      Else
        WSMessage "Para conectar a Wit a un segundo canal, debes exclusivizar tu bot en http://www.peletier.com/trivial/persoWit", True
      End If
      
    End With
    
  Case "SECRETCODE"
    CheckManagementConnection
    Dim rc As Recordset
    Set rc = New Recordset
    Dim secretCode As Long
    
    If IsNumeric(cmd(1)) Then
      secretCode = CLng(Mid(cmd(1), 1, 8))
    Else
      secretCode = -1
    End If
    
    Dim wl As WitClient
    For Each wl In frmWit.clients
        If wl.secretCode = secretCode Then
            wl.Terminate
            WSMessage "Código secreto en uso actualmente.", True
            Exit Sub
        End If
    Next
    
    rc.Open "select scid,nick,nickpassword,exclusive from wsnicks where secretcode=" & secretCode & " AND dateend > '" & Now & "'", CnMgt, adOpenForwardOnly, adLockReadOnly
    
    If rc.EOF Then
      'WSMessage "Código secreto incorrecto o caducado. Se asignará un nick aleatorio.", False
      WSMessage "Código secreto incorrecto o caducado. Obten un código de 1 mes de duración enviando PELE PERSOWIT al 5015. Más información en http://www.peletier.com/trivial/persoWit", False
      EndHandshake
    Else
      CnMgt.Execute "UPDATE WSNicks set lastserver=" & Machine & " where secretcode=" & secretCode
      wcl.secretCode = secretCode
      secretCodeOK = True
      scid = rc!scid
      
      If IsNull(rc!exclusive) Then
        wcl.exclusive = False
      Else
        wcl.exclusive = rc!exclusive
      End If
      
      
      If IsNull(rc!nick) Then
        WSMessage "El código secreto es correcto, sin embargo no has personalizado el nick todavía. Ve a http://www.peletier.com/trivial/persoWit para personalizar tu bot. Mientras tanto, se asignará un nick aleatorio.", False
        nick = ""
      Else
        nick = "" & rc!nick
        password = "" & rc!nickpassword
        
        If Len(nick) = 6 Then
          nick = nick & "Wit"
        Else
          nick = nick & "_Wit"
        End If
      End If
    End If
    
    rc.Close
          
     
  Case "DONE"
    WSMessage "Actualiza tu bot. Descarga la nueva versión en http://www.peletier.com/trivial/WitSummon", True
  
End Select



End Sub


Private Sub Protocol_1_1(cmd() As String)

Select Case cmd(0)

  Case "VERSION"
    
  Case "DONE"
    If Not secretCodeOK Then
      WSMessage "Para utilizar WitSummon, debes personalizar tu bot. Obten un código de activación por 1 mes enviando el mensaje PELE PERSOWIT al 5015. Más información en http://www.peletier.com/trivial/persoWit", True
      Exit Sub
    End If

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
  parent.removeWCn Key
  sock_Read -15, 0
  Set sock = Nothing
  Set wcl = Nothing
End Sub

Private Sub WSMessage(message As String, closeSocket As Boolean)

If closeSocket Then
  Dim tws As TWSMessage
  Set tws = New TWSMessage
  tws.initialize sock, message
  sock.Flush
  EndHandshake
 Else
  rawOutput "MSG " & message & vbCrLf
  Debug.Print "TWSMessage (no close) to " & sock.PeerAddress & " : " & message

End If

End Sub
