VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3195
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Form_Load()


Dim cn As Connection

Set cn = New Connection

cn.Open TrivialDatabase
Dim sql As String

sql = "select * from correctedquestions"


Dim rc As New Recordset


rc.Open sql, cn, adOpenDynamic, adLockOptimistic

Do Until rc.EOF
  cn.Execute "UPDATE Questions_TABLE set question='" & Replace(rc!question, "'", "''") & "', IDAuthor=" & rc!idauthor & ", Answer='" & Replace(rc!answer, "'", "''") & "', IDSubject=" & rc!idsubject & ", Repeats=0, Source=-2 WHERE IDQuestion= " & rc!oldidquestion
  cn.Execute "DELETE WrongQuestions where idquestion=" & rc!oldidquestion
  rc.Delete
rc.MoveNext
Loop

rc.Close
cn.Execute "DELETE FROM questions_table WHERE IDSubject=76" 'errores



End



End Sub


Public Function TrivialDatabase() As String
  TrivialDatabase = ConMSSQL("Trivial", "****", "****", "****") ' ConStrAccess(App.Path & "\trivia.mdb")
End Function

Public Function ConMSSQL(bd As String, uid As String, pwd As String, Optional server As String = "****") As String

'  ConMSSQL = "Provider=sqloledb;Server=" & server & ";Database=" & bd & ";uid=" & uid & ";pwd=" & pwd
ConMSSQL = "PROVIDER=sqloledb;DATA SOURCE=" & server & ";USER ID=" & uid & ";PASSWORD=" & pwd & ";INITIAL CATALOG=" & bd
End Function
