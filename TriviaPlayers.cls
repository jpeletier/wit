VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TriviaPlayers"
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
Private gRanking As Recordset


Friend Sub initialize(cn As Connection)

Set cnQ = cn
Set gRanking = New Recordset
gRanking.Open "SELECT * FROM Ranking ORDER BY SCORE DESC", cnQ, adOpenKeyset, adLockOptimistic

End Sub


Function getPlayer(gUsr As GlobalUser) As TriviaPlayer

Dim tp As TriviaPlayer
Set tp = Item(gUsr.nickName)
If tp Is Nothing Then
  Set tp = New TriviaPlayer
  Set tp.gUsr = gUsr
  mCol.Add tp, tp.gUsr.nickName

  With gRanking
    .Requery
    .Find "Nick='" & gUsr.nickName & "'"
    If .EOF Then
      .AddNew
      !nick = gUsr.nickName
      !lastupdate = Now
      .update
    End If
    tp.IDRank = !IDRank
    tp.totalScore = !score
    tp.score = 0
  End With
End If

Set getPlayer = tp


End Function


Public Sub AddScore(player As TriviaPlayer, up As Long, questionsUp As Long)
player.score = player.score + up
player.totalScore = player.totalScore + up

If Not player.IDRank = 0 Then
  If Not gRanking.EOF Then gRanking.MoveFirst
  gRanking.Find "IDRANK=" & player.IDRank
  
  If gRanking.EOF Then
    Debug.Print "AddScore(): No se encontró IDRank=" & player.IDRank
  Else
  
    gRanking!score = gRanking!score + up
    gRanking!lastupdate = Now
    gRanking!correctanswers = gRanking!correctanswers + questionsUp
    gRanking.update
  
  End If

End If
End Sub


Public Sub Requery()
  gRanking.Requery
End Sub

Public Function PlayerRank(player As TriviaPlayer) As Long

  If Not gRanking.EOF Then gRanking.MoveFirst
  gRanking.Find "IDRANK=" & player.IDRank
  
  If gRanking.EOF Then
    Debug.Print "PlayerRank(): No se encontró IDRank=" & player.IDRank
  Else
    PlayerRank = gRanking.AbsolutePosition
  End If

End Function





Public Sub update(player As TriviaPlayer)
    'create a new object

    Remove player.gUsr.nickName
    
    Dim tp As TriviaPlayer
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

Public Property Get Item(name As Variant) As TriviaPlayer
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

