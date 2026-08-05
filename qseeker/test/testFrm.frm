VERSION 5.00
Begin VB.Form testFrm 
   Caption         =   "Form1"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3195
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Command1 
      Caption         =   "Command1"
      Height          =   675
      Left            =   600
      TabIndex        =   0
      Top             =   240
      Width           =   1815
   End
End
Attribute VB_Name = "testFrm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim qs As Seeker
Private s As Subject

Public Function TrivialDatabase() As String
  TrivialDatabase = ConMSSQL("Trivial", "****", "****")  ' ConStrAccess(App.Path & "\trivia.mdb")
End Function

Public Function ConMSSQL(bd As String, uid As String, pwd As String, Optional server As String = "****") As String

'  ConMSSQL = "Provider=sqloledb;Server=" & server & ";Database=" & bd & ";uid=" & uid & ";pwd=" & pwd
ConMSSQL = "PROVIDER=sqloledb;DATA SOURCE=" & server & ";USER ID=" & uid & ";PASSWORD=" & pwd & ";INITIAL CATALOG=" & bd
End Function

Private Sub Command1_Click()




Dim q As Question_Type


q = qs.getRandomQuestionBySubset(1)



Debug.Print q.Subject & ": " & q.Question
End Sub

Private Sub Form_Load()



'Set qs = New Seeker

'qs.Initialize TrivialDatabase

Dim cn As New Connection

cn.Open TrivialDatabase


Dim rc As Recordset
Set rc = New Recordset

Dim numquestions As Long

numquestions = 30 * 2

Dim strWhere As String

Dim n As Long
For n = 1 To numquestions
  If Len(strWhere) <> 0 Then
    strWhere = strWhere & " OR "
  End If
  
  strWhere = strWhere & "IFS = " & Int(Rnd * 2950) + 1
Next
  
numquestions = numquestions / 2
'rc.Open "SELECT TOP " & numquestions & " * FROM Questions WHERE IDSubject = " & IDSubject & " AND (" & strWhere & ") ORDER BY repeats", parent.cn, adOpenStatic, adLockOptimistic

rc.Open "SELECT TOP " & numquestions & " Questions_Table.IdQuestion, Questions_Table.Question, Questions_Table.Answer, Subjects.Subject, Authors.Author,     Questions_Table.Source, Questions_Table.Repeats,    Questions_Table.IdSubject, Questions_Table.IdAuthor,    Questions_Table.IFS FROM Subjects INNER JOIN     Authors INNER JOIN    Questions_Table ON    Authors.IdAuthor = Questions_Table.IdAuthor ON    Subjects.IDSubject = Questions_Table.IDSubject WHERE questions_table.IDSubject = 11 AND (" & strWhere & ") ORDER BY repeats", cn, adOpenForwardOnly, adLockOptimistic





End Sub
