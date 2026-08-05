Attribute VB_Name = "Module1"
Option Explicit

Public Function mIRCFilterCodes(ByVal text As String, Optional ByVal bold As Boolean, Optional ByVal underline As Boolean, Optional ByVal colors As Boolean, Optional normal As Boolean) As String

If Not (bold Or underline Or normal Or colors) Then
  bold = True
  underline = True
  colors = True
  normal = True
End If


If bold Then
  text = Replace(text, "", "")
End If

If underline Then
  text = Replace(text, "", "")
End If

If normal Then
  text = Replace(text, "", "")
End If


If colors Then
  Dim n As Long
  Dim c As String
  Dim lenst As Long
  Dim comma As Boolean
  Dim endcode As Boolean
  Dim st As String
  Dim digs As Long
  
  lenst = Len(text)
  n = 1
  Do Until n > lenst
    c = Mid(text, n, 1)
    If c = "" Then
      comma = False
      n = n + 1
      
      endcode = False
      digs = 0
      Do Until endcode
        c = Mid(text, n, 1)
        Select Case c
          Case "0" To "9"
            If digs < 2 Then
              n = n + 1
              digs = digs + 1
            Else
              endcode = True
            End If
          Case ","
            If digs = 0 Then
              endcode = True
            Else
              If Not comma Then
                comma = True
                n = n + 1
                digs = 0
              Else
                endcode = True
              End If
            End If
          Case Else
            endcode = True
        End Select
      Loop
    Else
      st = st & c
      n = n + 1
    End If
  Loop
  text = st
End If
        
      

  

mIRCFilterCodes = text




End Function
