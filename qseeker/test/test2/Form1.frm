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

Randomize Timer

Set cn = New Connection

cn.Open TrivialDatabase



Dim c As New Class1

c.initialize 21


Dim sum As Long
Dim t As Long
Dim n As Long
For n = 1 To 500
  t = GetTickCount
  c.fillBuffer
  sum = sum + GetTickCount - t
Next

Debug.Print "Results: " & sum / 500 & " ms."




End Sub
