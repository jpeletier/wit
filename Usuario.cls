VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "User"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"No"
Option Explicit

Private mOperator As Boolean
Private mVoice As Boolean
Private mBanned As Boolean
Private mChannelName As String
Private parent As CIRCClient
Private mProperties As CFairCollection

Public Event OnOpStatusChange(byWho As GlobalUser)
Public Event OnVoiceStatusChange(byWho As GlobalUser)
Public Event OnBanStatusChange(byWho As GlobalUser, nickNameMask As String, userNameMask As String, hostNameMask As String)

Private mGlobalUser As GlobalUser

Friend Sub SetGlobalUser(gUsr As GlobalUser)
  Set mGlobalUser = gUsr
End Sub

Public Property Get gUsr() As GlobalUser
  Set gUsr = mGlobalUser
End Property

Public Property Get hostName() As String
  hostName = mGlobalUser.hostName
End Property

Public Property Get userName() As String
  userName = mGlobalUser.userName
End Property


Public Property Get nickName() As String
Attribute nickName.VB_UserMemId = 0
  nickName = mGlobalUser.nickName
End Property

Public Property Get operator() As Boolean
  operator = mOperator
End Property

Public Property Let operator(nv As Boolean)
  channel.setMode nv, "o", , , Me
End Property

Friend Sub setOperator(nv As Boolean, byWho As GlobalUser)
  If nv <> mOperator Then
    mOperator = nv
    If Not byWho Is Nothing Then RaiseEvent OnOpStatusChange(byWho)
  End If
  
End Sub

Public Property Get voice() As Boolean
  voice = mVoice
End Property

Public Property Let voice(nv As Boolean)
  channel.setMode nv, "v", , , Me
End Property
Friend Sub setVoice(nv As Boolean, byWho As GlobalUser)
  If nv <> mVoice Then
    mVoice = nv
    If Not byWho Is Nothing Then RaiseEvent OnVoiceStatusChange(byWho)
  End If
  
End Sub

Public Property Get banned() As Boolean
  banned = mBanned
End Property

Public Property Let banned(nv As Boolean)
  channel.setMode nv, "b", , , Me
End Property

Friend Sub setBanStatus(nv As Boolean, byWho As GlobalUser, nickNameMask As String, userNameMask As String, hostNameMask As String)
  If nv <> mBanned Then
    mBanned = nv
    If Not byWho Is Nothing Then RaiseEvent OnBanStatusChange(byWho, nickNameMask, userNameMask, hostNameMask)
  End If
  
End Sub

Friend Sub initialize(p As CIRCClient, cName)
  Set parent = p
  mChannelName = cName
End Sub

Public Property Get channel() As channel
'mchannelname="" y parent=nothing ????
  Set channel = parent.getChannel(mChannelName)
End Property

Public Property Get Properties() As CFairCollection
  If mProperties Is Nothing Then
    Set mProperties = New CFairCollection
  End If
  
  Set Properties = mProperties
End Property

Public Sub kick(why As String)
  parent.kickUser mChannelName, Me.nickName, why
End Sub

