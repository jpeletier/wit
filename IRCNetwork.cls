VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IRCNetwork"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False

Private mIDNetwork As Long

Private mOnConnect_RAW As String
Private mAllowJOIN_SC As Boolean
Private mJoinFree As Boolean
Private mName As String



Public Sub initialize(IDNetwork As Long)
mIDNetwork = IDNetwork

CheckManagementConnection

Dim rc As New Recordset

rc.Open "SELECT * FROM IRCNetworks where IDNetwork=" & IDNetwork, CnMgt, adOpenForwardOnly, adLockReadOnly

mOnConnect_RAW = "" & rc!OnConnect_RAW
mAllowJOIN_SC = rc!AllowJOIN_SC
mJoinFree = rc!JoinFree
mName = rc!networkName


End Sub

Public Property Get IDNetwork() As Long
 IDNetwork = mIDNetwork
End Property

Public Property Get OnConnect_RAW() As String
 OnConnect_RAW = mOnConnect_RAW
End Property

Public Property Get Name() As String
 Name = mName
End Property


Public Property Get AllowJOIN_SC() As Boolean
 AllowJOIN_SC = mAllowJOIN_SC
End Property


Public Property Get JoinFree() As Boolean
    JoinFree = mJoinFree
End Property


Public Function getChannels()
End Function

