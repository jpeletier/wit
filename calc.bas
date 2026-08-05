Attribute VB_Name = "Module1"
Option Explicit
Const CALC_MAX_TERMS = 20
Const CALC_MAX_RECURSION = 10


Function superCalc(st) As String
On Error GoTo sc_error
Dim cl As String
Dim calcError As Long

If InStr(1, st, "#") > 0 Then
  Dim md() As String
  md = Split(st, "#", 2)
  Dim n As Long
  Dim t As Long
  t = calc(md(0))
  If t > 20 Then t = 20
  cl = "["
  For n = 1 To t
    cl = cl & calc(md(1), , calcError)
    If n < t Then cl = cl & ", "
    If calcError <> 0 Then Exit For
  Next
  cl = cl & "]"
  
Else
  cl = calc(st, , calcError)
End If


sc_exit:
Select Case calcError

  Case 0
    superCalc = cl
  Case Else
    superCalc = ""

End Select



Exit Function

sc_error:
calcError = -1
Resume sc_exit



End Function



Private Function SChar(c As String) As Boolean

Select Case c
  Case ")", "(", " ", "'", ""
    SChar = True
  Case Else
    SChar = False
End Select

End Function

Public Function calc(ByVal st As String, Optional reset = True, Optional calcError As Long = 0) As Double

On Error GoTo calc_error

Static stack(CALC_MAX_TERMS) As String
Static flags(CALC_MAX_TERMS) As Integer
Static sp As Long
Static nestLevel As Long


If reset Then
    nestLevel = 1
    calcError = 0
    sp = 0
    st = Replace(st, ".", ",")
    st = Replace(st, "d", "q")
Else
    nestLevel = nestLevel + 1
End If

If nestLevel > CALC_MAX_RECURSION Then
  calcError = -2
  Exit Function
End If

Dim n As Long
Dim acc As Double

Dim a_trm As Long
Dim b_trm As Long
Dim parseError As Long


If IsNumeric(st) Then
  calc = st
Else

  a_trm = sp
  SplitTParenthesees st, "+", stack, flags, parseError, sp, "-"
  b_trm = sp - 1
  
  If parseError <> 0 Then
    calcError = parseError
    Exit Function
  End If
  
  If a_trm <> b_trm Then
    acc = 0
    For n = a_trm To b_trm
      If flags(n) = 1 Then
        acc = acc + calc(stack(n), False, calcError)
      Else
        acc = acc - calc(stack(n), False, calcError)
      End If
      If calcError <> 0 Then Exit Function
    Next
    sp = a_trm
    calc = acc
  Else
    sp = a_trm
    a_trm = sp
    SplitTParenthesees st, "*", stack, flags, parseError, sp, "/"
    b_trm = sp - 1
    
    If parseError <> 0 Then
      calcError = parseError
      Exit Function
    End If
    
    If a_trm <> b_trm Then
      acc = 1
      For n = a_trm To b_trm
        If flags(n) = 1 Then
          acc = acc * calc(stack(n), False, calcError)
        Else
          acc = acc / calc(stack(n), False, calcError)
        End If
        If calcError <> 0 Then Exit Function
      Next
      sp = a_trm
      calc = acc
    Else
      sp = a_trm
      a_trm = sp
      SplitTParenthesees st, "^", stack, flags, parseError, sp
      b_trm = sp - 1
      
      If parseError <> 0 Then
        calcError = parseError
        Exit Function
      End If
      
      If a_trm <> b_trm Then
        acc = calc(stack(a_trm), False) ^ calc(stack(a_trm + 1), False, calcError)
        For n = a_trm + 2 To b_trm
          acc = acc ^ calc(stack(n), False, calcError)
          If calcError <> 0 Then Exit Function
        Next
        sp = a_trm
        calc = acc
      Else
        sp = a_trm
        a_trm = sp
        SplitTParenthesees st, "q", stack, flags, parseError, sp
        b_trm = sp - 1
        
        If parseError <> 0 Then
          calcError = parseError
          Exit Function
        End If
        
        If a_trm <> b_trm Then
          acc = rollDice(calc(stack(a_trm), False), calc(stack(a_trm + 1), False, calcError), calcError)
          For n = a_trm + 2 To b_trm
            acc = rollDice(acc, calc(stack(n), False, calcError), calcError)
            If calcError <> 0 Then Exit Function
          Next
          sp = a_trm
          calc = acc
        Else
          calcError = -3
        End If
      End If
    End If
  End If
End If

calc_exit:
nestLevel = nestLevel - 1
Exit Function

calc_error:
calcError = -6
Resume calc_exit

End Function




Public Sub SplitTParenthesees(st As String, Sep As String, terms() As String, signs() As Integer, parseError As Long, sp As Long, Optional sep2 As String = "")

'Devuelve una colección de términos, teniendo en cuenta
'los paréntesis.

Dim col As New Collection

Dim p As Integer 'Contador de paréntesis
Dim q As Boolean 'indica si está dentro de '
Dim c As String * 1 'Caracter actual
Dim LastC As String * 1 'último caracter
Dim lsep As String * 1
Dim ln As Integer       'Longitud de st
Dim lsp As Integer      'Longitud de Sep
Dim lsp2 As Integer
Dim n As Integer        'Contador
Dim last As Integer     'Pos. del último operador
Dim ct As Long          'Término actual
Dim lt As Long          'Máximo subíndice de terms.

ln = Len(st)
lsp = Len(Sep)
lsp2 = Len(sep2)
lt = UBound(terms)
ct = 0
last = 1


'Set SplitTParenthesees = col
If ln = 0 Then parseError = -1: Exit Sub

signs(sp) = 1

If ln = 1 And st <> "(" And st <> ")" Then
  terms(sp) = st
  sp = sp + 1

  Exit Sub
End If


Dim nr As Boolean 'Almacena si hay paréntesis redundantes.

Do
  For n = 1 To ln
    c = Mid(st, n, 1)
    Select Case c
      Case "(": p = p + 1
      Case ")": p = p - 1
      Case "'": q = Not q
    End Select
    
    If p = 0 And n <> ln Then nr = True 'Detector de paréntesis redundantes "((X=5))"
    
    If p = 0 And Not q Then
      If (lsp = 1) Or SChar(LastC) And SChar(Mid(st, n + lsp, 1)) Then
        lsep = Mid(st, n, lsp)
        If (lsep = Sep) Or (lsep = sep2) Then
          terms(sp) = Trim(Mid(st, last, n - last))
          sp = sp + 1
          If sp > CALC_MAX_TERMS Then
              parseError = -2
              Exit Sub
          Else
            If c = sep2 Then signs(sp) = -1 Else signs(sp) = 1
          End If
          last = n + lsp
        End If
      End If
    End If
    
    LastC = c
  Next n

If Not nr Then
  'Paréntesis redundantes. Quitar.
  If ln < 2 Then parseError = True: Exit Sub
  st = Mid(st, 2, ln - 2)
  ln = ln - 2
End If

Loop Until nr

terms(sp) = Trim(Mid(st, last, n - last))

sp = sp + 1



parseError = p <> 0 Or q

End Sub

Public Function rollDice(times As Double, die As Double, Optional calcError As Long)

  If times > 100 Then
    calcError = -4
  Else
    Dim n As Long
    Dim sum As Long
    For n = 1 To times
      sum = sum + Int(Rnd * die) + 1
    Next
    rollDice = sum
  End If


End Function

