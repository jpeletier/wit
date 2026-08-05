VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "mIRCHelper"
Attribute VB_GlobalNameSpace = True
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Public Enum mircColorConstants
  mccNone = -1
  mccWhite = 0
  mccBlack = 1
  mccDarkBlue = 2
  mccDarkGreen = 3
  mccDarkRed = 4
  mccDarkMagenta = 5
  mccPurple = 6
  mccOrange = 7
  mccYellow = 8
  mccBrightGreen = 9
  mccBlueGreen = 10
  mccCyan = 11
  mccPureBlue = 12
  mccBrightMagenta = 13
  mccDarkGrey = 14
  mccLightGrey = 15
  mccTransparent = 99
End Enum

Public Function mircBoldText(text As String) As String
  mircBoldText = "" & text & ""
End Function

Public Function mircUnderlineText(text As String) As String
  mircUnderlineText = "" & text & ""
End Function

Public Function mircReverseText(text As String) As String
  mircReverseText = "" & text & ""
End Function

Public Function mircColorText(text As String, foreColor As mircColorConstants, Optional backgroundColor As mircColorConstants = mccNone) As String
If foreColor = mccNone Then
  mircColorText = text
  Exit Function
End If


Dim clr As String

clr = "" & foreColor
  
If backgroundColor <> mccNone Then
  clr = clr & "," & backgroundColor
End If

  mircColorText = clr & text & ""
End Function

