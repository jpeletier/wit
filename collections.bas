Attribute VB_Name = "collectionsmod"
Option Explicit

Public Function ExistsInCollection(cl As Collection, element As String) As Object

On Error GoTo eic_err


Set ExistsInCollection = cl(element)

eic_exit:
Exit Function


eic_err:
Set ExistsInCollection = Nothing
Resume eic_exit






End Function
