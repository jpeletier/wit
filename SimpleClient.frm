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
      Begin VB.Menu mnu_wcnrestart 
         Caption         =   "&Reiniciar WCNServer"
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

Private WithEvents tmrreset As CTimer
Attribute tmrreset.VB_VarHelpID = -1

Private WithEvents tmrCheckCodes As CTimer
Attribute tmrCheckCodes.VB_VarHelpID = -1

Private WithEvents IRC_Chatpolis As CIRCClient
Attribute IRC_Chatpolis.VB_VarHelpID = -1
Private WithEvents IRC_GlobalChat As CIRCClient
Attribute IRC_GlobalChat.VB_VarHelpID = -1

Private accList As AccessList

Public BanList As New BanList
Public ipBanList As New ipBanList


Public config As INIFile

Private wcn_bindAddress As String
Private wcn_bindPort As Integer


Public Function getWitClubAccessList(wcl As WitClient, Optional usr As GlobalUser) As AccessList

Static lastRequest As Date

If (Not accList.isCurrent) And (DateDiff("n", lastRequest, Now) > 1) And (wcl.IRC.Properties("IDNetwork") = IDN_IRC_HISPANO) Then
  lastRequest = Now
  Set accList = wcl.CHaNBot.getAccessList(wcl.IRC.getChannel("#WitClub"))
End If

If Not usr Is Nothing And Not accList.ready Then
  usr.privateMessage "Estoy comprobando la lista de acceso de #WitClub. Por favor, reintenta el comando cuando haya terminado."
  accList.addToNotifyList usr
End If


Set getWitClubAccessList = accList

End Function


Private Sub IRC_Chatpolis_OnEndOfMOTD()

Dim wcl As WitClient

Set wcl = clients("WitChatPolis")

wcl.nick = "Wit"

IRC_Chatpolis.rawOutput "NICK Wit!PoTTKj3FjcUj"

IRC_Chatpolis.self.setMode True, "k"

End Sub





Private Sub MDIForm_Load()
Utils.initialize

Set Utils.gInfo = New GlobalInfo

Set accList = New AccessList

Dim fso As New FileSystemObject
Set config = New INIFile
If fso.FileExists(Command) Then
    config.load Command
Else
    config.load "wit.cfg.ini"
End If




Randomize Timer
'MnuConectar_Click

InitDB



Set clients = New WitClients




Set Tray = New jCore.CTrayIcon
Tray.Create Me.hWnd, Me.Icon, "Wit IRC bot"
Me.Visible = False





Dim cn As New Connection
cn.Open TrivialDatabase
cn.Execute "EXEC FixDateEnds"
'cn.Close

Set triviaConnection = cn
initQuestions

BanList.load
ipBanList.load


activeLeague = -1
CheckLeague cn

'Select Case Machine

'Case 1

'  init_Wit1
'  init_Wit3
  
'  init_GlobalChat
 
'Case 2
'  init_Wit2
'  init_Wit4
'  init_ChatPolis

'Case 3
'    init_WitB

'End Select

'init_WitP

initBots



frmClientList.Show



If config.Sections("witsummon").Keys("enabled").value <> 0 Then
    wcn_bindAddress = config.Sections("witsummon").Keys("bindaddress").value
    wcn_bindPort = config.Sections("witsummon").Keys("bindport").value
    mnu_wcnrestart_Click

End If

Set tmrreset = New CTimer
tmrreset.TimeScale = TU_Minutes
tmrreset.Interval = 5

Set tmrCheckCodes = New CTimer
tmrCheckCodes.TimeScale = TU_Minutes
tmrCheckCodes.Interval = 1




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

Private Sub mnu_wcnrestart_Click()


If Not WCnServer Is Nothing Then
  WCnServer.Terminate
End If
Set WCnServer = New CWCnServer

WCnServer.listen wcn_bindPort, wcn_bindAddress


End Sub

Private Sub mnuActiveClients_Click()
frmClientList.Show


End Sub

Private Sub tmrCheckCodes_ThatTime()

Dim st As String
Dim rc As New Recordset
Dim wcl As WitClient

For Each wcl In clients
    
    If Len(st) > 0 Then
        st = st & " OR "
    End If
    
    If wcl.secretCode <> 0 Then
        st = st & "(secretCode = " & wcl.secretCode & ")"
    End If
Next

If Len(st) > 0 Then

    CheckManagementConnection
    
    rc.Open "SELECT secretCode from wsnicks WHERE lastServer <> " & Machine & " AND (" & st & ")", CnMgt, adOpenForwardOnly, adLockReadOnly
    
    Do Until rc.EOF
        For Each wcl In clients
            If wcl.secretCode = rc!secretCode Then
                LogLine "tmrCheckCodes", "Closing connection with " & wcl.IRC.remoteAddress & ". Using same secret code in both servers."
                wcl.Terminate
            End If
        Next
        rc.MoveNext
    Loop
    
    rc.Close

End If

End Sub

Private Sub tmrreset_ThatTime()
mnu_wcnrestart_Click
End Sub

Private Sub Tray_TrayMessage(ByVal message As Long, ByVal id As Long)
On Error Resume Next
  If message = 515 Then
    WindowState = vbNormal
    Me.Visible = True
    AppActivate Me.Caption
  End If
End Sub

Private Sub init_WitP()
Dim wcl As WitClient

Set wcl = New WitClient
wcl.nick = "Wit"
wcl.IRC.serverName = "localhost"
wcl.IRC.remotePort = 6667


'wcl.OnJoinChannels.Add "#trivial"
wcl.OnJoinChannels.Add "#sms"
wcl.OnJoinChannels.Add "#witclub"

'wcl.OnJoinChannels.Add "#trivialeros"
'wcl.OnJoinChannels.Add "#trivial_jugones"
wcl.persist = True
wcl.IRC.Properties("IDNetwork") = IDN_ZONAGURU_COM
wcl.Connect
clients.Add wcl, "WitP"

End Sub



Private Sub init_ChatPolis()
Dim wcl As WitClient

Set wcl = New WitClient
wcl.nick = "Wit" & Int(Rnd * 99999) + 1000

Set IRC_Chatpolis = wcl.IRC

wcl.IRC.serverName = "irc.chatpolis.org"
wcl.IRC.remotePort = 6667


'wcl.OnJoinChannels.Add "#trivial"
'wcl.OnJoinChannels.Add "#sms"
wcl.OnJoinChannels.Add "#wit"

'wcl.OnJoinChannels.Add "#trivialeros"
'wcl.OnJoinChannels.Add "#trivial_jugones"
wcl.persist = True
wcl.IRC.Properties("IDNetwork") = IDN_CHATPOLIS_ORG
wcl.Connect
clients.Add wcl, "WitChatPolis"

End Sub

Private Sub init_GlobalChat()
Dim wcl As WitClient

Set wcl = New WitClient
wcl.IRC.nick = "Wit"
wcl.IRC.password = "****"
wcl.IRC.serverName = "irc.globalchat.org"
wcl.IRC.remotePort = 6667
wcl.IRC.Properties("IDNetwork") = IDN_GLOBALCHAT_ORG

Set IRC_GlobalChat = wcl.IRC

wcl.OnJoinChannels.Add "#witclub"

'wcl.OnJoinChannels.Add "#trivialeros"
'wcl.OnJoinChannels.Add "#trivial_jugones"
wcl.persist = True
wcl.Connect
clients.Add wcl, "WitGlobalChat"
End Sub

Private Sub init_Wit1()
Dim wcl As WitClient

Set wcl = New WitClient
wcl.IRC.nick = "Wit"
wcl.IRC.password = "****"
wcl.IRC.serverName = "libres.irc-hispano.org"
'wcl.IRC.serverName = "pulsar2.irc-hispano.org"
wcl.IRC.remotePort = 6667

wcl.OnJoinChannels.Add "#aarun"
wcl.OnJoinChannels.Add "#peletier"
wcl.OnJoinChannels.Add "#witclub"

'wcl.OnJoinChannels.Add "#trivialeros"
'wcl.OnJoinChannels.Add "#trivial_jugones"
wcl.persist = True
wcl.Connect
clients.Add wcl, "Wit"

End Sub



Private Sub init_Wit2()

Dim wcl As WitClient

Set wcl = New WitClient
wcl.nick = "Wit2"
wcl.IRC.password = "****"
wcl.OnJoinChannels.Add "#witclub"
wcl.IRC.serverName = "libres.irc-hispano.org"
wcl.IRC.remotePort = 6667
wcl.persist = True
wcl.Connect
clients.Add wcl, "Wit2"

'wcl.autoReconnect = False
End Sub

Private Sub init_Wit3()
Dim wcl As WitClient

Set wcl = New WitClient
wcl.nick = "Wit3"
wcl.IRC.password = "****"
wcl.IRC.serverName = "libres.irc-hispano.org"
'wcl.IRC.serverName = "pulsar2.irc-hispano.org"
wcl.IRC.remotePort = 6667


wcl.OnJoinChannels.Add "#witclub"

'wcl.OnJoinChannels.Add "#trivialeros"
'wcl.OnJoinChannels.Add "#trivial_jugones"
wcl.persist = True
wcl.Connect
clients.Add wcl, "Wit3"

End Sub

Private Sub init_Wit4()

Dim wcl As WitClient

Set wcl = New WitClient
wcl.nick = "Wit4"
wcl.IRC.password = "****"
wcl.OnJoinChannels.Add "#witclub"
wcl.IRC.serverName = "irc.irc-hispano.org"
wcl.IRC.remotePort = 6667
wcl.persist = True
wcl.Connect
clients.Add wcl, "Wit4"

'wcl.autoReconnect = False
End Sub

Private Sub init_WitB()

Dim wcl As WitClient

Set wcl = New WitClient
wcl.nick = "WitB"

wcl.OnJoinChannels.Add "#wit-beta"
wcl.IRC.serverName = "irc.irc-hispano.org"
wcl.IRC.remotePort = 6667
wcl.persist = True
wcl.Connect
clients.Add wcl, "WitB"

'wcl.autoReconnect = False
End Sub


Private Sub initBot(nick As String, host As String, port As Integer, Channel() As String, persist As Boolean, autoplaySection As Section, Optional password As String, Optional IDNetwork As Integer = IDN_DEFAULT)
Dim wcl As WitClient

Set wcl = New WitClient
wcl.IRC.nick = nick
wcl.IRC.Properties("IDNetwork") = IDNetwork

If password <> "" Then wcl.IRC.password = password
Dim n As Integer
    For n = 0 To UBound(Channel)
        wcl.OnJoinChannels.Add Channel(n)
    Next
    
    
If Not autoplaySection Is Nothing Then
    Dim autoplay As New Scripting.Dictionary
    Dim k As Key
    For Each k In autoplaySection.Keys
        autoplay.Add LCase(k.Name), k.value
    Next
   
    wcl.IRC.Properties.Add "AUTOPLAY", autoplay

End If
    
    
wcl.IRC.serverName = host
wcl.IRC.remotePort = port
clients.Add wcl, nick
wcl.persist = persist
wcl.Connect


End Sub

Private Sub initBots()

Dim s As jIniFileLib.Section

For Each s In config.Sections

    If s.Name = "bot" Then
        Dim channels() As String
        channels = Split(s.Keys("channels").value, ",")
        Dim IDNetwork As Integer
        IDNetwork = Val(s.Keys("IDNetwork").value)
        If IDNetwork = 0 Then IDNetwork = IDN_DEFAULT
        
        Dim k As Key
        Dim autoplaySection As Section
        Set k = getKey("autoplayconfig", s)
        If Not k Is Nothing Then
            Set autoplaySection = getSection(k.value, config)
        End If
        
        initBot s.Keys("nick").value, s.Keys("server").value, s.Keys("remoteport").value, channels, s.Keys("persist").value = "true", autoplaySection, s.Keys("password").value, IDNetwork
    End If


Next


End Sub
