VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ChannelProperties"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private bot As CHaNBot
Private mChannel As channel
Private mAccessList As accessList

Friend Sub initialize(chan As CHaNBot, xChannel As channel)
  Set bot = chan
  Set mChannel = xChannel

End Sub

Public Property Get accessList() As accessList
If mAccessList Is Nothing Then
  Set mAccessList = New accessList
  mAccessList.initialize Me
End If
End Property

Public Property Get chan() As CHaNBot
Set chan = bot
End Property

Public Property Get channel() As channel
  Set channel = mChannel
End Property

Friend Sub terminate()
  mAccessList.terminate
  Set bot = Nothing
  Set mChannel = Nothing
  
  Set mAccessList = Nothing
  
End Sub
