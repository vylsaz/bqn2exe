raylib ← •wdpath •file.At"raylib.dll"
{¬•file.Exists raylib?
  raylib ↩ ⟨•path⟩•Import"install-raylib.bqn"
  ;@
}
rl ← ⟨raylib⟩•Import"raylib.bqn"

file ← •file

white ← 255‿255‿255‿255
black ← 0‿0‿0‿255

list ← 255×⟨
  1‿0‿0‿1, 0‿1‿0‿1, 0‿0‿1‿1
  1‿1‿0‿1, 0‿1‿1‿1, 1‿0‿1‿1
⟩

fps ← 60
w‿h ← 800‿600
pos ← 0‿0
vel ← 1‿1×100

rl.SetConfigFlags rl.configFlags.flagWindowResizable 
rl.InitWindow⟨w, h, "hello!"⟩

rt ← rl.LoadRenderTexture⟨w, h⟩

mem ← file.Bytes"image/dvd-logo.png"
img ← rl.LoadImageFromMemory⟨".png", mem, ≠mem⟩
img ↩ ⊑⊑rl.ImageResizeRef⟨<img⟩∾⌊0.4×1‿2⊏img
img ↩ ⊑⊑rl.ImageColorInvertRef <img
dvd ← rl.LoadTextureFromImage img

rl.SetTargetFPS fps
{𝕊:
  pos +↩ vel×÷fps
  vel ×↩ ⊏⟜1‿¯1 hit ← (pos<0)∨w‿h<pos+1‿2⊏dvd

  list ⌽˜↩ ∨´hit

  rect ← {𝕊 w1‿h1:
    y‿x ← h1‿w1≥h2‿w2 ← w1‿h1×(⌽÷⊢)w‿h
    {y? ⟨0, 0.5×h1-h2, w1, h2⟩ ; ⟨0.5×w1-w2, 0, w2, h1⟩}
  }⟨rl.GetScreenWidth⟨⟩, rl.GetScreenHeight⟨⟩⟩

  rl.BeginTextureMode rt
  {
    rl.ClearBackground 25‿25‿25‿255
    rl.DrawTextureEx⟨dvd, pos, 0, 1, ⊑list⟩
  }
  rl.EndTextureMode⟨⟩

  rl.BeginDrawing⟨⟩
  {
    rl.ClearBackground black
    rl.DrawTexturePro ⟨t ← 1⊑rt, 0‿0∾1‿¯1×1‿2⊏t, rect, 0‿0, 0, white⟩
    rl.DrawFPS 0‿0
  }
  rl.EndDrawing⟨⟩
}•_while_(¬rl.WindowShouldClose∘⟨⟩)@

rl.CloseWindow⟨⟩
