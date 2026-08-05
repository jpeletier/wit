Attribute VB_Name = "Utils"
Option Explicit

Public Machine As Long

Public Const WITGAME_TRIVIA = 1
Public Const WITGAME_CYL = 2


Public activeLeague As Long

Public CnMgt As ADODB.Connection


Public NiCKBot As NiCKBot


Dim MemDB As Connection
Dim defs As Recordset

Public questions As jWitQuestionSeeker.Seeker
Public Numbers As New jNumbers.CNumbers
Public triviaConnection As Connection

Public gInfo As GlobalInfo



Public Function ConStrAccess(Path As String) As String
  
  ConStrAccess = "Provider=Microsoft.Jet.OLEDB.4.0;" & _
      "Data Source=" & Path

  'ConStrAccess = "Provider=MSDASQL.1;Extended Properties=""DSN=MS Access Database;DBQ=" & Path & ";DriverId=25;FIL=MS Access;MaxBufferSize=2048;PageTimeout=5;"""
End Function



Public Sub InitDB()

CheckManagementConnection

Set defs = New Recordset

CnMgt.Execute "DELETE  FROM DEFS WHERE LastUsed < '" & DateAdd("m", -6, Now) & "'"

defs.CursorLocation = adUseClient
defs.Open "SELECT ID,DEF,AUTHOR,LASTUSED,TEXT FROM DEFS ORDER BY ID", CnMgt, adOpenKeyset, adLockOptimistic
If Not defs.EOF Then
  defs.MoveLast
  defs.MoveFirst
End If

End Sub


Public Function LocateFirstDef(def As String, Optional Author As String = "") As String
Exit Function
On Error Resume Next
If def = "" Then Exit Function
defs.MoveFirst

Dim st As String

st = "(Def='" & Replace(def, "'", "''") & "')"

If Author <> "" Then
  st = st & " AND (Author='" & Replace(Author, "'", "''") & "')"
End If

Dim dfs As Recordset
Set dfs = defs.Clone
dfs.Filter = st

If Not dfs.EOF Then
  'defs.Find "ID=" & dfs!id
  defs.Bookmark = dfs.Bookmark
 
  LocateFirstDef = defs!text
  def = defs!def
  If Not IsNull(defs!lastused) Then
    defs!lastused = Now
    defs.update
  End If
  
End If

End Function

Public Function LocateRandomDef(def As String) As String
Exit Function

On Error Resume Next
If def = "" Then Exit Function
Dim cl As Recordset
Set cl = defs.Clone

cl.Filter = "DEF='" & Replace(def, "'", "''") & "'"

If Not cl.EOF Then
  cl.MoveLast
  If Not cl.BOF Then
    cl.MoveFirst
  End If
  
  If cl.RecordCount > 0 Then
    Dim m As Long
    m = rollDice(1, cl.RecordCount) - 1

    cl.Move m, adBookmarkFirst
    def = cl!def
    LocateRandomDef = cl!text
    If Not IsNull(defs!lastused) Then
      defs!lastused = Now
      defs.update
    End If
    
  End If
  
End If

End Function

Public Function AddModDef(def As String, text As String, Author As String) As Boolean
Exit Function

On Error Resume Next
If def = "" Then Exit Function
If LocateFirstDef(def, Author) = "" Then
  defs.AddNew
End If
If ("" & defs!Author = "") Or (UCase(Author) = UCase(defs!Author)) Then
  defs!def = def
  defs!text = Mid(text, 1, defs.Fields("text").DefinedSize)
  defs!Author = Author
  defs!lastused = Now
  'defs.Update
End If
defs.update
End Function

Public Sub Wait(msec)

Dim tmr As Single

tmr = Timer + msec / 1000

If tmr > 86400 Then tmr = tmr Mod 86400

Do Until Timer >= tmr

  DoEvents

Loop

End Sub



Public Function IsFriendly(usr As jIRCLib.GlobalUser) As Boolean

IsFriendly = False

Exit Function

Select Case LCase(usr.nickName)
  Case "iki", "juglar24", "Zoltar", "ka0s", "el_txakal", "txakal", "goznar", "elchomin", "chomin", "lord_yupa"
    IsFriendly = True
End Select


End Function


Public Function LocateFormChannel(Channel As String) As FormChannel

Dim frm As Form
Dim fc As FormChannel
For Each frm In Forms
  If TypeOf frm Is FormChannel Then
    Set fc = frm
    If UCase(fc.myChannel.Name) = UCase(Channel) Then
      Set LocateFormChannel = fc
      Exit Function
    End If
  End If
Next
    




End Function


Public Function TrivialDatabase() As String
  TrivialDatabase = ConMSSQL(TRIVIAL_DB, TRIVIAL_DBUSER, TRIVIAL_DBPASSWORD, TRIVIAL_DBSERVER)  ' ConStrAccess(App.Path & "\trivia.mdb")
End Function

Public Function ConMSSQL(bd As String, uid As String, pwd As String, Optional server As String = "****") As String

'  ConMSSQL = "Provider=sqloledb;Server=" & server & ";Database=" & bd & ";uid=" & uid & ";pwd=" & pwd
ConMSSQL = "PROVIDER=sqloledb;DATA SOURCE=" & server & ";USER ID=" & uid & ";PASSWORD=" & pwd & ";INITIAL CATALOG=" & bd
End Function


Public Function QuerySingleValue(sql As String, cn As Connection) As Variant

Dim rc As New Recordset

rc.Open sql, cn, adOpenStatic, adLockReadOnly

If rc.EOF Then
  QuerySingleValue = Null
Else
  QuerySingleValue = rc.Fields(0).value
End If

End Function

Public Function getLastID(cn As Connection) As Long

Dim v As Variant
 
v = QuerySingleValue("SELECT @@IDENTITY", cn)

If IsNull(v) Then
    getLastID = 0
Else
    getLastID = CLng(v)
End If

End Function

Public Sub initQuestions()
  Set questions = New jWitQuestionSeeker.Seeker
  
  questions.initialize TrivialDatabase
  
End Sub



Public Function getQuestion(IDQuestionSubset As Long) As Question_Type
  
On Error GoTo errq
  
  getQuestion = questions.getRandomQuestionBySubset(IDQuestionSubset)

errqexit:
Exit Function
errq:
  
  Debug.Print "getQuestion Error: " & Err.description & " " & Err.number
  initQuestions
  getQuestion = questions.getRandomQuestionBySubset(IDQuestionSubset)
  Resume errqexit

End Function


Public Function getChannelCount(IRC As jIRCLib.CIRCClient) As Long
    
    Dim n As Long
    Dim Count As Long
    
    For n = 1 To IRC.channels.Count
      If IRC.channels(n).joined Then
        Count = Count + 1
      End If
    Next

getChannelCount = Count
End Function

Public Function isAdmin(gUsr As GlobalUser) As Boolean

isAdmin = IsNumeric(gUsr.Properties("IDUser"))

End Function


Public Function isOperator(gUsr As GlobalUser, Channel As Channel) As Boolean

isOperator = isAdmin(gUsr)

Dim usrStop As User
Set usrStop = Channel.Users(gUsr)
If Not usrStop Is Nothing Then
  If usrStop.operator Then
    isOperator = True
  End If
End If

End Function


Public Sub AddScore(IDPlayer As Long, up As Long, questionsUp As Long, IDSubject As Long, IDTournament As Long)

CheckManagementConnection

On Error GoTo ads_err
CnMgt.Execute "EXECUTE sp_AddScore " & IDPlayer & ", " & IDSubject & ", " & IDTournament & ", " & questionsUp & ", " & up


ads_exit:
Exit Sub

ads_err:
Dim f As Long
f = FreeFile
Open "adslog.txt" For Append As #f
Print #f, IDPlayer & vbTab & up & vbTab & questionsUp & vbTab & IDSubject & vbTab & IDTournament & vbTab & Err.number & vbTab & Err.description
Close #f

Set CnMgt = Nothing

Resume ads_exit

End Sub

Public Sub AddCYLScore(IDPlayer As Long, up As Long, ChallengesUp As Long, IDChallengeType As Long, IDCYLTournament As Long)

CheckManagementConnection

On Error GoTo adsc_err
CnMgt.Execute "EXECUTE sp_CYLAddScore " & IDPlayer & ", " & IDCYLTournament & ", " & IDChallengeType & ", " & ChallengesUp & ", " & up


adsc_exit:
Exit Sub

adsc_err:
Dim f As Long
f = FreeFile
Open "adsCYLlog.txt" For Append As #f
Print #f, IDPlayer & vbTab & up & vbTab & ChallengesUp & vbTab & IDChallengeType & vbTab & IDCYLTournament & vbTab & Err.number & vbTab & Err.description
Close #f

Set CnMgt = Nothing

Resume adsc_exit

End Sub


Public Sub CheckManagementConnection()
If CnMgt Is Nothing Then
  Set CnMgt = New Connection
  CnMgt.Open TrivialDatabase
End If
End Sub



Public Sub CheckLeague(cn As Connection)

Dim IDLeague As Long

IDLeague = DateDiff("m", "1/3/2001", Date)

If IDLeague <> activeLeague Then
  Dim rc As Recordset
  Set rc = New Recordset
  rc.CursorLocation = adUseClient
  
  ' optimizada 22/02/04 clustered idleague en tabla leagues
  rc.Open "SELECT IDLeague, [Desc] FROM Leagues WHERE IDLeague=" & IDLeague, cn, adOpenKeyset, adLockOptimistic
  
  If rc.EOF Then
    rc.AddNew
    rc!Desc = IDLeague & "ª Liga de trivial"
    rc!IDLeague = IDLeague
    rc.update
  End If

  activeLeague = IDLeague

  On Error Resume Next
  
  Dim wcl As WitClient
  Dim ch As Channel
  Dim n As Long
  For Each wcl In frmWit.clients
    For n = 1 To wcl.IRC.channels.Count
      Set ch = wcl.IRC.channels.Item(n)
      If ch.joined And LCase(ch.Name) <> "#witclub" Then
        ch.say mircColorText("AVISO: La próxima partida que se juegue en este canal será ya de la " & activeLeague & "ª liga.", mccDarkRed)
      End If
    Next
  Next

End If

End Sub

Public Function getIDPlayer(gUsr As GlobalUser, Optional ByVal cnQ As Connection = Nothing)

Dim Network As IRCNetwork
Set Network = getNetworkFromGUsr(gUsr)

  If cnQ Is Nothing Then
    CheckManagementConnection
    Set cnQ = CnMgt
  End If
  
  
  If Network.IDNetwork = IDN_ZONAGURU_COM Then
    Dim FBId As Double
    Dim IDPlayer As Long
    Dim v As Variant
    FBId = Facebook.getFBId(gUsr)
    If FBId > 0 Then
        v = QuerySingleValue("select IDPlayer from players where ExternalID = " & FBId, cnQ)
        If (IsNull(v)) Then
            cnQ.Execute "INSERT INTO Players (Nickname, IDNetwork, ExternalID, LastUsed) values ('" & safeQueryText(gUsr.nickName) & "'," & Network.IDNetwork & ", " & FBId & ", GETDATE())"
            IDPlayer = getLastID(cnQ)
        Else
            IDPlayer = CLng(v)
            cnQ.Execute "UPDATE players set lastused = GETDATE() where IDPlayer=" & IDPlayer
        End If
    
        getIDPlayer = IDPlayer
        Exit Function
    End If
    
    'si no hay ID de facebook, se ejecuta el código anterior que genera un idplayer nuevo.
    
  End If
  
  

  Dim players As Recordset
  Set players = New Recordset

  With players
    'optimizada 22/02/04 IX:IDNetwork/Nickname en Players
    .Open "SELECT IDPlayer,NickName,lastused, idnetwork FROM Players WHERE IDNetwork=" & Network.IDNetwork & " AND NickName='" & gUsr.nickName & "'", cnQ, adOpenDynamic, adLockOptimistic
    If .EOF Then
      .AddNew
      !nickName = gUsr.nickName
      !IDNetwork = Network.IDNetwork
    End If
      !lastused = Now 'dbnetlib problem
      .update
      .Close
      .Open "SELECT IDPlayer FROM Players WHERE IDNetwork=" & Network.IDNetwork & " AND NickName='" & gUsr.nickName & "'", cnQ, adOpenDynamic, adLockOptimistic
  
  getIDPlayer = !IDPlayer
  
  End With
  
  
  players.Close
  Set players = Nothing



End Function




Public Function getIDChannel(Name As String, Network As IRCNetwork, Optional ByVal cnQ As Connection = Nothing)

  If cnQ Is Nothing Then
    CheckManagementConnection
    Set cnQ = CnMgt
  End If

  Dim channels As Recordset
  Set channels = New Recordset

  With channels
    'optimizada 22/02/2004 IX: IDNetwork,Name
    .Open "SELECT IDChannel,Name FROM channels WHERE IDNetwork=" & Network.IDNetwork & " AND name='" & Name & "'", cnQ, adOpenDynamic, adLockOptimistic
    If .EOF Then
      getIDChannel = Null
    Else
      getIDChannel = !IDChannel
    End If
  
  
  End With
  
  
  channels.Close
  Set channels = Nothing

End Function

Public Sub MessageOnEnd(ch As Channel)

If getNetworkFromChannel(ch).IDNetwork = IDN_IRC_HISPANO Then
  'MessageOnEnd = mircColorText(mircUnderlineText("PERSONALIZA TU BOT. Envía "), mccBlack, mccBrightGreen) & mircColorText("PELE PERSOWIT", mccDarkRed, mccYellow) & mircColorText(" al 5015. Podrás ponerle un nick chulo a tu clon.", mccBlack, mccBrightGreen) & " (coste 0,9E+IVA). " & mircColorText("NUEVO!! Ahorra usando tarjeta de crédito", mccPurple) & ". Más info en " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/PersoWit", mccPureBlue))
  
  Dim msg() As String
  Dim v As Variant
  msg = getMessages()
  
  For Each v In msg
    ch.say "" & v
  Next
  
  
Else
  'MessageOnEnd = mircColorText(mircUnderlineText("LLEVA A WIT A TU CANAL. Envía "), mccBlack, mccBrightGreen) & mircColorText("PELE WITPROPIO", mccDarkRed, mccYellow) & mircColorText(" al 5015 para activar el comando.", mccBlack, mccBrightGreen) & " (coste 0,9E). Más info en " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial/miWit", mccPureBlue))
  ch.say "Visita " & mircUnderlineText(mircColorText("http://www.peletier.com/trivial", mccPureBlue))
End If

End Sub

Public Function getConnection(Optional ByVal forceNew As Boolean) As Connection

Static cn As Connection
Static uses As Integer

If Not cn Is Nothing Then
  forceNew = cn.Errors.Count > 0
End If


If cn Is Nothing Or uses > 10 Or forceNew Then
  Set cn = New Connection
  cn.Open TrivialDatabase
  uses = 0
End If

uses = uses + 1

Set getConnection = cn

End Function

Public Function safeQueryText(ByVal st As String, Optional maxLength As Long = -1) As String

If maxLength >= 0 Then
  st = Mid(st, 1, maxLength)
End If

safeQueryText = Replace(st, "'", "''")
End Function

Public Function ObjectExistsInCollection(col As Collection, Key As String) As Object

On Error Resume Next

Set ObjectExistsInCollection = col(Key)



End Function

Public Sub LogLine(func As String, text As String)

On Error Resume Next

Dim f As Integer
f = FreeFile

Open LOGDIR & "witlog-" & Format(Now, "yyyy.mm.dd") & ".log" For Append As #f
  Print #f, "Wit" & Machine & vbTab & Format(Now, "dd/mm/yyyy hh:nn:ss") & vbTab & func & vbTab & text
Close #f

End Sub

Public Function getIDChannelIDTournament(ch As Channel, cn As Connection, IDChannel As Long, IDTournament As Long, isnew As Boolean) As Boolean

Dim rc As Recordset
Set rc = New Recordset

Dim IDNetwork As Long

IDNetwork = getNetworkFromChannel(ch).IDNetwork

rc.Open "SELECT * FROM Channels WHERE IDNetwork=" & IDNetwork & " AND name='" & Replace(ch.Name, "'", "''") & "'", cn, adOpenDynamic, adLockPessimistic

If rc.EOF Then
  rc.Close
  If Len(ch.Name) > 50 Then
    Debug.Print "El nombre del canal es demasiado largo... (" & ch.Name & " )"
    getIDChannelIDTournament = False
    Exit Function
  End If
  cn.Execute "INSERT INTO Channels (Name, IDDefaultTournament, LastUsed, IDNetwork ) Values ('" & Replace(ch.Name, "'", "''") & "', Null, '" & Now & "', " & IDNetwork & ")"
  isnew = True
  

Else
  rc.Close
  
  'deshabilitado el lastused opr timeoutexpired
  'cnQ.Execute "UPDATE Channels SET LastUsed='" & Now & "' WHERE name='" & Replace(ch.name, "'", "''") & "'"

  
End If
  

rc.Open "SELECT IdChannel,IDDefaultTournament FROM Channels WHERE IDNetwork=" & IDNetwork & " AND name='" & Replace(ch.Name, "'", "''") & "'", cn, adOpenDynamic, adLockPessimistic

IDChannel = rc!IDChannel

If IsNull(rc!IdDefaultTournament) Then
  IDTournament = 0
Else
  IDTournament = rc!IdDefaultTournament
End If

rc.Close



getIDChannelIDTournament = True

End Function

Function getNewIDGame(IDTournament As Long, cn As Connection, Optional numQuestions As Long = 0) As Long

Dim rc As Recordset
Set rc = New Recordset

rc.Open "SELECT * FROM GAMES WHERE IDGAME=0", cn, adOpenKeyset, adLockOptimistic
rc.AddNew
rc!IDTournament = IDTournament
rc!numQuestions = numQuestions
rc!DateInit = Now
rc.update
getNewIDGame = rc!IDGame
rc.Close

End Function


Public Sub initialize()

Select Case System.Machine
    Case "TIMMY1": Machine = 1
    Case "CARTMAN": Machine = 2
    Case Else: Machine = 3
End Select

MultiNetwork.intialize

LogLine "Initialize", "Wit IRC Bot " & App.Major & "." & App.Minor & "." & App.Revision & ". peletier.com 2004."

End Sub


