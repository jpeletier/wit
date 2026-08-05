VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Class1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const MAX_BUFFER = 30
Private Const MIN_BUFFER = 10
Private Const MAX_MINS_IDLE = 60


Private IDSubject As Long
Private cnt As Long

Dim buffer As New Collection



Private minsIdle As Long



Public Sub initialize(IDS As Long)
  IDSubject = IDS
  
  getCnt


End Sub

Private Sub getCnt()
  cnt = CLng(QuerySingleValue("SELECT cnt FROM Subjects WHERE IDSubject = " & IDSubject, cn))
End Sub



Public Function getRandomQuestionLocal() As question

minsIdle = 0

If buffer.Count = 0 Then
  fillBuffer
End If

Set getRandomQuestionLocal = buffer(1)
buffer.Remove 1

End Function

Public Sub fillBuffer()

Set buffer = New Collection

If buffer.Count > MIN_BUFFER Then Exit Sub


Dim rc As Recordset
Set rc = New Recordset

Dim numquestions As Long

numquestions = (MAX_BUFFER - buffer.Count) * 2

Dim strWhere As String

Dim n As Long
For n = 1 To numquestions
  If Len(strWhere) <> 0 Then
    strWhere = strWhere & " OR "
  End If
  
  strWhere = strWhere & "IFS = " & Int(Rnd * cnt) + 1
Next
  
numquestions = numquestions / 2
'rc.Open "SELECT TOP " & numquestions & " * FROM Questions WHERE IDSubject = " & IDSubject & " AND (" & strWhere & ") ORDER BY repeats", parent.cn, adOpenStatic, adLockOptimistic




rc.CursorLocation = adUseClient
rc.Open "SELECT TOP " & numquestions & " Questions_Table.IdQuestion, Questions_Table.Question, Questions_Table.Answer, Subjects.Subject, Authors.Author,     Questions_Table.Source, Questions_Table.Repeats,    Questions_Table.IdSubject, Questions_Table.IdAuthor,    Questions_Table.IFS, Questions_Table.rndnum FROM Subjects INNER JOIN     Authors INNER JOIN    Questions_Table ON    Authors.IdAuthor = Questions_Table.IdAuthor ON    Subjects.IDSubject = Questions_Table.IDSubject WHERE questions_table.IDSubject = " & IDSubject & " AND (" & strWhere & ") ORDER BY repeats,rndnum", cn, adOpenStatic, adLockBatchOptimistic
    
Dim q As New question



Do Until rc.EOF Or numquestions <= 0
  
  Set q = New question
  
  With q
  
    .IDQuestion = rc!IDQuestion
    .answer = rc!answer
    .author = rc!author
    .IDSubject = rc!IDSubject
    .question = rc!question
    .subject = rc!subject
  End With
  
  buffer.Add q
  
  rc!Repeats = rc!Repeats + 1
  rc!rndnum = Int(Rnd * 10000) + 1
  
 ' secureUpdate rc
  

  numquestions = numquestions - 1
  rc.MoveNext
Loop




On Error Resume Next
rc.UpdateBatch 'En teoría esto lo actualiza todo de golpe




rc.Close


















End Sub

Private Sub secureUpdate(rc As Recordset)
On Error Resume Next
  rc.Update
End Sub




