VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CHaNBot"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
Private WithEvents bot As GlobalUser
Attribute bot.VB_VarHelpID = -1
Private IRC As CIRCClient
Private lastAccessList As String

Public Event OnAccessListLine(Channel As Channel, level As Integer, nick As String)
Public Event OnAccessListCompleted(Channel As Channel)

Public Sub initialize(xIRC As CIRCClient)

Set IRC = xIRC

Set bot = IRC.getUser("CHaN")

End Sub

Public Function getAccessList(ch As Channel) As AccessList

bot.privateMessage "ACCESS " & ch.name & " LIST"
bot.privateMessage "access_list_end"

Dim acl As AccessList

Set acl = New AccessList

Set acl.CHaNBot = Me
acl.Channel = ch.name

Set getAccessList = acl

End Function

Private Sub bot_OnPrivateMessage(text As String, cancel As Boolean)

Const aclstring = "Lista de acceso de 12"
Const aclend = "Comando desconocido 12access_list_end"


If InStr(1, text, aclstring, vbBinaryCompare) = 1 Then
  Dim chname As String
  
  chname = Mid(text, Len(aclstring) + 1)
  chname = Mid(chname, 1, Len(chname) - 2)
 
  lastAccessList = chname

  Exit Sub
End If



If InStr(1, text, aclend, vbBinaryCompare) = 1 Then
  RaiseEvent OnAccessListCompleted(IRC.getChannel(lastAccessList))
  Exit Sub
End If


':CHaN!-@- PRIVMSG Wait_wit :  Num   Niv  Nick
':CHaN!-@- PRIVMSG Wait_wit :  1   499  Zoltar
':CHaN!-@- PRIVMSG Wait_wit :  2   300  _|NADIE|_
':CHaN!-@- PRIVMSG Wait_wit :  3   350  Gutas
':CHaN!-@- PRIVMSG Wait_wit :  4   499  Wit

  If Len(text) < 12 Then Exit Sub
  
  Dim num As String
  Dim niv As String
  Dim nick As String
  
  num = Left(text, 3)
  niv = Mid(text, 5, 5)
  nick = Trim(Mid(text, 11))
  
  If IsNumeric(num) Then ' Vale "N" si es la 1ª línea
    RaiseEvent OnAccessListLine(IRC.getChannel(lastAccessList), Val(niv), nick)
  End If



End Sub
