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
Attribute VB_Ext_KEY = "Member0" ,"CHaNBot"
Attribute VB_Ext_KEY = "Member1" ,"WitChannels"
Option Explicit

Public WithEvents IRC As CIRCClient
Attribute IRC.VB_VarHelpID = -1
Public OnJoinChannels As Collection
Public allowedChannels As New Collection

Public password As String
Public Key As String
Public persist As Boolean
Public initialNick As String

Public secretCode As Long
Public exclusive As Long


Private WithEvents DCCs As DCChatCollection
Attribute DCCs.VB_VarHelpID = -1
Private WithEvents DCCCapture As DccChat
Attribute DCCCapture.VB_VarHelpID = -1

Public WitChannels As WitChannels
Private simtrivials As Long

Private WithEvents NiCKBot As NiCKBot
Attribute NiCKBot.VB_VarHelpID = -1
Public WithEvents CHaNBot As CHaNBot
Attribute CHaNBot.VB_VarHelpID = -1
Private WithEvents reconnectTimer As CTimer
Attribute reconnectTimer.VB_VarHelpID = -1
Private WithEvents checkConnection As CTimer
Attribute checkConnection.VB_VarHelpID = -1

Public chWit As Channel

Private alive As Boolean

Private mAutoReconnect As Boolean

Public Event OnDisconnect()

Const WITMODE_OPCONTROL_MASK = &H1

Public Property Get nick() As String
  nick = initialNick
End Property

Public Property Let nick(v As String)
  initialNick = v
  IRC.nick = v
End Property


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
    If Not IRC Is Nothing Then
      IRC.pingServer "are you there?"
    End If
  End If
End If


If Not IRC Is Nothing Then
  If getChannelCount(IRC) = 0 Then
    If Not (chWit Is Nothing) Then
      joinChannel chWit.Name
   
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

Private Sub DCCs_OnConnect(Index As Long, Source As jIRCLib.DccChat)
  
  
  Source.say "Wit IRC Bot v" & App.Major & "." & App.Minor & "." & App.Revision & ", by Javier Peletier. www.peletier.com"
  Source.say ""
  Source.say "Hola," & mircColorText(" " & Source.gUsr, mccDarkRed) & " bienvenido a la consola de control de " & IRC.nick
  
  DCCs_OnMessage Index, Source, "HELP"
  
  
End Sub

Private Sub DCCs_OnDisconnect(Index As Long, Source As jIRCLib.DccChat)
  DCCs.col.RemoveByIndex Index
End Sub


Private Sub ProcessConsoleCMDs(text As String, usr As GlobalUser)

Dim fword() As String

Dim np As Long
Dim tt As String
Dim wch As WitChannel

tt = Trim(text)
If tt = "" Then Exit Sub

fword = Split(tt, " ", 5)



Select Case UCase(fword(0))
  Case "HELP"
    
'    Dim dcc As DccChat
'    Set dcc = usr.dcc
'
'   If Not dcc.Connected Then
'      dcc.startDCC
'      DCCs.col.Add dcc
'    Else
      
      usr.DCCMessage "Wit IRC Bot, by Javier Peletier Ribera (c) peletier.com 2000-2003. Todos los derechos reservados.", True
      usr.DCCMessage "Versión " & App.Major & "." & App.Minor & "." & App.Revision & ". Basado en jIRC ActiveX DLL", True
      usr.DCCMessage mircColorText(mircUnderlineText("http://www.peletier.com"), mccPureBlue) & " jm@peletier.com", True
      usr.DCCMessage "----------------", True
      usr.DCCMessage "Wit es un bot de juegos que te permitirá jugar al Trivial y a Cifras y Letras en IRC", True
      usr.DCCMessage "Más información en " & mircColorText(mircUnderlineText("http://www.peletier.com/trivial/faq.asp"), mccPureBlue), True
      usr.DCCMessage "", True
      usr.DCCMessage "Comandos disponibles: ", True
      usr.DCCMessage "HELP                        : Muestra la ayuda.", True
'      usr.DCCMessage "LET palabra=Definición      : Permite establecer definiciones"
'      usr.DCCMessage "LET nick=saludo             : Define cómo Wit te saludará cuando entres en un canal"
      usr.DCCMessage "TRIVIAL #canal numpreguntas : Comienza una partida de numpreguntas preguntas de trivial en el canal #canal.", True
      usr.DCCMessage "TRIVIAL #canal STOP         : Detiene una partida de trivial en el canal #canal", True
      usr.DCCMessage "CYL #canal numdesafíos      : Comienza una partida de numdesafíos desafíos de Cifras y Letras en el canal #canal.", True
      usr.DCCMessage "CYL #canal STOP             : Detiene una partida de Cifras y Letras en el canal #canal", True
      usr.DCCMessage "DATE                        : Muestra la hora en el servidor.", True
      usr.DCCMessage "JOIN                        : Invita a Wit a tu canal (en redes distintas de IRC-Hispano)", True
      usr.DCCMessage "", True
      usr.DCCMessage "HELP_END", True
'    End If
  
  Case "LET"
  
    usr.DCCMessage "Comando deshabilitado por el momento.", True
    Exit Sub
  
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
   ' If usr.NickName = "Zoltar" And NiCKBot.getNickStatus(usr) = nckstIdentifiedByPassword Then
   '   IRC.rawOutput Mid(text, 5) & vbCrLf
   ' End If
    
  Case "FOLK"
    'If usr.NickName = "Zoltar" And NiCKBot.getNickStatus(usr) = nckstIdentifiedByPassword Then
    '  Dim wcl As WitClient
    '  For Each wcl In frmWit.clients
    '    wcl.IRC.rawOutput Mid(text, 6) & vbCrLf
    '  Next
    'End If
 

  Case "CAPTURE"
    Set DCCCapture = New DccChat
    Set DCCCapture.gUsr = usr
    DCCCapture.startDCC
    
  Case "WITMODE"
    ProcessWitMode fword, text, usr


  Case "JOIN"
    cmd_JOIN usr, text, fword
  

  Case "GOTO"
    If UBound(fword) < 1 Then
      usr.DCCMessage "Sintaxis incorrecta. GOTO #canal", True
      Exit Sub
    End If
    
    If Left(fword(1), 1) <> "#" Then
      usr.DCCMessage "Error de sintaxis: Le falta la # al canal.", True
      Exit Sub
    End If
    
    If Not chWit.joined Then
      usr.DCCMessage "GOTO desactivado hasta que vuelva a #WitClub", True
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
    
    Dim ble As BanListEntry
    
    Set ble = frmWit.BanList.getBanStatus(IRC.getChannel(fword(1)))
    
    If Not ble Is Nothing Then
      chWit.say "No puedo ir al canal " & fword(1) & ". El canal tiene un WIT-BAN por " & ble.Author & " hasta " & ble.DateEnd & " -> " & ble.Reason
      Exit Sub
    End If
      
    
    If getChannelCount(IRC) = 1 Then
      chWit.say usr.nickName & " me envía a " & fword(1)
    Else
      chWit.part usr.nickName & " me envía a " & fword(1)
    End If
    
    'IRC.joinChannel fword(1)
    joinChannel fword(1)
    
    Dim tj As TJoinOnInvite
    Set tj = New TJoinOnInvite
    tj.initialize Me, IRC.getChannel(fword(1)), usr, tjSentByWitOp
    
    LogLine "GOTO", usr.nickName & " sent " & IRC.nick & " to channel " & fword(1)


  
  Case "ISEXCLUSIVE"
    cmd_isExclusive usr, text, fword
  
  Case "LEAVE"
    cmd_leaveChannel usr, text, fword
    
  Case "WITBAN-ADD"
    cmd_WitBanADD usr, text, fword
    
  Case "WITBAN-DEL"
    cmd_WitBanDEL usr, text, fword
    
  Case "WITBAN-LIST"
    cmd_WitBanLIST usr, text, fword
    
  Case "WHERE"
    cmd_Where usr, text, fword
    
  Case "GETIP"
    cmd_GetIP usr, text, fword
  
  Case "IPBAN-ADD"
    cmd_IPBanADD usr, text, fword
  
  Case "IPBAN-DEL"
    cmd_IPBanDEL usr, text, fword
  
  Case "IPBAN-LIST"
    cmd_IPBanLIST usr, text, fword
  
    
  Case "DATE"
    usr.DCCMessage "La hora en el servidor es " & Now

    
  Case "LOGIN"
  
    cmd_login usr, text, fword
  
  
  Case "PORRA"
    cmd_porra usr, text, fword
  
  Case "TRIVIAL"
  
    cmd_trivial usr, text, fword



  Case "CYL"
    If UBound(fword) < 1 Then
      usr.DCCMessage "Sintaxis incorrecta. Escribe HELP", True
      Exit Sub
    End If
    
    
    Set wch = WitChannels(fword(1))
   
    
    If wch Is Nothing Then
      usr.DCCMessage "Primero debo estar en el canal " & fword(1) & ". Invítame allí con el comando /invite " & IRC.nick & " " & fword(1) & ". Recuerda que sólo un OP de ese canal me puede invitar.", True
      usr.DCCMessage "Ve a http://www.peletier.com/trivial/WitSummon , donde podrás bajarte tu propio bot.", True
      usr.DCCMessage "Entra en el canal #WitClub para más información.", True
      Exit Sub
    Else
      If wch.myChannel Is chWit Then
        wch.myChannel.say usr.nickName & " ha intentado crear una partida en #WitClub... :P"
        Exit Sub
      End If
    
    
    
      np = 20
      If UBound(fword) >= 2 Then
        If IsNumeric(fword(2)) Then
          np = Val(Mid(fword(2), 1, 4))
        Else
          If UCase(fword(2)) = "STOP" Then
            If wch.CYLRunning Then
              If isOperator(usr, wch.myChannel) Then
                wch.stopCYL mircColorText("--- Partida detenida por " & mircUnderlineText(usr.nickName) & " ---", mccDarkRed)
              Else
                usr.DCCMessage "Sólo un operador (@) de " & wch.myChannel.Name & " puede detener la partida.", True
              End If
            Else
              usr.DCCMessage "No hay ninguna partida activa en " & wch.myChannel.Name, True
            End If
              
              
              
              Exit Sub
            End If
        End If
      End If
          
      If np > 30 Then
        usr.DCCMessage "El máximo son 30 desafíos", True
      Else
        If IRC.Properties("SIMTRIVIAL") < 2 Then
          wch.runCYL usr, np
        Else
          usr.DCCMessage "Estoy en demasiados juegos. Inténtalo de nuevo más tarde o mira en " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/WitSummon", mccPureBlue)) & " para solucionar este problema.", True
        End If
      End If
    End If




      
  End Select



End Sub


Private Sub DCCs_OnMessage(Index As Long, Source As jIRCLib.DccChat, text As String)
  

ProcessConsoleCMDs text, Source.gUsr


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

ub = UBound(fword)



Select Case UCase(fword(1))

  Case "OPCONTROL"
      If ub = 1 Then
        usr.DCCMessage "OPCONTROL WITMODE IS " & OnOffMode(flags And WITMODE_OPCONTROL_MASK)
      Else
        ToggleMode flags, WITMODE_OPCONTROL_MASK, "OPControl", UCase(fword(2)) = "ON", usr
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






Private Sub DCCs_OnTimeout(Index As Long, Source As jIRCLib.DccChat)
  DCCs.col.RemoveByIndex Index
End Sub

Private Sub IRC_LíneaRecibida(ByVal Línea As String)
  If Not DCCCapture Is Nothing Then
    DCCCapture.say Línea
  End If
  
  alive = True
  
End Sub

Private Sub IRC_OnConnect()
  IRC.MaxOutputDataRate = 60
  
  Set chWit = IRC.getChannel("#WitClub")

End Sub

Private Sub IRC_OnDccChatRequest(DccChatObject As jIRCLib.DccChat)

  DCCs.col.Add DccChatObject
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
    frmWit.clients.Remove Key
    IRC.Destroy
    Set IRC = Nothing
    
  Else
    Set reconnectTimer = New CTimer
    reconnectTimer.TimeScale = TU_Minutes
    reconnectTimer.Interval = 2
  End If
  
  
End Sub

Private Sub IRC_OnEndOfMOTD()
  Set NiCKBot = New NiCKBot
  NiCKBot.initialize IRC
  Set CHaNBot = New CHaNBot
  CHaNBot.initialize IRC
  
  Set reconnectTimer = Nothing

 
' NiCKBot.identify password


Dim v As Variant
For Each v In OnJoinChannels
  joinChannel "" & v
Next

If Not exclusive Then
    joinChannel chWit.Name
End If

End Sub

Private Sub IRC_OnInvite(cChannel As jIRCLib.Channel, cUser As jIRCLib.GlobalUser)
    
'comando deshabilitado
Exit Sub
    
    
    If getChannelCount(IRC) < 2 Then
    
      Dim jin As TJoinOnInvite
      Set jin = New TJoinOnInvite
      jin.initialize Me, cChannel, cUser
    
    
    Else
      cUser.privateMessage "Estoy en demasiados canales. Para solucionar este problema, visita " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/WitSummon", mccPureBlue))
    End If
End Sub

Private Sub IRC_OnJoin(nChannel As jIRCLib.Channel, gU As jIRCLib.GlobalUser)
    
If Left(nChannel.Name, 1) <> "#" Then Exit Sub
    
'If LCase(nChannel.name) = "#wit" Then
'  nChannel.part "Lo siento, soy alérgico a este canal."
'  Exit Sub
'End If

If LCase(nChannel.Name) = "#usa" Then
  nChannel.part "annoying autojoin"
  Exit Sub
End If


If gU Is IRC.self Then

  
  If Not Network.JoinFree Then
    
    Dim notAllowedChannel As Boolean
    notAllowedChannel = ObjectExistsInCollection(allowedChannels, LCase(nChannel.Name)) Is Nothing
  
    If notAllowedChannel Then
      Debug.Print nChannel.Name & " not added to allowedChannels. " & IRC.nick
      
      frmWit.ipBanList.Add IRC.remoteAddress, "WitSummon modificado: entrar en canales no permitidos.", "Wit"
      Exit Sub
    End If
   
    allowedChannels.Remove LCase(nChannel.Name)
  
  End If
  
End If


If nChannel Is chWit And Not IsNull(IRC.Properties("WITMSG")) Then
  chWit.say IRC.Properties("WITMSG")
  IRC.Properties("WITMSG") = Null
End If
  

If frmWit.BanList.partIfBanned(nChannel) Then
  Exit Sub
End If
  
    
    If gU Is IRC.self Then
      IRC.getUser("chan").privateMessage "OP " & nChannel.Name & " " & IRC.nick
    End If
    

  WitChannels.Add nChannel, NiCKBot, Me


    
End Sub

Private Sub IRC_OnLeave(nChannel As jIRCLib.Channel, gU As jIRCLib.GlobalUser, kickedBy As jIRCLib.GlobalUser, Reason As String)
  
  If gU Is IRC.self Then
    Dim WChn As WitChannel
    Set WChn = WitChannels(nChannel.Name)
    
    If Not WChn Is Nothing Then
      WChn.Terminate
      WitChannels.Remove nChannel
    End If
      
    If Not (nChannel Is chWit) Then
      joinChannel chWit.Name
    End If
  End If
  
  If nChannel.Users.Count <= 1 Then
    Dim v As Variant
    For Each v In OnJoinChannels
      If UCase(v) = UCase(nChannel.Name) Then
        Exit Sub
      End If
    Next
    
    nChannel.part
  End If
  
  
  
End Sub

Private Sub IRC_OnLineOut(line As String, cancel As Boolean)

line = Replace(line, "5757", "57**")

End Sub

Private Sub IRC_OnNickChange(gU As jIRCLib.GlobalUser, ByVal newNick As String)
If gU Is IRC.self Then

  If newNick <> initialNick Then
    'un listo ha cambiado de nick. Iniciar tarea de autoipban
    Dim t As TAutoIPBan
    Set t = New TAutoIPBan
    t.initialize IRC
  End If

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
  checkConnection.Interval = 8
 
  mAutoReconnect = True
  
  IRC.Properties("IDNetwork") = IDN_DEFAULT
 
End Sub

Public Property Get Network() As IRCNetwork
  Set Network = getNetworkFromIRClient(IRC)
End Property

Public Property Set Network(nt As IRCNetwork)
  IRC.Properties("IDNetwork") = nt.IDNetwork
End Property

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



Private Sub cmd_leaveChannel(usr As GlobalUser, text As String, fword() As String)
    
If Not isAdmin(usr) Then
    If UBound(fword) < 1 Then
      usr.DCCMessage "Sintaxis incorrecta. LEAVE #channel [razón]", True
      Exit Sub
    End If
    
    Dim acl As AccessList
    Set acl = frmWit.getWitClubAccessList(Me, usr)
    
    If Not acl.ready Then
      Exit Sub
    End If
    
    If acl.level(usr.nickName) < 300 Then
      usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
      Exit Sub
    End If
End If

Dim Reason As String

If UBound(fword) >= 1 Then
  Reason = textBeyondWord(1, fword, text)
End If

Dim ch As Channel

Set ch = IRC.getChannel(fword(1))
ch.part (Reason)

LogLine "LEAVE", usr.nickName & " forced " & IRC.nick & " to leave channel " & fword(1)
    
    
   
End Sub

Private Sub cmd_isExclusive(usr As GlobalUser, text As String, fword() As String)
    
    Dim acl As AccessList
    Set acl = frmWit.getWitClubAccessList(Me, usr)
    
    If Not acl.ready Then
      Exit Sub
    End If
    
    If acl.level(usr.nickName) < 300 Then
      usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
      Exit Sub
    End If
    
    Dim st As String
    If exclusive Then
        st = ""
    Else
        st = "NO "
    End If
    
    usr.privateMessage IRC.nick & " " & st & "es un bot en modo exclusivo."
    
    
  LogLine "ISEXCLUSIVE", "Query by " & usr.nickName & " on " & IRC.nick
    
    
    
End Sub



Private Sub cmd_WitBanADD(usr As GlobalUser, text As String, fword() As String)

'WITBAN #channel duration reason

  If UBound(fword) < 3 Then
    usr.DCCMessage "Sintaxis: WITBAN-ADD #canal días:horas:minutos razón", True
    Exit Sub
  End If

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If

  If Left(fword(1), 1) <> "#" Then
    usr.DCCMessage "Error de sintaxis: Le falta la # al canal.", True
    Exit Sub
  End If

  Dim tm() As String
  
  tm = Split(fword(2), ":", 3, vbBinaryCompare)
  If UBound(tm) < 2 Then
    usr.DCCMessage "Formato de tiempo incorrecto. Utiliza el formato días:horas:minutos", True
    Exit Sub
  End If
  
  If (Not IsNumeric(tm(0))) Or (Not IsNumeric(tm(1))) Or (Not IsNumeric(tm(2))) _
    Or (Len(tm(0)) > 6) Or (Len(tm(1)) > 2) Or (Len(tm(2)) > 2) Then
    usr.DCCMessage "Formato de tiempo incorrecto. Utiliza el formato días:horas:minutos", True
    Exit Sub
  End If
  
  Dim mins As Long
  Dim hours As Long
  Dim days As Long
  
  mins = CLng(tm(2))
  hours = CLng(tm(1))
  days = CLng(tm(0))
  
  If (mins > 59 Or mins < 0 Or hours > 23 Or hours < 0 Or days < 0) Then
    usr.DCCMessage "Formato de tiempo incorrecto. Utiliza el formato días:horas:minutos", True
    Exit Sub
  End If

  Dim DateEnd  As Date
  
  DateEnd = Now
  DateEnd = DateAdd("d", days, DateEnd)
  DateEnd = DateAdd("h", hours, DateEnd)
  DateEnd = DateAdd("n", mins, DateEnd)
  
  Dim Reason As String
  
  Reason = textBeyondWord(2, fword, text)
  frmWit.BanList.Add IRC.getChannel(fword(1)), DateEnd, Now, Reason, usr.nickName
  
  usr.notice "Canal " & fword(1) & ": WIT-BAN hasta " & DateEnd
  
  LogLine "WITBAN-ADD", usr.nickName & " set a WIT-BAN on channel " & fword(1) & " until " & DateEnd
  

End Sub


Private Sub cmd_WitBanDEL(usr As GlobalUser, text As String, fword() As String)

  If UBound(fword) < 1 Then
    usr.DCCMessage "Sintaxis: WITBAN-DEL #canal", True
    Exit Sub
  End If

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If

  If Left(fword(1), 1) <> "#" Then
    usr.DCCMessage "Error de sintaxis: Le falta la # al canal.", True
    Exit Sub
  End If
  
  frmWit.BanList.Remove fword(1), IRC.Properties("IDNetwork")
  
  usr.DCCMessage "El WIT-BAN sobre " & fword(1) & " ha sido eliminado.", True

  LogLine "WITBAN-DEL", usr.nickName & " removed the WIT-BAN on channel " & fword(1)


End Sub


Private Sub cmd_WitBanLIST(usr As GlobalUser, text As String, fword() As String)

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If


  Dim ble As BanListEntry
  
  usr.DCCMessage "La hora actual es " & Now & ". Lista de WIT-BANs:", True
  usr.DCCMessage "canal autor (fecha inicio) -> (fecha fin) razón", True
  
  For Each ble In frmWit.BanList
    If ble.DateEnd > Now Then
      usr.DCCMessage ble.channelName & " " & ble.Author & " (" & ble.DateInit & ") -> (" & ble.DateEnd & ") " & ble.Reason, True
    End If
  Next
  
  usr.DCCMessage "WITBAN-LIST END", True
  
  

End Sub

Private Sub cmd_Where(usr As GlobalUser, text As String, fword() As String)

If Not isAdmin(usr) Then
  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If
End If

  Dim IDNetwork As Long
  IDNetwork = IRC.Properties("IDNetwork")
  Dim n As Long
  Dim wcl As WitClient
  Dim ch As Channel
  Dim col As Collection
  Dim cp As CProperty
  
  Set col = New Collection
  
  For Each wcl In frmWit.clients
    For n = 1 To wcl.IRC.channels.col.Count
      Set ch = wcl.IRC.channels.col(n)
      If ch.parent.Properties("IDNetwork") = IDNetwork Then
        Set cp = ObjectExistsInCollection(col, ch.Name)
        
        If cp Is Nothing Then
          Set cp = New CProperty
          cp.Key = ch.Name
          cp.value = ""
          col.Add cp, cp.Key
        End If
        
        If cp.value <> "" Then
          cp.value = cp.value & ", "
        End If
        
        If wcl.exclusive Then
            cp.value = cp.value & mircBoldText(wcl.IRC.nick)
        Else
            cp.value = cp.value & wcl.IRC.nick
        End If
            
      End If
    Next
  Next

  usr.privateMessage "Canales en los que está Wit: (bots exclusivos en " & mircBoldText("negrilla") & ")"

  For Each cp In col
    usr.privateMessage cp.Key & ": " & cp.value
  Next
  
  usr.privateMessage "WHERE_END"
    

End Sub

Private Sub cmd_GetIP(usr As GlobalUser, text As String, fword() As String)

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If

  If UBound(fword) < 1 Then
    usr.DCCMessage "Sintaxis: GETIP <wit-nick>", True
    Exit Sub
  End If
  

  Dim wcl As WitClient
  
  For Each wcl In frmWit.clients
    If LCase(wcl.IRC.nick) = LCase(fword(1)) Then
      usr.DCCMessage "La IP de " & wcl.IRC.nick & " es " & wcl.IRC.remoteAddress, True
      LogLine "GETIP", usr.nickName & " obtained IP from " & wcl.IRC.nick & "=" & wcl.IRC.remoteAddress
      Exit Sub
    End If
  Next
  

  usr.DCCMessage "No encuentro a " & fword(1)
   

End Sub


Private Sub cmd_IPBanADD(usr As GlobalUser, text As String, fword() As String)

'IPBAN-ADD IP reason

  If UBound(fword) < 2 Then
    usr.DCCMessage "Sintaxis: IPBAN-ADD IP razón", True
    Exit Sub
  End If

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If

  
  Dim Reason As String
  
  Reason = textBeyondWord(1, fword, text)
  
  
  Dim st As String
  
  Dim wcl As WitClient
  
  For Each wcl In frmWit.clients
    If wcl.IRC.remoteAddress = fword(1) Then
      st = st & wcl.IRC.nick & " "
    End If
  Next
  
  If st = "" Then st = "ninguno."
  
  frmWit.ipBanList.Add fword(1), Reason, usr.nickName
  
  usr.notice "IP " & fword(1) & " prohibida a partir de ahora. Bots desconectados con esa IP: " & st
  
  LogLine "IPBAN-ADD", usr.nickName & " set IP-BAN on " & fword(1) & ". Disconnected bots: " & st
  

End Sub


Private Sub cmd_IPBanDEL(usr As GlobalUser, text As String, fword() As String)

  If UBound(fword) < 1 Then
    usr.DCCMessage "Sintaxis: IPBAN-DEL IP", True
    Exit Sub
  End If

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If

  
  frmWit.ipBanList.Remove fword(1)
  
  usr.DCCMessage "El IP-BAN sobre " & fword(1) & " ha sido eliminado.", True
  
  LogLine "IPBAN-DEL", usr.nickName & " removed IPBAN on " & fword(1)

End Sub


Private Sub cmd_IPBanLIST(usr As GlobalUser, text As String, fword() As String)

  Dim acl As AccessList
  Set acl = frmWit.getWitClubAccessList(Me, usr)
    
  If Not acl.ready Then
    Exit Sub
  End If
  
  If acl.level(usr.nickName) < 300 Then
    usr.notice "No estás en la lista de acceso de #WitClub o no puedo verla."
    Exit Sub
  End If


  Dim ble As IPBanListEntry
  
  usr.DCCMessage "La hora actual es " & Now & ". Lista de IP-BANs:", True
  usr.DCCMessage "IP autor (fecha inicio) razón", True
  
  For Each ble In frmWit.ipBanList
    usr.DCCMessage ble.IP & " " & ble.Author & " (" & ble.DateInit & ") " & ble.Reason, True
  Next
  
  usr.DCCMessage "IPBAN-LIST END", True

End Sub


Private Sub cmd_JOIN(usr As GlobalUser, text As String, fword() As String)
    
  If Not Network.AllowJOIN_SC Then
    usr.DCCMessage "Comando no soportado en esta red. (" & Network.Name & ")"
    Exit Sub
  End If
   
   
   
 If Network.JoinFree Then
     
           If UBound(fword) < 1 Then
            usr.DCCMessage "Sintaxis incorrecta. JOIN #canal", True
            Exit Sub
           End If
           
          If Left(fword(1), 1) <> "#" Then
            usr.DCCMessage "Error de sintaxis: Le falta la # al canal.", True
            Exit Sub
          End If
          
          Dim c As Channel
          
          Set c = IRC.getChannel(fword(1))
          
          joinChannel c.Name 'para evitar la protección de ataque por cmd JOIN
        
     
 Else
   
    
          If UBound(fword) < 2 Then
            usr.DCCMessage "Sintaxis incorrecta. JOIN #canal código_secreto", True
            usr.DCCMessage "Para obtener tu código secreto, envía el mensaje PELE WITPROPIO al 5015. Más información en http://www.peletier.com/trivial/miWit", True
            Exit Sub
          End If
            
          If Left(fword(1), 1) <> "#" Then
            usr.DCCMessage "Error de sintaxis: Le falta la # al canal.", True
            Exit Sub
          End If
        
         
          If Not IsNumeric(fword(2)) Then
            usr.DCCMessage "Código secreto escrito incorrectamente", True
            Exit Sub
          End If
          
        
          Dim n As Long
          Dim rc As New Recordset
          Dim lastIdChannel As Long
          Dim lastChannelName As String
          n = CLng(Mid(fword(2), 1, 8))
            
          CheckManagementConnection
          rc.Open "SELECT MyWits.DateEnd, MyWits.IDChannel,Channels.Name as ChannelName from mywits LEFT OUTER JOIN " & _
                  "Channels ON MyWits.IDChannel = Channels.IdChannel " & _
                  "WHERE MyWits.SecretCode = " & n & _
                  " AND MyWits.DateEnd > '" & Now & "'", CnMgt, adOpenStatic, adLockOptimistic
           
          If rc.EOF Then
            usr.DCCMessage "Código secreto caducado o incorrecto.", True
            Exit Sub
          End If
  
            Dim IDChannel As Long
            Dim IDTournament As Long
            Dim ch As Channel
            Set ch = IRC.getChannel(fword(1))
            
            Dim isnew As Boolean
            If getIDChannelIDTournament(ch, CnMgt, IDChannel, IDTournament, isnew) = False Then
              usr.DCCMessage "Error al asignar canal.", True
              Exit Sub
            End If
            
            CnMgt.Execute "UPDATE MyWits SET IDChannel=" & IDChannel & " Where secretcode=" & n
            
            Dim tj As New TJoinOnInvite
            tj.initialize Me, ch, usr
            
            usr.notice "Entrando en el canal " & ch.Name & "..."
            
            
            '¿Existe algún código no caducado para el anterior IDChannel?
            If Not IsNull(rc!IDChannel) Then
            
              lastChannelName = rc!channelName
            
              lastIdChannel = rc!IDChannel
              rc.Close
              
              rc.Open "SELECT MyWits.DateEnd, MyWits.IDChannel " & _
                      "FROM MyWits WHERE (MyWits.DateEnd > '" & Now & "') AND " & _
                      "(MyWits.IDChannel = " & lastIdChannel & ")"
            
              If rc.EOF Then
                leaveChannel "" & lastChannelName, "Utiliza el comando /MSG " & IRC.nick & " JOIN para traerme de vuelta."
              End If
              
            End If
            rc.Close
    
 End If 'isfree
    
End Sub


Function validate_cmd_trivial(usr As GlobalUser, text As String, fword() As String, offset As Long, ByRef wch As WitChannel, ByRef np As Long) As Boolean

validate_cmd_trivial = False
    
    If UBound(fword) < 1 + offset Then
      usr.DCCMessage "Sintaxis incorrecta. Escribe HELP", True
      Exit Function
    End If
    
    Set wch = WitChannels(fword(1 + offset))
       
    
    If wch Is Nothing Then
      usr.DCCMessage "Primero debo estar en el canal " & fword(1 + offset), True '& ". Invítame allí con el comando /invite " & IRC.nick & " " & fword(1+ offset) & ". Recuerda que sólo un OP de ese canal me puede invitar.", True
      usr.DCCMessage "Ve a http://www.peletier.com/trivial/WitSummon , donde podrás bajarte tu propio bot.", True
      usr.DCCMessage "Entra en el canal #WitClub para más información.", True
      Exit Function
    Else
      If wch.myChannel Is chWit Then
        wch.myChannel.say usr.nickName & " ha intentado crear una partida en #WitClub... :P"
        Exit Function
      End If
    
    
    
      np = 20
      If UBound(fword) >= 2 + offset Then
        If IsNumeric(fword(2 + offset)) Then
          np = Val(Mid(fword(2 + offset), 1, 4))
        Else
          If UCase(fword(2 + offset)) = "STOP" Then
            If wch.trivial2Running Then
              If isOperator(usr, wch.myChannel) Then
                wch.stopTrivial2 mircColorText("--- Partida detenida por " & mircUnderlineText(usr.nickName) & " ---", mccDarkRed)
              Else
                usr.DCCMessage "Sólo un operador (@) de " & wch.myChannel.Name & " puede detener la partida.", True
              End If
            Else
              usr.DCCMessage "No hay ninguna partida activa en " & wch.myChannel.Name, True
            End If
              
              Exit Function
            End If
        End If
      End If
          
      If np > 30 Then
        usr.DCCMessage "El máximo son 30 preguntas", True
      Else
        If IRC.Properties("SIMTRIVIAL") < 2 Then
          validate_cmd_trivial = True
        Else
          usr.DCCMessage "Estoy en demasiados trivials. Inténtalo de nuevo más tarde o mira en " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/WitSummon", mccPureBlue)) & " para solucionar este problema.", True
        End If
      End If
    End If


End Function


Private Sub cmd_login(usr As GlobalUser, text As String, fword() As String)

If UBound(fword) < 2 Then
    usr.DCCMessage "Sintaxis incorrecta: LOGIN user password", True
    Exit Sub
End If

Dim username As String
Dim password As String
Dim IDUser As Long

username = Left(fword(1), 75)
password = Left(fword(2), 25)

IDUser = login(username, password)

If IDUser = 0 Then
    usr.DCCMessage "Nombre de usuario o contraseña incorrecto.", True
    usr.DCCMessage "Debes usar tu nombre de usuario y contraseña de peletier.com. Regístrate en http://www.peletier.com/forum/register.asp", True
    usr.DCCMessage "Tu registro en peletier.com es independiente del nick que uses en IRC", True
    Exit Sub
End If

usr.Properties("IDUser") = IDUser

usr.notice "Validación correcta."


End Sub


Private Sub cmd_trivial(usr As GlobalUser, text As String, fword() As String)
    
    Dim wch As WitChannel
    Dim np As Long
    
    'devuelve np y wch
    If validate_cmd_trivial(usr, text, fword(), 0, wch, np) = False Then Exit Sub
    
    wch.runTrivial2 usr, np
    
End Sub



Private Sub cmd_porra(usr As GlobalUser, text As String, fword() As String)

'PORRA 100 TRIVIAL #wit-beta 5

If UBound(fword) < 4 Then
    usr.DCCMessage "Sintaxis incorrecta. Escribe HELP", True
    Exit Sub
End If

If Not IsNumeric(fword(1)) Then
    usr.DCCMessage "Sintaxis incorrecta. Escribe HELP", True
    Exit Sub
End If

Dim amount As Long
Dim wch As WitChannel
Dim np As Long

amount = Abs(Val(Mid(fword(1), 1, 4))) 'evitar números grandes
    
validate_cmd_trivial usr, text, fword, 2, wch, np
    
If wch Is Nothing Then Exit Sub

    
wch.runPorraTrivial amount, usr, np


End Sub









Private Function textBeyondWord(lastword As Long, fword() As String, text As String)

Dim ln As Long
Dim n As Long

If n > UBound(fword) Then
  textBeyondWord = ""
  Exit Function
End If


For n = 0 To lastword
  ln = ln + 1 + Len(fword(n))
Next

textBeyondWord = Mid(text, ln + 1)


End Function



Public Sub joinChannel(Channel As String)

On Error Resume Next
allowedChannels.Add frmWit, LCase(Channel)
IRC.joinChannel LCase(Channel)

End Sub

Public Sub leaveChannel(Channel As String, msg As String)

On Error Resume Next
allowedChannels.Remove LCase(Channel)
IRC.leaveChannel Channel, msg


End Sub




