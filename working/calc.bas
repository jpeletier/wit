Attribute VB_Name = "Module1"
Private CalcError As Integer


Function calc(st$)
On Error Resume Next

st$ = UCase$(st$)
'Calculates a string given to it.
Static calls As Integer
calls = calls + 1
If calls > 10 Or calls < 0 Then CalcError = -2
'Dividir en términos
If CalcError <> 0 Then
  calls = 0
  Exit Function
End If
ReDim Ter$(100)
ReDim sign(100)
ReDim Values(100)
ReDim clc(100)
ReDim pps(100)
ReDim pty$(100)
pa = 0
ls = Len(st$)
t = 1
For n = 1 To ls
np = False
c$ = Mid$(st$, n, 1)
If n = 1 And (c$ = "-") Then sign(1) = -1 Else sign(1) = 1
If c$ = ")" Then pa = pa - 1: np = (pa = 0)
If c$ = "(" Then pa = pa + 1: np = (pa = 1)
If pa = 0 Then
 Select Case c$
  Case "+": t = t + 1: sign(t) = 1: Ter$(t - 1) = cst$: cst$ = ""
  Case "-": t = t + 1: sign(t) = -1: Ter$(t - 1) = cst$: cst$ = ""
 End Select
End If
func = False ' InString(cst$, "SIN") Or InString(cst$, "COS") Or InString(cst$, "TAN")
If ((Not np) Or func) And ((pa > 0) Or (c$ <> "-") And (c$ <> "+")) Then
 cst$ = cst$ + c$
End If
Ter$(t) = cst$
Next
maxt = t


For t = 1 To maxt
'1.- Ver si sólo contiene números:
 lt = Len(Ter$(t))
 SoloNum = True
 For n = 1 To lt
 c$ = Mid$(Ter$(t), n, 1)
 SoloNum = SoloNum And (((c$ >= "0") And (c$ <= "9")) Or c$ = ".")
 Next
 If SoloNum Then
  Values(t) = sign(t) * Val(Ter$(t))
  clc(t) = True
 End If










If Not clc(t) Then
 'Dividir en tres factores
ReDim pps(100)
ReDim pty$(100)
csts$ = ""
prmax = 0
pa = 0
pr = 0
For n = 1 To lt
np = False
c$ = Mid$(Ter$(t), n, 1)
If c$ = ")" Then pa = pa - 1: np = (pa = 0)
If c$ = "(" Then pa = pa + 1: np = (pa = 1)
If pa = 0 Then
 Select Case c$
  Case "*", "/": pr = pr + 1: pps(pr) = n: pty$(pr) = c$
 End Select
End If
Next
prmax = pr
If prmax > 0 Then clc(t) = True
Select Case prmax
 Case 1
  f1$ = Left$(Ter$(t), pps(1) - 1)
  f2$ = Mid$(Ter$(t), pps(1) + 1, lt - pps(1))
  Select Case pty$(1)
   Case "*"
    Values(t) = sign(t) * calc(f1$) * calc(f2$)
   Case "/"
    divd = calc(f2$)
    If divd = 0 Then CalcError = -1: calls = 0: Exit Function
    Values(t) = sign(t) * calc(f1$) / divd
  End Select

 Case Is > 1
  f1$ = Left$(Ter$(t), pps(1) - 1)
  f2$ = Mid$(Ter$(t), pps(1) + 1, pps(2) - pps(1) - 1)
  f3$ = Mid$(Ter$(t), pps(2), lt - pps(2) + 1)
  Select Case pty$(1)
   Case "*"
    Values(t) = sign(t) * calc(f1$) * calc(f2$) * calc("1" + f3$)
   Case "/"
    Values(t) = sign(t) * calc(f1$) / calc(f2$) * calc("1" + f3$)
  End Select

End Select
End If


If Not clc(t) Then
prmax = 0
pa = 0
pr = 0
For n = 1 To lt
np = False
c$ = Mid$(Ter$(t), n, 1)
If c$ = ")" Then pa = pa - 1: np = (pa = 0)
If c$ = "(" Then pa = pa + 1: np = (pa = 1)
If pa = 0 And UCase$(c$) = "^" Then
  If n = 1 Then f1$ = "1" Else f1$ = Left$(Ter$(t), n - 1)
  f2$ = Mid$(Ter$(t), n + 1, lt - n)
  BaseP = calc(f1$)
  If times > 1000 Then CalcError = -3: Exit Function
  Values(t) = sign(t) * BaseP ^ calc(f2$)
  clc(t) = True

End If
If clc(t) Then Exit For
Next n

End If



If Not clc(t) Then
prmax = 0
pa = 0
pr = 0
For n = 1 To lt
np = False
c$ = Mid$(Ter$(t), n, 1)
If c$ = ")" Then pa = pa - 1: np = (pa = 0)
If c$ = "(" Then pa = pa + 1: np = (pa = 1)
If pa = 0 And UCase$(c$) = "D" Then
  If n = 1 Then f1$ = "1" Else f1$ = Left$(Ter$(t), n - 1)
  f2$ = Mid$(Ter$(t), n + 1, lt - n)
  times = calc(f1$)
  If times > 1000 Then CalcError = -3: Exit Function
  Values(t) = sign(t) * d(calc(f2$), times)
  clc(t) = True

End If
If clc(t) Then Exit For
Next n

End If

If Not clc(t) And 0 Then 'deshabilitado
prmax = 0
pa = 0
pr = 0
For n = 1 To lt
np = False
c$ = Mid$(Ter$(t), n, 1)
If c$ = ")" Then pa = pa - 1: np = (pa = 0)
If c$ = "(" Then pa = pa + 1: np = (pa = 1)
If pa = 0 Then
   
   f1$ = Mid$(Ter$(t), 5, Len(Ter$(t)) - 5)
   fval = calc(f1$)
   Select Case Left$(Ter$(t), 3)
    Case "SIN": Values(t) = sign(t) * Sin(fval * pi / 180): clc(t) = True
    Case "COS": Values(t) = sign(t) * Cos(fval * pi / 180): clc(t) = True
    Case "TAN"
      If fval = 90 Or fval = 270 Then
      CalcError = -4
      Exit Function
      Else
       Values(t) = sign(t) * Tan(fval * pi / 180)
       clc(t) = True
      End If
    End Select

End If
If clc(t) Then Exit For
Next n

End If






If Not clc(t) Then Values(t) = sign(t) * calc(Ter$(t))



Next t
cf = 0
For t = 1 To maxt
'Values(t) = Int(Values(t) * 10 ^ 8) * 10 ^ (-8)
cf = cf + Values(t)
Next
calc = cf

calls = calls - 1
End Function


Function InString(ca$, par$)
InString = False
lca = Len(ca$)
lpar = Len(par$)
For n = 1 To lca - lpar + 1
If Mid$(ca$, n, lpar) = par$ Then InString = True: Exit For
Next





End Function

Function inb(st$, sm$)
ln = Len(st$)
lm = Len(sm$)
inb = False
For n = 1 To ln - lm + 1
If Mid$(st$, n, lm) = sm$ Then inb = n: Exit Function
Next

End Function


Function SuperCalc$(ByVal st$)
If st$ = "" Then Exit Function

'Calculates any string given to it. It's the
'procedure you should use.
st$ = UCase$(st$)
sn = inb(st$, "SIN")
If sn > 0 Then
st$ = Left$(st$, sn - 1) + "&&&" + Right$(st$, Len(st$) - sn - 2)
End If
sn = inb(st$, "COS")
If sn > 0 Then
st$ = Left$(st$, sn - 1) + "$$$" + Right$(st$, Len(st$) - sn - 2)
End If
sn = inb(st$, "TAN")
If sn > 0 Then
st$ = Left$(st$, sn - 1) + "@@@" + Right$(st$, Len(st$) - sn - 2)
End If


CalcError = 0
If CalcError <> 0 Then GoTo clcerr
st$ = Replace(st$, " ", "")
st$ = Replace(st$, ",", ".")

al = False
St2$ = ""


For n = 1 To Len(st$)
c$ = Mid$(st$, n, 1)
If c$ = "#" Then al = True
If c$ <> " " Then St2$ = St2$ + c$
Next
If Not al Then clc$ = stR$(calc(St2$)) Else clc$ = mdice$(St2$)

SuperCalc$ = Trim$(clc$)
clcerr:
Select Case CalcError
Case -1: SuperCalc$ = "Je je, división por cero."
Case -2: SuperCalc$ = "" 'Stack overflow...
Case -3: SuperCalc$ = "<--- Paso de movidas."
Case -4: SuperCalc$ = "± Infinite."
Case -5: SuperCalc$ = "Error!: Circular reference to function."
End Select
End Function


Function mdice$(st$)
'Multiple dice system proc.
For n = 1 To Len(st$)
c$ = Mid$(st$, n, 1)
If c$ = "#" Then alpos = n: Exit For
Next

If alpos = 1 Then f1$ = "1" Else f1$ = Left$(st$, alpos - 1)
f2$ = Mid$(st$, alpos + 1, Len(st$) - alpos)
times = calc(f1$)
If times > 10 Then CalcError = -3: Exit Function
stf$ = "["
For n = 1 To times
stf$ = stf$ + stR$(calc(f2$))
If n < times Then stf$ = stf$ + ","
Next
stf$ = stf$ + "]"

mdice = stf$

End Function

Function d(die, times)
'If times > 100 Then Exit Function
ff = 0
For n = 1 To times
ff = ff + Int(Rnd * die) + 1
Next
d = ff
If die = 0 Then d = 0
End Function
