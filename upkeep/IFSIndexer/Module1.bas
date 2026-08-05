Attribute VB_Name = "Module1"
Option Explicit

Dim cn As Connection


Function QuerySingleValue(sql)

Dim rcqs As Recordset

Set rcqs = New Recordset
rcqs.Open sql, cn, adOpenStatic, adLockReadOnly

If rcqs.EOF Then
  QuerySingleValue = Null
Else
  QuerySingleValue = rcqs.Fields(0).Value
End If

End Function


Public Function TrivialDatabase() As String
  TrivialDatabase = ConMSSQL("Trivial", "****", "****")  ' ConStrAccess(App.Path & "\trivia.mdb")
End Function

Public Function ConMSSQL(bd As String, uid As String, pwd As String, Optional server As String = "****") As String

'  ConMSSQL = "Provider=sqloledb;Server=" & server & ";Database=" & bd & ";uid=" & uid & ";pwd=" & pwd
ConMSSQL = "PROVIDER=sqloledb;DATA SOURCE=" & server & ";USER ID=" & uid & ";PASSWORD=" & pwd & ";INITIAL CATALOG=" & bd
End Function

Public Function getMaxIFS(IDSubject) As Long

Dim tmp As Variant
tmp = QuerySingleValue("SELECT MAX(IFS) AS MaxIFS From Questions_Table Where (IDSubject = " & IDSubject & ")")

If IsNull(tmp) Then
  getMaxIFS = 0
Else
  getMaxIFS = CLng(tmp)
End If


End Function


Sub Main()
Set cn = New ADODB.Connection

Dim rcs As New Recordset
Dim rc As New Recordset

cn.Open TrivialDatabase


rcs.Open "SELECT subject ,IDSubject,cnt from subjects", cn, adOpenStatic, adLockOptimistic

Dim lastIFS As Long
Dim IFS As Long


Dim regstart As Long
Dim regend As Long
Dim rcount As Long
Dim nullsptr As Long


Do Until rcs.EOF
  
  Debug.Print rcs!subject & ": ";
   
  rc.CursorLocation = adUseClient
  
  'COLUMNA SOURCE
  '-1 reci�n habilitada
  '-2 en juego
  '0 en evaluaci�n
  
  rc.Open "SELECT IFS FROM Questions_table where (Source =-2 AND IDSubject=" & rcs!IDSubject & ") ORDER BY IFS", cn, adOpenKeyset, adLockBatchOptimistic
  
  lastIFS = 0
  If Not rc.EOF Then
    
    rc.MoveLast
    rcount = rc.AbsolutePosition
    rc.MoveFirst
    
    rc.Find "IFS >=1"
    
    If rc.EOF Then
      regstart = rcount + 1
    Else
      regstart = rc.AbsolutePosition
    End If
    
    regend = rcount
    
    nullsptr = regstart - 1

    
    rc.MoveFirst
    
    
    Do Until regstart > regend
    
      rc.AbsolutePosition = regstart
      IFS = rc!IFS
      
      Do Until (lastIFS + 1 = IFS) Or regstart > regend
        If nullsptr > 0 Then
          lastIFS = lastIFS + 1
          rc.AbsolutePosition = nullsptr
          rc!IFS = lastIFS
          rc.Update
          nullsptr = nullsptr - 1
        Else
          lastIFS = lastIFS + 1
          rc.AbsolutePosition = regend
          rc!IFS = lastIFS
          rc.Update
          regend = regend - 1
        End If
      Loop

      If (regstart > regend) Then
        IFS = lastIFS
      End If
      
      
      lastIFS = IFS
      regstart = regstart + 1
    Loop

  
  
  
  Do Until nullsptr <= 0
    rc.AbsolutePosition = nullsptr
    lastIFS = lastIFS + 1
    rc!IFS = lastIFS
    rc.Update

    nullsptr = nullsptr - 1
  Loop

  Else
    rcount = 0

  End If 'not rc.eof
  Debug.Print " U... ";
  rc.UpdateBatch
  rc.Close

  Debug.Print rcount

  rcs!cnt = rcount
  rcs.Update
  rcs.MoveNext
Loop





End Sub
