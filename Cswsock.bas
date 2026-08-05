Attribute VB_Name = "SocketWrench"
'------------------------------------------------------------------------------
'
' Catalyst SocketWrench 3.1
' Copyright 1995-2000, Catalyst Development Corp. All rights reserved.
'
' This file contains the constants and function declarations used
' with the SocketWrench control for Visual Basic 6.0
'
'------------------------------------------------------------------------------

'
' General constants used with most of the controls
'
Public Const INVALID_HANDLE = -1
Public Const CONTROL_ERRIGNORE = 0
Public Const CONTROL_ERRDISPLAY = 1

'
' SocketWrench Control Actions
'
Public Const SOCKET_OPEN = 1
Public Const SOCKET_CONNECT = 2
Public Const SOCKET_LISTEN = 3
Public Const SOCKET_ACCEPT = 4
Public Const SOCKET_CANCEL = 5
Public Const SOCKET_FLUSH = 6
Public Const SOCKET_CLOSE = 7
Public Const SOCKET_DISCONNECT = 7
Public Const SOCKET_ABORT = 8
'
' SocketWrench Control States
'
Public Const SOCKET_NONE = 0
Public Const SOCKET_IDLE = 1
Public Const SOCKET_LISTENING = 2
Public Const SOCKET_CONNECTING = 3
Public Const SOCKET_ACCEPTING = 4
Public Const SOCKET_RECEIVING = 5
Public Const SOCKET_SENDING = 6
Public Const SOCKET_CLOSING = 7
'
' Socket Address Families
'
Public Const AF_UNSPEC = 0
Public Const AF_UNIX = 1
Public Const AF_INET = 2
'
' Socket Types
'
Public Const SOCK_STREAM = 1
Public Const SOCK_DGRAM = 2
Public Const SOCK_RAW = 3
Public Const SOCK_RDM = 4
Public Const SOCK_SEQPACKET = 5
'
' Protocol Types
'
Public Const IPPROTO_IP = 0
Public Const IPPROTO_ICMP = 1
Public Const IPPROTO_GGP = 2
Public Const IPPROTO_TCP = 6
Public Const IPPROTO_PUP = 12
Public Const IPPROTO_UDP = 17
Public Const IPPROTO_IDP = 22
Public Const IPPROTO_ND = 77
Public Const IPPROTO_RAW = 255
Public Const IPPROTO_MAX = 256
'
' Well-Known Port Numbers
'
Public Const IPPORT_ANY = 0
Public Const IPPORT_ECHO = 7
Public Const IPPORT_DISCARD = 9
Public Const IPPORT_SYSTAT = 11
Public Const IPPORT_DAYTIME = 13
Public Const IPPORT_NETSTAT = 15
Public Const IPPORT_FTP = 21
Public Const IPPORT_TELNET = 23
Public Const IPPORT_SMTP = 25
Public Const IPPORT_TIMESERVER = 37
Public Const IPPORT_NAMESERVER = 42
Public Const IPPORT_WhoIS = 43
Public Const IPPORT_MTP = 57
Public Const IPPORT_FINGER = 79
Public Const IPPORT_HTTP = 80
Public Const IPPORT_TFTP = 69
Public Const IPPORT_RESERVED = 1024
Public Const IPPORT_USERRESERVED = 5000
'
' Network Addresses
'
Public Const INADDR_ANY = "0.0.0.0"
Public Const INADDR_LOOPBACK = "127.0.0.1"
Public Const INADDR_NONE = "255.255.255.255"
'
' Shutdown Values
'
Public Const SOCKET_READ = 0
Public Const SOCKET_WRITE = 1
Public Const SOCKET_READWRITE = 2
'
' SocketWrench Error Response
'
Public Const SOCKET_ERRIGNORE = 0
Public Const SOCKET_ERRDISPLAY = 1
'
' SocketWrench Error Codes
'
Public Const WSABASEERR = 24000
Public Const WSAEINTR = 24004
Public Const WSAEBADF = 24009
Public Const WSAEACCES = 24013
Public Const WSAEFAULT = 24014
Public Const WSAEINVAL = 24022
Public Const WSAEMFILE = 24024
Public Const WSAEWOULDBLOCK = 24035
Public Const WSAEINPROGRESS = 24036
Public Const WSAEALREADY = 24037
Public Const WSAENOTSOCK = 24038
Public Const WSAEDESTADDRREQ = 24039
Public Const WSAEMSGSIZE = 24040
Public Const WSAEPROTOTYPE = 24041
Public Const WSAENOPROTOOPT = 24042
Public Const WSAEPROTONOSUPPORT = 24043
Public Const WSAESOCKTNOSUPPORT = 24044
Public Const WSAEOPNOTSUPP = 24045
Public Const WSAEPFNOSUPPORT = 24046
Public Const WSAEAFNOSUPPORT = 24047
Public Const WSAEADDRINUSE = 24048
Public Const WSAEADDRNOTAVAIL = 24049
Public Const WSAENETDOWN = 24050
Public Const WSAENETUNREACH = 24051
Public Const WSAENETRESET = 24052
Public Const WSAECONNABORTED = 24053
Public Const WSAECONNRESET = 24054
Public Const WSAENOBUFS = 24055
Public Const WSAEISCONN = 24056
Public Const WSAENOTCONN = 24057
Public Const WSAESHUTDOWN = 24058
Public Const WSAETOOMANYREFS = 24059
Public Const WSAETIMEDOUT = 24060
Public Const WSAECONNREFUSED = 24061
Public Const WSAELOOP = 24062
Public Const WSAENAMETOOLONG = 24063
Public Const WSAEHOSTDOWN = 24064
Public Const WSAEHOSTUNREACH = 24065
Public Const WSAENOTEMPTY = 24066
Public Const WSAEPROCLIM = 24067
Public Const WSAEUSERS = 24068
Public Const WSAEDQUOT = 24069
Public Const WSAESTALE = 24070
Public Const WSAEREMOTE = 24071
Public Const WSASYSNOTREADY = 24091
Public Const WSAVERNOTSUPPORTED = 24092
Public Const WSANOTINITIALISED = 24093
Public Const WSAHOST_NOT_FOUND = 25001
Public Const WSATRY_AGAIN = 25002
Public Const WSANO_RECOVERY = 25003
Public Const WSANO_DATA = 25004
Public Const WSANO_ADDRESS = 25004

'
' RAS Control Actions
'
Public Const RAS_ACTION_CONNECT = 1
Public Const RAS_ACTION_DISCONNECT = 2
Public Const RAS_ACTION_RESET = 3
'
' RAS Control States
'
Public Const RAS_UNUSED = -1
Public Const RAS_OPENPORT = 0
Public Const RAS_PORTOPENED = 1
Public Const RAS_CONNECTDEV = 2
Public Const RAS_DEVCONNECTED = 3
Public Const RAS_ALLDEVCONNECTED = 4
Public Const RAS_AUTHENTICATE = 5
Public Const RAS_AUTHENTICATED = 14
Public Const RAS_PREPCALLBACK = 15
Public Const RAS_MODEMRESET = 16
Public Const RAS_WAITFORCALL = 17
Public Const RAS_PROJECTED = 18
Public Const RAS_PAUSED = 4096
Public Const RAS_RETRYAUTH = 4097
Public Const RAS_CALLBACK = 4098
Public Const RAS_PASSEXPIRED = 4099
Public Const RAS_CONNECTED = 8192
Public Const RAS_DISCONNECTED = 8193

'
' RAS Control Error Codes
'
' These error codes are returned by the LastError property and
' passed as an argument to the LastError event. These are the
' same codes returned by the RAS library, with 25000 added to the
' base value
'
Public Const ERROR_INVALID_PORT_HANDLE = 25601
Public Const ERROR_PORT_ALREADY_OPEN = 25602
Public Const ERROR_BUFFER_TOO_SMALL = 25603
Public Const ERROR_WRONG_INFO_SPECIFIED = 25604
Public Const ERROR_CANNOT_SET_PORT_INFO = 25605
Public Const ERROR_PORT_NOT_CONNECTED = 25606
Public Const ERROR_EVENT_INVALID = 25607
Public Const ERROR_DEVICE_DOES_NOT_EXIST = 25608
Public Const ERROR_DEVICETYPE_DOES_NOT_EXIST = 25609
Public Const ERROR_INVALID_BUFFER = 25610
Public Const ERROR_ROUTE_NOT_AVAILABLE = 25611
Public Const ERROR_ROUTE_NOT_ALLOCATED = 25612
Public Const ERROR_INVALID_COMPRESSION_SPECIFIED = 25613
Public Const ERROR_OUT_OF_BUFFERS = 25614
Public Const ERROR_PORT_NOT_FOUND = 25615
Public Const ERROR_ASYNC_REQUEST_PENDING = 25616
Public Const ERROR_ALREADY_DISCONNECTING = 25617
Public Const ERROR_PORT_NOT_OPEN = 25618
Public Const ERROR_PORT_DISCONNECTED = 25619
Public Const ERROR_NO_ENDPOINTS = 25620
Public Const ERROR_CANNOT_OPEN_PHONEBOOK = 25621
Public Const ERROR_CANNOT_LOAD_PHONEBOOK = 25622
Public Const ERROR_CANNOT_FIND_PHONEBOOK_ENTRY = 25623
Public Const ERROR_CANNOT_WRITE_PHONEBOOK = 25624
Public Const ERROR_CORRUPT_PHONEBOOK = 25625
Public Const ERROR_CANNOT_LOAD_STRING = 25626
Public Const ERROR_KEY_NOT_FOUND = 25627
Public Const ERROR_DISCONNECTION = 25628
Public Const ERROR_REMOTE_DISCONNECTION = 25629
Public Const ERROR_HARDWARE_FAILURE = 25630
Public Const ERROR_USER_DISCONNECTION = 25631
Public Const ERROR_INVALID_SIZE = 25632
Public Const ERROR_PORT_NOT_AVAILABLE = 25633
Public Const ERROR_CANNOT_PROJECT_CLIENT = 25634
Public Const ERROR_UNKNOWN = 25635
Public Const ERROR_WRONG_DEVICE_ATTACHED = 25636
Public Const ERROR_BAD_STRING = 25637
Public Const ERROR_REQUEST_TIMEOUT = 25638
Public Const ERROR_CANNOT_GET_LANA = 25639
Public Const ERROR_NETBIOS_ERROR = 25640
Public Const ERROR_SERVER_OUT_OF_RESOURCES = 25641
Public Const ERROR_NAME_EXISTS_ON_NET = 25642
Public Const ERROR_SERVER_GENERAL_NET_FAILURE = 25643
Public Const ERROR_AUTH_INTERNAL = 25645
Public Const ERROR_RESTRICTED_LOGON_HOURS = 25646
Public Const ERROR_ACCT_DISABLED = 25647
Public Const ERROR_PASSWD_EXPIRED = 25648
Public Const ERROR_NO_DIALIN_PERMISSION = 25649
Public Const ERROR_SERVER_NOT_RESPONDING = 25650
Public Const ERROR_FROM_DEVICE = 25651
Public Const ERROR_UNRECOGNIZED_RESPONSE = 25652
Public Const ERROR_MACRO_NOT_FOUND = 25653
Public Const ERROR_MACRO_NOT_DEFINED = 25654
Public Const ERROR_MESSAGE_MACRO_NOT_FOUND = 25655
Public Const ERROR_DEFAULTOFF_MACRO_NOT_FOUND = 25656
Public Const ERROR_FILE_COULD_NOT_BE_OPENED = 25657
Public Const ERROR_DEVICENAME_TOO_LONG = 25658
Public Const ERROR_DEVICENAME_NOT_FOUND = 25659
Public Const ERROR_NO_RESPONSES = 25660
Public Const ERROR_NO_COMMAND_FOUND = 25661
Public Const ERROR_WRONG_KEY_SPECIFIED = 25662
Public Const ERROR_UNKNOWN_DEVICE_TYPE = 25663
Public Const ERROR_ALLOCATING_MEMORY = 25664
Public Const ERROR_PORT_NOT_CONFIGURED = 25665
Public Const ERROR_DEVICE_NOT_READY = 25666
Public Const ERROR_READING_INI_FILE = 25667
Public Const ERROR_NO_CONNECTION = 25668
Public Const ERROR_BAD_USAGE_IN_INI_FILE = 25669
Public Const ERROR_READING_SECTIONNAME = 25670
Public Const ERROR_READING_DEVICETYPE = 25671
Public Const ERROR_READING_DEVICENAME = 25672
Public Const ERROR_READING_USAGE = 25673
Public Const ERROR_READING_MAXCONNECTBPS = 25674
Public Const ERROR_READING_MAXCARRIERBPS = 25675
Public Const ERROR_LINE_BUSY = 25676
Public Const ERROR_VOICE_ANSWER = 25677
Public Const ERROR_NO_ANSWER = 25678
Public Const ERROR_NO_CARRIER = 25679
Public Const ERROR_NO_DIALTONE = 25680
Public Const ERROR_IN_COMMAND = 25681
Public Const ERROR_WRITING_SECTIONNAME = 25682
Public Const ERROR_WRITING_DEVICETYPE = 25683
Public Const ERROR_WRITING_DEVICENAME = 25684
Public Const ERROR_WRITING_MAXCONNECTBPS = 25685
Public Const ERROR_WRITING_MAXCARRIERBPS = 25686
Public Const ERROR_WRITING_USAGE = 25687
Public Const ERROR_WRITING_DEFAULTOFF = 25688
Public Const ERROR_READING_DEFAULTOFF = 25689
Public Const ERROR_EMPTY_INI_FILE = 25690
Public Const ERROR_AUTHENTICATION_FAILURE = 25691
Public Const ERROR_PORT_OR_DEVICE = 25692
Public Const ERROR_NOT_BINARY_MACRO = 25693
Public Const ERROR_DCB_NOT_FOUND = 25694
Public Const ERROR_STATE_MACHINES_NOT_STARTED = 25695
Public Const ERROR_STATE_MACHINES_ALREADY_STARTED = 25696
Public Const ERROR_PARTIAL_RESPONSE_LOOPING = 25697
Public Const ERROR_UNKNOWN_RESPONSE_KEY = 25698
Public Const ERROR_RECV_BUF_FULL = 25699
Public Const ERROR_CMD_TOO_LONG = 25700
Public Const ERROR_UNSUPPORTED_BPS = 25701
Public Const ERROR_UNEXPECTED_RESPONSE = 25702
Public Const ERROR_INTERACTIVE_MODE = 25703
Public Const ERROR_BAD_CALLBACK_NUMBER = 25704
Public Const ERROR_INVALID_AUTH_STATE = 25705
Public Const ERROR_WRITING_INITBPS = 25706
Public Const ERROR_INVALID_WIN_HANDLE = 25707
Public Const ERROR_NO_PASSWORD = 25708
Public Const ERROR_NO_USERNAME = 25709
Public Const ERROR_CANNOT_START_STATE_MACHINE = 25710
Public Const ERROR_GETTING_COMMSTATE = 25711
Public Const ERROR_SETTING_COMMSTATE = 25712
Public Const ERROR_COMM_FUNCTION = 25713
Public Const ERROR_CONFIGURATION_PROBLEM = 25714
Public Const ERROR_X25_DIAGNOSTIC = 25715
Public Const ERROR_TOO_MANY_LINE_ERRORS = 25716
Public Const ERROR_OVERRUN = 25717
Public Const ERROR_ACCT_EXPIRED = 25718
Public Const ERROR_CHANGING_PASSWORD = 25719
Public Const ERROR_NO_ACTIVE_ISDN_LINES = 25720
Public Const ERROR_NO_ISDN_CHANNELS_AVAILABLE = 25721

'
' Declarations for functions to encode and decode files, typically
' used as with attachments to mail messages or news articles
'
Declare Function DecodeFile Lib "UUCODE32.DLL" Alias "DecodeFileA" (ByVal InputFile As String, ByVal OutputFile As String) As Long
Declare Function EncodeFile Lib "UUCODE32.DLL" Alias "EncodeFileA" (ByVal InputFile As String, ByVal OutputFile As String) As Long
Declare Function DecodeBase64File Lib "UUCODE32.DLL" Alias "DecodeBase64FileA" (ByVal InputFile As String, ByVal OutputFile As String) As Long
Declare Function EncodeBase64File Lib "UUCODE32.DLL" Alias "EncodeBase64FileA" (ByVal InputFile As String, ByVal OutputFile As String) As Long
