Attribute VB_Name = "CnstIRC"
Option Explicit

Public Const IRC_ERR_NOSUCHNICK = 401
'   "<nickname> :No such nick/channel"
'
' - Used to indicate the nickname parameter supplied to a
' command is currently unused.
'
Public Const IRC_ERR_NOSUCHSERVER = 402
' "<server name> :No such server"
'
' - Used to indicate the server name given currently
' doesn't exist.
'
Public Const IRC_ERR_NOSUCHCHANNEL = 403
' "<channel name> :No such channel"
'
' - Used to indicate the given channel name is invalid.
'
Public Const IRC_ERR_CANNOTSENDTOCHAN = 404
' "<channel name> :Cannot send to channel"
'
' - Sent to a user who is either (a) not on a channel
' which is mode +n or (b) not a chanop (or mode +v) on
' a channel which has mode +m set and is trying to send
' a PRIVMSG message to that channel.
'
Public Const IRC_ERR_TOOMANYCHANNELS = 405
' "<channel name> :You have joined too many \
' channels"
' - Sent to a user when they have joined the maximum
' number of allowed channels and they try to join
' another channel.
'
Public Const IRC_ERR_WASNOSUCHNICK = 406
' "<nickname> :There was no such nickname"
'
' - Returned by WHOWAS to indicate there is no history
' information for that nickname.
'
Public Const IRC_ERR_TOOMANYTARGETS = 407
' "<target> :Duplicate recipients. No message \
' delivered"
'
' - Returned to a client which is attempting to send a
' PRIVMSG/NOTICE using the user@host destination format
' and for a user@host which has several occurrences.
'
Public Const IRC_ERR_NOORIGIN = 409
' ":No origin specified"
'
' - PING or PONG message missing the originator parameter
' which is required since these commands must work
' without valid prefixes.
'
Public Const IRC_ERR_NORECIPIENT = 411
' ":No recipient given (<command>)"
Public Const IRC_ERR_NOTEXTTOSEND = 412
' ":No text to send"
Public Const IRC_ERR_NOTOPLEVEL = 413
' "<mask> :No toplevel domain specified"
Public Const IRC_ERR_WILDTOPLEVEL = 414
' "<mask> :Wildcard in toplevel domain"
'
' - 412 - 414 are returned by PRIVMSG to indicate that
' the message wasn't delivered for some reason.
' ERR_NOTOPLEVEL and ERR_WILDTOPLEVEL are errors that
' are returned when an invalid use of
' "PRIVMSG $<server>" or "PRIVMSG #<host>" is attempted.
'
Public Const IRC_ERR_UNKNOWNCOMMAND = 421
' "<command> :Unknown command"
'
' - Returned to a registered client to indicate that the
' command sent is unknown by the server.
'
Public Const IRC_ERR_NOMOTD = 422
' ":MOTD File is missing"
'
' - Server's MOTD file could not be opened by the server.
'
Public Const IRC_ERR_NOADMININFO = 423
' "<server> :No administrative info available"
'
' - Returned by a server in response to an ADMIN message
' when there is an error in finding the appropriate
' information.
'
Public Const IRC_ERR_FILEERROR = 424
' ":File error doing <file op> on <file>"
'
'
'
'
'
'
'
'
'
' - Generic error message used to report a failed file
' operation during the processing of a message.
'
Public Const IRC_ERR_NONICKNAMEGIVEN = 431
' ":No nickname given"
'
' - Returned when a nickname parameter expected for a
' command and isn't found.
'
Public Const IRC_ERR_ERRONEUSNICKNAME = 432
' "<nick> :Erroneus nickname"
'
' - Returned after receiving a NICK message which contains
' characters which do not fall in the defined set.  See
' section x.x.x for details on valid nicknames.
'
Public Const IRC_ERR_NICKNAMEINUSE = 433
' "<nick> :Nickname is already in use"
'
' - Returned when a NICK message is processed that results
' in an attempt to change to a currently existing
' nickname.
'
Public Const IRC_ERR_NICKCOLLISION = 436
' "<nick> :Nickname collision KILL"
'
' - Returned by a server to a client when it detects a
' nickname collision (registered of a NICK that
' already exists by another server).
'
Public Const IRC_ERR_USERNOTINCHANNEL = 441
' "<nick> <channel> :They aren't on that channel"
'
' - Returned by the server to indicate that the target
' user of the command is not on the given channel.
'
Public Const IRC_ERR_NOTONCHANNEL = 442
' "<channel> :You're not on that channel"
'
' - Returned by the server whenever a client tries to
' perform a channel effecting command for which the
' client isn't a member.
'
Public Const IRC_ERR_USERONCHANNEL = 443
' "<user> <channel> :is already on channel"
'
' - Returned when a client tries to invite a user to a
' channel they are already on.
'
'
'
'
'
'
'
'
'
Public Const IRC_ERR_NOLOGIN = 444
' "<user> :User not logged in"
'
' - Returned by the summon after a SUMMON command for a
' user was unable to be performed since they were not
' logged in.
'
Public Const IRC_ERR_SUMMONDISABLED = 445
' ":SUMMON has been disabled"
'
' - Returned as a response to the SUMMON command.  Must be
' returned by any server which does not implement it.
'
Public Const IRC_ERR_USERSDISABLED = 446
' ":USERS has been disabled"
'
' - Returned as a response to the USERS command.  Must be
' returned by any server which does not implement it.
'
Public Const IRC_ERR_NOTREGISTERED = 451
' ":You have not registered"
'
' - Returned by the server to indicate that the client
' must be registered before the server will allow it
' to be parsed in detail.
'
Public Const IRC_ERR_NEEDMOREPARAMS = 461
' "<command> :Not enough parameters"
'
' - Returned by the server by numerous commands to
' indicate to the client that it didn't supply enough
' parameters.
'
Public Const IRC_ERR_ALREADYREGISTRED = 462
' ":You may not reregister"
'
' - Returned by the server to any link which tries to
' change part of the registered details (such as
' password or user details from second USER message).
'
'
Public Const IRC_ERR_NOPERMFORHOST = 463
' ":Your host isn't among the privileged"
'
' - Returned to a client which attempts to register with
' a server which does not been setup to allow
' connections from the host the attempted connection
' is tried.
'
'
'
'
'
'
'
'
'
Public Const IRC_ERR_PASSWDMISMATCH = 464
' ":Password incorrect"
'
' - Returned to indicate a failed attempt at registering
' a connection for which a password was required and
' was either not given or incorrect.
'
Public Const IRC_ERR_YOUREBANNEDCREEP = 465
' ":You are banned from this server"
'
' - Returned after an attempt to connect and register
' yourself with a server which has been setup to
' explicitly deny connections to you.
'
Public Const IRC_ERR_KEYSET = 467
' "<channel> :Channel key already set"
Public Const IRC_ERR_CHANNELISFULL = 471
' "<channel> :Cannot join channel (+l)"
Public Const IRC_ERR_UNKNOWNMODE = 472
' "<char> :is unknown mode char to me"
Public Const IRC_ERR_INVITEONLYCHAN = 473
' "<channel> :Cannot join channel (+i)"
Public Const IRC_ERR_BANNEDFROMCHAN = 474
' "<channel> :Cannot join channel (+b)"
Public Const IRC_ERR_BADCHANNELKEY = 475
' "<channel> :Cannot join channel (+k)"
Public Const IRC_ERR_NOPRIVILEGES = 481
' ":Permission Denied- You're not an IRC operator"
'
' - Any command requiring operator privileges to operate
' must return this error to indicate the attempt was
' unsuccessful.
'
Public Const IRC_ERR_CHANOPRIVSNEEDED = 482
' "<channel> :You're not channel operator"
'
' - Any command requiring 'chanop' privileges (such as
' MODE messages) must return this error if the client
' making the attempt is not a chanop on the specified
' channel.
'
Public Const IRC_ERR_CANTKILLSERVER = 483
' ":You cant kill a server!"
'
' - Any attempts to use the KILL command on a server
' are to be refused and this error returned directly
' to the client.
'
'
'
'
'
'
'
'
'
'
Public Const IRC_ERR_NOOPERHOST = 491
' ":No O-lines for your host"
'
' - If a client sends an OPER message and the server has
' not been configured to allow connections from the
' client's host as an operator, this error must be
' returned.
'
Public Const IRC_ERR_UMODEUNKNOWNFLAG = 501
' ":Unknown MODE flag"
'
' - Returned by the server to indicate that a MODE
' message was sent with a nickname parameter and that
' the a mode flag sent was not recognized.
'
Public Const IRC_ERR_USERSDONTMATCH = 502
' ":Cant change mode for other users"
'
' - Error sent to any user trying to view or change the
' user mode for a user other than themselves.
'
'
Public Const IRC_RPL_NONE = 300
' Dummy reply number. Not used.
'
Public Const IRC_RPL_USERHOST = 302
' ":[<reply>{<space><reply>}]"
'
' - Reply format used by USERHOST to list replies to
' the query list.  The reply string is composed as
' follows:
'
' <reply> ::= <nick>['*'] '=' <'+'|'-'><hostname>
'
' The '*' indicates whether the client has registered
' as an Operator.  The '-' or '+' characters represent
' whether the client has set an AWAY message or not
' respectively.
'
Public Const IRC_RPL_ISON = 303
' ":[<nick> {<space><nick>}]"
'
' - Reply format used by ISON to list replies to the
' query list.
'
Public Const IRC_RPL_AWAY = 301
' "<nick> :<away message>"
'
'
'
'
'
'
'
'
'
Public Const IRC_RPL_UNAWAY = 305
' ":You are no longer marked as being away"
Public Const IRC_RPL_NOWAWAY = 306
' ":You have been marked as being away"
'
' - These replies are used with the AWAY command (if
' allowed).  RPL_AWAY is sent to any client sending a
' PRIVMSG to a client which is away.  RPL_AWAY is only
' sent by the server to which the client is connected.
' Replies RPL_UNAWAY and RPL_NOWAWAY are sent when the
' client removes and sets an AWAY message.
'
Public Const IRC_RPL_WHOISUSER = 311
' "<nick> <user> <host> * :<real name>"
Public Const IRC_RPL_WHOISSERVER = 312
' "<nick> <server> :<server info>"
Public Const IRC_RPL_WHOISOPERATOR = 313
' "<nick> :is an IRC operator"
Public Const IRC_RPL_WHOISIDLE = 317
' "<nick> <integer> :seconds idle"
Public Const IRC_RPL_ENDOFWHOIS = 318
' "<nick> :End of /WHOIS list"
Public Const IRC_RPL_WHOISCHANNELS = 319
' "<nick> :{[@|+]<channel><space>}"
'
' - Replies 311 - 313, 317 - 319 are all replies
' generated in response to a WHOIS message.  Given that
' there are enough parameters present, the answering
' server must either formulate a reply out of the above
' numerics (if the query nick is found) or return an
' error reply.  The '*' in RPL_WHOISUSER is there as
' the literal character and not as a wild card.  For
' each reply set, only RPL_WHOISCHANNELS may appear
' more than once (for long lists of channel names).
' The '@' and '+' characters next to the channel name
' indicate whether a client is a channel operator or
' has been granted permission to speak on a moderated
' channel.  The RPL_ENDOFWHOIS reply is used to mark
' the end of processing a WHOIS message.
'
Public Const IRC_RPL_WHOWASUSER = 314
' "<nick> <user> <host> * :<real name>"
Public Const IRC_RPL_ENDOFWHOWAS = 369
' "<nick> :End of WHOWAS"
'
' - When replying to a WHOWAS message, a server must use
' the replies RPL_WHOWASUSER, RPL_WHOISSERVER or
' ERR_WASNOSUCHNICK for each nickname in the presented
'
'
'
'
'
'
'
'
'
' list.  At the end of all reply batches, there must
' be RPL_ENDOFWHOWAS (even if there was only one reply
' and it was an error).
'
Public Const IRC_RPL_LISTSTART = 321
' "Channel :Users  Name"
Public Const IRC_RPL_LIST = 322
' "<channel> <# visible> :<topic>"
Public Const IRC_RPL_LISTEND = 323
' ":End of /LIST"
'
' - Replies RPL_LISTSTART, RPL_LIST, RPL_LISTEND mark
' the start, actual replies with data and end of the
' server's response to a LIST command.  If there are
' no channels available to return, only the start
' and end reply must be sent.
'
Public Const IRC_RPL_CHANNELMODEIS = 324
' "<channel> <mode> <mode params>"
'
Public Const IRC_RPL_CHANNELDATECREATED = 329
' "<channel> <timestamp gmt>"


Public Const IRC_RPL_NOTOPIC = 331
' "<channel> :No topic is set"
Public Const IRC_RPL_TOPIC = 332
' "<channel> :<topic>"
'
' - When sending a TOPIC message to determine the
' channel topic, one of two replies is sent.  If
' the topic is set, RPL_TOPIC is sent back else
' RPL_NOTOPIC.
'
Public Const IRC_RPL_INVITING = 341
' "<channel> <nick>"
'
' - Returned by the server to indicate that the
' attempted INVITE message was successful and is
' being passed onto the end client.
'
Public Const IRC_RPL_SUMMONING = 342
' "<user> :Summoning user to IRC"
'
' - Returned by a server answering a SUMMON message to
' indicate that it is summoning that user.
'
Public Const IRC_RPL_VERSION = 351
' "<version>.<debuglevel> <server> :<comments>"
'
' - Reply by the server showing its version details.
' The <version> is the version of the software being
'
'
'
'
'
'
'
'
'
' used (including any patchlevel revisions) and the
' <debuglevel> is used to indicate if the server is
' running in "debug mode".
'
' The "comments" field may contain any comments about
' the version or further version details.
'
Public Const IRC_RPL_WHOREPLY = 352
' "<channel> <user> <host> <server> <nick> \
' <H|G>[*][@|+] :<hopcount> <real name>"
Public Const IRC_RPL_ENDOFWHO = 315
' "<name> :End of /WHO list"
'
' - The RPL_WHOREPLY and RPL_ENDOFWHO pair are used
' to answer a WHO message.  The RPL_WHOREPLY is only
' sent if there is an appropriate match to the WHO
' query.  If there is a list of parameters supplied
' with a WHO message, a RPL_ENDOFWHO must be sent
' after processing each list item with <name> being
' the item.
'
Public Const IRC_RPL_NAMREPLY = 353
' "<channel> :[[@|+]<nick> [[@|+]<nick> [...]]]"
Public Const IRC_RPL_ENDOFNAMES = 366
' "<channel> :End of /NAMES list"
'
' - To reply to a NAMES message, a reply pair consisting
' of RPL_NAMREPLY and RPL_ENDOFNAMES is sent by the
' server back to the client.  If there is no channel
' found as in the query, then only RPL_ENDOFNAMES is
' returned.  The exception to this is when a NAMES
' message is sent with no parameters and all visible
' channels and contents are sent back in a series of
' RPL_NAMEREPLY messages with a RPL_ENDOFNAMES to mark
' the end.
'
Public Const IRC_RPL_LINKS = 364
' "<mask> <server> :<hopcount> <server info>"
Public Const IRC_RPL_ENDOFLINKS = 365
' "<mask> :End of /LINKS list"
'
' - In replying to the LINKS message, a server must send
' replies back using the RPL_LINKS numeric and mark the
' end of the list using an RPL_ENDOFLINKS reply.
'
Public Const IRC_RPL_BANLIST = 367
' "<channel> <banid>"
Public Const IRC_RPL_ENDOFBANLIST = 368
'
'
'
'
'
'
'
'
'
' "<channel> :End of channel ban list"
'
' - When listing the active 'bans' for a given channel,
' a server is required to send the list back using the
' RPL_BANLIST and RPL_ENDOFBANLIST messages.  A separate
' RPL_BANLIST is sent for each active banid.  After the
' banids have been listed (or if none present) a
' RPL_ENDOFBANLIST must be sent.
'
Public Const IRC_RPL_INFO = 371
' ":<string>"
Public Const IRC_RPL_ENDOFINFO = 374
' ":End of /INFO list"
'
' - A server responding to an INFO message is required to
' send all its 'info' in a series of RPL_INFO messages
' with a RPL_ENDOFINFO reply to indicate the end of the
' replies.
'
Public Const IRC_RPL_MOTDSTART = 375
' ":- <server> Message of the day - "
Public Const IRC_RPL_MOTD = 372
' ":- <text>"
Public Const IRC_RPL_ENDOFMOTD = 376
' ":End of /MOTD command"
'
' - When responding to the MOTD message and the MOTD file
' is found, the file is displayed line by line, with
' each line no longer than 80 characters, using
' RPL_MOTD format replies.  These should be surrounded
' by a RPL_MOTDSTART (before the RPL_MOTDs) and an
' RPL_ENDOFMOTD (after).
'
Public Const IRC_RPL_YOUREOPER = 381
' ":You are now an IRC operator"
'
' - RPL_YOUREOPER is sent back to a client which has
' just successfully issued an OPER message and gained
' operator status.
'
Public Const IRC_RPL_REHASHING = 382
' "<config file> :Rehashing"
'
' - If the REHASH option is used and an operator sends
' a REHASH message, an RPL_REHASHING is sent back to
' the operator.
'
Public Const IRC_RPL_TIME = 391
'
'
'
'
'
'
'
'
'
' "<server> :<string showing server's local time>"
'
' - When replying to the TIME message, a server must send
' the reply using the RPL_TIME format above.  The string
' showing the time need only contain the correct day and
' time there.  There is no further requirement for the
' time string.
'
Public Const IRC_RPL_USERSSTART = 392
' ":UserID   Terminal  Host"
Public Const IRC_RPL_USERS = 393
' ":%-8s %-9s %-8s"
Public Const IRC_RPL_ENDOFUSERS = 394
' ":End of users"
Public Const IRC_RPL_NOUSERS = 395
' ":Nobody logged in"
'
' - If the USERS message is handled by a server, the
' replies RPL_USERSTART, RPL_USERS, RPL_ENDOFUSERS and
' RPL_NOUSERS are used.  RPL_USERSSTART must be sent
' first, following by either a sequence of RPL_USERS
' or a single RPL_NOUSER.  Following this is
' RPL_ENDOFUSERS.
'
Public Const IRC_RPL_TRACELINK = 200
' "Link <version & debug level> <destination> \
' <next server>"
Public Const IRC_RPL_TRACECONNECTING = 201
' "Try. <class> <server>"
Public Const IRC_RPL_TRACEHANDSHAKE = 202
' "H.S. <class> <server>"
Public Const IRC_RPL_TRACEUNKNOWN = 203
' "???? <class> [<client IP address in dot form>]"
Public Const IRC_RPL_TRACEOPERATOR = 204
' "Oper <class> <nick>"
Public Const IRC_RPL_TRACEUSER = 205
' "User <class> <nick>"
Public Const IRC_RPL_TRACESERVER = 206
' "Serv <class> <int>S <int>C <server> \
' <nick!user|*!*>@<host|server>"
Public Const IRC_RPL_TRACENEWTYPE = 208
' "<newtype> 0 <client name>"
Public Const IRC_RPL_TRACELOG = 261
' "File <logfile> <debug level>"
'
' - The RPL_TRACE* are all returned by the server in
' response to the TRACE message.  How many are
' returned is dependent on the the TRACE message and
'
'
'
'
'
'
'
'
'
' whether it was sent by an operator or not.  There
' is no predefined order for which occurs first.
' Replies RPL_TRACEUNKNOWN, RPL_TRACECONNECTING and
' RPL_TRACEHANDSHAKE are all used for connections
' which have not been fully established and are either
' unknown, still attempting to connect or in the
' process of completing the 'server handshake'.
' RPL_TRACELINK is sent by any server which handles
' a TRACE message and has to pass it on to another
' server.  The list of RPL_TRACELINKs sent in
' response to a TRACE command traversing the IRC
' network should reflect the actual connectivity of
' the servers themselves along that path.
' RPL_TRACENEWTYPE is to be used for any connection
' which does not fit in the other categories but is
' being displayed anyway.
'
Public Const IRC_RPL_STATSLINKINFO = 211
' "<linkname> <sendq> <sent messages> \
' <sent bytes> <received messages> \
' <received bytes> <time open>"
Public Const IRC_RPL_STATSCOMMANDS = 212
' "<command> <count>"
Public Const IRC_RPL_STATSCLINE = 213
' "C <host> * <name> <port> <class>"
Public Const IRC_RPL_STATSNLINE = 214
' "N <host> * <name> <port> <class>"
Public Const IRC_RPL_STATSILINE = 215
' "I <host> * <host> <port> <class>"
Public Const IRC_RPL_STATSKLINE = 216
' "K <host> * <username> <port> <class>"
Public Const IRC_RPL_STATSYLINE = 218
' "Y <class> <ping frequency> <connect \
' frequency> <max sendq>"
Public Const IRC_RPL_ENDOFSTATS = 219
' "<stats letter> :End of /STATS report"
Public Const IRC_RPL_STATSLLINE = 241
' "L <hostmask> * <servername> <maxdepth>"
Public Const IRC_RPL_STATSUPTIME = 242
' ":Server Up %d days %d:%02d:%02d"
Public Const IRC_RPL_STATSOLINE = 243
' "O <hostmask> * <name>"
Public Const IRC_RPL_STATSHLINE = 244
' "H <hostmask> * <servername>"
'
Public Const IRC_RPL_UMODEIS = 221
' "<user mode string>"
'
'
'
'
'
'
'
'
'
'
' - To answer a query about a client's own mode,
' RPL_UMODEIS is sent back.
'
Public Const IRC_RPL_LUSERCLIENT = 251
' ":There are <integer> users and <integer> \
' invisible on <integer> servers"
Public Const IRC_RPL_LUSEROP = 252
' "<integer> :operator(s) online"
Public Const IRC_RPL_LUSERUNKNOWN = 253
' "<integer> :unknown connection(s)"
Public Const IRC_RPL_LUSERCHANNELS = 254
' "<integer> :channels formed"
Public Const IRC_RPL_LUSERME = 255
' ":I have <integer> clients and <integer> \
' servers"
'
' - In processing an LUSERS message, the server
' sends a set of replies from RPL_LUSERCLIENT,
' RPL_LUSEROP, RPL_USERUNKNOWN,
' RPL_LUSERCHANNELS and RPL_LUSERME.  When
' replying, a server must send back
' RPL_LUSERCLIENT and RPL_LUSERME.  The other
' replies are only sent back if a non-zero count
' is found for them.
'
Public Const IRC_RPL_ADMINME = 256
' "<server> :Administrative info"
Public Const IRC_RPL_ADMINLOC1 = 257
' ":<admin info>"
Public Const IRC_RPL_ADMINLOC2 = 258
' ":<admin info>"
Public Const IRC_RPL_ADMINEMAIL = 259
' ":<admin info>"
'
' - When replying to an ADMIN message, a server
' is expected to use replies RLP_ADMINME
' through to RPL_ADMINEMAIL and provide a text
' message with each.  For RPL_ADMINLOC1 a
' description of what city, state and country
' the server is in is expected, followed by
' details of the university and department
' (RPL_ADMINLOC2) and finally the administrative
' contact for the server (an email address here
' is required) in RPL_ADMINEMAIL.
'
'
'
'
'
'
'
'
'
'
'
'
'
'
' rics are not described above since they fall into one of  These nume
' ing categories: the follow
'
'
Public Const IRC_RPL_TRACECLASS = 217
Public Const IRC_RPL_STATSQLINE = 209
Public Const IRC_RPL_SERVICEINFO = 232
Public Const IRC_RPL_ENDOFSERVICES = 231
Public Const IRC_RPL_SERVICE = 234
Public Const IRC_RPL_SERVLIST = 233
Public Const IRC_RPL_SERVLISTEND = 235
Public Const IRC_RPL_WHOISCHANOP = 361
Public Const IRC_RPL_KILLDONE = 316
Public Const IRC_RPL_CLOSING = 363
Public Const IRC_RPL_CLOSEEND = 362
Public Const IRC_RPL_INFOSTART = 384
Public Const IRC_RPL_MYPORTIS = 373
Public Const IRC_ERR_YOUWILLBEBANNED = 476
Public Const IRC_ERR_BADCHANMASK = 466
Public Const IRC_ERR_NOSERVICEHOST = 492
Public Sub splitUserLabel(label As String, nickName As String, userName As String, hostName As String)
On Error Resume Next
Dim sts() As String
Dim hn() As String
nickName = "*"
hostName = "*"
userName = "*"
sts = Split(label, "!")
nickName = sts(0)
hn = Split(sts(1), "@")
userName = hn(0)
hostName = hn(1)

End Sub

Public Function joinUserLabel(nickName As String, userName As String, hostName As String) As String
  joinUserLabel = nickName & "!" & userName & "@" & hostName
End Function
