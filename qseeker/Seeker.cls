VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Seeker"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Public Type Question_Type
  IDSubject As Long
  question As String
  answer As String
  author As String
  subject As String
  IDQuestion As Long
End Type

Public cn As ADODB.Connection
Private subjects As New Collection
Private subsets As New Collection

Private mConStr As String

Public revTmr As CTimer

Public Sub initialize(constr As String)
Randomize Timer


mConStr = constr

resetConnection


Set revTmr = New CTimer

revTmr.TimeScale = TU_Minutes
revTmr.Interval = 1


App.LogEvent "Seeker initialized", vbLogEventTypeInformation

End Sub


Friend Sub freeSubject(IDSubject As Long)
On Error Resume Next

subjects.Remove "X" & IDSubject

End Sub

Friend Sub freeSubset(IDSubset As Long)
On Error Resume Next

subsets.Remove "X" & IDSubset

End Sub



Friend Function getSubject(IDSubject As Long) As subject
On Error Resume Next

Dim sb As subject

Set sb = subjects("X" & IDSubject)

If sb Is Nothing Then
  Set sb = New subject
  sb.initialize IDSubject, Me
  subjects.Add sb, "X" & IDSubject
End If

Set getSubject = sb

End Function


Friend Function getSubset(IDSubset As Long) As Subset
On Error Resume Next

Dim sb As Subset

Set sb = subsets("X" & IDSubset)

If sb Is Nothing Then
  Set sb = New Subset
  sb.initialize IDSubset, Me
  subsets.Add sb, "X" & IDSubset
End If

Set getSubset = sb

End Function


Public Function getRandomQuestionBySubset(IDSubset As Long) As Question_Type

getRandomQuestionBySubset = getSubset(IDSubset).getRandomQuestionLocal.data

End Function

Public Function getRandomQuestionBySubject(IDSubject As Long) As Question_Type

getRandomQuestionBySubject = getSubject(IDSubject).getRandomQuestionLocal.data

End Function

Public Sub destroy()
Set subjects = Nothing
Set subsets = Nothing


End Sub


Public Sub resetConnection()

Set cn = New ADODB.Connection
cn.ConnectionTimeout = 60
cn.Open mConStr

End Sub
