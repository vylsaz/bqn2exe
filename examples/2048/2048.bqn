#!/usr/bin/env BQN
# https://rosettacode.org/wiki/2048#BQN
# 2048 game
# The game is controlled with the vim movement keys:
# h: left, j: down, k: up, l: right, q: quit
# needs a VT-100 compatible terminal

Merge←{𝕩 0⊸≠⊸/↩ ⋄ m←<`=⟜«𝕩 ⋄ 4↑(¬»m)/𝕩×1+m}⌾⌽ # Merge a single row to the right
Step←Merge˘    # Merges each row of the board
Up←Step⌾(⌽⍉∘⌽) # Each direction merges the board
Down←Step⌾⍉    # by rotating it to the correct orientation, merging the rows
Right←Step     # and reversing the rotation
Left←Step⌾(⌽˘)    
# Spawns a 2 or a 4 (10% chance) at a random empty position
Spawn←{i←•rand.Range∘≠⊸⊑(0⊸= /○⥊ ↕∘≢)𝕩 ⋄ (•rand.Range∘≠⊸⊑9‿1/2‿4)⌾(i⊸⊑) 𝕩} 
Lose←Left∘Right∘Down∘Up⊸≡ # Losing condition, no moves change the board
Win←∨´·∨˝2048⊸= #  Winning condition, 2048!

e←@+27 # Escape character for the ANSI escape codes
Quit←{
  •Out e∾"[?12l"∾e∾"[?25h"
  •term.OutRaw"Press Any Key to Continue ...", •term.CharB@
  •Out e∾"[?1049l"
  •term.RawMode 0
  •Exit 𝕩
} # Restores the terminal and exits
Display←{ # Displays the board, score and controls
  •Out e∾"[H"∾e∾"[2J" # Cursor to origin and clear screen
  •Out "Controls: h: left, j: down, k: up, l: right, q: quit"
  •Show 𝕩
  •Out "score: "∾•Repr ⌈´⌈˝ 𝕩
}

board←Spawn 4‿4⥊0
•term.RawMode 1
•Out e∾"[?1049h"
•Out e∾"[?25l"∾e∾"[2J"∾e∾"[H" # Cursor to origin, hide it and clear screen
{𝕤⋄
  Display board
  {𝕤⋄•Out "You win!" ⋄ Quit 0}⍟Win board
  {𝕤⋄•Out "You lose!"⋄ Quit 1}⍟Lose board
  key←•term.CharB @ # Read key
  ⊑key∊"hjklq"? # Valid key?
    {𝕤⋄ Quit 0}⍟(key='q')@ # Quit key?
    move←⊑(key="hjkl")/Left‿Down‿Up‿Right # Get movement function from the key
    {𝕤⋄board↩Spawn∘Move 𝕩}⍟(Move⊸≢) board # Generate the next board if the move is valid
  ; @
}•_While_{𝕤⋄1}@
