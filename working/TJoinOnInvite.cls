VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TJoinOnInvite"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private WithEvents myChannel As Channel
Attribute myChannel.VB_VarHelpID = -1
Private gUsr As GlobalUser

Private WithEvents tmr As CTimer
Attribute tmr.VB_VarHelpID = -1

Private self As TJoinOnInvite



Enum TJActionsEnum
  tjInvited = 0
  tjSentByWitOp = 1
End Enum


Private mAction As TJActionsEnum



Public Sub initialize(ch As Channel, usr As GlobalUser, Optional action As TJActionsEnum = tjInvited)
      
  Set myChannel = ch
  Set gUsr = usr
  Set self = Me
  
  mAction = action
  
  Set tmr = New CTimer
  tmr.SharedTimer = True
  tmr.TimeScale = TU_Seconds
  tmr.Interval = 60
  
  myChannel.Join
  
  

End Sub

Private Sub Class_Terminate()
  Debug.Print "Autojoin terminated"
End Sub

Private Sub myChannel_OnJoin(who As jIRCLib.User, cancel As Boolean)

  If who.gUsr Is myChannel.parent.self Then
  
  Select Case mAction
  
    Case TJActionsEnum.tjInvited
      myChannel.say "Hola, " & gUsr & " me ha invitado aquí."
      myChannel.parent.getUser("Zoltar").notice gUsr.nickName & " me ha invitado al canal " & myChannel.name
    
    Case TJActionsEnum.tjSentByWitOp
      myChannel.say "Hola, " & gUsr & " me ha enviado a este canal."
      
      
  End Select
    
    
    myChannel.say "Para organizar una partida de trivial, dime en un privado: TRIVIAL " & myChannel.name
    
    Debug.Print "Joined " & myChannel.name
    
    
    
    
    tmr_ThatTime 'Destruye todas las variables
   
  End If


End Sub

Private Sub tmr_ThatTime()

  Set tmr = Nothing
  Set myChannel = Nothing
  Set gUsr = Nothing
  Set self = Nothing

End Sub
