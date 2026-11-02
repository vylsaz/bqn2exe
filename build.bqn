⟨At, Remove⟩ ← •file

dir ← At"examples"
bqn ← "bqn2exe.bqn"
exe ← At"bqn2exe.exe"
exe0 ← At"bqn2exe0.exe"

⟨Bqn2Exe⟩ ← •Import bqn
Bqn2Exe {
    path ⇐ •path
    input ⇐ bqn
    output ⇐ exe0
    verbose ⇐ 1
    static ⇐ 1
}
Cmd ← {
    •Out "[BUILD] "∾>{𝕨∾' '∾𝕩}´𝕩
    ⟨r, o, e⟩ ← •SH 𝕩
    {o≡""? @; •term.OutRaw •ToUtf8 o}
    {e≡""? @; •term.ErrRaw •ToUtf8 e}
    {r≡0? @; •Exit r}
}
Cmd ⟨exe0, bqn, "-so", exe⟩
Remove exe0

Cmd ⟨exe, "examples/hello/hello.bqn", "-o="∾hello ← dir At "hello.exe"⟩
Cmd ⟨hello⟩

Cmd ⟨exe, "examples/raylib-test/main.bqn", "-vso", "raylib-test", "--", "-mwindows"⟩

Cmd ⟨exe, "examples/2048/2048.bqn", "--output", dir At "2048"⟩

Cmd ⟨exe, "examples/wordle/wordle.bqn"⟩

Cmd ⟨exe, "examples/echo/echo.bqn"⟩
Cmd ⟨dir At"echo"At"echo.exe"⟩
Cmd ⟨dir At"echo"At"echo.exe", "foo", "bar"⟩
