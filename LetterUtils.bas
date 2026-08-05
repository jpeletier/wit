Attribute VB_Name = "LetterUtils"
Option Explicit


'Const CYL_LETTERS = "AAAAAAAAAAAABBCCCCCDDDDDEEEEEEEEEEEEFGGHHHIIIIIIJLLLLLLMMNNNNNÑOOOOOOOOOPPQRRRRRRRSSSSSSTTTTUUUUUVXYZ"
Const CYL_LETTERS = "AAABBCCCCCDDDDDEEEEFGGHHHIIJLLLLLLMMNNNNNÑOOOPPQRRRRRRRSSSSSSTTTTUUVXYZ"
Const CYL_VOCALS = "AAAAAAAAAAAAEEEEEEEEEEEEIIIIIIOOOOOOOOOUUUUU"
Const CYL_CONSONANTS = "BBCCCCCDDDDDFGGHHHJLLLLLLMMNNNNNÑPPQRRRRRRRSSSSSSTTTTVXYZ"
Const CYL_CONSONANTS2 = "RNCLTSDMPBGHFVZJÑQYXKW"

Public LetterValues(0 To 26) As Long
Private LetterFrec(21) As Long

Public Function generateRandomLetter() As String
  generateRandomLetter = Mid(CYL_LETTERS, Int(Rnd * 71) + 1, 1)
End Function

Public Function generateRandomVocal() As String
  generateRandomVocal = Mid(CYL_VOCALS, Int(Rnd * 44) + 1, 1)
End Function

Public Function generateRandomConsonant() As String
  generateRandomConsonant = Mid(CYL_CONSONANTS, Int(Rnd * 57) + 1, 1)
End Function

Public Function generateRandomLetter2() As String
  
  Dim n As Long
  n = Int(Rnd * 71) + 1
  
  If n < 15 Then
    generateRandomLetter2 = Mid("AAAEEEEIIOOOUU", n, 1)
  Else
    generateRandomLetter2 = generateRandomConsonant2
  End If
  
End Function

Function generateRandomConsonant2() As String


Dim azar As Long, f As Integer

azar = Int(Rnd * 221110) + 20001
f = -1
Do
f = f + 1
Loop While azar > LetterFrec(f)

generateRandomConsonant2 = Mid$(CYL_CONSONANTS2, f + 1, 1)
End Function


Public Function Letter2Index(letter As String) As Integer


Dim c As String
c = UCase(letter)
Select Case c
  Case "A" To "Z"
    Letter2Index = Asc(c) - 65
  Case "Ñ"
    Letter2Index = 26
    
  Case "Á"
    Letter2Index = Letter2Index("A")
  Case "É"
    Letter2Index = Letter2Index("E")
  Case "Í"
    Letter2Index = Letter2Index("I")
  Case "Ó"
    Letter2Index = Letter2Index("O")
  Case "Ú"
    Letter2Index = Letter2Index("U")
  Case "Ü"
    Letter2Index = Letter2Index("U")
    

End Select
  
  
  
End Function

Public Function calcWordValue(word As String) As Long

Dim n As Long
Dim ln As Long
Dim sum As Long
ln = Len(word)
For n = 1 To ln
  sum = sum + LetterValues(Letter2Index(Mid(word, n, 1)))
Next

If ln >= 9 Then
  sum = sum * 2
End If

calcWordValue = sum * 10
End Function

Public Sub initLetterValues()

  If LetterValues(0) <> 0 Then Exit Sub
  
  LetterValues(Letter2Index("A")) = 1
  LetterValues(Letter2Index("B")) = 3
  LetterValues(Letter2Index("C")) = 3
  LetterValues(Letter2Index("D")) = 2
  LetterValues(Letter2Index("E")) = 1
  LetterValues(Letter2Index("F")) = 4
  LetterValues(Letter2Index("G")) = 2
  LetterValues(Letter2Index("H")) = 4
  LetterValues(Letter2Index("I")) = 1
  LetterValues(Letter2Index("J")) = 8
  LetterValues(Letter2Index("L")) = 1
  LetterValues(Letter2Index("M")) = 3
  LetterValues(Letter2Index("N")) = 1
  LetterValues(Letter2Index("O")) = 1
  LetterValues(Letter2Index("P")) = 3
  LetterValues(Letter2Index("Q")) = 5
  LetterValues(Letter2Index("R")) = 1
  LetterValues(Letter2Index("S")) = 1
  LetterValues(Letter2Index("T")) = 1
  LetterValues(Letter2Index("U")) = 1
  LetterValues(Letter2Index("V")) = 4
  LetterValues(Letter2Index("X")) = 8
  LetterValues(Letter2Index("Z")) = 10
  
  LetterValues(Letter2Index("Y")) = 10
  LetterValues(Letter2Index("W")) = 18
  
  LetterValues(Letter2Index("Ñ")) = 8
  
  
  
'Consonant frequency chart

  LetterFrec(0) = 43437
  LetterFrec(1) = 67852
  LetterFrec(2) = 91954
  LetterFrec(3) = 114851
  LetterFrec(4) = 135974
  LetterFrec(5) = 153959
  LetterFrec(6) = 171451
  LetterFrec(7) = 183862
  LetterFrec(8) = 194558
  LetterFrec(9) = 203833
  LetterFrec(10) = 212505
  LetterFrec(11) = 217725
  LetterFrec(12) = 222918
  LetterFrec(13) = 227602
  LetterFrec(14) = 231801
  LetterFrec(15) = 235788
  LetterFrec(16) = 237499
  LetterFrec(17) = 239195
  LetterFrec(18) = 240273
  LetterFrec(19) = 241027
  LetterFrec(20) = 241093
  LetterFrec(21) = 241110


End Sub

Public Function alterText(st As String)

Dim ln As Long
Dim i As Long
Dim c As String * 1

ln = Len(st)

If ln > 2 Then

  i = Int(Rnd * ln) + 1
  
  
  If (Int(Rnd * 20)) = 4 Then
    c = "æ"
  Else
    c = Chr(Int(Rnd * 25) + 97)
  End If
  
  st = Left(st, i) & c & Mid(st, i + 1)
End If

alterText = st
End Function


