VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "AccessNode"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Member0" ,"AccessList"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

'local variable(s) to hold property value(s)
Private mvargUsr As GlobalUser 'local copy
Private mvarlevel As Integer 'local copy


Public Property Let level(ByVal vData As Integer)
    mvarlevel = vData
End Property


Public Property Get level() As Integer
    level = mvarlevel
End Property


Friend Property Set gUsr(x As GlobalUser)
  Set mvargUsr = x
End Property


Public Property Get gUsr() As GlobalUser
    Set gUsr = mvargUsr
End Property



