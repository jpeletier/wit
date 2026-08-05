VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CFairCollection"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Private CL As Collection

Public Event ItemRemoved(ByVal Key As String)
Public Event ItemAdded(ByVal Key As String, ByVal Value As Variant)
Public Event ItemUpdated(ByVal Key As String, ByVal Value As Variant)

Public Function Exists(Key As String) As Boolean
On Error GoTo eic_error

If CL(Key) Is Nothing Then:

Exists = True
eic_exit:
Exit Function

eic_error:
Exists = False
Resume eic_exit

End Function


Public Sub Add(Key As String, Value As Variant)
  If IsObject(Value) Then
    Set Item(Key) = Value
  Else
    Item(Key) = Value
  End If

End Sub

Public Property Let Item(Key As String, Value As Variant)
Dim Cp As CProperty
If Exists(Key) Then
  Set Cp = CL(Key)
  Cp.Value = Value
  RaiseEvent ItemUpdated(Key, Value)
Else
  Set Cp = New CProperty
  Cp.Key = Key
  CL.Add Cp, Key
  Cp.Value = Value
  RaiseEvent ItemAdded(Key, Value)
End If

End Property


Public Property Set Item(Key As String, Value As Variant)
Dim Cp As CProperty
If Exists(Key) Then
  Set Cp = CL(Key)
  Set Cp.Value = Value
  RaiseEvent ItemUpdated(Key, Value)
Else
  Set Cp = New CProperty
  Cp.Key = Key
  CL.Add Cp, Key
  Set Cp.Value = Value
  RaiseEvent ItemAdded(Key, Value)
End If

End Property


Public Property Get Item(Key As String) As Variant
Attribute Item.VB_UserMemId = 0
On Error GoTo pgca_err
Dim Cp As CProperty
Set Cp = CL(Key)

If IsObject(Cp.Value) Then
  Set Item = Cp.Value
Else
  Item = Cp.Value
End If

pgca_exit:
Exit Property
pgca_err:
Item = ""
Resume pgca_exit

End Property

Public Function Count() As Long
  Count = CL.Count
End Function

Public Sub Remove(Key As String)
If Exists(Key) Then
  CL.Remove Key
  RaiseEvent ItemRemoved(Key)
End If
End Sub

Private Sub Class_Initialize()
  Set CL = New Collection
End Sub
Public Property Get NewEnum() As IUnknown
    Set NewEnum = CL.[_NewEnum]
End Property

Public Function Col() As Collection
Set Col = CL
End Function


