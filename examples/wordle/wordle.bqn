#!/usr/bin/env bqn

n ← 5
tries ← 1+n

cand ← (n=≠¨)⊸/ •FLines "words.txt"

rng ← •rand

word ← cand ⊑˜ rng.Range ≠cand

l1 ← "qwertyuiop"
l2 ← "asdfghjkl"
l3 ← "zxcvbnm"
letters ← 26⥊0

nl‿cr ← @+10‿13
Out ← •Out

e ← @+27
Begin ← { 𝕊: •term.OutRaw e∾"[?1049h" }
End   ← { 𝕊: •term.OutRaw e∾"[?1049l" }
ClearScreen ← { 𝕊: •term.OutRaw e∾"[2J"∾e∾"[H" }
HideCursor ← { 𝕊: •term.OutRaw e∾"[?25l" }
ShowCursor ← { 𝕊: •term.OutRaw e∾"[?25h" }

reset ← e∾"[0m"
Green  ← { e∾"[97m"∾e∾"[42m"∾𝕩∾reset }
Yellow ← { e∾"[97m"∾e∾"[43m"∾𝕩∾reset }
Gray   ← { e∾"[97m"∾e∾"[100m"∾𝕩∾reset }

Refresh ← { 𝕊: •term.OutRaw cr∾e∾"[K" }
CursorY ← { •term.OutRaw e∾"["∾(•Fmt 1+𝕩)∾";1H" }

OneLine ← { ¯1↓ ∾((𝕩-'a')⊏letters){ " "∾˜𝕎◶⥊‿Green‿Yellow‿Gray 𝕩 }¨𝕩 }
PrintLetters ← { 𝕊:
    CursorY 1+tries
    Out OneLine l1
    Out " "∾OneLine l2
    OUt "  "∾OneLine l3
}


Begin @
ClearScreen @
HideCursor @

PrintLetters @

win ← 0
i ← 0
exit ← 0
{ 𝕊:
    CursorY i, Refresh @
    ShowCursor @
    guess ← n↑•GetLine @
    HideCursor @
    CursorY tries, Refresh @

    { guess≡n↑' '?
        exit ↩ 1
    ; ¬⊑(<guess)∊cand?
        Out "Not in word list"
    ; guess≡word?
        win ↩ 1
        exit ↩ 1
        CursorY i, Refresh @
        Out Green guess

        letters 1¨⌾((guess-'a')⊸⊏)↩
    ;
        correct ← word=guess
        couldbe ← {
            n ← +´ m ← ¬correct
            r ← n>(m/word)⊒m/guess
            r˙⌾(m⊸/)m
        }
        nowhere ← ¬couldbe∨correct

        CursorY i, Refresh @
        d ← 1¨⌾(correct⊸/) 2¨⌾(couldbe⊸/) 3¨⌾(nowhere⊸/) n⥊0
        Out ∾ d{ 𝕎◶⥊‿Green‿Yellow‿Gray 𝕩 }¨guess

        g ← guess-'a'
        n ← nowhere/g, n ↩ (0=n⊏letters)/n
        b ← couldbe/g, b ↩ (0=b⊏letters)/b
        c ← correct/g

        letters { 1¨⌾(c⊸⊏) 2¨⌾(b⊸⊏) 3¨⌾(n⊸⊏) 𝕩 }↩

        i +↩ 1
    }

    PrintLetters @
} •_while_ { 𝕊: (¬exit)∧i<tries } @

CursorY 5+tries

Out { win? ""; "word: "∾word }
Out "press enter to exit..."
•GetLine @

ShowCursor @
End @
