VERSION 5.00
Begin VB.MDIForm frmWit 
   BackColor       =   &H8000000C&
   Caption         =   "Wit"
   ClientHeight    =   4530
   ClientLeft      =   165
   ClientTop       =   735
   ClientWidth     =   6255
   Icon            =   "SimpleClient.frx":0000
   LinkTopic       =   "MDIForm1"
   StartUpPosition =   3  'Windows Default
   Begin VB.Menu mnuClients 
      Caption         =   "&Clientes"
      Begin VB.Menu mnuActiveClients 
         Caption         =   "&Lista de clientes activos"
      End
   End
End
Attribute VB_Name = "frmWit"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False


Option Explicit

Private WithEvents Tray As jCore.CTrayIcon
Attribute Tray.VB_VarHelpID = -1

Public WithEvents clients As WitClients
Attribute clients.VB_VarHelpID = -1
Private WCnServer As CWCnServer




Private Sub MDIForm_Load()
Set Utils.gInfo = New GlobalInfo



Randomize Timer
'MnuConectar_Click

InitDB


Set WCnServer = New CWCnServer

Set clients = New WitClients

init_Wit1
init_Wit2



Set Tray = New jCore.CTrayIcon
Tray.Create Me.hWnd, Me.Icon, "Wit IRC bot"
Me.Visible = False


Dim cn As New Connection
cn.Open TrivialDatabase
cn.Execute "EXEC FixDateEnds"
cn.Close

frmClientList.Show

'inicializar calc
SuperCalc "test"

initQuestions


WCnServer.listen 5520

End Sub

Private Sub MDIForm_Resize()
  If Me.WindowState = vbMinimized Then
    Me.Visible = False
  End If
End Sub

Private Sub MDIForm_Unload(cancel As Integer)

Dim wcn As WitClient
On Error Resume Next
For Each wcn In clients

  If Not wcn.IRC Is Nothing Then
    wcn.Terminate

    
  End If

Next

Set clients = Nothing



End Sub

Private Sub mnuActiveClients_Click()
frmClientList.Show


End Sub

Private Sub Tray_TrayMessage(ByVal Message As Long, ByVal id As Long)
  
  If Message = 515 Then
    WindowState = vbNormal
    Me.Visible = True
    AppActivate Me.Caption
  End If
End Sub


Private Sub init_Wit1()
Dim wcl As WitClient

Set wcl = New WitClient
wcl.IRC.nick = "Wit"
wcl.IRC.password = "****"
wcl.OnJoinChannels.Add "#aarun"
wcl.OnJoinChannels.Add "#trivialeros"
wcl.OnJoinChannels.Add "#trivial_jugones"
wcl.persist = True
wcl.IRC.serverName = "irc.wanadoo.es"
wcl.IRC.remotePort = 6667
wcl.Connect
clients.Add wcl, "Wit"

End Sub


Private Sub init_Wit2()

Dim wcl As WitClient

Set wcl = New WitClient
wcl.IRC.nick = "Wit2"
wcl.IRC.password = "****"
wcl.OnJoinChannels.Add "#peletier"
wcl.IRC.serverName = "pulsar1.irc-hispano.org"
wcl.IRC.remotePort = 6667
clients.Add wcl, "Wit2"
wcl.persist = True
wcl.autoReconnect = False

End Sub

Private Sub initBot(nick As String, host As String, port As Integer, Channel As String)
Dim wcl As WitClient

Set wcl = New WitClient
wcl.IRC.nick = nick
wcl.OnJoinChannels.Add Channel
wcl.IRC.serverName = host
wcl.IRC.remotePort = port
clients.Add wcl, nick
wcl.persist = True
wcl.Connect


End Sub


