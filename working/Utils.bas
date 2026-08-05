Attribute VB_Name = "Utils"
Option Explicit

Public Const activeLeague = 6


Public NiCKBot As NiCKBot


Dim MemDB As Connection
Dim defs As Recordset

Public questions As jWitQuestionSeeker.Seeker
Public Numbers As New jNumbers.CNumbers

Public gInfo As GlobalInfo



Public Function ConStrAccess(Path As String) As String
  
  ConStrAccess = "Provider=Microsoft.Jet.OLEDB.4.0;" & _
      "Data Source=" & Path

  'ConStrAccess = "Provider=MSDASQL.1;Extended Properties=""DSN=MS Access Database;DBQ=" & Path & ";DriverId=25;FIL=MS Access;MaxBufferSize=2048;PageTimeout=5;"""
End Function



Public Sub InitDB()
Set MemDB = New Connection
Set defs = New Recordset

'MemDB.Open ConStrAccess(App.Path & "\mem.mdb")
MemDB.Open ConStrAccess("<redacted-path>")

MemDB.Execute "DELETE * FROM DEFS WHERE LastUsed < dateValue('" & DateAdd("m", -6, Now) & "')"


defs.Open "DEFS", MemDB, adOpenKeyset, adLockOptimistic


End Sub


Public Function LocateFirstDef(def As String, Optional Author As String = "") As String
On Error Resume Next
If def = "" Then Exit Function
defs.MoveFirst

Dim st As String

st = "(Def='" & Replace(def, "'", "''") & "')"

If Author <> "" Then
  st = st & " AND (Author='" & Replace(Author, "'", "''") & "')"
End If

Dim dfs As Recordset
Set dfs = defs.Clone
dfs.Filter = st

If Not dfs.EOF Then
  defs.Bookmark = dfs.Bookmark
  LocateFirstDef = defs!text
  def = defs!def
  If Not IsNull(defs!lastused) Then
    defs!lastused = Now
    defs.update
  End If
  
End If

End Function

Public Function LocateRandomDef(def As String) As String
On Error Resume Next
If def = "" Then Exit Function
Dim cl As Recordset
Set cl = defs.Clone

cl.Filter = "DEF='" & Replace(def, "'", "''") & "'"

If Not cl.EOF Then
  cl.MoveLast
  If Not cl.BOF Then
    cl.MoveFirst
  End If
  
  If cl.RecordCount > 0 Then
    Dim m As Long
    m = d(cl.RecordCount, 1) - 1

    cl.Move m, adBookmarkFirst
    def = cl!def
    LocateRandomDef = cl!text
    If Not IsNull(defs!lastused) Then
      defs!lastused = Now
      defs.update
    End If

    
  End If
  
End If

End Function

Public Function AddModDef(def As String, text As String, Author As String) As Boolean
'On Error Resume Next
If def = "" Then Exit Function
If LocateFirstDef(def, Author) = "" Then
  defs.AddNew
End If
If ("" & defs!Author = "") Or (UCase(Author) = UCase(defs!Author)) Then
  defs!def = def
  defs!text = Mid(text, 1, defs.Fields("text").DefinedSize)
  defs!Author = Author
  defs!lastused = Now
  'defs.Update
End If
defs.update
End Function

Public Sub Wait(msec)

Dim tmr As Single

tmr = Timer + msec / 1000

If tmr > 86400 Then tmr = tmr Mod 86400

Do Until Timer >= tmr

  DoEvents

Loop

End Sub



Public Function IsFriendly(usr As jIRCLib.GlobalUser) As Boolean

Select Case LCase(usr.nickName)
  Case "iki", "juglar24", "Zoltar", "ka0s", "el_txakal", "txakal", "goznar", "elchomin", "chomin", "lord_yupa"
    IsFriendly = True
End Select


End Function


Public Function LocateFormChannel(Channel As String) As FormChannel

Dim frm As Form
Dim fc As FormChannel
For Each frm In Forms
  If TypeOf frm Is FormChannel Then
    Set fc = frm
    If UCase(fc.myChannel.name) = UCase(Channel) Then
      Set LocateFormChannel = fc
      Exit Function
    End If
  End If
Next
    




End Function


Public Function TrivialDatabase() As String
  TrivialDatabase = ConMSSQL("Trivial", "****", "****")  ' ConStrAccess(App.Path & "\trivia.mdb")
End Function

Public Function ConMSSQL(bd As String, uid As String, pwd As String, Optional server As String = "****") As String

'  ConMSSQL = "Provider=sqloledb;Server=" & server & ";Database=" & bd & ";uid=" & uid & ";pwd=" & pwd
ConMSSQL = "PROVIDER=sqloledb;DATA SOURCE=" & server & ";USER ID=" & uid & ";PASSWORD=" & pwd & ";INITIAL CATALOG=" & bd
End Function


Public Function QuerySingleValue(sql As String, cn As Connection) As Variant

Dim rc As New Recordset

rc.Open sql, cn, adOpenStatic, adLockReadOnly

If rc.EOF Then
  QuerySingleValue = Null
Else
  QuerySingleValue = rc.Fields(0).Value
End If

End Function


Public Sub initQuestions()
  Set questions = New jWitQuestionSeeker.Seeker
  
  questions.initialize TrivialDatabase
  
End Sub



Public Function getQuestion(IDQuestionSubset As Long) As Question_Type
  
On Error GoTo errq
  
  getQuestion = questions.getRandomQuestionBySubset(IDQuestionSubset)

errqexit:
Exit Function
errq:
  
  Debug.Print "getQuestion Error: " & Err.Description & " " & Err.Number
  initQuestions
  getQuestion = questions.getRandomQuestionBySubset(IDQuestionSubset)
  Resume errqexit

End Function


Public Function getChannelCount(IRC As jIRCLib.CIRCClient) As Long
    
    Dim n As Long
    Dim Count As Long
    
    For n = 1 To IRC.Channels.Count
      If IRC.Channels(n).joined Then
        Count = Count + 1
      End If
    Next

getChannelCount = Count
End Function



Public Function isOperator(gUsr As GlobalUser, Channel As Channel) As Boolean


Dim usrStop As User
Set usrStop = Channel.Users(gUsr)
If Not usrStop Is Nothing Then
  If usrStop.operator Then
    isOperator = True
  End If
End If


End Function


