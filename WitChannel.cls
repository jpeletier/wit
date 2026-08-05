VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "WitChannel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
Option Compare Text
Public WithEvents myChannel As jIRCLib.Channel
Attribute myChannel.VB_VarHelpID = -1

Private WithEvents trivial2 As TriviaGame2
Attribute trivial2.VB_VarHelpID = -1
Private WithEvents CYL As CYLGame
Attribute CYL.VB_VarHelpID = -1
Private WithEvents Porra As PorraGame
Attribute Porra.VB_VarHelpID = -1

Private ChannelCtrl As IChannelControl
Private NiCKBot As NiCKBot

Private WithEvents mClient As WitClient
Attribute mClient.VB_VarHelpID = -1
Private WithEvents gInfo As GlobalInfo
Attribute gInfo.VB_VarHelpID = -1

Private autoplayGame As Long
Private autoplayParameters As String



Public Property Get game() As TriviaGame2
  Set game = trivial2
End Property


Public Property Get trivial2Running() As Boolean
  trivial2Running = Not (trivial2 Is Nothing)
End Property

Public Property Get CYLRunning() As Boolean
  CYLRunning = Not (CYL Is Nothing)
End Property

Public Property Get PorraRunning() As Boolean
    PorraRunning = Not (Porra Is Nothing)
End Property

Public Property Get gameRunning() As Boolean
    gameRunning = trivial2Running Or CYLRunning Or PorraRunning
End Property



Public Sub stopTrivial2(Reason As String)
  If Not trivial2Running Then Exit Sub
  Set trivial2 = Nothing
  myChannel.say Reason
End Sub

Public Sub stopCYL(Reason As String)
  If Not CYLRunning Then Exit Sub
  Set CYL = Nothing
  myChannel.say Reason
End Sub

Public Sub Terminate()
  If Not myChannel Is Nothing Then
    myChannel.part
  End If
  
  Set myChannel = Nothing
  Set trivial2 = Nothing
  Set ChannelCtrl = Nothing
  Set mClient = Nothing
  
  Debug.Print "WitChannel.Terminate()"
  
  
End Sub




Public Sub initialize(ch As Channel, xNickBot As NiCKBot, xClient As WitClient)
Set myChannel = ch
Set NiCKBot = xNickBot
Set gInfo = Utils.gInfo

Set mClient = xClient

'Select Case myChannel.name

'  Case "#trivialeros", "#el_mirador"
'    Set ChannelCtrl = New CTrivCtrl
'    ChannelCtrl.initialize myChannel, TrivialDatabase, NiCKBot
    

'End Select



End Sub

Private Sub Class_Initialize()
    autoplayGame = -1
End Sub

Private Sub Class_Terminate()
  If Not myChannel Is Nothing Then
    myChannel.part
  End If
  Debug.Print "WitChannel Class_Terminate()"
End Sub

Private Sub CYL_gameOver()
  Set CYL = Nothing
End Sub

Private Sub mClient_OnDisconnect()


If Me.trivial2Running Then
  Utils.gInfo.notifyDisconnectedWhilePlaying mClient, trivial2
End If


End Sub

Private Sub gInfo_OnDisconnectedWhilePlaying(Client As WitClient, game As TriviaGame2)

'Este evento también es "emulado" cuando se detecta un Quit

If (Client Is mClient) Or (game Is Nothing) Or (myChannel Is Nothing) Then
  Exit Sub
End If
 

 
If (LCase(game.gameChannel.Name) = LCase(myChannel.Name)) And (trivial2 Is Nothing) And (Val(myChannel.parent.Properties("SIMTRIVIAL")) <= 1) Then
  
  
  myChannel.say "¡Que no panda el cúnico!. " & Client.IRC.nick & " se ha desconectado, pero sigo yo la partida. Aquí no ha pasado nada, ¡circulen!, ¡circulen!."
  
  game.changeBot mClient, myChannel ' <-- aquí dentro se levanta OnGameOver, que a su vez hace set trivial2=nothing
  
  Set trivial2 = game
  Set game = Nothing  ' = "Yo me encargo"
  
  
End If





End Sub

Private Sub runAutoPlay()

If autoplayGame <> WITGAME_TRIVIA Then Exit Sub


runTrivial2 myChannel.parent.self, Val(autoplayParameters)


End Sub


Private Sub myChannel_OnJoin(who As jIRCLib.User, cancel As Boolean)
  If who.gUsr Is myChannel.parent.self Then
  
    'myChannel.parent.getChannelNames myChannel.Name
    
    
      
    Exit Sub
  End If
  
  
If who.gUsr.realName = "" Then
    myChannel.parent.whois who.nickName
End If


  
  
  
  If LCase(myChannel.Name) = "#witclub" And myChannel.parent.nick <> "Wit" Then Exit Sub
  
  Dim id As String
  Dim def As String
  id = who.nickName
  def = LocateFirstDef(id, id)
  
  If def <> "" Then
    myChannel.action "saluda a " & id & ", " & def
  End If
  
  'If who.NickName = "Zoltar" And who.userName = "er" Then
    'Debug.Print who.userName
    'who.operator = True
  'End If
  
 
    
If Int(Rnd * 100) < 10 Then
  who.gUsr.notice "Bienvenido a " & myChannel.Name & ". Para obtener ayuda, escribe /msg " & myChannel.parent.nick & " HELP"
End If

End Sub

Private Sub MyChannel_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)
  
  If LCase(myChannel.Name) = "#witclub" Then Exit Sub
  
  
  'myChannel.say "Realname de " & who.nickName & " es '" & who.gUsr.realName & "'"

  
  
  If (IsNumeric(Left(text, 1)) Or Left(text, 1) = "?") And trivial2 Is Nothing And CYL Is Nothing Then
    Dim tirada As String
    If Left(text, 1) = "?" Then text = Mid(text, 2)
    tirada = superCalc(text)
    If tirada <> "" And (text <> tirada Or Left(text, 1) = "?") Then
      myChannel.say who.nickName & ": " & text & "=" & tirada
    End If
  Else
      Dim id As String
      Dim def As String
    
    If Left(text, 1) = "(" And Right(text, 1) = ")" Then
      id = Mid(text, 2, Len(text) - 2)
      def = LocateFirstDef(id)
    Else
      If Left(text, 1) = "[" And Right(text, 1) = "]" Then
        id = Mid(text, 2, Len(text) - 2)
        def = LocateRandomDef(id)
      End If
    End If
    
    If def <> "" Then
      myChannel.say id & ": " & def
    End If
    
  End If

End Sub


Private Sub myChannel_OnNames()

If myChannel Is mClient.chWit Then Exit Sub

If getNetworkFromIRClient(myChannel.parent).IDNetwork = IDN_ZONAGURU_COM Then

    Dim u As User
    For Each u In myChannel.Users
        If u.gUsr.realName = "" Then
            myChannel.parent.whois u.nickName
        End If
    Next
End If


If autoplayGame = -1 Then
    autoplayGame = 0
    Dim d As Scripting.Dictionary
    Dim st() As String
    If myChannel.parent.Properties.Exists("AUTOPLAY") Then
        Set d = myChannel.parent.Properties("AUTOPLAY")
        If d.Exists(LCase(myChannel.Name)) Then
            st = Split(d(LCase(myChannel.Name)), ",")
            If UBound(st) = 1 Then
                Select Case st(0)
                    Case "trivial"
                        autoplayGame = WITGAME_TRIVIA
                    Case "cyl"
                        autoplayGame = WITGAME_CYL
                    Case Else
                        autoplayGame = 0
                End Select
                autoplayParameters = st(1)
            End If
        End If
          
          
        
        runAutoPlay
    
    End If
End If


'Detector de clones desactivado

Exit Sub

Dim clones As Long

Dim usr As User
Dim ln As Long
For Each usr In myChannel.Users
  ln = Len(usr.nickName)
  If ln >= 3 Then
    If ln <= 4 And LCase(Left(usr.nickName, 3)) = "wit" Then
      clones = clones + 1
    Else
      If LCase(Right(usr.nickName, 3)) = "wit" Then
        clones = clones + 1
      End If
    End If
  End If
Next

If clones > 2 Then
  myChannel.part "Demasiados clones de Wit en este canal (" & clones - 1 & ")"
  mClient.IRC.Properties("WITMSG") = "He tenido que abandonar " & myChannel.Name & ". Había demasiados clones."
End If


End Sub

Private Sub MyChannel_OnUserLeave(who As jIRCLib.User, kickedBy As jIRCLib.GlobalUser, Reason As String, cancel As Boolean)
  If who.gUsr Is myChannel.parent.self Then
    If Not kickedBy Is Nothing Then
      'myChannel.parent.getUser("Zoltar").notice kickedBy.NickName & " me ha echado de " & myChannel.Name
    End If
  End If
  
   
   If mClient.Network.AllowJOIN_SC Then
     If myChannel.Users.Count <= 1 Then
        myChannel.part ("Me aburro aquí yo solo")
     End If
   End If
        
   
   
   
End Sub


Public Function runTrivial2(starter As GlobalUser, np As Long) As Boolean

If Not gameRunning Then
  starter.notice "Trivial2 iniciado en " & myChannel.Name
  Set trivial2 = New TriviaGame2
  trivial2.initialize Me.myChannel, starter, np, TrivialDatabase
  runTrivial2 = True
End If
  
End Function

Public Function runCYL(starter As GlobalUser, np As Long) As Boolean

If Not gameRunning Then
  starter.notice "Cifras y Letras iniciado en " & myChannel.Name
  Set CYL = New CYLGame
  CYL.initialize Me.myChannel, starter, np, TrivialDatabase
  runCYL = True
End If
  
End Function

Public Function runPorraTrivial(amount As Long, starter As GlobalUser, np As Long) As Boolean

If Not gameRunning Then
  starter.notice "Porra de trivial iniciada en " & myChannel.Name
  Set Porra = New PorraGame
  Porra.initialize New TriviaGame2, amount, starter, np, myChannel
  runPorraTrivial = True
End If

End Function



Private Sub myChannel_OnUserQuit(who As jIRCLib.User, quitMessage As String)

   If mClient.Network.AllowJOIN_SC Then
     If myChannel.Users.Count <= 1 Then
        myChannel.part ("Me aburro aquí yo solo")
     End If
   End If


Exit Sub


If trivial2Running Then Exit Sub 'Si estamos haciendo partida, nos importa un comino que se caiga quien sea

If InStr(1, quitMessage, "hispano", vbTextCompare) > 0 Then Exit Sub 'Pasar de los splits

'¿es un wit?

If InStr(1, who.gUsr.nickName, "wit", vbTextCompare) = 0 Then Exit Sub

'Parece que sí

'buscar el objeto client a ver si está

Dim wcl As WitClient

Dim wclq As WitClient

For Each wcl In frmWit.clients
  If wcl.IRC.nick = who.gUsr.nickName Then
    'Es este
    Set wclq = wcl
    Exit For
  End If
Next wcl

If wclq Is Nothing Then Exit Sub 'Falsa alarma

Dim wch As WitChannel

Set wch = wclq.WitChannels(myChannel.Name)

If wch Is Nothing Then Exit Sub 'Vaya, ahora resulta que no estaba en ese canal ???

If Not wch.trivial2Running Then Exit Sub 'Se ha caído un Wit, pero no estaba con partida.

'O.K. se acaba de caer en medio de una partida, y lo hemos detectado nosotros primero
'Nos cogemos la partida


Dim gm As TriviaGame2
Set gm = wch.game

gInfo_OnDisconnectedWhilePlaying wclq, gm



End Sub

Private Sub Porra_gameOver()
    Set Porra = Nothing
End Sub

Private Sub trivial2_gameOver()
  Set trivial2 = Nothing
  
  If Not ChannelCtrl Is Nothing Then
    ChannelCtrl.DoSomething 1
  End If
  
runAutoPlay
  
End Sub

