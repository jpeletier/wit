VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "FMessageGroup"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private messages As Collection
Private total As Integer


Private Sub Class_Initialize()
Set messages = New Collection
End Sub

Public Sub addMessage(m As FMessage)

    messages.Add m
    total = total + m.probability

End Sub

Public Function getMessage() As String

If messages.Count = 0 Then
    getMessage = ""
    Exit Function
End If


Dim i As Integer
Dim m As FMessage
Dim c As Integer
Dim last As FMessage

i = Int(Rnd * total) + 1

For Each m In messages

    c = c + m.probability

    If i < c Then
        getMessage = m.message
        Exit Function
    End If
    Set last = m
Next

getMessage = last.message

End Function

