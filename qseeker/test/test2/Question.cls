VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Question"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Type Question_Type
  IDSubject As Long
  question As String
  answer As String
  author As String
  subject As String
  IDQuestion As Long
End Type


Dim mdata As Question_Type



Friend Property Let IDSubject(x As Long)
  mdata.IDSubject = x
End Property

Friend Property Let IDQuestion(x As Long)
  mdata.IDQuestion = x
End Property

Friend Property Let question(x As String)
  mdata.question = x
End Property

Friend Property Let answer(x As String)
  mdata.answer = x
End Property

Friend Property Let author(x As String)
  mdata.author = x
End Property

Friend Property Let subject(x As String)
  mdata.subject = x
End Property

