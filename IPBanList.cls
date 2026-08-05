VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IPBanList"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Collection" ,"Class1"
Attribute VB_Ext_KEY = "Member0" ,"Class1"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit
'local variable to hold collection
Private mCol As Collection

Public Function Add(IP As String, Reason As String, Author As String) As IPBanListEntry
    'create a new object
    
   
    Remove IP

    'return the object created
    Dim DateInit As Date
    DateInit = Now
    Dim ble As IPBanListEntry
    Set ble = AddMember(IP, Reason, Author, DateInit)
    Set Add = ble
      
    
    On Error Resume Next
    
    CheckManagementConnection

    CnMgt.Execute "INSERT INTO ipbans (IP,reason,author,DateInit) values ('" & safeQueryText(IP, 15) & "', '" & safeQueryText(Reason, 100) & "','" & safeQueryText(Author, 50) & "','" & DateInit & "')"

    Dim n As Long
    Dim wcl As WitClient
    For Each wcl In frmWit.clients
      If wcl.IRC.remoteAddress = IP Then
        wcl.Terminate
      End If
    Next


End Function


Private Function AddMember(IP As String, Reason As String, Author As String, DateInit As Date) As IPBanListEntry

    Dim objNewMember As IPBanListEntry
    Set objNewMember = New IPBanListEntry


    'set the properties passed into the method
    objNewMember.Reason = Reason
    objNewMember.Author = Author
    objNewMember.IP = IP
    objNewMember.DateInit = DateInit
    
        
    mCol.Add objNewMember, "C" & IP

Set AddMember = objNewMember

End Function


Public Property Get Item(IP As String) As IPBanListEntry
    
    On Error Resume Next
  Set Item = mCol("C" & IP)
End Property



Public Property Get Count() As Long
    'used when retrieving the number of elements in the
    'collection. Syntax: Debug.Print x.Count
    Count = mCol.Count
End Property


Public Sub Remove(IP As String)
    
    On Error Resume Next
    mCol.Remove "C" & IP
    
    CheckManagementConnection
    CnMgt.Execute "DELETE ipBANS WHERE IP='" & safeQueryText(IP) & "'"
    
End Sub


Public Property Get NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
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

'CnMgt.Execute "delete bans where DateEnd < '" & Now & "'"

rc.Open "select * from ipbans", CnMgt, adOpenStatic, adLockReadOnly

Do Until rc.EOF
  AddMember rc!IP, rc!Reason, rc!Author, rc!DateInit
  rc.MoveNext
Loop

End Sub

Public Function getBanStatus(IP As String) As IPBanListEntry


Dim ble As IPBanListEntry

Set ble = Item(IP)

Set getBanStatus = ble

End Function

