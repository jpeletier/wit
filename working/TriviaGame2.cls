VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TriviaGame2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
'El cliente de este objeto asume que al descartar la referencia, todo el objeto se destruye en cascada

Option Explicit
Option Compare Text

Private WithEvents Channel As Channel
Attribute Channel.VB_VarHelpID = -1
Private mStarter As GlobalUser
Private cnQ As Connection
Private Players As TriviaPlayers2

Private mNumQuestions As Long
Private mAnswer As String
Private mNumAnswer As Double
Private mNumericAnswer As Boolean
Private qCount As Long
Private mLnWords As Long
Private words() As String
Private guessed() As String
Private IDChannel As Long
Private IDTournament As Long
Private IDQuestionSubset As Long
Private IDGame As Long
Private IDSubject As Long
Private questionText As String
Private questionSubject As String
Private questionAuthor As String
Private questionAnswer As String
Private IDQuestion As Long



Private mMultiplier As Single


Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1
Public Event gameOver()
Private stage As Long

Public Sub changeBot(client As WitClient, newChannel As Channel)

  RaiseEvent gameOver 'Para que el cliente antiguo finalice la partida
  Channel.parent.Properties("SIMTRIVIAL") = Val(Channel.parent.Properties("SIMTRIVIAL")) - 1

  Set Channel = newChannel
  Channel.parent.Properties("SIMTRIVIAL") = Val(Channel.parent.Properties("SIMTRIVIAL")) + 1

  Set mStarter = client.IRC.getUser(mStarter.nickName)
  
  Players.changeBot client.IRC
  
  
  Channel.say "La pregunta era : - " & questionSubject & " - " & mircColorText(questionText, mccDarkBlue) & " (" & mLnWords + 1 & " pal.)"
  
  If stage >= 11 Then stage = stage - 5 'Dar un poco más de tiempo
  
  
End Sub




Public Property Get gameChannel() As Channel
  Set gameChannel = Channel
End Property

Public Sub initialize(ch As Channel, starter As GlobalUser, numQuestions As Long, triviaDB As String)
mLnWords = -1
Set Channel = ch
mNumQuestions = numQuestions
Set mStarter = starter

If mNumQuestions < 5 Then mNumQuestions = 5

'buscar el canal

Set cnQ = New Connection
cnQ.CommandTimeout = 60
cnQ.Open triviaDB

Channel.parent.Properties("SIMTRIVIAL") = Val(Channel.parent.Properties("SIMTRIVIAL")) + 1

Dim rc As Recordset
Set rc = New Recordset





rc.Open "SELECT * FROM Channels WHERE name='" & Replace(ch.name, "'", "''") & "'", cnQ, adOpenDynamic, adLockPessimistic

If rc.EOF Then
  rc.Close
  cnQ.Execute "INSERT INTO Channels (Name, IDDefaultTournament, LastUsed ) Values ('" & Replace(ch.name, "'", "''") & "', Null, '" & Now & "')"
  Channel.say "Es la primera partida que se juega en este canal."

Else
  rc.Close
  
  'deshabilitado el lastused opr timeoutexpired
  'cnQ.Execute "UPDATE Channels SET LastUsed='" & Now & "' WHERE name='" & Replace(ch.name, "'", "''") & "'"

  
  
End If
  
'rc!lastused = Now

'rc.update
'rc.Close

rc.Open "SELECT IdChannel,IDDefaultTournament FROM Channels WHERE name='" & Replace(ch.name, "'", "''") & "'", cnQ, adOpenDynamic, adLockPessimistic

IDChannel = rc!IDChannel

If IsNull(rc!iddefaulttournament) Then
  IDTournament = 0
Else
  IDTournament = rc!iddefaulttournament
End If

rc.Close

'buscar torneo y verificar si pertenece a liga activa:

Dim TourOK As Boolean
Dim rct As New Recordset

Do

  rc.Open "SELECT * FROM Tournament_Subset WHERE IDTournament=" & IDTournament & " AND IDLeague=" & activeLeague, cnQ, adOpenKeyset, adLockPessimistic
  If rc.EOF Then
    
    rct.Open "SELECT * FROM Tournaments WHERE IDTournament=0", cnQ, adOpenKeyset, adLockPessimistic
    
    rct.AddNew
    rct!idleague = activeLeague
    rct!Desc = "Torneo oficial de " & ch.name & " en la " & activeLeague & "ª liga de trivial."
    rct!dateinit = Now
    rct!idleague = activeLeague
    rct!IDQuestionSubset = 1
    rct!IDChannel = IDChannel
    rct.update
    Channel.say mircBoldText("¡Bienvenidos a la " & activeLeague & "ª liga de trivial!")
    Channel.say "Más información, clasificación, estadísticas, etc en: " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial", mccPureBlue))
    IDTournament = rct!IDTournament
    rct.Close
    rc.Close
    
    cnQ.Execute "UPDATE CHANNELS SET IDDEFAULTTOURNAMENT=" & IDTournament & " WHERE IDCHANNEL=" & IDChannel
    
    TourOK = False
  Else
    TourOK = True
  End If

Loop Until TourOK

IDTournament = rc!IDTournament


IDQuestionSubset = rc!IDQuestionSubset

Channel.say "Comienza una nueva partida de " & mNumQuestions & " preguntas iniciada por" & mircColorText(" " & mStarter.nickName, mccDarkRed)
Channel.say "Torneo" & mircColorText(" " & rc!Desc, mccPureBlue) & " Preguntas:" & mircColorText(" " & rc!subsetdesc, mccPureBlue)
Channel.say "La puntuación máxima por respuesta es de" & mircColorText(" " & Int(100 * rc!multiplier), mccDarkRed) & " puntos."
Channel.say " "
mMultiplier = rc!multiplier

rc.Close

rc.Open "SELECT * FROM GAMES WHERE IDGAME=0", cnQ, adOpenKeyset, adLockOptimistic
rc.AddNew
rc!IDTournament = IDTournament
rc!numQuestions = mNumQuestions
rc!dateinit = Now
rc.update
IDGame = rc!IDGame
rc.Close


Set tmr = New CTimer
tmr.Interval = 1000






Set Players = New TriviaPlayers2
Players.initialize cnQ, IDGame, IDTournament
End Sub

Private Sub Channel_OnJoin(who As jIRCLib.User, cancel As Boolean)

Exit Sub

who.gUsr.notice "Estamos jugando al trivial. Vamos por la pregunta " & qCount & " de " & mNumQuestions & " ¡anímate a jugar!"


On Error Resume Next
If stage > 5 Then
  who.gUsr.notice "La pregunta actual es: " & mircColorText(questionText, mccDarkBlue) & " (" & mLnWords + 1 & " pal.)"
End If


End Sub

Private Sub channel_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)



If mLnWords = -1 Or stage <= 5 Then Exit Sub
'dividir en palabras

Dim guessed As Boolean
Dim res As String


If Not mNumericAnswer Then
  
  
  Dim lnans As Long
  Dim i As Long
  Dim j As Long
  Dim answer() As String
  Dim gs() As Boolean
  answer = Split(text, " ")
  lnans = UBound(answer)
  
  
  Dim gw As Long
  gw = 0
  ReDim gs(0 To mLnWords)
  
  For i = 0 To lnans
    For j = 0 To mLnWords
      If answer(i) = words(j) And Not gs(j) Then
        gs(j) = True
        gw = gw + 1
      End If
    Next
  Next
  
  guessed = gw >= mLnWords + 1
Else
  res = SuperCalc(text)
  If res <> "" Then
    Dim ans As Double
    If Len(text) < 30 Then
      ans = Val(res)
      guessed = ans = mNumAnswer
    End If
  End If

End If


If guessed And (stage >= 5) Then
  Dim tp As TriviaPlayer2
  Set tp = Players.getPlayer(who.gUsr)
  Dim up As Long
  Select Case stage
    
    Case Is < 35
      up = 100
    Case Is < 45
      up = 75
    Case Else
      up = 50
  End Select
      
  up = CInt(up * mMultiplier)
  
  Dim st As String
  
  If mNumericAnswer Then
    st = "" & mNumAnswer
    If text <> st Then
      st = text & "=" & st
    End If
  Else
    st = questionAnswer
  End If
  
  st = mircColorText("¡¡" & mircBoldText(who.nickName) & " acertó!!. La respuesta era " & mircBoldText(st), mccOrange) & ". " & mircBoldText(mircColorText(" " & up & " puntos más para " & mircUnderlineText(who.nickName), mccOrange))
  
  Channel.say st
  
  Players.AddScore tp, up, 1, IDSubject
  
  Players.update tp
      
  ShowScore
  stage = 0
    
End If

  


End Sub

Private Sub channel_OnUserLeave(who As jIRCLib.User, kickedBy As jIRCLib.GlobalUser, reason As String, cancel As Boolean)

If who.gUsr Is Channel.parent.self Then
  If Not kickedBy Is Nothing Then
    kickedBy.notice "Para quitar el trivial sin patearme, utiliza en un privado el comando TRIVIAL " & Channel.name & " STOP"
  End If
  RaiseEvent gameOver
End If



End Sub

Private Sub Class_Terminate()
Channel.parent.Properties("SIMTRIVIAL") = Val(Channel.parent.Properties("SIMTRIVIAL")) - 1
If Val(Channel.parent.Properties("SIMTRIVIAL")) < 0 Then
  Channel.parent.Properties("SIMTRIVIAL") = 0
End If

Dim rc As New Recordset

rc.Open "SELECT DateEnd fROM GAMES WHERE IDGame=" & IDGame, cnQ, adOpenKeyset, adLockOptimistic
rc!dateend = Now
rc.update
rc.Close

'rcQ.Close
cnQ.Close
End Sub



Private Sub tmr_ThatTime()



Dim n As Long
Dim st As String

Select Case stage
  
  Case 1
    If qCount = mNumQuestions Then
      tmr.Interval = 0
      Channel.say "Acabó la partida. Puntuaciones: "
      Dim tp As TriviaPlayer2
      
      
      Dim rct As New Recordset
      
      rct.Open "SELECT IDPlayer, TotalScore FROM ScoresPerTournament WHERE IDTournament=" & IDTournament & " ORDER BY TotalScore desc", cnQ, adOpenStatic, adLockReadOnly
      
      
      
      n = 0
      
      Dim plr As TriviaPlayer2
      
      For Each plr In Players
        n = n + 1
        If Not rct.BOF Then rct.MoveFirst
        If rct!IDPlayer <> plr.IDPlayer Then
          rct.Find "IdPlayer=" & plr.IDPlayer
        End If
        Channel.say mircColorText(mircBoldText(n & "º") & " " & plr.gUsr.nickName & " " & plr.score & " p. Clasificación General (" & mircBoldText(rct.AbsolutePosition & "º") & ", " & rct!totalscore & " p.)", mccBlack, mccLightGrey)
        
        If n >= 10 Then Exit For
      Next
      rct.Close
      
      'Channel.Say "Dime " & mircboldtext("TRIVIAL " & Channel.name & " " & mNumQuestions) & " en un privado para empezar otra partida de " & mNumQuestions & " preguntas."
      'Para volver a jugar dile a un WIT en privado---> trivial #(nombre del canal) 30
      
      Channel.say "Para volver a jugar, dile a " & Channel.parent.nick & " o a cualquier otro Wit en privado --> " & mircBoldText("TRIVIAL " & Channel.name & " " & mNumQuestions)
      
      Channel.say "Puedes ver la clasificación completa y tus estadísticas en: " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial", mccPureBlue))
      RaiseEvent gameOver
      Set tmr = Nothing
    End If
    
  
  
  Case 5
    qCount = qCount + 1
    
    Do
      selectQuestion
      mAnswer = Trim("" & questionAnswer)
      words = Split(mAnswer, " ")
      mLnWords = UBound(words)
      mNumericAnswer = False
      
      If mLnWords = 0 Then
        st = Replace(Replace(words(0), ",", "."), "'", ".")
        If IsNumeric(st) Then
          mNumericAnswer = Len(st) < 30
          mNumAnswer = Val(st)
        End If
      End If
      
    ReDim guessed(0 To mLnWords)
    Loop Until mLnWords < 10
    
      For n = 0 To mLnWords
        guessed(n) = BuildHintString(words(n), 0)
      Next
    
    
    
    
    '
    '11,0`%0,11%,12,11`%11,12%,2,12`%12,2%,8,2 wIt TrIvIa 12,2`%2,12%,11,12`%12,11%,0,11`%11,0%,
    '7,0`%0,7%,4,7`%7,4%,5,4`%4,5%,8,5 wIt TrIvIa 4,5`%5,4%,7,4`%4,7%,0,7`%7,0%,
    '7,0`%0,7%,4,7`%7,4%,1,4`%4,1%,8,1 wIt TrIvIa 4,1`%1,4%,7,4`%4,7%,0,7`%7,0%,
    Channel.say " 7,0`%0,7%,4,7`%7,4%,1,4`%4,1%,8,1 wIt TrIvIa 4,1`%1,4%,7,4`%4,7%,0,7`%7,0%, " & mircColorText(" Pregunta " & qCount & "/" & mNumQuestions & ". TEMA: " & questionSubject & ". Autor: " & questionAuthor, mccDarkMagenta) & " (#" & IDQuestion & ")"
    

    Channel.say mircColorText(questionText, mccDarkBlue) & " (" & mLnWords + 1 & " pal.)"
    
    showGuessSoFar
    
  Case 35

    If mNumericAnswer Then
      st = numericGuess(mNumAnswer, 1)
    Else
      For n = 0 To mLnWords
        st = st & BuildHintString(words(n), 1) & " "
          
      Next
    End If
    
    Channel.say mircColorText("Una pista:", mccDarkGreen) & "  " & st

  Case 45
    If mNumericAnswer Then
      st = numericGuess(mNumAnswer, 2)
    Else
      If mLnWords <> -1 Then
        For n = 0 To mLnWords
          st = st & BuildHintString(words(n), 2) & " "
        Next
      End If
    End If
    Channel.say mircColorText("Otra pista:", mccDarkGreen) & " " & st
  
  Case 55
    stage = 0
    Channel.say mircColorText("Se acabó el tiempo. La respuesta era " & mircBoldText("" & questionAnswer), mccOrange)
    ShowScore
    
  
  

End Select

stage = stage + 1

End Sub


Private Sub selectQuestion()

Dim q As Question_Type

q = getQuestion(IDQuestionSubset)

questionText = q.question
questionAuthor = q.Author
questionSubject = q.subject
questionAnswer = q.answer
IDSubject = q.IDSubject
IDQuestion = q.IDQuestion

Exit Sub



End Sub

Private Sub ShowScore()
  Dim n As Long
  Dim st As String
  Dim tp As TriviaPlayer2
  
  st = mircBoldText("Puntuación:") & " "
  
  For Each tp In Players
    n = n + 1
    If n <= 3 Then
      st = st & n & ".- " & mircColorText(tp.gUsr.nickName, mccDarkRed) & " (" & tp.score & ")   "
    Else
      Channel.say st
      st = ""
      Exit For
      'If n > 6 Then Exit For
      'tp.gUsr.notice "Estás en el puesto " & n & "º con " & tp.score & " puntos."
    End If
  Next
  
  
  If st <> "" Then
    Channel.say st
  End If
  
End Sub


Private Sub showGuessSoFar()

Dim st As String

If Not mNumericAnswer Then
  Dim n As Long
  For n = 0 To mLnWords
    If guessed(n) = "" Then
      st = st & words(n) & " "
    Else
      st = st & guessed(n) & " "
    End If
  Next

Else

st = numericGuess(mNumAnswer, 0)

End If



Channel.say mircColorText("->", mccDarkBlue) & " " & st

End Sub


Private Function numericGuess(ans As Double, m As Integer) As String

Dim R As Double
Dim L As Double
Dim stR As String
Dim stL As String
Dim var As Single

Select Case m
  Case 0
    var = 30
  
  Case 1
    var = 20
  Case 2
    var = 10
End Select
    


RandomInterval var, ans, L, R

If Int(ans) = ans Then
  stL = "" & L
  stR = "" & R
Else
  stL = Format(L, "#.##")
  stR = Format(R, "#.##")
End If

numericGuess = "El número está entre" & mircColorText(" " & stL, mccPurple) & " y" & mircColorText(" " & stR, mccPurple)


End Function

Private Sub RandomInterval(var As Single, center As Double, L As Double, R As Double)
  
On Error Resume Next
L = center - Rnd * var
R = center + Rnd * var
  
If Int(center) = center Then
  L = Int(L)
  R = Int(R)
End If

End Sub




Function BuildHintString(word As String, hintLevel As Long) As String

Dim guess As String

Dim ln As Long
ln = Len(word)
Dim char As Integer
Dim n As Integer
guess = String(ln, "-")

Dim showLetter As Boolean


For n = 1 To ln
  char = jCore.CharFromStr(word, n)
  showLetter = False
     
  If (hintLevel >= 1 And n = 1) Or (hintLevel = 2 And n = ln) Then
    showLetter = True
  Else
    Select Case char
    
      Case 97 To 122
      Case 65 To 90
      Case 48 To 57
      Case 241, 209
      
      Case Else
        showLetter = True
    End Select
  End If
  
  If showLetter Then
    jCore.InsertChar guess, Chr(char), n
  End If
  
Next

BuildHintString = guess

End Function
