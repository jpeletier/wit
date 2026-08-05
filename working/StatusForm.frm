VERSION 5.00
Begin VB.Form StatusForm 
   Caption         =   "Status"
   ClientHeight    =   4635
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6885
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   4635
   ScaleWidth      =   6885
   Begin VB.TextBox Comandos 
      Height          =   375
      Left            =   0
      TabIndex        =   0
      Top             =   4200
      Width           =   6855
   End
   Begin VB.TextBox Mensajes 
      Height          =   4095
      Left            =   0
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      TabIndex        =   1
      Top             =   0
      Width           =   6855
   End
End
Attribute VB_Name = "StatusForm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Versión 2
Option Explicit
Public WithEvents IRC As CIRCClient
Attribute IRC.VB_VarHelpID = -1

Public Event Terminate()
Public Event IRCDisconnect()

Private Sub Form_Resize()

On Error Resume Next
Comandos.Height = 375
Mensajes.Width = Me.Width - 100
Comandos.Width = Mensajes.Width
Comandos.Top = Me.Height - 450 - Comandos.Height
Mensajes.Height = Me.Height - Comandos.Height - 450

End Sub


Private Sub Comandos_KeyPress(KeyAscii As Integer)
If KeyAscii = 13 Then
  KeyAscii = 0
  If Not IRC Is Nothing Then
    IRC.rawOutput Comandos.text & vbLf
  End If
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

Private Sub Form_Unload(Cancel As Integer)
  RaiseEvent Terminate
End Sub

Private Sub IRC_LíneaRecibida(ByVal Línea As String)
AñadirTexto Línea
End Sub


Public Sub initialize(xIRC As CIRCClient)

Set IRC = xIRC

Me.Caption = "Status de " & xIRC.nick

Dim ch As Channel
Dim frm As FormChannel
Dim n As Long
For n = 1 To IRC.channels.Count
  Set ch = IRC.channels.Col(n)
  If ch.joined Then
    Set frm = New FormChannel
    frm.initialize ch, Me
    frm.Show
  End If
Next

End Sub

Private Sub IRC_OnDisconnect()
  Set IRC = Nothing
  Me.Caption = Me.Caption & " [desconectado]"
  RaiseEvent IRCDisconnect
End Sub

Private Sub IRC_OnJoin(nChannel As jIRCLib.Channel, gU As jIRCLib.GlobalUser)
  If gU Is IRC.self Then
    Dim frm As FormChannel
    Set frm = New FormChannel
    frm.initialize nChannel, Me
  End If
End Sub
