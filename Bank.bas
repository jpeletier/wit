Attribute VB_Name = "Bank"
Option Explicit

Public Const IDUser_Bank = 1


Public Function getIDUser(gUsr As GlobalUser) As Long

On Error Resume Next

getIDUser = 0
getIDUser = CLng(gUsr.Properties("IDUser"))

End Function

Public Function login(username As String, password As String) As Long

login = 0
On Error Resume Next

Dim cmd As New ADODB.Command

cmd.CommandText = "sp_login"
cmd.CommandType = adCmdStoredProc

cmd.Parameters.Append cmd.CreateParameter("@username", adVarChar, adParamInput, 75, username)
cmd.Parameters.Append cmd.CreateParameter("@password", adVarChar, adParamInput, 25, password)
cmd.Parameters.Append cmd.CreateParameter("@IDUser", adInteger, adParamOutput)

Set cmd.ActiveConnection = CnMgt

cmd.Execute

login = CLng(cmd.Parameters("@IDUSER").value)


End Function

Function formatW(amount As Long) As String
formatW = amount & " W$"
End Function


Function lockBalance(amount As Currency, IDUser As Long, description As String, Optional cn As Connection = Nothing) As String
If cn Is Nothing Then
    Set cn = CnMgt
End If

Dim cmd As New ADODB.Command

cmd.CommandText = "sp_lockBalance"
cmd.CommandType = adCmdStoredProc

cmd.Parameters.Append cmd.CreateParameter("@IDUser", adInteger, adParamInput, , IDUser)
cmd.Parameters.Append cmd.CreateParameter("@amount", adBigInt, adParamInput, , amount)
cmd.Parameters.Append cmd.CreateParameter("@description", adVarChar, adParamInput, 250, description)
cmd.Parameters.Append cmd.CreateParameter("@GUIDLock", adGUID, adParamOutput)
cmd.Parameters.Append cmd.CreateParameter("@error", adInteger, adParamOutput)



Set cmd.ActiveConnection = cn

cmd.Execute

Dim GUIDLock As String
Dim error As Integer
error = cmd.Parameters("@error").value

If error = 0 Then
    GUIDLock = cmd.Parameters("@GUIDLock").value
End If

lockBalance = GUIDLock


End Function

Public Sub unLockBalance(GUIDLock As String, Optional cn As Connection)
If cn Is Nothing Then
    Set cn = CnMgt
End If

Dim cmd As New ADODB.Command

cmd.CommandText = "sp_unlockBalance"
cmd.CommandType = adCmdStoredProc

cmd.Parameters.Append cmd.CreateParameter("@GUIDLock", adGUID, adParamInput, , GUIDLock)
cmd.Parameters.Append cmd.CreateParameter("@error", adInteger, adParamOutput)

Set cmd.ActiveConnection = cn

cmd.Execute


End Sub

Public Sub transferLockedBalance(GUIDLock As String, targetIDUser As Long, Optional cn As Connection)
If cn Is Nothing Then
    Set cn = CnMgt
End If

Dim cmd As New ADODB.Command

cmd.CommandText = "sp_transferLockedBalance"
cmd.CommandType = adCmdStoredProc

cmd.Parameters.Append cmd.CreateParameter("@GUIDLock", adGUID, adParamInput, , GUIDLock)
cmd.Parameters.Append cmd.CreateParameter("@targetIDUser", adInteger, adParamInput, , targetIDUser)
cmd.Parameters.Append cmd.CreateParameter("@error", adInteger, adParamOutput)

Set cmd.ActiveConnection = cn

cmd.Execute


End Sub

Public Function transferBalance(amount As Long, sourceIDUser As Long, targetIDUser As Long, Optional cn As Connection) As Integer
If cn Is Nothing Then
    Set cn = CnMgt
End If

Dim cmd As New ADODB.Command

cmd.CommandText = "sp_transferBalance"
cmd.CommandType = adCmdStoredProc

cmd.Parameters.Append cmd.CreateParameter("@sourceIDUser", adInteger, adParamInput, , sourceIDUser)
cmd.Parameters.Append cmd.CreateParameter("@targetIDUser", adInteger, adParamInput, , targetIDUser)
cmd.Parameters.Append cmd.CreateParameter("@amount", adBigInt, adParamInput, , amount)
cmd.Parameters.Append cmd.CreateParameter("@description", adVarChar, adParamInput, 100)
cmd.Parameters.Append cmd.CreateParameter("@error", adInteger, adParamOutput)

Set cmd.ActiveConnection = cn

cmd.Execute

transferBalance = cmd.Parameters("@error").value

End Function

Public Function getBalance(IDUser As Long, Optional cn As Connection) As Currency
If cn Is Nothing Then
    Set cn = CnMgt
End If

Dim cmd As New ADODB.Command

cmd.CommandText = "sp_getbalance"
cmd.CommandType = adCmdStoredProc

cmd.Parameters.Append cmd.CreateParameter("@IDUser", adInteger, adParamInput, , IDUser)
cmd.Parameters.Append cmd.CreateParameter("@balance", adBigInt, adParamOutput)
cmd.Parameters.Append cmd.CreateParameter("@error", adInteger, adParamOutput)

Set cmd.ActiveConnection = cn

cmd.Execute


getBalance = CLng(cmd.Parameters("@balance").value)

End Function
