VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "PorraGame"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Private Const ADMISSION_TIME = 60
Private Const COMMISSION_RATE = 0.1

Private percent_prize(1 To 3) As Long

Private amount As Long
Private starter As GlobalUser
Private numChallenges As Long
Private witGame As IWitGame
Private WithEvents witGameEvents As EventCollection
Attribute witGameEvents.VB_VarHelpID = -1

Private participants As Collection

Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1
Private counter As Long

Private WithEvents ch As Channel
Attribute ch.VB_VarHelpID = -1


Private stage As PorraStageEnum

Private Enum PorraStageEnum

    PR_ADMISSION = 1
    PR_GAME = 2


End Enum

Private balance_lock As String

Public Event gameOver()


Public Sub initialize(xWitGame As IWitGame, xAmount As Long, xStarter As GlobalUser, xNumChallenges As Long, xCh As Channel)

percent_prize(1) = 80
percent_prize(2) = 15
percent_prize(3) = 5


Set ch = xCh
Set witGame = xWitGame
Set starter = xStarter
numChallenges = xNumChallenges
amount = xAmount

balance_lock = newGUID()

Set witGameEvents = New EventCollection
witGameEvents.Add witGame

chSay "Comienza una nueva porra de " & witGame.gameName & " en el canal " & ch.Name
chSay "La porra es a " & amount & " W$ por participante."
chSay "Para participar, escribe !porra"

stage = PR_ADMISSION
Set participants = New Collection

counter = 0
Set tmr = New CTimer
tmr.Interval = 1000





End Sub

Private Sub ch_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)

Select Case stage

Case PR_ADMISSION
    If Left(LCase(text), 6) = "!porra" Then
        addNewParticipant who
    End If

End Select
        






End Sub

Private Sub tmr_ThatTime()
counter = counter + 1

Select Case stage
    Case PR_ADMISSION
        stage_admission_tick

End Select

End Sub


Private Sub addNewParticipant(who As User)

Dim IDUser As Long

IDUser = getIDUser(who.gUsr)

If IDUser = 0 Then
    who.gUsr.notice "No estás validado con Wit. Validate mediante el comando /MSG Wit LOGIN user password"
    Exit Sub
End If


Dim GUIDLock As String

GUIDLock = lockBalance(0 + amount, IDUser, "Partida " & Now)

If GUIDLock = "" Then
    who.gUsr.notice "No tienes saldo suficiente para jugar una porra de " & formatW(amount)
    Exit Sub
End If

who.gUsr.Properties(balance_lock) = GUIDLock


If ObjectExistsInCollection(participants, "U" & IDUser) Is Nothing Then
   participants.Add who, "U" & IDUser
   who.gUsr.notice "Has sido añadido a la lista de participantes"
Else
    who.gUsr.notice "Ya estabas en la lista de participantes"
End If


End Sub

Private Sub stage_admission_tick()

Dim st As String
If (counter Mod 20 = 0 Or counter = ADMISSION_TIME - 10) And counter < ADMISSION_TIME Then
    st = "La partida comenzará en " & ADMISSION_TIME - counter & " segundos."
    If participants.Count > 0 Then
        st = st & " Por" & mircColorText(" " & formatW(getMaxPrize()), mccDarkRed) & " juegan" & mircColorText(" " & getParticipantList, mccOrange)
    End If
    
    st = st & ". " & mircColorText("Escribe !porra para participar", mccBlack, mccYellow)
    chSay st
    Exit Sub
End If

If counter >= ADMISSION_TIME Then

    If participants.Count < 2 Then
        chSay "No hay suficientes participantes para una porra. Se requieren al menos 2."
        returnLockedBalance
        RaiseEvent gameOver
        tmr.Interval = 0
        Set tmr = Nothing
        Exit Sub
    End If

    stage = PR_GAME
    
    tmr.Interval = 0
    Set tmr = Nothing
    
    witGame.initialize ch, starter, numChallenges, TrivialDatabase
    
End If



End Sub

Private Function getParticipantList() As String

Dim u As User
Dim st As String

For Each u In participants
    st = st & u.NickName & " "
Next

getParticipantList = st

End Function

Private Function getMaxPrize() As Long

getMaxPrize = CLng(participants.Count * amount * (1 - COMMISSION_RATE))

End Function

Private Function getPrize(pos As Long, numplayers As Long)

Dim percent As Long
Dim n As Long

If pos = 1 And numplayers < UBound(percent_prize) Then
    For n = numplayers + 1 To UBound(percent_prize)
        percent = percent + percent_prize(n)
    Next
End If

percent = percent + percent_prize(pos)

getPrize = Int(getMaxPrize * percent / 100)

End Function


Private Sub witGame_gameOver()

Dim ParticipantsPlaying As Collection
Set ParticipantsPlaying = getParticipantsPlaying(witGame.players)

Dim p As TriviaPlayer2

Dim GUIDLock As String

If ParticipantsPlaying.Count = 0 Then
    'ningún participante ha acertado ni una sola pregunta: devolver todo el saldo
    
    returnLockedBalance

    chSay "Ningún participante de la porra está clasificado, se devuelven las aportaciones"
    Exit Sub
End If

Dim st As String

st = getResultList(ParticipantsPlaying)


chSay "Fin de juego. Resultado final: " & st


Dim cn As ADODB.Connection

Set cn = New Connection
cn.Open TrivialDatabase

cn.BeginTrans

For Each usr In participants
    
        GUIDLock = usr.gUsr.Properties(balance_lock)
        Bank.transferLockedBalance GUIDLock, IDUser_Bank, cn
        Bank.unLockBalance GUIDLock, cn
        usr.gUsr.Properties.Remove balance_lock

Next

Dim pos As Long
Dim prize As Long
pos = 0

For Each p In ParticipantsPlaying
    pos = pos + 1
    If pos > UBound(percent_prize) Then
        Exit For
    End If
    
    prize = getPrize(pos, ParticipantsPlaying.Count)
    
    p.gUsr.Properties(balance_lock & "prize") = prize
    
    Bank.transferBalance prize, IDUser_Bank, getIDUser(p.gUsr), cn
    
Next

cn.CommitTrans
cn.Close
Set cn = Nothing

For Each p In ParticipantsPlaying

    prize = p.gUsr.Properties(balance_lock & "prize")
    p.gUsr.Properties.Remove (balance_lock & "prize")
    
    If prize > 0 Then
        p.gUsr.notice "Se han transferido " & formatW(prize) & " a tu cuenta. Tu saldo ahora es " + formatW(Bank.getBalance(getIDUser(p.gUsr)))
    End If

Next


RaiseEvent gameOver

End Sub

Private Sub witGame_ChallengeFinished()


Dim ParticipantsPlaying As Collection
Set ParticipantsPlaying = getParticipantsPlaying(witGame.players)
If ParticipantsPlaying.Count = 0 Then Exit Sub

Dim st As String

st = getResultList(ParticipantsPlaying)
st = "Parcial de la porra: " & st
chSay st


End Sub

Private Sub witGameEvents_EventRaised(ByVal Index As Long, ByVal Source As Object, ByVal RaisedEvent As Variant, aParams() As Variant)

Dim eventID As Long
eventID = CLng(RaisedEvent)

Select Case eventID

    Case 1 ' gameOver
        witGame_gameOver
        
    Case 2 ' ChallengeFinished
        witGame_ChallengeFinished

End Select

End Sub

Private Function getParticipantsPlaying(players As TriviaPlayers2) As Collection
Dim ParticipantsPlaying As Collection
Dim p As TriviaPlayer2

Set ParticipantsPlaying = New Collection

For Each p In players
    If Not ObjectExistsInCollection(participants, "U" & getIDUser(p.gUsr)) Is Nothing Then
        ParticipantsPlaying.Add p
    End If
Next

Set getParticipantsPlaying = ParticipantsPlaying

End Function


Function getResultList(ParticipantsPlaying As Collection)

Dim p As TriviaPlayer2

Dim pos As Long
Dim st As String

pos = 0

For Each p In ParticipantsPlaying
        pos = pos + 1
        
        If pos > UBound(percent_prize) Then
            Exit For
        End If
        If (pos > 1) Then
            st = st & ", "
        End If
        
        st = st & p.gUsr.NickName & ": " & formatW(getPrize(pos, ParticipantsPlaying.Count))
Next

getResultList = st
End Function

Private Sub returnLockedBalance()
Dim usr As User
Dim GUIDLock As String

    For Each usr In participants
        GUIDLock = usr.gUsr.Properties(balance_lock)
        Bank.unLockBalance GUIDLock
        usr.gUsr.Properties.Remove balance_lock
       
    Next
End Sub

Private Sub chSay(st As String)


ch.say mircColorText("[PoRRa " + witGame.gameName + "]", mccBlack, mccCyan) & " - " & st


End Sub

