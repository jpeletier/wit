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
Set tp = Item(gUsr.nickName)



If tp Is Nothing Then
  Set tp = New TriviaPlayer2
  Set tp.gUsr = gUsr
  mCol.Add tp, tp.gUsr.nickName

  Dim Players As Recordset
  Set Players = New Recordset

  With Players
    .Open "SELECT IDPlayer,NickName,lastused FROM Players WHERE NickName='" & gUsr.nickName & "'", cnQ, adOpenDynamic, adLockOptimistic
    If .EOF Then
      .AddNew
      !nickName = gUsr.nickName
    End If
      !lastused = Now
      .update
      .Close
      .Open "SELECT IDPlayer FROM Players WHERE NickName='" & gUsr.nickName & "'", cnQ, adOpenDynamic, adLockOptimistic
      tp.IDPlayer = !IDPlayer
  End With
  
  Players.Close
  Set Players = Nothing

    
  Set tp.rcStatistics = New Recordset
  With tp.rcStatistics
    .Open "SELECT * FROM ScoresT WHERE IDPlayer=" & tp.IDPlayer & " AND IDTournament=" & IDTournament, cnQ, adOpenKeyset, adLockOptimistic
  End With
      
End If

Set getPlayer = tp











Exit Function


errUpd:

'Dim tmr As Single
'tmr = Timer
'Do Until Timer > tmr + 2 Or Timer < 10
'Loop
'Debug.Print "bloqueo y espera " & Now
'Resume updcont




End Function


Public Sub AddScore(player As TriviaPlayer2, up As Long, questionsUp As Long, IDSubject As Long)


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

    Remove player.gUsr.nickName
    
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
      mCol.Add player, player.gUsr.nickName, n
    Else
      mCol.Add player, player.gUsr.nickName
    End If
      

End Sub

Public Property Get Item(name As Variant) As TriviaPlayer2
Attribute Item.VB_UserMemId = 0
  
On Error Resume Next
  
  Set Item = mCol(name)
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
  Set plr.gUsr = IRC.getUser(plr.gUsr.nickName)
Next

End Sub
