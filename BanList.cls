VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BanList"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Collection" ,"BanListEntry"
Attribute VB_Ext_KEY = "Member0" ,"BanListEntry"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
'local variable to hold collection
Private mCol As Collection

Public Function Add(Channel As Channel, DateEnd As Date, DateInit As Date, Reason As String, Author As String) As BanListEntry
    'create a new object
    
    Dim IDNetwork As Long
    IDNetwork = Channel.parent.Properties("IDNetwork")
    
    Remove Channel.name, IDNetwork

    'return the object created
    Dim ble As BanListEntry
    Set ble = AddMember(IDNetwork, Channel.name, DateEnd, DateInit, Reason, Author)
    Set Add = ble
      
    
    On Error Resume Next
    
    CheckManagementConnection

    CnMgt.Execute "INSERT INTO bans (channelName,reason,author,DateInit,DateEnd) values ('" & safeQueryText(Channel.name) & "', '" & safeQueryText(Reason, 100) & "','" & safeQueryText(Author, 50) & "','" & Now & "','" & DateEnd & "' )"

    Dim n As Long
    Dim wcl As WitClient
    Dim ch As Channel
    For Each wcl In frmWit.clients
      For n = 1 To wcl.IRC.channels.col.Count
        Set ch = wcl.IRC.channels.col(n)
        If LCase(ch.name) = LCase(Channel.name) And ch.parent.Properties("IDNetwork") = IDNetwork Then
          partFromChannel ch, ble
        End If
      Next
    Next


End Function


Private Function AddMember(IDNetwork As Long, channelName As String, DateEnd As Date, DateInit As Date, Reason As String, Author As String) As BanListEntry

    Dim objNewMember As BanListEntry
    Set objNewMember = New BanListEntry


    'set the properties passed into the method
    objNewMember.DateEnd = DateEnd
    objNewMember.DateInit = DateInit
    objNewMember.Reason = Reason
    objNewMember.Author = Author
    objNewMember.IDNetwork = IDNetwork
    objNewMember.channelName = channelName
    mCol.Add objNewMember, "C" & IDNetwork & channelName

Set AddMember = objNewMember

End Function


Public Property Get Item(channelName As String, IDNetwork As Long) As BanListEntry
Attribute Item.VB_UserMemId = 0
    
    On Error Resume Next
  Set Item = mCol("C" & IDNetwork & channelName)
End Property



Public Property Get Count() As Long
    'used when retrieving the number of elements in the
    'collection. Syntax: Debug.Print x.Count
    Count = mCol.Count
End Property


Public Sub Remove(channelName As String, IDNetwork As Long)
    
    On Error Resume Next
    mCol.Remove "C" & IDNetwork & channelName
    
    CheckManagementConnection
    CnMgt.Execute "DELETE BANS WHERE IDNetwork=" & IDNetwork & " AND channelName='" & safeQueryText(channelName) & "'"
    
End Sub


Public Property Get NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
Attribute NewEnum.VB_MemberFlags = "40"
    'this property allows you to enumerate
    'this collection with the For...Each syntax
    Set NewEnum = mCol.[_NewEnum]
End Property


Private Sub Class_Initialize()
    'creates the collection when this class is created
    Set mCol = New Collection
End Sub


Private Sub Class_Terminate()
    'destroys collection when this class is terminated
    Set mCol = Nothing
End Sub

Public Sub load()

Dim rc As Recordset

Set rc = New Recordset

CheckManagementConnection

CnMgt.Execute "delete bans where DateEnd < '" & Now & "'"

rc.Open "select * from bans", CnMgt, adOpenStatic, adLockReadOnly

Do Until rc.EOF
  AddMember rc!IDNetwork, rc!channelName, rc!DateEnd, rc!DateInit, rc!Reason, rc!Author
  rc.MoveNext
Loop

End Sub

Public Function getBanStatus(Channel As Channel) As BanListEntry

Dim IDNetwork As Long
IDNetwork = Channel.parent.Properties("IDNetwork")

Dim ble As BanListEntry

Set ble = Item(Channel.name, IDNetwork)

If Not ble Is Nothing Then
  If ble.DateEnd < Now Then
    Remove ble.channelName, ble.IDNetwork
    Set ble = Nothing
  End If
End If

Set getBanStatus = ble


End Function


Public Sub partFromChannel(Channel As Channel, ble As BanListEntry)

Channel.part mircColorText("WIT-BAN", mccDarkRed) & " hasta " & ble.DateEnd & ". -> " & ble.Reason

End Sub

Public Function partIfBanned(Channel As Channel) As Boolean

  Dim ble As BanListEntry
  Set ble = getBanStatus(Channel)
  
  If Not ble Is Nothing Then
    partFromChannel Channel, ble
    partIfBanned = True
  End If

End Function

