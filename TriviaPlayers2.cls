VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TriviaPlayers2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Collection" ,"TriviaPlayer"
Attribute VB_Ext_KEY = "Member0" ,"TriviaPlayer"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

'local variable to hold collection
Private mCol As Collection

Private cnQ As Connection
Private IDGame As Long
Private IDTournament As Long



Friend Sub initialize(cn As Connection, xIDGame As Long, xIDTournament As Long)

Set cnQ = cn

IDGame = xIDGame
IDTournament = xIDTournament

End Sub


Function getPlayer(gUsr As GlobalUser) As TriviaPlayer2
Dim tp As TriviaPlayer2
Set tp = Item(gUsr.NickName)
If tp Is Nothing Then
  Set tp = New TriviaPlayer2
  Set tp.gUsr = gUsr
  mCol.Add tp, tp.gUsr.NickName

  tp.IDPlayer = getIDPlayer(gUsr, cnQ)

End If

Set getPlayer = tp




End Function


Public Sub AddScore(player As TriviaPlayer2, up As Long, questionsUp As Long, IDSubject As Long)


Utils.AddScore player.IDPlayer, up, questionsUp, IDSubject, IDTournament

player.score = player.score + up

Exit Sub
With player.rcStatistics
  .Find "IDSubject=" & IDSubject
  If .EOF Then
    .AddNew
    !IDTournament = IDTournament
    !IDSubject = IDSubject
    !IDPlayer = player.IDPlayer
  End If
  
  !QuestionsAnswered = !QuestionsAnswered + questionsUp
  !score = !score + up
  'On Error GoTo errUpd
updcont:
  .update
End With
  
player.score = player.score + up
Exit Sub




errUpd:

Dim tmr As Single
tmr = Timer
Do Until Timer > tmr + 2 Or Timer < 10
Loop
Debug.Print "bloqueo y espera (addscore)" & Now
Resume updcont


End Sub



Public Sub update(player As TriviaPlayer2)
    'create a new object

    Remove player.gUsr.NickName
    
    Dim tp As TriviaPlayer2
    Dim n As Long
    Dim f As Boolean
    n = 0
    For Each tp In mCol
      n = n + 1
      If player.score > tp.score Then
        f = True
        Exit For
      End If
    Next
    
    If Not f Then n = 0
    
    
    If n <> 0 Then
      mCol.Add player, player.gUsr.NickName, n
    Else
      mCol.Add player, player.gUsr.NickName
    End If
      

End Sub

Public Property Get Item(Name As Variant) As TriviaPlayer2
Attribute Item.VB_UserMemId = 0
  
On Error Resume Next
  
  Set Item = mCol(Name)
End Property



Public Property Get Count() As Long
    'used when retrieving the number of elements in the
    'collection. Syntax: Debug.Print x.Count
    Count = mCol.Count
End Property


Public Sub Remove(vntIndexKey As Variant)
    'used when removing an element from the collection
    'vntIndexKey contains either the Index or Key, which is why
    'it is declared as a Variant
    'Syntax: x.Remove(xyz)

On Error Resume Next

    mCol.Remove vntIndexKey
End Sub


Public Property Get NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
Attribute NewEnum.VB_MemberFlags = "40"
    'this property allows you to enumerate
    'this collection with the For...Each syntax
    Set NewEnum = mCol.[_NewEnum]
End Property


Private Sub Class_Initialize()
    'creates the collection when this class is created
    Set mCol = New Collection
End Sub


Private Sub Class_Terminate()
    'destroys collection when this class is terminated
    Set mCol = Nothing
End Sub

Sub changeBot(IRC As jIRCLib.CIRCClient)

Dim plr As TriviaPlayer2

For Each plr In mCol
  Set plr.gUsr = IRC.getUser(plr.gUsr.NickName)
Next

End Sub


Public Sub showScoresInChannel(Channel As Channel)
  Dim tp As TriviaPlayer2
  Dim rct As Recordset
  Dim n As Long
    Dim plr As TriviaPlayer2
  
  Set rct = OpenRecordsetRetry("SELECT IDPlayer, TotalScore FROM ScoresPerTournament WHERE IDTournament=" & IDTournament & " ORDER BY TotalScore desc", cnQ, adOpenStatic, adLockReadOnly, adUseClient, 5)
  
  If rct Is Nothing Then
    'error. omit total score.
    
    For Each plr In Me
      n = n + 1
        Channel.say mircColorText(mircBoldText(n & "º") & " " & plr.gUsr.NickName & " " & plr.score, mccBlack, mccLightGrey)
      If n >= 10 Then Exit For
    Next

  
  Else
   
    n = 0
    
    
    For Each plr In Me
      n = n + 1
      If Not rct.BOF Then rct.MoveFirst
      If rct!IDPlayer <> plr.IDPlayer Then
        rct.Find "IdPlayer=" & plr.IDPlayer
      End If
      If Not rct.EOF Then
        Channel.say mircColorText(mircBoldText(n & "º") & " " & plr.gUsr.NickName & " " & plr.score & " p. Clasificación General (" & mircBoldText(rct.AbsolutePosition & "º") & ", " & rct!totalscore & " p.)", mccBlack, mccLightGrey)
      End If
      
      If n >= 10 Then Exit For
    Next
    rct.Close
    
  End If

End Sub



Public Function OpenRecordsetRetry(Source As String, ByRef ActiveConnection As Connection, CursorType As ADODB.CursorTypeEnum, LockType As LockTypeEnum, CursorLocation As CursorLocationEnum, retries As Integer) As Recordset

Dim st As String
Dim rc As Recordset
On Error GoTo orr_error


orr_res:
  retries = retries - 1
  Set rc = New Recordset
  rc.CursorLocation = CursorLocation
  rc.Open Source, ActiveConnection, CursorType, LockType

  Set OpenRecordsetRetry = rc
orr_giveup:

Exit Function

orr_error:
If retries <= 0 Then Resume orr_giveup
Debug.Print "OpenRecordsetRetry"

st = ActiveConnection.ConnectionString
Set ActiveConnection = New Connection
ActiveConnection.Open st

Resume orr_res

End Function

