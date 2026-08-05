Attribute VB_Name = "debugMod"
Option Explicit

Public Sub TRACE(st As String)

Dim n As Long
n = FreeFile

Open "trace.txt" For Append As #n
  Print #n, "[" & Now & "] " & st
Close #n

Debug.Print st

End Sub
