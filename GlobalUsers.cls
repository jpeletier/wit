VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "GlobalUsers"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

'local variable to hold collection
Private mCol As jGhostRef.GRCollection

Friend Function Add(ByVal Key As String, Optional gU As GlobalUser = Nothing) As GlobalUser
    
    Dim objNewMember As GlobalUser
    
    
    Set objNewMember = Item(Key)
    
    If objNewMember Is Nothing Then
      If gU Is Nothing Then
        Set objNewMember = New GlobalUser
      Else
        Set objNewMember = gU
      End If
      mCol.Add objNewMember, Key
    End If

    'return the object created
    Set Add = objNewMember
    Set objNewMember = Nothing


End Function

Public Property Get Item(vntIndexKey As Variant) As GlobalUser
Attribute Item.VB_UserMemId = 0
    'used when referencing an element in the collection
    'vntIndexKey contains either the Index or Key to the collection,
    'this is why it is declared as a Variant
    'Syntax: Set foo = x.Item(xyz) or Set foo = x.Item(5)
  On Error Resume Next
  Set Item = mCol(vntIndexKey)
End Property



Public Property Get Count() As Long
    'used when retrieving the number of elements in the
    'collection. Syntax: Debug.Print x.Count
    Count = mCol.Count
End Property


Friend Sub Remove(vntIndexKey As Variant)
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
    Set NewEnum = mCol.NewEnum
End Property


Private Sub Class_Initialize()
    'creates the collection when this class is created
    Set mCol = New jGhostRef.GRCollection
End Sub


Private Sub Class_Terminate()
    'destroys collection when this class is terminated
    Set mCol = Nothing
End Sub


Public Property Get Exists(nick As String) As Boolean

  Exists = Not Item(nick) Is Nothing

End Property


Public Sub clear()
  
  Do Until mCol.Count = 0
    mCol.Remove 1
  Loop

End Sub
