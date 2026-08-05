VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TAutoIPBan"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1

Private self As TAutoIPBan

Private IRC As CIRCClient


Public Sub initialize(i As CIRCClient)
      
  Set IRC = i
  Set self = Me
  
  
  Set tmr = New CTimer
  tmr.SharedTimer = True
  tmr.TimeScale = TU_Seconds
  tmr.Interval = 10
  

End Sub

Private Sub Class_Terminate()
  Debug.Print "AutoIPBan Terminated"
End Sub


Private Sub tmr_ThatTime()
  On Error Resume Next
  Set tmr = Nothing
  LogLine "Protocol Tampering", "Tampering detected from " & IRC.remoteAddress
  frmWit.ipBanList.Add IRC.remoteAddress, "Protocol tampering", "Wit"
  Set self = Nothing
  Set IRC = Nothing

End Sub

