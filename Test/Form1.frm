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
   Begin VB.CommandButton Command3 
      Caption         =   "list users"
      Height          =   615
      Left            =   480
      TabIndex        =   2
      Top             =   2400
      Width           =   975
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Command2"
      Height          =   615
      Left            =   1680
      TabIndex        =   1
      Top             =   360
      Width           =   975
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Command1"
      Height          =   735
      Left            =   360
      TabIndex        =   0
      Top             =   420
      Width           =   1035
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private WithEvents irc As jIRCLib.CIRCClient
Attribute irc.VB_VarHelpID = -1



Private Sub dcc_OnConnect()
End Sub

Private Sub dcc_OnDisconnect()

End Sub

Private Sub dcc_OnMessage(text As String)
End Sub

Private Sub Command1_Click()

irc.joinChannel "#aarun"

End Sub

Private Sub Command2_Click()
irc.leaveChannel "#aarun", "bye"
End Sub

Private Sub Command3_Click()
Dim ch As Channel

Set ch = irc.getChannel("#Aarun")

Dim usr As User

For Each usr In ch.users
  Debug.Print usr.nickName & " OPERATOR=" & usr.operator
Next

End Sub

Private Sub Form_Load()

Set irc = New CIRCClient

irc.serverName = "cartman.peletier.com"
irc.remotePort = 6667
Randomize Timer
irc.nick = "TestBot" & Int(Rnd * 10)
irc.Connect


End Sub

Private Sub irc_LíneaRecibida(ByVal Línea As String)
Debug.Print Línea
End Sub

Private Sub irc_OnNoticeUser(usr As jIRCLib.GlobalUser, text As String)
Debug.Print text
End Sub
