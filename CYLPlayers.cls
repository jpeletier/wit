VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CYLPlayers"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'local variable to hold collection
Private mCol As Collection
Private cnQ As Connection
Private IDCYLTournament As Long

Public Enum CYL_ChallengeType
CYL_Cifras = 0
CYL_Letras = 1
End Enum




Friend Sub initialize(cn As Connection, xIDCYLTournament As Long)

Set cnQ = cn

IDCYLTournament = xIDCYLTournament

End Sub


Function getPlayer(gUsr As GlobalUser) As CYLPlayer

Dim tp As CYLPlayer
Set tp = Item(gUsr.NickName)
If tp Is Nothing Then
  Set tp = New CYLPlayer
  Set tp.gUsr = gUsr
  tp.IDPlayer = getIDPlayer(gUsr.NickName, cnQ)
  mCol.Add tp, tp.gUsr.NickName

End If

Set getPlayer = tp


End Function


Public Sub AddScore(player As CYLPlayer, up As Long, ChallengesUp As Long, IDChallengeType As CYL_ChallengeType)


Utils.AddCYLScore player.IDPlayer, up, ChallengesUp, IDChallengeType, IDCYLTournament

player.score = player.score + up


End Sub



Public Sub update(player As CYLPlayer)
    'create a new object

    Remove player.gUsr.NickName
    
    Dim tp As CYLPlayer
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

Public Property Get Item(name As Variant) As CYLPlayer
  
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

