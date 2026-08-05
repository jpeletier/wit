VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CYLGame"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
Implements IWitGame

Private Const IDSubject_Cifras = 97
Private Const IDSubject_Letras = 98
Private Const IDQuestionSubset_CYL = 34

Private WithEvents Channel As Channel
Attribute Channel.VB_VarHelpID = -1

Private IDChannel As Long
Private IDGame As Long
Private IDCYLTournament As Long

Private mStarter As GlobalUser
Private mNumChallenges As Long
Private nStage As Long
Private nStageRequest As Long
Private nCurrentToken As Long
Private PlayerRequest As TriviaPlayer2

Private mCurrentChallenge As Long
Private mChallengeStage As Long
Private mNumberChallenge As Double

Private Const MAXLETTERS = 9
Private Const MAXNUMBERS = 6
Private Const MAXWINNERS_LETRAS = 3
Private Const MAXWINNERS_CIFRAS = 1



Private Type tokenUsageType
    ltr(0 To MAXLETTERS - 1) As String * 1
    nums(0 To MAXNUMBERS - 1) As Long
    used(0 To MAXLETTERS - 1) As Boolean
End Type

Private Type WinnerListMemberType
    player As TriviaPlayer2
    word As CYLWord
    number As Double
    score As Long
    response As String
End Type

Private WinnerList(0 To MAXWINNERS_LETRAS - 1) As WinnerListMemberType

Private Enum StageTypeEnum
  STAGE_LETRAS = 1
  STAGE_CIFRAS = 0
End Enum
    


Private cnQ As ADODB.Connection

Private tokens As tokenUsageType
Private players As TriviaPlayers2


Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1

Public Event gameOver() ' no cambiar el orden de los eventos, la clase PorraGame los identifica por orden.



Private Property Get IWitGame_gameName() As String
    IWitGame_gameName = "CYL"
End Property

Public Sub IWitGame_initialize(ch As jIRCLib.Channel, starter As jIRCLib.GlobalUser, numChallenges As Long, triviaDB As String)
    initialize ch, starter, numChallenges, triviaDB
End Sub

Private Property Get IWitGame_players() As TriviaPlayers2
   Set IWitGame_players = players
End Property



Public Sub initialize(ch As Channel, starter As GlobalUser, numChallenges As Long, triviaDB As String)

Set Channel = ch
Set mStarter = starter

Set cnQ = New Connection
cnQ.Open triviaDB

Dim isnew As Boolean
If Not getIDChannelIDTournament(ch, cnQ, IDChannel, 1, isnew) Then
  RaiseEvent gameOver
End If

If isnew Then
  ch.say "Es la primera partida que se juega en este canal."
End If
  
Dim rc As Recordset
Set rc = New Recordset
  
 
rc.CursorLocation = adUseClient
rc.Open "SELECT * FROM Tournaments WHERE IDChannel=" & IDChannel & " AND IDLeague=" & activeLeague & " AND IdWitGame=" & WITGAME_CYL, cnQ, adOpenKeyset, adLockOptimistic

If rc.EOF Then
  'No se ha encontrado un torneo de CYL en la liga activa.
  Dim rct As Recordset
  Set rct = New Recordset
  rct.CursorLocation = adUseClient

  rct.Open "SELECT * FROM Tournaments WHERE IDTournament=0", cnQ, adOpenKeyset, adLockOptimistic
  
  rct.AddNew
  rct!idleague = activeLeague
  rct!Desc = "Torneo oficial de " & ch.Name & " en la " & activeLeague & "ª liga de CYL."
  rct!DateInit = Now
  rct!idleague = activeLeague
  rct!IDChannel = IDChannel
  rct!IDWitGame = WITGAME_CYL
  rct!IDQuestionSubset = IDQuestionSubset_CYL
  rct.update
  Channel.say mircBoldText("¡Bienvenidos a la " & activeLeague & "ª liga de CYL!")
  Channel.say "Más información, clasificación, estadísticas, etc en: " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial", mccPureBlue))
  IDCYLTournament = rct!IDTournament
  rct.Close
  rc.Close
Else
  IDCYLTournament = rc!IDTournament
End If






initLetterValues

Set players = New TriviaPlayers2


IDGame = getNewIDGame(IDCYLTournament, cnQ)
players.initialize cnQ, IDGame, IDCYLTournament
mNumChallenges = numChallenges

Channel.say "8,1 wIt C&L  Comienza una nueva partida de C&L iniciada por " & mircColorText(starter.NickName, mccDarkRed)


Set tmr = New CTimer

tmr.Interval = 1000

End Sub

Private Sub Channel_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)

If nStageRequest >= 0 Then
  If PlayerRequest Is Nothing Or Not (PlayerRequest Is players(who.gUsr.NickName)) Or Len(text) < 1 Then Exit Sub
  
  Dim ok As Boolean
  Select Case LCase(Left(text, 1))
    Case "v"
      tokens.ltr(nCurrentToken) = generateRandomVocal
      ok = True
    Case "c"
      tokens.ltr(nCurrentToken) = generateRandomConsonant
      ok = True
  End Select
 
  If ok Then
    nCurrentToken = nCurrentToken + 1
    Set PlayerRequest = Nothing
    nStageRequest = 0
  End If
  


  Exit Sub
End If







If stageType = StageTypeEnum.STAGE_CIFRAS Then
  processCifrasResponse who, text, cancel
Else
  processLetrasResponse who, text, cancel
End If

End Sub

Private Sub processCifrasResponse(who As User, text As String, cancel As Boolean)

If nStage > 200 Then Exit Sub 'this prevents reentrancy after exact number.


'check number usage ability

Dim ln As Long
Dim numsResp(0 To MAXNUMBERS - 1) As Long
Dim cn As Long

Dim ch As Integer
Dim fnum As Boolean
Dim i As Long
Dim n As Long
Dim numsok As Long

ln = Len(text)


For n = 0 To MAXLETTERS - 1
    tokens.used(n) = False
Next n

For n = 1 To ln
  ch = jCore.CharFromStr(text, n)
  If (ch >= 48) And (ch <= 57) Then
      cn = cn * 10 + ch - 48
      If cn > 20000 Then Exit Sub
      fnum = True
  End If
  If ((Not (ch >= 48) And (ch <= 57)) Or n = ln) And fnum Then
    numsok = False
    For i = 0 To MAXNUMBERS - 1
      If Not tokens.used(i) And tokens.nums(i) = cn Then
        tokens.used(i) = True
        numsok = True
        Exit For
      End If
    Next
    If Not numsok Then Exit Sub
    cn = 0
    fnum = False
  End If
Next

'text contains good numbers.

Dim num As Double
Dim calcError As Long
num = calc(text, , calcError)
If calcError <> 0 Or num < 0 Then Exit Sub


With WinnerList(0)
  
  If Abs(num - mNumberChallenge) < Abs(.number - mNumberChallenge) Or .player Is Nothing Then
    Set .player = players.getPlayer(who.gUsr)
    .number = num
    .response = text
    If Abs(num - mNumberChallenge) < 0.001 Then nStage = 10000 'end the round.
  End If

End With
  








End Sub


Private Sub processLetrasResponse(who As User, text As String, cancel As Boolean)

If nStage < 5 Then Exit Sub 'Can't answer if you know not the question


'1.- check letter usage validity
Dim n As Integer
Dim i As Integer
Dim ln As Long
Dim c As String * 1
Dim valid As Boolean
Dim found As Boolean
ln = Len(text)

If ln = 1 Then Exit Sub 'Wont allow just one letter


For n = 0 To MAXWINNERS_LETRAS - 1
  If WinnerList(n).player Is Nothing Then Exit For
  
  If LCase(WinnerList(n).word.word) = LCase(text) Then
    Exit Sub 'repeated word
  End If
  If WinnerList(n).player.gUsr Is who.gUsr Then
    If WinnerList(n).word.length >= Len(text) Then
      Exit Sub
    End If
  End If
    
  
Next


For n = 0 To MAXLETTERS - 1
    tokens.used(n) = False
Next n

valid = True
For i = 1 To ln
    c = UCase(Mid(text, i, 1))
    found = False
    For n = 0 To MAXLETTERS - 1
        If CompareNoPunct(tokens.ltr(n), c) And Not tokens.used(n) Then
            tokens.used(n) = True
            found = True
            Exit For
        End If
    Next n
    
    valid = valid And found
    If Not valid Then Exit Sub

Next i
    
'At this point, the word has been built just with the letters provided... But, ¿does it actually exist?
'2.- lookup the word in the dictionary

Dim wrd As CYLWord
Set wrd = getWord(text)


If wrd Is Nothing Then Exit Sub



'3.- If the word is valid, add it and its meaning to the winner list if the word is longer

Dim tmpgusr As TriviaPlayer2
Dim tmpcw As CYLWord


For n = 0 To MAXWINNERS_LETRAS - 1
  If WinnerList(n).player Is Nothing Then Exit For
  
  If WinnerList(n).player.gUsr Is who.gUsr Then
    
    If n < MAXWINNERS_LETRAS - 1 Then
      For i = n To MAXWINNERS_LETRAS - 2
        Set WinnerList(i).player = WinnerList(i + 1).player
        Set WinnerList(i).word = WinnerList(i + 1).word
      Next i
    End If
    Set WinnerList(MAXWINNERS_LETRAS - 1).player = Nothing
    Set WinnerList(MAXWINNERS_LETRAS - 1).word = Nothing
    Exit For
  End If
Next n
      


For n = 0 To MAXWINNERS_LETRAS - 1
    If compareLengths(wrd, WinnerList(n).word) = -1 Then
        If n < MAXWINNERS_LETRAS - 1 Then
            For i = MAXWINNERS_LETRAS - 1 To n + 1 Step -1
                Set WinnerList(i).player = WinnerList(i - 1).player
                Set WinnerList(i).word = WinnerList(i - 1).word
            Next
        End If
        Set WinnerList(n).player = players.getPlayer(who.gUsr)
        Set WinnerList(n).word = wrd
        Exit For
    End If
Next



End Sub



Function CompareNoPunct(ByVal a As String, ByVal b As String) As Boolean

a = LCase(Replace(Replace(Replace(Replace(Replace(Replace(a, "Ú", "U"), "Ó", "O"), "Í", "I"), "É", "E"), "Á", "A"), "Ü", "U"))
b = LCase(Replace(Replace(Replace(Replace(Replace(Replace(b, "Ú", "U"), "Ó", "O"), "Í", "i"), "É", "E"), "Á", "A"), "Ü", "U"))

CompareNoPunct = a = b



End Function



Private Sub Class_Initialize()
nStageRequest = -1
End Sub



Private Sub tmr_ThatTime()
If tmr Is Nothing Then Exit Sub


If nStageRequest >= 0 Then
  nStageRequest = nStageRequest + 1
Else
  nStage = nStage + 1
End If

Dim n As Long, i As Long
Dim st As String


Select Case nStageRequest
  Case 1
    If nCurrentToken >= MAXLETTERS Then
      nStageRequest = -1
      nStage = 6
      For n = 0 To MAXLETTERS - 1
        st = st & tokens.ltr(n) & " "
      Next
      Channel.say "Puedes usar estas letras: " & mircColorText(st, mccDarkBlue)
    Else
      n = (nCurrentToken Mod players.Count) + 1
      Set PlayerRequest = players.Item(n)
      For n = 0 To nCurrentToken - 1
        If n = nCurrentToken - 1 Then
          st = st & mircColorText(tokens.ltr(n), mccDarkRed) & " "
        Else
          st = st & tokens.ltr(n) & " "
        End If
      Next
      If st <> "" Then st = st & ": "
      st = st & mircColorText(PlayerRequest.gUsr.NickName, mccOrange) & ", ¿Vocal o Consonante?"
      Channel.say st
    End If
  
  Case 10
    st = PlayerRequest.gUsr.NickName & ", veo que no te decides. Elijo yo por ti: "
    If rollDice(1, 2) = 1 Then
      st = st & "VOCAL"
      tokens.ltr(nCurrentToken) = LetterUtils.generateRandomVocal()
    Else
      st = st & "CONSONANTE"
      tokens.ltr(nCurrentToken) = LetterUtils.generateRandomConsonant()
    End If
    nCurrentToken = nCurrentToken + 1
    Set PlayerRequest = Nothing
    Channel.say st
    
    
  Case 12
    nStageRequest = 0
    

End Select

If nStageRequest >= 0 Then Exit Sub


Select Case nStage

  Case 5
    mChallengeStage = mChallengeStage + 1
    If mChallengeStage >= 5 Then mChallengeStage = 1

    'Clearup from previous rounds:
    
    resetWinnerList
   
    mCurrentChallenge = mCurrentChallenge + 1
     
    If stageType = STAGE_CIFRAS Then
      prepareCifrasStage
    Else
      Channel.say "7,0`%0,7%,4,7`%7,4%,1,4`%4,1%,8,1 wIt C&L 4,1`%1,4%,7,4`%4,7%,0,7`%7,0%, Desafío #" & mCurrentChallenge & " a LETRAS"
            

' Deshabilitado interactividad al seleccionar letras

'      If players.Count = 0 Or mCurrentChallenge < 5 Or mCurrentChallenge Mod 5 <> 0 Then
        prepareLetrasStage
'      Else
'        nStageRequest = 0
'        nCurrentToken = 0
'      End If
    
    
    End If



    Case 40
      If stageType = STAGE_LETRAS Then
        For n = 0 To MAXLETTERS - 1
          st = st & tokens.ltr(n) & " "
        Next
        st = "Puedes usar estas letras: " & mircColorText(st, mccDarkBlue)
      Else
        For n = 0 To MAXNUMBERS - 1
          st = st & tokens.nums(n) & " "
        Next
        st = "Puedes usar estas cifras: " & mircColorText(" " & st, mccDarkBlue) & " para conseguir el " & mircColorText(" " & mNumberChallenge & " ", mccWhite, mccBlack)
      End If
        

      Channel.say "20 segundos ... " & st

    Case Is >= 60
        
        If stageType = STAGE_CIFRAS Then
          endCifrasStage
        Else
          endLetrasStage
        End If
        
        showScores True
        
        
        If mCurrentChallenge >= mNumChallenges Then
          tmr.Interval = 0
           Set tmr = Nothing
           Channel.say "Acabó la partida de C&L. Puntuaciones: "
           
           players.showScoresInChannel Channel
           
           Channel.say "Para volver a jugar, dile a " & Channel.parent.nick & " o a cualquier otro Wit en privado --> " & mircBoldText("CYL " & Channel.Name & " " & mNumChallenges)
           
           'Channel.say "C&L en fase de pruebas. " & mircUnderlineText(mircColorText("http://www.peletier.com", mccPureBlue))
           Channel.say "Puedes ver la clasificación completa y tus estadísticas en: " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial", mccPureBlue))
           
           MessageOnEnd Channel
           
          RaiseEvent gameOver
        End If
        
        
        
        nStage = 0
          



End Select



End Sub

Private Sub showScores(showDiff As Boolean)

Dim n As Long, i As Long, x As Long
Dim st As String
Dim mwinners As Long
If stageType = STAGE_CIFRAS Then
  mwinners = MAXWINNERS_CIFRAS
Else
  mwinners = MAXWINNERS_LETRAS
End If


  n = 0
  st = "Puntuaciones: "
  
  Dim cp As TriviaPlayer2
  
  For Each cp In players
    n = n + 1
    
    st = st & n & ".- " & cp.gUsr.NickName & ": " & cp.score & " "
    If showDiff Then
      For i = 0 To MAXWINNERS_LETRAS - 1
        If WinnerList(i).player Is cp Then
          st = st & "(" & mircColorText("+" & WinnerList(i).score, mccDarkRed) & ") "
        End If
      Next
    End If

  If n >= 3 Then Exit For
  Next


  If players.Count > 0 Then
    Channel.say st
  End If



End Sub





Private Function getWord(word As String) As CYLWord

Dim w As String
Dim cw As CYLWord
Dim rc As Recordset

Set rc = New Recordset
rc.Open "SELECT top 1 word,meaning from dictionary where word='" & word & "'", cnQ, adOpenStatic, adLockReadOnly

If Not rc.EOF Then
    Set cw = New CYLWord

    cw.meaning = "" & rc!meaning
    cw.word = rc!word
End If

Set getWord = cw
End Function

Private Function compareLengths(w1 As CYLWord, w2 As CYLWord)

Dim l1 As Long
Dim l2 As Long

If w1 Is Nothing Then l1 = 0 Else l1 = w1.length
If w2 Is Nothing Then l2 = 0 Else l2 = w2.length

If l1 > l2 Then
    compareLengths = -1
Else
    If l1 = l2 Then
        compareLengths = 0
    Else
        compareLengths = 1
    End If
End If







End Function

Private Function compareLengthsText(w1 As CYLWord, w2 As String)

Dim l1 As Long
Dim l2 As Long

If w1 Is Nothing Then l1 = 0 Else l1 = w1.length
l2 = Len(w2)

If l1 > l2 Then
    compareLengthsText = -1
Else
    If l1 = l2 Then
        compareLengthsText = 0
    Else
        compareLengthsText = 1
    End If
End If







End Function


Private Function stageType() As StageTypeEnum
'stageType = STAGE_CIFRAS
'Exit Function

If mChallengeStage >= 4 Then
  stageType = STAGE_CIFRAS
Else
  stageType = STAGE_LETRAS
End If


End Function

Private Sub resetWinnerList()
Dim n As Long
    For n = 0 To MAXWINNERS_LETRAS - 1
        Set WinnerList(n).player = Nothing
        Set WinnerList(n).word = Nothing
        WinnerList(n).number = -1000
        WinnerList(n).score = 0
    Next
End Sub


Private Sub prepareCifrasStage()

Dim utokens(1 To 14) As Byte

Dim i As Long
Dim n As Long
Dim r As Long
Dim st As String

For n = 0 To 5
  
  Do While r = 0
    r = Int(Rnd * 24) + 1
    
    If (r > 10) Then r = r - 10
  
    If Not ((r <= 10 And utokens(r) < 2) Or (r > 10 And utokens(r) < 1)) Then
      r = 0
    End If

  Loop
    
  utokens(r) = utokens(r) + 1
  Select Case r
    Case Is <= 10
      tokens.nums(n) = r
    Case 11
      tokens.nums(n) = 25
    Case 12
      tokens.nums(n) = 50
    Case 13
      tokens.nums(n) = 75
    Case 14
      tokens.nums(n) = 100
  End Select
  
  r = 0
  
  st = st & tokens.nums(n) & " "
  
Next

    mNumberChallenge = Int(Rnd * 899) + 101

    Channel.say "7,0`%0,7%,4,7`%7,4%,1,4`%4,1%,8,1 wIt C&L 4,1`%1,4%,7,4`%4,7%,0,7`%7,0%, Desafío #" & mCurrentChallenge & " a CIFRAS"
    Channel.say "Puedes usar estas cifras: " & mircColorText(" " & st, mccDarkBlue) & " para conseguir el " & mircColorText(" " & mNumberChallenge & " ", mccWhite, mccBlack)
    

End Sub


Private Sub prepareLetrasStage()
     'Generate valid random letters

Dim n As Long
Dim st As String
    
    For n = 0 To 2
      tokens.ltr(n) = LetterUtils.generateRandomVocal
      tokens.used(n) = False
      st = st & tokens.ltr(n) & " "
    Next
        
    
    For n = 3 To MAXLETTERS - 1
      tokens.ltr(n) = LetterUtils.generateRandomLetter2
      tokens.used(n) = False
      st = st & tokens.ltr(n) & " "
    Next
    
    
    Channel.say "Puedes usar estas letras: " & mircColorText(st, mccDarkBlue)

End Sub

Private Sub endCifrasStage()

Dim st As String
Dim n As Double

With WinnerList(0)

If .player Is Nothing Then
  Channel.say "Se acabó el tiempo. Nadie consiguió la cifra."
Else
  If .number = mNumberChallenge Then
    st = "consiguió el número exacto"
    .score = 200
  Else
    st = "fue el que más se aproximó"
    n = Abs(.number - mNumberChallenge)
    If n < 100 Then
      .score = 100 - n + 1
    End If
  End If

  st = mircColorText("¡ " & .player.gUsr.NickName & " " & st & " !", mccOrange) & mircColorText(" " & .response & " = " & .number, mccDarkBlue)
  Channel.say st
  players.AddScore .player, .score, 1, IDSubject_Cifras
  players.update .player

End If


End With

End Sub

Private Sub endLetrasStage()
        
Dim st As String
Dim n As Long
Dim i As Long

        
        If WinnerList(0).player Is Nothing Then
            Channel.say "Se acabó el tiempo. Nadie supo construir una palabra."
        Else
          st = mircBoldText(WinnerList(0).word.word) & " (" & WinnerList(0).player.gUsr.NickName & " " & mircColorText("+" & WinnerList(0).word.score, mccDarkRed) & ") "
          If WinnerList(0).word.meaning <> "" Then
            WinnerList(0).word.meaning = Replace(Mid(WinnerList(0).word.meaning, 1, 100), "", " || ")
            
            st = st & ": """ & WinnerList(0).word.meaning
            If Len(WinnerList(0).word.meaning) > 100 Then
                st = st & " ..."
            End If
            st = st & """"
          End If
          
          If Not WinnerList(1).player Is Nothing Then
            st = st & ". Otras palabras: "
            i = 1
            For n = 1 To MAXWINNERS_LETRAS - 1
              If WinnerList(n).player Is Nothing Then Exit For
              i = i * 2
              st = st & WinnerList(n).word.word & " " & "(" & WinnerList(n).player.gUsr.NickName & " " & mircColorText("+" & CLng(WinnerList(n).word.score / i), mccDarkRed) & ") "
            Next
          End If
              
          Channel.say st
          
          i = 1
          For n = 0 To MAXWINNERS_LETRAS - 1
            With WinnerList(n)
              If Not .player Is Nothing Then
                .score = CLng(.word.score / i)
                players.AddScore .player, .score, 1, IDSubject_Letras
                players.update .player
              Else
                Exit For
              End If
              i = i * 2
            End With
          Next
        End If

End Sub


