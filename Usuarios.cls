VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Users"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"No"
Attribute VB_Ext_KEY = "Collection" ,"Usuario"
Attribute VB_Ext_KEY = "Member0" ,"Usuario"
Option Explicit

'local variable to hold collection
Private mCol As Collection
Private WithEvents parent As CIRCClient
Attribute parent.VB_VarHelpID = -1
Public Event OnNickChange(usr As User, newNick As String)
Private mChannelName As String

Friend Sub initialize(newParent As CIRCClient, cName As String)
  Set parent = newParent
  mChannelName = cName
End Sub


Friend Function Add(gU As GlobalUser) As User
    
    Dim nu As User
    Set nu = Item(gU.nickName)
    
    If nu Is Nothing Then
      Set nu = New User
      mCol.Add nu, gU.nickName
      
    End If
    nu.initialize parent, mChannelName
    nu.SetGlobalUser gU
    Set Add = nu
    
    


End Function

Public Property Get Item(vntIndexKey As Variant) As User
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


Friend Sub Remove(gU As GlobalUser)
    'used when removing an element from the collection
    'vntIndexKey contains either the Index or Key, which is why
    'it is declared as a Variant
    'Syntax: x.Remove(xyz)

  On Error Resume Next
    mCol.Remove gU.nickName
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

Private Sub parent_OnNickChange(gU As GlobalUser, ByVal newNick As String)
Dim usr As User
  Set usr = Item(gU.nickName)
  If Not usr Is Nothing Then
    On Error Resume Next
    mCol.Remove gU.nickName
    mCol.Add usr, newNick
    RaiseEvent OnNickChange(usr, newNick)
  End If
End Sub


Public Sub Clear()
  Set mCol = New Collection
End Sub
