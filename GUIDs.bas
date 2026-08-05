Attribute VB_Name = "GUIDs"
Option Explicit

Private Type GUID
   Data1 As Long
   Data2 As Long
   Data3 As Long
   Data4(8) As Byte
End Type

Private Declare Function CoCreateGuid Lib "ole32.dll" ( _
   pguid As GUID) As Long

Private Declare Function StringFromGUID2 Lib "ole32.dll" ( _
   rguid As Any, _
   ByVal lpstrClsId As Long, _
   ByVal cbMax As Long) As Long


Public Function newGUID() As String

Dim tG As GUID
   CoCreateGuid tG

Dim b() As Byte
Dim lSize As Long
Dim sCLSID As String
Dim lR As Long

   lSize = 40
   ReDim b(0 To (lSize * 2) - 1) As Byte

   lR = StringFromGUID2(tG, VarPtr(b(0)), lSize)
   sCLSID = Left$(b, lR - 1)

newGUID = sCLSID

End Function
