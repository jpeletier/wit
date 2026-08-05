Attribute VB_Name = "Module1"
Option Explicit

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
