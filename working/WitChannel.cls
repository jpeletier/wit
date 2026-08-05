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

Private ChannelCtrl As IChannelControl
Private NiCKBot As NiCKBot

Private WithEvents mClient As WitClient
Attribute mClient.VB_VarHelpID = -1
Private WithEvents gInfo As GlobalInfo
Attribute gInfo.VB_VarHelpID = -1

Public Property Get game() As TriviaGame2
  Set game = trivial2
End Property

Public Property Get trivial2Running() As Boolean
  trivial2Running = Not (trivial2 Is Nothing)
End Property

Public Sub stopTrivial2(reason As String)
  If Not trivial2Running Then Exit Sub
  Set trivial2 = Nothing
  myChannel.say reason
End Sub

Public Sub Terminate()
  If Not myChannel Is Nothing Then
    myChannel.part
  End If
  
  Set myChannel = Nothing
  Set trivial2 = Nothing
  Set ChannelCtrl = Nothing
  Set NiCKBot = Nothing
  Set mClient = Nothing
  
  Debug.Print "WitChannel.Terminate()"
  
  
End Sub




Public Sub initialize(ch As Channel, xNickBot As NiCKBot, xClient As WitClient)
Set myChannel = ch
Set NiCKBot = xNickBot
Set gInfo = Utils.gInfo

Set mClient = xClient

Select Case myChannel.name

  Case "#trivialeros", "#el_mirador"
    Set ChannelCtrl = New CTrivCtrl
    ChannelCtrl.initialize myChannel, TrivialDatabase, NiCKBot
    

End Select



End Sub

Private Sub Class_Terminate()
  If Not myChannel Is Nothing Then
    myChannel.part
  End If
  Debug.Print "WitChannel Class_Terminate()"
End Sub

Private Sub mClient_OnDisconnect()


If Me.trivial2Running Then
  Utils.gInfo.notifyDisconnectedWhilePlaying mClient, trivial2
End If


End Sub

Private Sub gInfo_OnDisconnectedWhilePlaying(client As WitClient, game As TriviaGame2)

'Este evento también es "emulado" cuando se detecta un Quit

If (client Is mClient) Or (game Is Nothing) Then
  Exit Sub
End If
 

 
If (LCase(game.gameChannel.name) = LCase(myChannel.name)) And (trivial2 Is Nothing) And (Val(myChannel.parent.Properties("SIMTRIVIAL")) <= 1) Then
  
  
  myChannel.say "¡Que no panda el cúnico!. " & client.IRC.nick & " se ha desconectado, pero sigo yo la partida. Aquí no ha pasado nada, ¡circulen!, ¡circulen!."
  
  game.changeBot mClient, myChannel ' <-- aquí dentro se levanta OnGameOver, que a su vez hace set trivial2=nothing
  
  Set trivial2 = game
  Set game = Nothing  ' = "Yo me encargo"
  
  
End If





End Sub


Private Sub myChannel_OnJoin(who As jIRCLib.User, cancel As Boolean)
  If who.gUsr Is myChannel.parent.self Then
      
    Exit Sub
  End If
  
  
  
  If LCase(myChannel.name) = "#wit" Then Exit Sub
  
  Dim id As String
  Dim def As String
  id = who.nickName
  def = LocateFirstDef(id)
  
  If def <> "" Then
    myChannel.action "saluda a " & id & ", " & def
  End If
  
  If who.nickName = "Zoltar" And who.userName = "er" Then
    'Debug.Print who.userName
    'who.operator = True
  End If
  
 
    
If Int(Rnd * 100) < 10 Then
  who.gUsr.notice "Bienvenido a " & myChannel.name & ". Para obtener ayuda, escribe /msg " & myChannel.parent.nick & " HELP"
End If

End Sub

Private Sub MyChannel_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)
  
  If LCase(myChannel.name) = "#wit" Then Exit Sub
  
  
  If (IsNumeric(Left(text, 1)) Or Left(text, 1) = "?") And trivial2 Is Nothing Then
    Dim tirada As String
    If Left(text, 1) = "?" Then text = Mid(text, 2)
    tirada = SuperCalc(text)
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


Private Sub MyChannel_OnUserLeave(who As jIRCLib.User, kickedBy As jIRCLib.GlobalUser, reason As String, cancel As Boolean)
  If who.gUsr Is myChannel.parent.self Then
    If Not kickedBy Is Nothing Then
      myChannel.parent.getUser("Zoltar").notice kickedBy.nickName & " me ha echado de " & myChannel.name
    End If
  End If
  
   
   
End Sub


Public Function runTrivial2(starter As GlobalUser, np As Long) As Boolean

If trivial2 Is Nothing Then
  starter.DCCMessage "Trivial2 iniciado en " & myChannel.name, True
  Set trivial2 = New TriviaGame2
  trivial2.initialize Me.myChannel, starter, np, TrivialDatabase
  runTrivial2 = True
End If
  
End Function



Private Sub myChannel_OnUserQuit(who As jIRCLib.User, quitMessage As String)

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

Set wch = wclq.WitChannels(myChannel.name)

If wch Is Nothing Then Exit Sub 'Vaya, ahora resulta que no estaba en ese canal ???

If Not wch.trivial2Running Then Exit Sub 'Se ha caído un Wit, pero no estaba con partida.

'O.K. se acaba de caer en medio de una partida, y lo hemos detectado nosotros primero
'Nos cogemos la partida


Dim gm As TriviaGame2
Set gm = wch.game

gInfo_OnDisconnectedWhilePlaying wclq, gm



End Sub

Private Sub trivial2_gameOver()
  Set trivial2 = Nothing
  
  If Not ChannelCtrl Is Nothing Then
    ChannelCtrl.DoSomething 1
  End If
  
End Sub

