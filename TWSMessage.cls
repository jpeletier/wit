VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TWSMessage"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1
Private sock As Socket

Private self As TWSMessage




Public Sub initialize(sck As Socket, message As String)
      
  Set sock = sck
  
  Set tmr = New CTimer
  tmr.SharedTimer = True
  tmr.TimeScale = TU_Seconds
  tmr.Interval = 5
  
 rawOutput "MSG " & message & vbCrLf
 
 Debug.Print "TWSMessage to " & sck.PeerAddress & " : " & message
 

End Sub
Private Sub rawOutput(st As String)
  sock.Write st, Len(st)
End Sub

Private Sub Class_Terminate()
  Debug.Print "TWSMessage terminated"
End Sub


Private Sub tmr_ThatTime()

On Error Resume Next
  sock.Flush
  sock.action = SOCKET_CLOSE
  

  Set sock = Nothing
  Set tmr = Nothing
  Set self = Nothing

End Sub

