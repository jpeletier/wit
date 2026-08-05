VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "DCChatCollection"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Option Compare Text

Private WithEvents mCol As jEventCollection.EventCollection
Attribute mCol.VB_VarHelpID = -1

Public Event OnConnect(Index As Long, source As DccChat)
Public Event OnDisconnect(Index As Long, source As DccChat)
Public Event OnMessage(Index As Long, source As DccChat, text As String)
Public Event OnTimeout(Index As Long, source As DccChat)

Private Sub Class_Initialize()
  Set mCol = New EventCollection
End Sub

Private Sub mCol_EventRaised(ByVal Index As Long, ByVal source As Object, ByVal RaisedEvent As Variant, aParams() As Variant)

Select Case RaisedEvent
  Case "OnConnect"
    RaiseEvent OnConnect(Index, source)
  Case "OnDisconnect"
    RaiseEvent OnDisconnect(Index, source)
  Case "OnMessage"
    RaiseEvent OnMessage(Index, source, CStr(aParams(0)))
  Case "OnTimeout"
    RaiseEvent OnTimeout(Index, source)
End Select

End Sub

Public Property Get Col() As EventCollection
  Set Col = mCol
End Property
