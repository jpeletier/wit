Attribute VB_Name = "time"
Option Explicit
Private Declare Sub GetSystemTime Lib "kernel32" (lpSystemTime As SYSTEMTIME)
Private Type SYSTEMTIME
        wYear As Integer
        wMonth As Integer
        wDayOfWeek As Integer
        wDay As Integer
        wHour As Integer
        wMinute As Integer
        wSecond As Integer
        wMilliseconds As Integer


End Type

Private Declare Function SystemTimeToTzSpecificLocalTime Lib "kernel32" (lpTimeZoneInformation As TIME_ZONE_INFORMATION, lpUniversalTime As SYSTEMTIME, lpLocalTime As SYSTEMTIME) As Long

Private Declare Function GetTimeZoneInformation Lib "kernel32" (lpTimeZoneInformation As TIME_ZONE_INFORMATION) As Long
Private Type TIME_ZONE_INFORMATION
        Bias As Long
        StandardName(32) As Integer
        StandardDate As SYSTEMTIME
        StandardBias As Long
        DaylightName(32) As Integer
        DaylightDate As SYSTEMTIME
        DaylightBias As Long
End Type


Private Function systemTimeToDate(s As SYSTEMTIME) As Date
  systemTimeToDate = DateSerial(s.wYear, s.wMonth, s.wDay) & " " & TimeSerial(s.wHour, s.wMinute, s.wSecond)
End Function

Public Function getTimeStamp() As Long
Dim s As SYSTEMTIME

GetSystemTime s

Dim d As Date
d = systemTimeToDate(s)



getTimeStamp = DateDiff("s", #1/1/1970#, d)

End Function

Public Function timestampToLocalTime(tst As Long) As Date
Dim gmtDate As Date
Dim gmtS As SYSTEMTIME
Dim localS As SYSTEMTIME
gmtDate = DateAdd("s", tst, #1/1/1970#)
gmtS.wDay = Day(gmtDate)
gmtS.wHour = Hour(gmtDate)
gmtS.wMilliseconds = 0
gmtS.wMinute = Minute(gmtDate)
gmtS.wMonth = Month(gmtDate)
gmtS.wSecond = Second(gmtDate)
gmtS.wYear = Year(gmtDate)

Dim tz As TIME_ZONE_INFORMATION

GetTimeZoneInformation tz

SystemTimeToTzSpecificLocalTime tz, gmtS, localS

timestampToLocalTime = systemTimeToDate(localS)


End Function
