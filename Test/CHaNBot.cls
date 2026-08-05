VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CHaNBot"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Private bot As GlobalUser
Private mCol As Collection

Public Function addChannel(channel As channel) As ChannelProperties

remove channel.name
Dim chprops As New ChannelProperties
chprops.initialize Me, channel
mCol.Add chprops, channel.name
Set addChannel = chprops

End Function


Public Property Get Item(name As String) As ChannelProperties
Attribute Item.VB_UserMemId = 0
On Error Resume Next
  Set Item = mCol(name)
End Property

Public Sub remove(name As String)
  On Error Resume Next
  mCol.remove name
End Sub

Public Property Get count() As Long
  count = mCol.count
End Property

Public Sub clear()
  
  terminate
  
  Set mCol = New Collection
 
End Sub

Public Function NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
Attribute NewEnum.VB_MemberFlags = "40"
  Set NewEnum = mCol.[_NewEnum]
End Function


Public Sub initialize(xClient As CIRCClient)
  Set bot = xClient.getUser("chan")
End Sub

Public Property Get gUsr() As GlobalUser
  Set gUsr = bot
End Property

Public Property Get client() As CIRCClient
  Set client = bot.Parent
End Property


Public Sub terminate()
  Dim ch As ChannelProperties
  For Each ch In mCol
    ch.terminate
  Next
End Sub

Private Sub Class_Initialize()
  Set mCol = New Collection
End Sub
