VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Subset"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const MAX_MINS_IDLE = 30

Private parent As Seeker

Private weights() As Long
Private totalWeight As Long
Private subjects As Long

Private IDQuestionSubset As Long

Private WithEvents revTmr As CTimer
Attribute revTmr.VB_VarHelpID = -1

Private minsIdle As Long


Friend Sub initialize(IDQS As Long, sk As Seeker)

IDQuestionSubset = IDQS


Set parent = sk

Set revTmr = parent.revTmr

refreshRatios
End Sub

Private Sub refreshRatios()
Dim rc As New Recordset
Dim sum As Long

sum = 0

rc.Open "SELECT IDSubject,weight FROM QSubsetMembers WHERE IDQuestionSubset= " & IDQuestionSubset, parent.cn, adOpenKeyset, adLockReadOnly

Dim cnt As Long

If rc.EOF Then
  cnt = 0
Else
  rc.MoveLast
  cnt = rc.AbsolutePosition
  If Not rc.BOF Then rc.MoveFirst
  
  ReDim weights(0 To cnt - 1, 1)
  
  Do Until rc.EOF
    If IsNull(rc!Weight) Then
      sum = sum + 1
    Else
      sum = sum + rc!Weight
    End If
    weights(rc.AbsolutePosition - 1, 0) = sum
    weights(rc.AbsolutePosition - 1, 1) = rc!IDSubject
    
    rc.MoveNext
  Loop
  
End If

totalWeight = sum
subjects = cnt


End Sub



Public Function getRandomQuestion() As Question_Type

getRandomQuestion = getRandomQuestionLocal.data

End Function

Public Function getRandomQuestionLocal() As question

minsIdle = 0

Dim n As Long

Dim r As Long

r = Int(Rnd * totalWeight) + 1

Dim s As Long
s = -1

For n = 0 To subjects - 1

  If r <= weights(n, 0) Then
    s = weights(n, 1)
    Exit For
  End If

Next

Debug.Assert s <> -1


Set getRandomQuestionLocal = parent.getSubject(s).getRandomQuestionLocal



End Function


Private Sub revTmr_ThatTime()
  minsIdle = minsIdle + 1
  
  If minsIdle >= MAX_MINS_IDLE Then
    parent.freeSubset IDQuestionSubset
  End If
  
  
  Static rcount As Long
  
  rcount = rcount + 1
  
  If rcount >= 1440 Then
    rcount = 0
    refreshRatios
  End If
  
  
  
End Sub
