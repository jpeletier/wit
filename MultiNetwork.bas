Attribute VB_Name = "MultiNetwork"

Public Const IDN_IRC_HISPANO = 1
Public Const IDN_ZONAGURU_COM = 2
Public Const IDN_CHATPOLIS_ORG = 3
Public Const IDN_GLOBALCHAT_ORG = 4

Public Const IDN_DEFAULT = IDN_IRC_HISPANO

Private Networks As Collection


Public Function getNetworkFromChannel(ch As Channel) As IRCNetwork
  Set getNetworkFromChannel = getNetworkFromIRClient(ch.parent)
End Function

Public Function getNetworkFromGUsr(gUsr As GlobalUser) As IRCNetwork
  Set getNetworkFromGUsr = getNetworkFromIRClient(gUsr.parent)
End Function

Public Function getNetworkFromIRClient(IRC As CIRCClient) As IRCNetwork
  Set getNetworkFromIRClient = getNetworkFromID(IRC.Properties("IDNetwork"))
End Function

Public Function getNetworkFromID(IDNetwork As Long) As IRCNetwork
  Set getNetworkFromID = ObjectExistsInCollection(Networks, "C" & IDNetwork)
End Function


Public Sub intialize()

Set Networks = New Collection

Dim rc As New Recordset
Dim nt As IRCNetwork

CheckManagementConnection
rc.Open "SELECT IDNetwork FROM IRCNetworks", CnMgt, adOpenForwardOnly, adLockReadOnly

Do Until rc.EOF
  Set nt = New IRCNetwork
  nt.initialize rc!IDNetwork
  Networks.Add nt, "C" & nt.IDNetwork
  rc.MoveNext
Loop




End Sub

