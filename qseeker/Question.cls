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




Private mdata As jWitQuestionSeeker.Question_Type
Attribute mdata.VB_VarUserMemId = 0

Public Property Get data() As jWitQuestionSeeker.Question_Type
Attribute data.VB_UserMemId = 0
  data = mdata
End Property

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

