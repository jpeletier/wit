VERSION 5.00
Begin VB.Form FormChannel 
   Caption         =   "Canal"
   ClientHeight    =   4635
   ClientLeft      =   60
   ClientTop       =   630
   ClientWidth     =   6885
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   4635
   ScaleWidth      =   6885
   Visible         =   0   'False
   Begin VB.TextBox Mensajes 
      Height          =   4095
      Left            =   0
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      TabIndex        =   1
      Top             =   0
      Width           =   6855
   End
   Begin VB.TextBox Comandos 
      Height          =   375
      Left            =   0
      TabIndex        =   0
      Top             =   4200
      Width           =   6855
   End
   Begin VB.Menu mnuUser 
      Caption         =   "User"
      Begin VB.Menu mnuPing 
         Caption         =   "Ping"
      End
   End
End
Attribute VB_Name = "FormChannel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Versión 2
Option Explicit
Public WithEvents MyChannel As jIRCLib.Channel
Attribute MyChannel.VB_VarHelpID = -1

Private WithEvents parent As StatusForm
Attribute parent.VB_VarHelpID = -1

Private Sub Comandos_KeyPress(KeyAscii As Integer)
If MyChannel Is Nothing Then Exit Sub
If KeyAscii = 13 Then
  KeyAscii = 0
  MyChannel.Say Comandos.text
  AñadirTexto "<" & MyChannel.parent.nick & "> " & Comandos.text
  Comandos.text = ""
End If
End Sub

Public Sub AñadirTexto(datos As String)
'Esto añade el texto que acaba de llegar a la caja de texto.
  Dim lmt As Long
  lmt = Len(Mensajes.text)
  If lmt > 5000 Then Mensajes.text = Mid(Mensajes.text, 4000): lmt = 4000
  
  Mensajes.SelStart = lmt
  Mensajes.SelText = datos & vbCrLf
  

  
End Sub




Private Sub Form_Resize()

On Error Resume Next
Comandos.Height = 375
Mensajes.Width = Me.Width - 100
Comandos.Width = Mensajes.Width
Comandos.Top = Me.Height - 450 - Comandos.Height
Mensajes.Height = Me.Height - Comandos.Height - 450

End Sub

Private Sub MyChannel_OnJoin(who As jIRCLib.User, cancel As Boolean)
  If who.gUsr Is MyChannel.parent.self Then
      
    Exit Sub
  End If
  
  AñadirTexto "*** " & who.nickName & " (" & who.HostName & ") acaba de entrar en " & MyChannel.name
  
End Sub

Private Sub MyChannel_OnMessage(who As jIRCLib.User, text As String, cancel As Boolean)
  AñadirTexto "<" & who.nickName & "> " & text
End Sub

Private Sub MyChannel_OnNickChange(who As jIRCLib.User, newNick As String)
  AñadirTexto "*** " & who.nickName & " se llama ahora " & newNick
End Sub

Private Sub MyChannel_OnTopicChange(cancel As Boolean)
    refreshCaption
End Sub


Private Sub MyChannel_OnUserLeave(who As jIRCLib.User, kickedBy As jIRCLib.GlobalUser, reason As String, cancel As Boolean)

If who.gUsr Is MyChannel.parent.self Then
  Unload Me
End If

End Sub

Private Sub MyChannel_OnUserPart(who As jIRCLib.User, cancel As Boolean)
  AñadirTexto "*** " & who.nickName & " (" & who.HostName & ") acaba de salir de " & MyChannel.name
End Sub

Private Sub mnuPing_Click()
  If MyChannel Is Nothing Then Exit Sub
  Dim nick As String
  nick = InputBox("Enter nickname", "Ping")
  MyChannel.parent.pingUser MyChannel.parent.getUser(nick)
  
End Sub


Public Sub initialize(ch As Channel, parentfrm As StatusForm)
  Set MyChannel = ch
  Set parent = parentfrm
  refreshCaption
End Sub

Private Sub parent_Terminate()
Unload Me
End Sub

Private Sub refreshCaption()
On Error Resume Next
Me.Caption = "[" & parent.IRC.nick & "]" & " - Canal " & MyChannel.name & ": " & MyChannel.topic
End Sub
