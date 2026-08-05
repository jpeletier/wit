VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CTrivCtrl"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Implements IChannelControl

Private WithEvents Channel As Channel
Attribute Channel.VB_VarHelpID = -1
Private IDChannel As Long
Private rank As Recordset
Private cn As Connection
Private WithEvents NiCKBot As NiCKBot

Private Sub CheckOP(u As User)

If Not rank.BOF Then rank.MoveFirst
  rank.Find "nickname='" & u.nickName & "'"
  If Not rank.EOF Then
    If rank.AbsolutePosition <= 35 Then
    
      Dim nickStatus As NiCKStatusEnum
    
      nickStatus = NiCKBot.getNickStatus(u.gUsr)
      
      If nickStatus = nckstIdentifiedByPassword Then
        Select Case rank.AbsolutePosition
          Case Is <= 5
            u.operator = True
          Case Is <= 35
            u.voice = True
        End Select
      Else
        If nickStatus = nckstUnknownStatus Then
          u.gUsr.Properties(Channel.name & "_NICKSTATUS") = True
          NiCKBot.requestNickStatus u.gUsr
        End If
      
      End If
  End If
End If

End Sub

Private Sub Channel_OnJoin(who As jIRCLib.User, cancel As Boolean)

CheckOP who

End Sub

Private Sub IChannelControl_DoSomething(op As Long, ParamArray parms() As Variant)

If op = 1 Then
  op = 0
  rank.Requery
End If

Select Case op
  Case 0
    Dim u As User
    For Each u In Channel.Users
      CheckOP u
    Next
End Select

End Sub



Private Sub IChannelControl_Initialize(ch As jIRCLib.Channel, ParamArray parms() As Variant)
  Set Channel = ch
  Set rank = New Recordset
  Set cn = New Connection
  cn.Open parms(0)
  
  Dim tmp As Variant
  tmp = QuerySingleValue("SELECT IDChannel FROM Channels WHERE name='" & Replace(ch.name, "'", "''") & "'", cn)
  
  If IsNumeric(tmp) Then
    IDChannel = CLng(tmp)
  Else
    Debug.Print "El canal " & ch.name & " no existe en bd trivial."
    Exit Sub
  End If
  
  
  rank.Open "SELECT TOP 50 NickName,TotalScore from PlayerScoresPerLeagueChannel WHERE IDChannel='" & IDChannel & "' AND IDLeague=" & activeLeague & " ORDER BY TotalScore desc", cn, adOpenStatic, adLockReadOnly
  
  
  Set NiCKBot = parms(1)
  
  
End Sub

Private Sub IChannelControl_Terminate()
  rank.Close
  cn.Close
End Sub

Private Sub NiCKBot_StatusResponse(gUsr As jIRCLib.GlobalUser)

If gUsr.Properties(Channel.name & "_NICKSTATUS") = True Then
  gUsr.Properties(Channel.name & "_NICKSTATUS") = Empty
  If NiCKBot.getNickStatus(gUsr) = nckstIdentifiedByPassword Then
    Dim u As User
    Set u = Channel.Users(gUsr)
    If Not u Is Nothing Then
      CheckOP u
    End If
  End If
End If

End Sub
