Attribute VB_Name = "config"
Public Const LOGDIR = "<redacted-path>"

Public Const TRIVIAL_DB = "Trivial"
Public Const TRIVIAL_DBUSER = "****"
Public Const TRIVIAL_DBPASSWORD = "****"
Public Const TRIVIAL_DBSERVER = "****"


'Public Const TRIVIAL_DB = "Trivial"
'Public Const TRIVIAL_DBUSER = "****"
'Public Const TRIVIAL_DBPASSWORD = "****"
'Public Const TRIVIAL_DBSERVER = "****"

Public Function getSection(sectionName As String, config As INIFile) As Section
On Error Resume Next


Set getSection = config.Sections(sectionName)

End Function

Public Function getKey(keyName As String, s As Section) As Key
On Error Resume Next

Set getKey = s.Keys(keyName)

End Function
