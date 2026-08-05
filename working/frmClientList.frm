VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.Form frmClientList 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Lista de clientes activos"
   ClientHeight    =   3195
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   6330
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MDIChild        =   -1  'True
   MinButton       =   0   'False
   ScaleHeight     =   3195
   ScaleWidth      =   6330
   ShowInTaskbar   =   0   'False
   Begin VB.CommandButton DiscAll 
      Caption         =   "Desc. Todos"
      Height          =   375
      Left            =   3780
      TabIndex        =   6
      Top             =   1920
      Width           =   1275
   End
   Begin VB.CommandButton cmdRefresh 
      Caption         =   "&Refrescar"
      Height          =   375
      Left            =   3780
      TabIndex        =   5
      Top             =   2760
      Width           =   1275
   End
   Begin VB.CommandButton Connect 
      Caption         =   "&Conectar"
      Height          =   375
      Left            =   3780
      TabIndex        =   4
      Top             =   660
      Width           =   1275
   End
   Begin VB.CommandButton Delete 
      Caption         =   "&Eliminar"
      Height          =   375
      Left            =   3780
      TabIndex        =   3
      Top             =   1500
      Width           =   1275
   End
   Begin VB.CommandButton Disconnect 
      Caption         =   "&Desconectar"
      Height          =   375
      Left            =   3780
      TabIndex        =   2
      Top             =   1080
      Width           =   1275
   End
   Begin MSComctlLib.ListView clientList 
      Height          =   2595
      Left            =   60
      TabIndex        =   1
      Top             =   540
      Width           =   3615
      _ExtentX        =   6376
      _ExtentY        =   4577
      View            =   3
      LabelEdit       =   1
      LabelWrap       =   -1  'True
      HideSelection   =   -1  'True
      FullRowSelect   =   -1  'True
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      NumItems        =   2
      BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         Key             =   "NICKNAME"
         Text            =   "Nickname"
         Object.Width           =   2540
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Key             =   "STATUS"
         Text            =   "Status"
         Object.Width           =   2540
      EndProperty
   End
   Begin VB.Label Label1 
      Caption         =   "Lista de Clientes"
      Height          =   375
      Left            =   60
      TabIndex        =   0
      Top             =   60
      Width           =   2115
   End
End
Attribute VB_Name = "frmClientList"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private WithEvents clients As WitClients
Attribute clients.VB_VarHelpID = -1

Private Sub clientList_DblClick()
  Dim wcl As WitClient
  Set wcl = frmWit.clients(clientList.selectedItem.key)
  
  Dim frm As New StatusForm
  frm.initialize wcl.IRC
  frm.Show
  
End Sub

Private Sub clients_ElementAdded()
  refreshInfo
End Sub

Private Sub clients_ElementRemoved()
  refreshInfo
End Sub

Private Sub cmdRefresh_Click()
refreshInfo
End Sub

Private Sub Connect_Click()
selectedItem.Connect
selectedItem.autoReconnect = True
End Sub

Private Sub Delete_Click()

selectedItem.Terminate

refreshInfo
End Sub

Private Sub DiscAll_Click()

Dim reason As String

reason = InputBox("Mensaje de salida:", "", "Conn. reset by master")

Dim wc As WitClient

For Each wc In frmWit.clients
  wc.IRC.quit reason
  wc.autoReconnect = False
Next

End Sub

Private Sub Disconnect_Click()
selectedItem.IRC.quit "Connection reset by master"
selectedItem.autoReconnect = False
End Sub

Private Sub Form_Load()


refreshInfo
Set clients = frmWit.clients

End Sub


Public Sub refreshInfo()

Dim wcl As WitClient
Dim li As ListItem
Dim st As String

clientList.ListItems.clear

Dim disc As Boolean

For Each wcl In frmWit.clients
  Set li = clientList.ListItems.Add(, wcl.key, wcl.IRC.nick)
  If wcl.IRC.Connected Then
    st = "Conectado"
    disc = False
  Else
    st = "Desconectado"
    disc = True
  End If
  li.SubItems(clientList.ColumnHeaders("STATUS").SubItemIndex) = st
  
  If disc Then
    If Not wcl.persist Then
      frmWit.clients.Remove wcl.key
    End If
  End If

  
Next

End Sub


Private Property Get selectedItem() As WitClient

Set selectedItem = frmWit.clients(clientList.selectedItem.key)

End Property
