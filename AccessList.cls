VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "AccessList"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Collection" ,"AccessListEntry"
Attribute VB_Ext_KEY = "Member0" ,"AccessListEntry"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Attribute VB_Ext_KEY = "Member1" ,"CHaNBot"
Option Explicit
'local variable to hold collection
Private mCol As Collection

Private lastGenerated As Date

Private Const MAX_AGE = 60

Public WithEvents CHaNBot As CHaNBot
Attribute CHaNBot.VB_VarHelpID = -1
Public Channel As String

Private WithEvents timeout As CTimer
Attribute timeout.VB_VarHelpID = -1

Private mReady As Boolean
Private notifyList As Collection

Public Property Get ready() As Boolean
  ready = mReady
End Property

Public Property Get isCurrent() As Boolean

isCurrent = DateDiff("n", lastGenerated, Now) < MAX_AGE

End Property


Public Function Add(level As Integer, nick As String) As AccessListEntry
    'create a new object
    
    Remove nick
    
    Dim objNewMember As AccessListEntry
    Set objNewMember = New AccessListEntry


    'set the properties passed into the method
    objNewMember.level = level
    objNewMember.nick = nick
    If Len(nick) = 0 Then
        mCol.Add objNewMember
    Else
        mCol.Add objNewMember, nick
    End If


    'return the object created
    Set Add = objNewMember
    Set objNewMember = Nothing


End Function

Public Property Get Item(nick As String) As AccessListEntry
Attribute Item.VB_UserMemId = 0
    'used when referencing an element in the collection
    'vntIndexKey contains either the Index or Key to the collection,
    'this is why it is declared as a Variant
    'Syntax: Set foo = x.Item(xyz) or Set foo = x.Item(5)
    
  On Error Resume Next
    
  Set Item = mCol(nick)
End Property



Public Property Get Count() As Long
    'used when retrieving the number of elements in the
    'collection. Syntax: Debug.Print x.Count
    Count = mCol.Count
End Property


Public Sub Remove(nick As String)
    'used when removing an element from the collection
    'vntIndexKey contains either the Index or Key, which is why
    'it is declared as a Variant
    'Syntax: x.Remove(xyz)

  On Error Resume Next

    mCol.Remove nick
End Sub


Public Property Get NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
Attribute NewEnum.VB_MemberFlags = "40"
    'this property allows you to enumerate
    'this collection with the For...Each syntax
    Set NewEnum = mCol.[_NewEnum]
End Property


Private Sub CHaNBot_OnAccessListCompleted(Channel As jIRCLib.Channel)

If Channel.name = Me.Channel Then
  timeout_ThatTime
End If

End Sub

Private Sub CHaNBot_OnAccessListLine(Channel As jIRCLib.Channel, level As Integer, nick As String)
  
  If Channel.name = Me.Channel Then
  
    If Count = 0 Then
      mReady = False
      lastGenerated = Now
      Set timeout = New CTimer
      timeout.TimeScale = TU_Minutes
      timeout.Interval = 1
    End If
    Add level, nick
  End If

End Sub

Private Sub Class_Initialize()
    'creates the collection when this class is created
    Set mCol = New Collection
    lastGenerated = 0
    Set notifyList = New Collection
End Sub


Private Sub Class_Terminate()
    'destroys collection when this class is terminated
    Set mCol = Nothing
End Sub

Private Sub clear()
  Set mCol = New Collection
End Sub

Public Function level(nick As String) As Integer

Dim ale As AccessListEntry

Set ale = Item(nick)
If ale Is Nothing Then
  level = 0
Else
  level = ale.level
End If

End Function

Private Sub timeout_ThatTime()
    
  On Error Resume Next
  Set timeout = Nothing
  mReady = True
  Set CHaNBot = Nothing
  
  Dim gUsr As GlobalUser
  
  For Each gUsr In notifyList
    gUsr.notice "He terminado de comprobar la lista de acceso de " & Channel & ". Tu nivel es " & level(gUsr.NickName)
  Next


End Sub


Public Sub addToNotifyList(gUsr As GlobalUser)

notifyList.Add gUsr

End Sub
