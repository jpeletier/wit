Function QuerySingleValue(sql)

dim rcqs

set rcqs=createobject("ADODB.Recordset")
rcqs.Open sql, cn, 3,1

If rcqs.EOF Then
  QuerySingleValue = Null
Else
  QuerySingleValue = rcqs.Fields(0).Value
End If

End Function


'set cmd= createObject("jcore.CExecutive")
'cmd.Run "<redacted-path>"

dim cn
set cn=CreateObject("ADODB.Connection")
cn.Open "PROVIDER=sqloledb;DATA SOURCE=****;USER ID=****;PASSWORD=****;INITIAL CATALOG=Trivial"


activeLeague=QuerySingleValue( "SELECT TOP 1 IDLeague FROM Leagues ORDER BY idleague DESC")


cn.execute "EXEC Generate_ScoresPerPlayerTotalByQSubset " & activeleague
