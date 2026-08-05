VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TriviaGame"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
Option Compare Text

Private WithEvents Channel As Channel
Attribute Channel.VB_VarHelpID = -1
Private mStarter As GlobalUser
Private mNumQuestions As Long
Private qCount As Long
Private words() As String
Private rcQ As Recordset
Private cnQ As Connection
Private Players As TriviaPlayers

Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1
Public Event gameOver()
Private stage As Long

Public Sub initialize(ch As Channel, starter As GlobalUser, numQuestions As Long, triviaDB As String)

Set Channel = ch
mNumQuestions = numQuestions
Set mStarter = starter
If mNumQuestions < 5 Then mNumQuestions = 5
Channel.Say "Comienza una nueva partida de " & mNumQuestions & " preguntas iniciada por " & mStarter.nickName

Set tmr = New CTimer
tmr.Interval = 1000

Set cnQ = New Connection
cnQ.Open ConStrAccess(triviaDB)
Set rcQ = New Recordset
rcQ.Open "SELECT * FROM Questions;", cnQ, adOpenKeyset, adLockOptimistic
rcQ.MoveLast

Set Players = New TriviaPlayers
Players.initialize cnQ
End Sub

Private Sub Channel_OnJoin(who As jIRCLib.User, cancel As Boolean)

who.gUsr.notice "Estamos jugando al trivial. Vamos por la pregunta " & qCount & " de " & mNumQuestions & " ¡anímate a jugar!"


On Error Resume Next
who.gUsr.notice "La pregunta actual es: " & mircColorText(rcQ!question, mccDarkBlue) & " (" & UBound(words) + 1 & " pal.)"



End Sub

Private Sub channel_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)

If (Trim(text) = Trim(rcQ!answer)) And (stage >= 15) Then
  Dim tp As TriviaPlayer
  Set tp = Players.getPlayer(who.gUsr)
  Dim up As Long
  Select Case stage
    
    Case Is < 45
      up = 100
    Case Is < 55
      up = 75
    Case Else
    
      up = 50
  End Select
  
  Channel.Say mircColorText("¡¡" & mircBoldText(who.nickName) & " acertó!!. La respuesta era " & mircBoldText(rcQ!answer), mccOrange) & ". " & mircBoldText(mircColorText(" " & up & " puntos más para " & mircUnderlineText(who.nickName), mccOrange))
  
  Players.AddScore tp, up, 1
  
  Players.update tp
      
  ShowScore
  
  
  stage = 0
End If



End Sub

Private Sub channel_OnUserLeave(who As jIRCLib.User, kickedBy As jIRCLib.GlobalUser, reason As String, cancel As Boolean)

If who.gUsr Is Channel.Parent.self Then
  If Not kickedBy Is Nothing Then
    kickedBy.notice "Hay otras maneras de quitar el trivial sin tener que patearme. Escribe /query Wit HELP, para más información."
  End If
  RaiseEvent gameOver
End If



End Sub

Private Sub tmr_ThatTime()



Dim n As Long
Dim st As String

Select Case stage
  
  Case 1
    If qCount >= mNumQuestions Then
      Channel.Say "Acabó la partida. Puntuaciones: "
      Dim tp As TriviaPlayer
      
      Players.Requery
      
      For Each tp In Players
        n = n + 1
        If n <= 10 Then
          Channel.Say mircColorText(mircBoldText(n & "º") & " " & tp.gUsr.nickName & " " & tp.score & " p. Clasificación General (" & mircBoldText(Players.PlayerRank(tp) & "º") & ", " & tp.totalScore & " p.)", mccBlack, mccLightGrey)
        Else
          tp.gUsr.notice mircColorText(mircBoldText(n & "º") & " " & tp.gUsr.nickName & " " & tp.score & " p. Clasificación General (" & mircBoldText(Players.PlayerRank(tp) & "º") & ", " & tp.totalScore & " p.)", mccBlack, mccLightGrey)
        End If
          
        
      Next
      Channel.Say "Escribe " & mircBoldText("/query Wit TRIVIAL " & Channel.name & " " & mNumQuestions) & " para empezar otra partida de " & mNumQuestions & " preguntas."
      Channel.Say "Puedes ver la clasificación general en " & mircUnderlineText(mircColorText("http://dungeon.avedc.net/trivial", mccPureBlue))
      RaiseEvent gameOver
      Set tmr = Nothing
    End If
    
  
  
  Case 15
    qCount = qCount + 1
    selectQuestion
    
    Channel.Say mircColorText(" wIt TrIvIa ", mccWhite, mccDarkBlue) & mircColorText(" Pregunta " & qCount & "/" & mNumQuestions & ". TEMA: " & rcQ!subject & ". Autor: " & rcQ!Author, mccDarkMagenta) & " (#" & rcQ!idquestion & ")"
    
    words = Split(Trim("" & rcQ!answer), " ")
    Channel.Say mircColorText(rcQ!question, mccDarkBlue) & " (" & UBound(words) + 1 & " pal.)"
    
  Case 45

    For n = 0 To UBound(words)
      st = st & Left(words(n), 1)
      If Len(words(n)) > 1 Then
        st = st & String(Len(words(n)) - 1, "-")
      End If
      st = st & " "
        
    Next
    Channel.Say mircColorText("Una pista:  ", mccDarkGreen) & st

  Case 55
    
    If UBound(words) > 0 Or Len(words(0)) > 2 Then
    
      For n = 0 To UBound(words)
        st = st & Left(words(n), 1)
        If Len(words(n)) > 2 Then
          st = st & String(Len(words(n)) - 2, "-")
        End If
        If Len(words(n)) > 1 Then
          st = st & Right(words(n), 1)
        End If
        
        st = st & " "
          
      Next
      
      Channel.Say "Otra pista: " & st
    End If
  
  Case 65
    stage = 0
    Channel.Say mircColorText("Se acabó el tiempo. La respuesta era " & mircBoldText(rcQ!answer), mccOrange)
    ShowScore
    
  
  

End Select

stage = stage + 1

End Sub


Private Sub selectQuestion()

Dim n As Long
Dim p As Long
Dim min As Long
Dim rec As Variant
min = -1
If Not rcQ.BOF Then rcQ.MoveFirst
For n = 1 To 10
  p = Int(Rnd * rcQ.RecordCount) + 1
  rcQ.AbsolutePosition = p
  If min = -1 Or rcQ!repeats < min Then
    rec = rcQ.Bookmark
    min = rcQ!repeats
  End If
  

Next

rcQ.Bookmark = rec
rcQ!repeats = rcQ!repeats + 1
rcQ.update

'rcQ.AbsolutePosition = 3222


End Sub

Private Sub ShowScore()
  Dim n As Long
  Dim st As String
  Dim tp As TriviaPlayer
  
  st = mircBoldText("Puntuación:") & " "
  
  For Each tp In Players
    n = n + 1
    If n <= 3 Then
      st = st & n & ".- " & mircColorText(tp.gUsr.nickName, mccDarkRed) & " (" & tp.score & ")   "
    Else
      Channel.Say st
      st = "": Exit For
      'If n > 6 Then Exit For
      'tp.gUsr.notice "Estás en el puesto " & n & "º con " & tp.score & " puntos."
    End If
  Next
  
  
  If st <> "" Then
    Channel.Say st
  End If
  
End Sub
