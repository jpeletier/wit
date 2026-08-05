VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "WitClient"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Public WithEvents IRC As CIRCClient
Attribute IRC.VB_VarHelpID = -1
Public OnJoinChannels As Collection
Public password As String
Public key As String
Public persist As Boolean

Private WithEvents DCCs As DCChatCollection
Attribute DCCs.VB_VarHelpID = -1

Private WithEvents DCCCapture As DccChat
Attribute DCCCapture.VB_VarHelpID = -1


Public WitChannels As WitChannels

Private simtrivials As Long

Private WithEvents NiCKBot As NiCKBot
Attribute NiCKBot.VB_VarHelpID = -1
Private WithEvents reconnectTimer As CTimer
Attribute reconnectTimer.VB_VarHelpID = -1
Private WithEvents checkConnection As CTimer
Attribute checkConnection.VB_VarHelpID = -1

Private chWit As Channel


Private alive As Boolean

Private mAutoReconnect As Boolean

Public Event OnDisconnect()

Const WITMODE_OPCONTROL_MASK = &H1




Public Property Get autoReconnect() As Boolean
  autoReconnect = mAutoReconnect
End Property

Public Property Let autoReconnect(v As Boolean)
  mAutoReconnect = v
End Property


Private Sub checkConnection_ThatTime()

If mAutoReconnect Then
  If Not alive Then
    IRC_OnDisconnect
  Else
    alive = False
  End If
End If


If Not IRC Is Nothing Then
  If getChannelCount(IRC) = 0 Then
    If Not (chWit Is Nothing) Then
      chWit.Join
    End If
  End If
End If

End Sub

Private Sub Class_Terminate()
    
If Not IRC Is Nothing Then
    IRC.quit "Braulio: " & LocateRandomDef("Braulio")
End If

    'DCCs.Col.clear
End Sub

Public Sub Connect()


IRC.Connect

End Sub

Private Sub DCCCapture_OnConnect()
  DCCCapture.say "--------------------------START--------------------------"
End Sub

Private Sub DCCCapture_OnDisconnect()
  Set DCCCapture = Nothing
End Sub

Private Sub DCCCapture_OnMessage(text As String)
  IRC.rawOutput text & vbCrLf
End Sub

Private Sub DCCCapture_OnTimeout()
  Set DCCCapture = Nothing
End Sub

Private Sub DCCs_OnConnect(Index As Long, source As jIRCLib.DccChat)
  
  
  source.say "Wit IRC Bot v" & App.Major & "." & App.Minor & "." & App.Revision & ", by Javier Peletier. www.peletier.com"
  source.say ""
  source.say "Hola," & mircColorText(" " & source.gUsr, mccDarkRed) & " bienvenido a la consola de control de " & IRC.nick
  
  DCCs_OnMessage Index, source, "HELP"
  
  
End Sub

Private Sub DCCs_OnDisconnect(Index As Long, source As jIRCLib.DccChat)
  DCCs.Col.RemoveByIndex Index
End Sub


Private Sub ProcessConsoleCMDs(text As String, usr As GlobalUser)

Dim fword() As String

Dim np As Long
Dim tt As String
tt = Trim(text)
If tt = "" Then Exit Sub

fword = Split(tt, " ", 3)



Select Case UCase(fword(0))
  Case "HELP"
    
    Dim dcc As DccChat
    Set dcc = usr.dcc
    
    If Not dcc.Connected Then
      dcc.startDCC
      DCCs.Col.Add dcc
    Else
      usr.DCCMessage "Comandos disponibles: "
      usr.DCCMessage "HELP                        : Muestra la ayuda."
      usr.DCCMessage "LET palabra=Definición      : Permite establecer definiciones"
      usr.DCCMessage "LET nick=saludo             : Define cómo Wit te saludará cuando entres en un canal"
      usr.DCCMessage "TRIVIAL #canal numpreguntas : Comienza una partida de numpreguntas preguntas de trivial en el canal #canal."
      usr.DCCMessage "TRIVIAL #canal STOP         : Detiene una partida en el canal #canal"
      usr.DCCMessage ""
    End If
  
  Case "LET"
  
    If NiCKBot.getNickStatus(usr) < nckstIdentifiedPerAccessList Then
      usr.DCCMessage "Utiliza antes el comando /msg " & IRC.nick & " IDENTIFY", True
    Else
      Dim dfs() As String
      dfs = Split(Mid(text, 5), "=", 2)
      If UBound(dfs) >= 1 Then
        AddModDef dfs(0), dfs(1), usr.nickName
        usr.DCCMessage dfs(0) & "=" & LocateFirstDef(dfs(0), usr.nickName), True
      Else
        usr.DCCMessage "Sintaxis incorrecta. Escribe HELP", True
        Exit Sub
      End If
     
    End If
    
  Case "IDENTIFY"
    NiCKBot.requestNickStatus usr
    
  Case "RAW"
    If usr.nickName = "Zoltar" And NiCKBot.getNickStatus(usr) = nckstIdentifiedByPassword Then
      IRC.rawOutput Mid(text, 5) & vbCrLf
    End If
    
  Case "FOLK"
    If usr.nickName = "Zoltar" And NiCKBot.getNickStatus(usr) = nckstIdentifiedByPassword Then
      Dim wcl As WitClient
      For Each wcl In frmWit.clients
        wcl.IRC.rawOutput Mid(text, 6) & vbCrLf
      Next
    End If
 

  Case "CAPTURE"
    Set DCCCapture = New DccChat
    Set DCCCapture.gUsr = usr
    DCCCapture.startDCC
    
  Case "WITMODE"
    ProcessWitMode fword, text, usr


  Case "GOTO"
    If UBound(fword) < 1 Then
      usr.DCCMessage "Sintaxis incorrecta. GOTO #channel", True
      Exit Sub
    End If
    
    If Not chWit.joined Then
      usr.DCCMessage "GOTO desactivado hasta que vuelva a #Wit", True
      Exit Sub
    End If
    
    If Not (isOperator(usr, chWit)) Then
      usr.DCCMessage "Acceso denegado", True
      Exit Sub
    End If
    
    If Trim(fword(1)) = "" Then
      usr.DCCMessage "Sintaxis incorrecta. GOTO #channel", True
      Exit Sub
    End If
      
    
    If getChannelCount(IRC) = 1 Then
      chWit.say usr.nickName & " me envía a " & fword(1)
    Else
      chWit.part usr.nickName & " me envía a " & fword(1)
    End If
    
    IRC.joinChannel fword(1)
    
    Dim tj As TJoinOnInvite
    Set tj = New TJoinOnInvite
    tj.initialize IRC.getChannel(fword(1)), usr, tjSentByWitOp




  Case "TRIVIAL"
    If UBound(fword) < 1 Then
      usr.DCCMessage "Sintaxis incorrecta. Escribe HELP", True
      Exit Sub
    End If
    
    Dim wch As WitChannel
    
    Set wch = WitChannels(fword(1))
    

    
    
    If wch Is Nothing Then
      usr.DCCMessage "Primero debo estar en el canal " & fword(1) & ". Invítame allí con el comando /invite " & IRC.nick & " " & fword(1) & ". Recuerda que sólo un OP de ese canal me puede invitar.", True
      usr.DCCMessage "Ve a http://www.peletier.com/trivial/WitSummon , donde podrás bajarte tu propio bot.", True
      usr.DCCMessage "Entra en el canal #Wit para más información.", True
      Exit Sub
    Else
      If wch.myChannel Is chWit Then
        wch.myChannel.say usr.nickName & " ha intentado crear una partida en #Wit... :P"
        Exit Sub
      End If
    
    
    
      np = 20
      If UBound(fword) >= 2 Then
        If IsNumeric(fword(2)) Then
          np = Val(Mid(fword(2), 1, 4))
        Else
          If UCase(fword(2)) = "STOP" Then
            If wch.trivial2Running Then
              If isOperator(usr, wch.myChannel) Then
                wch.stopTrivial2 mircColorText("--- Partida detenida por " & mircUnderlineText(usr.nickName) & " ---", mccDarkRed)
              Else
                usr.DCCMessage "Sólo un operador (@) de " & wch.myChannel.name & " puede detener la partida.", True
              End If
            Else
              usr.DCCMessage "No hay ninguna partida activa en " & wch.myChannel.name, True
            End If
            
              
              
              
              
              Exit Sub
            End If
        End If
      End If
          
      If np > 30 Then
        usr.DCCMessage "El máximo son 30 preguntas", True
      Else
        If IRC.Properties("SIMTRIVIAL") < 2 Then
          wch.runTrivial2 usr, np
        Else
          usr.DCCMessage "Estoy en demasiados trivials. Inténtalo de nuevo más tarde o mira en " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/WitSummon", mccPureBlue)) & " para solucionar este problema.", True
        End If
      End If
    End If

      
End Select



End Sub


Private Sub DCCs_OnMessage(Index As Long, source As jIRCLib.DccChat, text As String)
  

ProcessConsoleCMDs text, source.gUsr


End Sub


Private Sub ProcessWitMode(fword() As String, text As String, usr As GlobalUser)

If Not isOperator(usr, chWit) Then Exit Sub

If UBound(fword) < 1 Then
  usr.DCCMessage "Sintaxis incorrecta: WITMODE OPCION parámetros"
  Exit Sub
End If



Dim flags As Long

flags = chWit.userLimit
If flags < 1024 Then
  chWit.userLimit = 1024
  flags = 1024
End If


Dim ub As Long

ub = UBound(fword) = 1



Select Case UCase(fword(1))

  Case "OPCONTROL"
      If ub = 1 Then
        usr.DCCMessage "OPCONTROL WITMODE IS " & OnOffMode(flags And WITMODE_OPCONTROL_MASK)
      Else
        ToggleMode flags, WITMODE_OPCONTROL_MASK, "OPControl", UCase(fword(2)) = "ON"
        chWit.userLimit = flags
      End If

End Select







End Sub

Public Sub ToggleMode(flags As Long, mask As Long, modeName As String, activate As Boolean, Optional usr As GlobalUser)

Dim usrTxt As String

If usr Is Nothing Then
  usrTxt = "Wit"
Else
  usrTxt = usr.nickName
End If

    If activate Then
      flags = flags Or WITMODE_OPCONTROL_MASK
      chWit.say mircColorText(usrTxt & " sets WitMode +" & modeName, mccDarkGreen)
    Else
      flags = flags And (Not WITMODE_OPCONTROL_MASK)
      chWit.say mircColorText(usrTxt & " sets WitMode -" & modeName, mccDarkGreen)
    End If


End Sub


Private Function OnOffMode(value As Long) As String

  If value = 0 Then
    OnOffMode = "OFF"
  Else
    OnOffMode = "ON"
  End If



End Function






Private Sub DCCs_OnTimeout(Index As Long, source As jIRCLib.DccChat)
  DCCs.Col.RemoveByIndex Index
End Sub

Private Sub IRC_LíneaRecibida(ByVal Línea As String)
  If Not DCCCapture Is Nothing Then
    DCCCapture.say Línea
  End If
  
  alive = True
  
End Sub

Private Sub IRC_OnConnect()
  IRC.MaxOutputDataRate = 60
  
  Set chWit = IRC.getChannel("#Wit")

End Sub

Private Sub IRC_OnDccChatRequest(DccChatObject As jIRCLib.DccChat)

  DCCs.Col.Add DccChatObject
  DccChatObject.AcceptDccChat

End Sub

Private Sub IRC_OnDisconnect()
  
  RaiseEvent OnDisconnect

On Error Resume Next
  Dim WChn As WitChannel
  For Each WChn In WitChannels
    WChn.Terminate
  Next
  
  WitChannels.clear
  
  If Not persist Then
    frmWit.clients.Remove key
    IRC.Destroy
    Set IRC = Nothing
    
  Else
    Set reconnectTimer = New CTimer
    reconnectTimer.TimeScale = TU_Seconds
    reconnectTimer.Interval = 20
  End If
  
  
End Sub

Private Sub IRC_OnEndOfMOTD()
  Set NiCKBot = New NiCKBot
  NiCKBot.initialize IRC
  
  Set reconnectTimer = Nothing

 
' NiCKBot.identify password


Dim v As Variant
For Each v In OnJoinChannels
  IRC.getChannel("" & v).Join
Next

chWit.Join

End Sub

Private Sub IRC_OnInvite(cChannel As jIRCLib.Channel, cUser As jIRCLib.GlobalUser)
    

    
    
    If getChannelCount(IRC) < 2 Then
    
      Dim jin As TJoinOnInvite
      Set jin = New TJoinOnInvite
      jin.initialize cChannel, cUser
    
    
    Else
      cUser.privateMessage "Estoy en demasiados canales. Para solucionar este problema, visita " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/WitSummon", mccPureBlue))
    End If
End Sub

Private Sub IRC_OnJoin(nChannel As jIRCLib.Channel, gU As jIRCLib.GlobalUser)
    If gU Is IRC.self Then
      IRC.getUser("chan").privateMessage "OP " & nChannel.name & " " & IRC.nick
    End If
    

  WitChannels.Add nChannel, NiCKBot, Me


    
End Sub

Private Sub IRC_OnLeave(nChannel As jIRCLib.Channel, gU As jIRCLib.GlobalUser, kickedBy As jIRCLib.GlobalUser, reason As String)
  
  If gU Is IRC.self Then
    Dim WChn As WitChannel
    Set WChn = WitChannels(nChannel.name)
    
    If Not WChn Is Nothing Then
      WChn.Terminate
      WitChannels.Remove nChannel
    End If
      
    If Not (nChannel Is chWit) Then
      chWit.Join
    End If
  End If
  
  If nChannel.Users.Count <= 1 Then
    Dim v As Variant
    For Each v In OnJoinChannels
      If UCase(v) = UCase(nChannel.name) Then
        Exit Sub
      End If
    Next
    
    nChannel.part
  End If
  
  
  
End Sub

Private Sub IRC_OnPrivateMessageUser(usr As jIRCLib.GlobalUser, text As String)

ProcessConsoleCMDs text, usr

End Sub

Private Sub NiCKBot_StatusResponse(gUsr As jIRCLib.GlobalUser)
  Select Case NiCKBot.getNickStatus(gUsr)
    Case NiCKStatusEnum.nckstIdentifiedByPassword, NiCKStatusEnum.nckstIdentifiedPerAccessList
      gUsr.notice "Acabo de comprobar que estás identificado."
    Case NiCKStatusEnum.nckstUnrecognized
      gUsr.notice "No estás identificado con NiCK. Identifícate y después escribe el comando /msg " & IRC.nick & " IDENTIFY"
    Case NiCKStatusEnum.nckstNotConnected
      gUsr.notice "Tu nick no está registrado con NiCK. Regístrate y después escribe el comando /msg " & IRC.nick & " IDENTIFY. Para ayuda sobre cómo registrarse, escribe /msg NiCK help"
  End Select
End Sub


Private Sub Class_Initialize()
  Set IRC = New CIRCClient
  IRC.Properties("SIMTRIVIAL") = 0
  Set OnJoinChannels = New Collection
  Set WitChannels = New WitChannels
  Set DCCs = New DCChatCollection
  
  Set checkConnection = New CTimer
  checkConnection.SharedTimer = True
  checkConnection.TimeScale = TU_Minutes
  checkConnection.Interval = 5
 
  mAutoReconnect = True
 
End Sub

Private Sub reconnectTimer_ThatTime()
  If IRC.Connected Then
    IRC.quit "-reconnect-"
  End If
  Connect
End Sub


Public Sub Terminate()

persist = False
mAutoReconnect = False

IRC_OnDisconnect

If Not IRC Is Nothing Then
  IRC.Destroy
  Set IRC = Nothing
End If
    
End Sub
