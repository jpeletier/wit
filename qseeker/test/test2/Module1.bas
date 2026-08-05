Attribute VB_Name = "Module1"
Option Explicit


Public Declare Function GetTickCount Lib "kernel32" () As Long


Public cn As Connection


Public Function TrivialDatabase() As String
  TrivialDatabase = ConMSSQL("Trivial", "****", "****")  ' ConStrAccess(App.Path & "\trivia.mdb")
End Function

Public Function ConMSSQL(bd As String, uid As String, pwd As String, Optional server As String = "****") As String

'  ConMSSQL = "Provider=sqloledb;Server=" & server & ";Database=" & bd & ";uid=" & uid & ";pwd=" & pwd
ConMSSQL = "PROVIDER=sqloledb;DATA SOURCE=" & server & ";USER ID=" & uid & ";PASSWORD=" & pwd & ";INITIAL CATALOG=" & bd
End Function



Function QuerySingleValue(sql As String, cn As ADODB.Connection)

Dim rcqs As Recordset

Set rcqs = New Recordset
rcqs.Open sql, cn, adOpenStatic, adLockReadOnly

If rcqs.EOF Then
  QuerySingleValue = Null
Else
  QuerySingleValue = rcqs.Fields(0).Value
End If

End Function

