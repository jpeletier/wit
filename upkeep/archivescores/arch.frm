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
Dim cn As Connection

Function QuerySingleValue(sql As String)

Dim rcqs As Recordset

Set rcqs = CreateObject("ADODB.Recordset")
rcqs.Open sql, cn, 3, 1

If rcqs.EOF Then
  QuerySingleValue = Null
Else
  QuerySingleValue = rcqs.Fields(0).Value
End If

End Function

Private Sub Form_Load()


Set cn = New Connection
Dim scr As New Recordset
Dim hist As New Recordset

cn.Open "PROVIDER=sqloledb;DATA SOURCE=****;USER ID=****;PASSWORD=****;INITIAL CATALOG=Trivial"

Dim ActiveLeague As Long
Dim LastTournament As Long

ActiveLeague = QuerySingleValue("SELECT TOP 1 IDLeague FROM Leagues ORDER BY idleague DESC")

LastTournament = QuerySingleValue("SELECT TOP 1 IDTournament FROM Tournaments WHERE IDLeague=" & ActiveLeague - 1 & " ORDER BY IDTournament DESC")


'the following line avoids tournament collission because of CYL in test mode.
cn.Execute "delete from scorest_history where idtournament=1"
cn.Execute "delete from scorest where idtournament=1"


scr.Open "Select * from scorest where idtournament<=" & LastTournament & " and idtournament<>1", cn, adOpenDynamic, adLockOptimistic
hist.Open "select * from scorest_history where idtournament=-1", cn, adOpenDynamic, adLockOptimistic
Dim n As Long
On Error Resume Next
Do Until scr.EOF
  n = n + 1
  hist.AddNew
  'Debug.Print n

  hist!idplayer = scr!idplayer
  hist!idtournament = scr!idtournament
  hist!idsubject = scr!idsubject
  hist!questionsanswered = scr!questionsanswered
  hist!score = scr!score
  hist.Update
  scr.Delete
  scr.MoveNext
Loop

End

End Sub
