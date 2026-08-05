VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Channel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"No"
Attribute VB_Ext_KEY = "Member0" ,"Usuarios"
Option Explicit
Implements IGhostRef
Private mGRC As GRCollection


Private mName As String
Private mParent As CIRCClient
Private WithEvents mUsers As Users
Attribute mUsers.VB_VarHelpID = -1
Private mTopic As String
Private mJoined As Boolean
Private mDateCreated As Date

Public Event OnMessage(who As User, text As String, cancel As Boolean)
Public Event OnExternalMessage(who As GlobalUser, text As String, cancel As Boolean)
Public Event OnUserLeave(who As User, kickedBy As GlobalUser, reason As String, cancel As Boolean)
Public Event OnUserQuit(who As User, quitMessage As String)
Public Event OnJoin(who As User, cancel As Boolean)
Public Event OnTopicChange(cancel As Boolean)
Public Event OnUserPart(who As User, cancel As Boolean)
Public Event OnNotice(who As User, text As String, cancel As Boolean)
Public Event OnExternalNotice(who As GlobalUser, text As String, cancel As Boolean)
Public Event OnNickChange(who As User, newNick As String)
Public Event OnBanStatusChange(onWho As User, byWho As GlobalUser, nickNameMask As String, userNameMask As String, hostNameMask As String)
Public Event OnVoiceStatusChange(who As User, byWho As GlobalUser)
Public Event OnModeChange(modeFlag As String, byWho As GlobalUser)
Public Event OnModeReady()
Public Event OnNames()
Public Event OnOperatorChange(usr As User, byWho As GlobalUser)

Private mChannelKey As String
Private mUserLimit As Long

Private flagModeParsed As Boolean
Private flagNamesReady As Boolean




Dim modes(26) As Byte

Private Function readMode(modeFlag As String) As Boolean
  readMode = modes(Asc(LCase(modeFlag)) - 97)
End Function



Public Property Get mode(modeFlag As String) As Boolean
  On Error Resume Next
  
'  If Not flagModeParsed Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    Me.getMode
'    msgLoop.WaitFor 10000, True, "MODEPARSED_" & mName
'  End If
  
  
  mode = readMode(modeFlag)
End Property

Friend Property Let mode(modeFlag As String, Value As Boolean)
  On Error Resume Next
  
  modes(Asc(LCase(modeFlag)) - 97) = Value
  
End Property

Public Sub setMode(sign As Boolean, modeFlags As String, Optional userLimit As Long = 0, Optional secretKey As String, Optional parm3 As String, Optional parm4 As String, Optional parm5 As String, Optional parm6 As String, Optional parm7 As String)

mParent.setMode mName, sign, modeFlags, userLimit, secretKey, parm3, parm4, parm5, parm6, parm7

End Sub

Public Property Get modeInviteOnly() As Boolean
  modeInviteOnly = mode("i")
End Property

Public Property Get modePrivate() As Boolean
  modePrivate = mode("p")
End Property

Public Property Get modeSecret() As Boolean
  modeSecret = mode("s")
End Property

Public Property Get modeNoExternalMessages() As Boolean
  modeNoExternalMessages = mode("n")
End Property

Public Property Get modeOnlyOpsChangeTopic() As Boolean
  modeOnlyOpsChangeTopic = mode("t")
End Property

Public Property Get modeModerated() As Boolean
  modeModerated = mode("m")
End Property

Public Property Get channelKey() As String
  channelKey = mChannelKey
End Property

Public Property Let modeInviteOnly(nv As Boolean)
  setMode nv, "i"
End Property

Public Property Let modePrivate(nv As Boolean)
  setMode nv, "p"
End Property

Public Property Let modeSecret(nv As Boolean)
  setMode nv, "s"
End Property

Public Property Let modeNoExternalMessages(nv As Boolean)
  setMode nv, "n"
End Property

Public Property Let modeOnlyOpsChangeTopic(nv As Boolean)
  setMode nv, "t"
End Property

Public Property Let modeModerated(nv As Boolean)
  setMode nv, "m"
End Property

Public Property Let channelKey(newKey As String)
  If newKey = "" Then
    setMode False, "k"
  Else
    setMode True, "k", , newKey
  End If
  
End Property

Public Property Get userLimit() As Long
  userLimit = mUserLimit
End Property

Public Property Let userLimit(nu As Long)
  If nu < 0 Then
    setMode False, "l"
  Else
    setMode True, "l", nu
  End If
End Property

Public Sub parseModeString(cmd() As String, gU As GlobalUser, offset As Long)

Dim sign As Boolean


Dim c As String * 1
Dim lencmd As Long
If offset > UBound(cmd) Then
    Debug.Print "ParseModeString: Offset out of range"
    Exit Sub
End If
lencmd = Len(cmd(offset))
Dim parm As Long
parm = offset + 1

Dim n As Long
Dim usr As User
For n = 1 To lencmd
  c = Mid(cmd(offset), n, 1)
  If parm > UBound(cmd) Then
         Debug.Print "ParseModeString: Offset out of range in case loop"
         Exit Sub
  End If
  
  Select Case c
    Case "+", "-"
      sign = c = "+"
    Case "o"
      If parm > UBound(cmd) Then
         Debug.Print "ParseModeString: Offset out of range in o case"
         Exit Sub
      End If
      Set usr = mUsers(cmd(parm))
      parm = parm + 1
      If Not usr Is Nothing Then
        If usr.operator <> sign Then
          usr.setOperator sign, gU
          RaiseEvent OnOperatorChange(usr, gU)
        End If
      End If
    
    Case "b"
     Exit Sub 'revisar nicks con "["exit sub
      Dim nickMask As String
      Dim userMask As String
      Dim hostMask As String
      CnstIRC.splitUserLabel cmd(parm), nickMask, userMask, hostMask
      parm = parm + 1
      For Each usr In mUsers
        If (usr.nickName Like nickMask) And (usr.hostName Like hostMask) And _
        (usr.userName Like userMask) Then
          
          If usr.banned <> sign Then
            usr.setBanStatus sign, gU, nickMask, userMask, hostMask
            RaiseEvent OnBanStatusChange(usr, gU, nickMask, userMask, hostMask)
          End If
        End If
      Next
    Case "v"
      If parm > UBound(cmd) Then
        For Each usr In mUsers
            If LCase(cmd(parm)) = LCase(usr.nickName) Then
                If usr.voice <> sign Then
                    usr.setVoice sign, gU
                    RaiseEvent OnVoiceStatusChange(usr, gU)
                End If
            End If
        Next
      End If
      parm = parm + 1
        
    Case "k"
      If parm > UBound(cmd) Then
         Debug.Print "ParseModeString: Offset out of range in k case"
         Exit Sub
      End If
      Dim oldKey As String
      'modes(Asc(c)) = Abs(sign)
      mode(c) = sign
      oldKey = mChannelKey
      If sign Then
        mChannelKey = cmd(parm)
        parm = parm + 1
      Else
        mChannelKey = ""
      End If
      
      If oldKey <> mChannelKey Then
        RaiseEvent OnModeChange("k", gU)
      End If
      
    Case "l"
      Dim oldUserLimit As Long
      oldUserLimit = mUserLimit
      'modes(Asc(c)) = Abs(sign)
      mode(c) = sign
      If sign Then
        mUserLimit = Val(cmd(parm))
        parm = parm + 1
      Else
        mUserLimit = -1
      End If
      If oldUserLimit <> mUserLimit Then
        RaiseEvent OnModeChange("l", gU)
      End If
      
    Case "a" To "z"
      If readMode(c) <> sign Then
        mode(c) = sign
        RaiseEvent OnModeChange(c, gU)
      End If
      
  End Select
  
Next
RaiseEvent OnModeReady

'flagModeParsed = True
'postMsg "MODEPARSED_" & mName

End Sub



Public Property Get name() As String
Attribute name.VB_UserMemId = 0
  name = mName
End Property

Friend Property Let name(nn As String)
  mName = nn
End Property

Friend Property Set parent(newParent As CIRCClient)
  Set mParent = newParent
  Set mUsers = New Users
  mUsers.initialize newParent, mName
End Property

Public Property Get parent() As CIRCClient
  Set parent = mParent
End Property


Public Property Get Topic() As String
    Topic = mTopic
End Property

Public Property Let Topic(newTopic As String)
    parent.changeTopic newTopic, mName
End Property

Friend Sub SetTopic(newTopic As String, cancel As Boolean)
    mTopic = newTopic
    RaiseEvent OnTopicChange(cancel)
End Sub



Public Property Get Users() As Users
    
'    If Not flagNamesReady Then
'      Set msgLoop = initMessageLoop(msgLoop)
'      parent.getChannelNames mName
'      msgLoop.WaitFor 20000, True, "NAMES_" & mName
'    End If
        
    
    Set Users = mUsers
End Property


Friend Property Set Users(vData As Users)
    Set mUsers = vData
End Property

Private Sub Class_Initialize()
  
  mUserLimit = -1
End Sub

Private Sub Class_Terminate()
    Set mUsers = Nothing
    If Not mGRC Is Nothing Then
      mGRC.Remove mName
    End If
End Sub

Public Sub say(text As String)
  parent.privateMessage mName, text
End Sub

Public Sub part(Optional message As String = "")
  On Error Resume Next
'  parent.channels.Remove mName
  parent.leaveChannel mName, message
'  Set parent = Nothing
End Sub

Friend Sub NotifyOnSpeak(gU As GlobalUser, text As String, cancel As Boolean)

Dim UserSpeaks As User

Set UserSpeaks = mUsers(gU)
  
If UserSpeaks Is Nothing Then
  'Mensaje externo.
  RaiseEvent OnExternalMessage(gU, text, cancel)
Else
  RaiseEvent OnMessage(UserSpeaks, text, cancel)
End If


End Sub

Friend Sub notifyOnNotice(gU As GlobalUser, text As String, cancel As Boolean)
    
  Dim usr As User
  Set usr = mUsers(gU)
  If usr Is Nothing Then
    RaiseEvent OnExternalNotice(gU, text, cancel)
  Else
    RaiseEvent OnNotice(usr, text, cancel)
  End If
  
End Sub

Public Sub NotifyNewUser(gU As GlobalUser, cancel As Boolean)

If mUsers(gU) Is Nothing Then
  If gU Is parent.self Then
    mJoined = True
    mUsers.clear
    gU.channels.Add Me
  
      
  End If
  RaiseEvent OnJoin(mUsers.Add(gU), cancel)
End If
  
End Sub

Friend Sub NotifyOnPart(gU As GlobalUser, cancel As Boolean)

If Not mUsers(gU.nickName) Is Nothing Then
  Dim who As User
  Set who = mUsers(gU)
  
  gU.notifyOnChannelPart Me, cancel
  gU.notifyOnChannelLeave Me, Nothing, "", cancel
  mUsers.Remove gU
  RaiseEvent OnUserPart(who, cancel)
  RaiseEvent OnUserLeave(who, Nothing, "", cancel)
  If gU Is parent.self Then
    Set mUsers = New Users
    mUsers.initialize mParent, mName
    flagNamesReady = False
    gU.channels.Remove Me.name
  End If
End If
  
End Sub

Friend Sub notifyOnQuit(gU As GlobalUser, quitMessage As String)
  Dim who As User
  Set who = mUsers(gU)
  mUsers.Remove gU
  If Not who Is Nothing Then
    RaiseEvent OnUserQuit(who, quitMessage)
    RaiseEvent OnUserLeave(who, Nothing, quitMessage, False)
  End If
  
  If gU Is parent.self Then
    gU.channels.Remove Me.name
  End If
  
End Sub



Friend Sub NotifyOnKick(usr As GlobalUser, byWho As GlobalUser, reason As String, cancel As Boolean)
If Not mUsers(usr.nickName) Is Nothing Then
  Dim who As User
  Set who = mUsers(usr)
  mUsers.Remove usr
  RaiseEvent OnUserLeave(who, byWho, reason, cancel)
  If usr Is parent.self Then
    Set mUsers = New Users
    mUsers.initialize mParent, mName
    flagNamesReady = False
  End If

End If

End Sub

Friend Sub ProcessUserList(list As String)

Dim usr() As String

usr = Split(Trim(list), " ")

Dim n As Long
Dim u As User
Dim op As Boolean
Dim vc As Boolean
For n = 0 To UBound(usr)
  
  op = False
  vc = False
 
  Select Case Mid(usr(n), 1, 1)
    Case "@"
      op = True
      usr(n) = Mid(usr(n), 2)
      If Mid(usr(n), 1, 1) = "+" Then
        vc = True
        usr(n) = Mid(usr(n), 2)
      End If

    Case "+"
      vc = True
      usr(n) = Mid(usr(n), 2)
    
    Case Else
      op = False
      vc = False
  End Select
  

  Set u = mUsers.Add(parent.getUser(usr(n)))
  
  
  u.setOperator op, Nothing
  u.setVoice vc, Nothing

Next

flagNamesReady = True
'postMsg "NAMES_" & mName

RaiseEvent OnNames

End Sub

Public Sub Invite(cUser As String)
  mParent.inviteToChannel mName, cUser
End Sub

Public Property Get joined() As Boolean
  joined = mJoined
End Property

Public Sub join(Optional password As String, Optional Wait As Long = 0)
  
  mParent.joinChannel mName, password
  If Not mJoined And Wait > 0 Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    msgLoop.WaitFor Wait, True, "JOIN_" & mName
  End If
  
End Sub

Private Sub IGhostRef_YourKey(GRC As jGhostRef.GRCollection, newKey As String)
  Set mGRC = GRC
  mName = newKey
End Sub



Private Sub mUsers_OnNickChange(usr As User, newNick As String)
  RaiseEvent OnNickChange(usr, newNick)
End Sub

Public Sub ban(nickMask As String, userNameMask As String, hostMask As String)
  setMode True, "b", , , joinUserLabel(nickMask, userNameMask, hostMask)
End Sub

Public Sub unBan(nickMask As String, userNameMask As String, hostMask As String)
  setMode False, "b", , , joinUserLabel(nickMask, userNameMask, hostMask)
End Sub

Public Property Get dateCreated() As Date
  
  If mDateCreated = 0 Then
'    Set msgLoop = initMessageLoop(msgLoop)
'    Me.getMode
'    msgLoop.WaitFor 10000, True, "DATECREATED_" & mName
  End If
  
  
  
  dateCreated = mDateCreated
End Property

Friend Property Let dateCreated(nv As Date)
  mDateCreated = nv
'  postMsg "DATECREATED_" & mName
End Property

Public Sub getMode()
  mParent.getMode Me.name
End Sub

Public Sub Action(text As String)

Me.say "ACTION " & text & ""


End Sub

Private Sub msgLoop_ExitedAllLoops()
'  Set msgLoop = Nothing
End Sub
