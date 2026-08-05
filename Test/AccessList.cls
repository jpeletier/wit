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
Attribute VB_Ext_KEY = "Top_Level" ,"No"
Attribute VB_Ext_KEY = "Collection" ,"AccessNode"
Attribute VB_Ext_KEY = "Member0" ,"AccessNode"
Option Explicit

'local variable to hold collection
Private mCol As Collection
Private WithEvents mBot As GlobalUser

Private requesting As Boolean
Private listening As Boolean
Private rndreq As String
Private WithEvents msgLoop As jSpMsgLoop.MessageLoop
Attribute msgLoop.VB_VarHelpID = -1

Private chprops As ChannelProperties

Friend Sub terminate()
  Set chprops = Nothing
  Set mCol = Nothing
  Set mBot = Nothing
End Sub

Friend Sub initialize(ChannelProperties As ChannelProperties)
  Set chprops = ChannelProperties
  
  
  Set mBot = chprops.chan.gUsr
  
  
  rndreq = "" & Int(Rnd * 1000000)
  
  mBot.privateMessage "ACCESS " & chprops.channel.name & " LIST"
  mBot.privateMessage rndreq
  
  Set msgLoop = initMessageLoop(msgLoop)
  msgLoop.WaitFor 20000, False, "CHAN_ACCESSLIST_" & chprops.channel.name
  
End Sub


Public Function Add(gUsr As GlobalUser, level As Integer, Optional updateToBot As Boolean = True) As AccessNode
    'create a new object
    Dim objNewMember As AccessNode
    Set objNewMember = New AccessNode


  'set the properties passed into the method
     Set objNewMember.gUsr = gUsr
        objNewMember.level = level
    
        mCol.Add objNewMember, gUsr.nickName


    'return the object created
    Set Add = objNewMember
    Set objNewMember = Nothing


End Function

Public Property Get Item(vntIndexKey As Variant) As AccessNode
Attribute Item.VB_UserMemId = 0

  Set Item = mCol(vntIndexKey)
End Property



Public Property Get count() As Long
    count = mCol.count
End Property


Public Sub remove(vntIndexKey As Variant)


    mCol.remove vntIndexKey
End Sub


Public Property Get NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
Attribute NewEnum.VB_MemberFlags = "40"
    Set NewEnum = mCol.[_NewEnum]
End Property


Private Sub Class_Initialize()
    Set mCol = New Collection
End Sub


Private Sub Class_Terminate()
    Set mCol = Nothing
End Sub

Private Sub mBot_OnPrivateMessage(text As String, cancel As Boolean)

If Not requesting Then Exit Sub

text = mIRCFilterCodes(text)

If text = "Lista de acceso de " & chprops.channel.name & ":" Then
  listening = True
  Set mCol = New Collection
  Exit Sub
End If

If listening Then
  If InStr(1, text, rndreq) Then
    listening = False
    requesting = False
    postMsg "CHAN_ACCESSLIST_" & chprops.channel.name
    Exit Sub
  End If
  
  Dim a() As String
  
  text = Trim(text)
  text = Replace(text, "   ", " ")
  text = Replace(text, "  ", " ")
  a = Split(text, " ", 3)
  
  If UBound(a) < 2 Then Exit Sub
  
  
  Add chprops.chan.client.getUser(a(1)), Val(a(2)), False
  
  Debug.Print a(1) & " " & a(2)
  



End If


End Sub

Private Sub msgLoop_ExitedAllLoops()
  Set msgLoop = Nothing
End Sub
