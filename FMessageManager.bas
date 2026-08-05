Attribute VB_Name = "FMessageManager"
Option Explicit

Public Const MESSAGE_REFRESH_PERIOD = 30 * 60
Public Const MESSAGE_FOLDER = "\messages"

Private FMessageGroups As Collection
Private LastRefresh As Date


Public Function getMessages() As String()

Dim mg As FMessageGroup

If FMessageGroups Is Nothing Or DateDiff("s", LastRefresh, Now) > MESSAGE_REFRESH_PERIOD Then

    Set FMessageGroups = New Collection
    LastRefresh = Now
    
    Dim fso As New FileSystemObject
    Dim mf As Folder
    Set mf = fso.GetFolder(App.Path & MESSAGE_FOLDER)
    Dim f As File
    Dim fpart() As String

    Dim m As FMessage
    
    For Each f In mf.Files
        '00_name_34_whatever.txt
        fpart = Split(f.Name, "_")
        If UBound(fpart) >= 2 Then
            Set mg = ObjectExistsInCollection(FMessageGroups, LCase(fpart(1)))
            If mg Is Nothing Then
                Set mg = New FMessageGroup
                FMessageGroups.Add mg, LCase(fpart(1))
            End If
            
            Set m = New FMessage
            
            m.probability = Val(fpart(2))
            m.message = f.OpenAsTextStream(ForReading).ReadAll()
            
            mg.addMessage m
        
    
        End If
    Next
End If

Dim msg() As String

ReDim msg(0 To FMessageGroups.Count - 1)

Dim i As Integer

For Each mg In FMessageGroups
    msg(i) = mg.getMessage()
    i = i + 1
Next

getMessages = msg

End Function



Public Sub test()

Dim msg() As String


msg = getMessages()

Dim st As Variant

For Each st In msg

Debug.Print st


Next

End Sub

