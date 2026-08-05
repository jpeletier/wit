Attribute VB_Name = "Facebook"

Public Function getFBId(gUsr As GlobalUser) As Double

On Error Resume Next
Dim i As Integer
i = InStr(1, gUsr.realName, "['", vbBinaryCompare)
If i > 0 Then
    getFBId = Val(Mid(gUsr.realName, i + 2))
End If

End Function
