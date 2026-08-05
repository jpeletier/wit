VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "NiCKBot"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Enum NiCKStatusEnum
  nckstUnknownStatus = -1
  nckstNotConnected = 0
  nckstUnrecognized = 1
  nckstIdentifiedPerAccessList = 2
  nckstIdentifiedByPassword = 3
End Enum

Private Const NiCKStatus = "NiCKStatus"


Private WithEvents mgUsr As jIRCLib.GlobalUser
Attribute mgUsr.VB_VarHelpID = -1
Private mClient As jIRCLib.CIRCClient

'Private msgLoop As New MessageLoop
Private msgSTATUS As Long

Public Event StatusResponse(gUsr As jIRCLib.GlobalUser)


Public Sub initialize(Client As CIRCClient)

  Set mgUsr = Client.getUser("NiCK")
  Set mClient = Client

End Sub

Public Sub identify(password As String)
  mClient.privateMessage "nick@deep.space", "IDENTIFY " & password
End Sub

Public Sub requestNickStatus(glUser As jIRCLib.GlobalUser)
  mgUsr.privateMessage "STATUS " & glUser.NickName
End Sub

Public Sub requestGlobalUsersStatus(glUsers As jIRCLib.GlobalUsers)
  
  Dim st As String
  Dim g As GlobalUser
  Dim n As Long
  For Each g In glUsers
    st = st & g.NickName & " "
    n = n + 1
    If n >= 15 Then
      n = 0
      mgUsr.privateMessage "STATUS " & st
      st = ""
    End If
  Next
  
  If st <> "" Then
    mgUsr.privateMessage "STATUS " & st
  End If
  
End Sub

Public Sub requestUsersStatus(Users As jIRCLib.Users)
  Dim st As String
  Dim u As User
  Dim n As Long
  For Each u In Users
    
    st = st & u.NickName & " "
    n = n + 1
    If n >= 15 Then
      n = 0
      mgUsr.privateMessage "STATUS " & st
      st = ""
    End If
  Next
  
  If st <> "" Then
    mgUsr.privateMessage "STATUS " & st
  End If
  
End Sub


Public Sub recover(glUser As jIRCLib.GlobalUser, password As String)
  mgUsr.privateMessage "RECOVER " & glUser.NickName & " " & password
End Sub

Private Sub Class_Initialize()
  'msgSTATUS = jSpMsgLoop.getUniqueMsg()
End Sub

Private Sub mgUsr_OnPrivateMessage(text As String, cancel As Boolean)

If Left(text, 6) = "STATUS" Then
  Dim cmd() As String
  cmd = Split(text, " ", 4)
    
  Dim glUser As GlobalUser
  Set glUser = mClient.knownUsers(cmd(1))
  
  If Not glUser Is Nothing Then
    glUser.Properties(NiCKStatus) = cmd(1) & " " & cmd(2)
    RaiseEvent StatusResponse(glUser)
    'jSpMsgLoop.postMsg "NICKSTATUS_" & glUser.nickName
  End If
  
End If
  

End Sub

Public Function getNickStatus(gUsr As GlobalUser) As NiCKStatusEnum

Dim st As String

st = gUsr.Properties(NiCKStatus)

If st = "" Then
  getNickStatus = nckstUnknownStatus
  Exit Function

'  Debug.Print "Request"
'  requestNickStatus gUsr
'  Debug.Print "Waiting"
'  If msgLoop.WaitFor(30000, True, "NICKSTATUS_" & gUsr.nickName) Then
'    getNickStatus = nckstUnknownStatus
'    Exit Function
'  Else
'    Debug.Print "End Wait"
'    st = gUsr.Properties(NiCKStatus)
'  End If
End If


  Dim cmd() As String
  cmd = Split(st, " ", 2)
  If UBound(cmd) < 1 Or st = "" Then Exit Function
  If cmd(0) <> gUsr.NickName Then
    getNickStatus = nckstUnknownStatus
    gUsr.Properties.Remove NiCKStatus
  Else
    getNickStatus = Val(cmd(1))
  End If
Debug.Print "Status=" & Val(cmd(1))

End Function

Public Property Get gUsr() As GlobalUser
  Set gUsr = mgUsr
End Property

