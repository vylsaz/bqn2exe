⟨At, Exists, RealPath⟩ ← •file
⟨Exec⟩ ← •Import "utils/common.bqn"
Out ← •Out

Out "Step 1: Get GCC (optional)"
•Import "utils/get-gcc.bqn"

Out "Step 2: Get libcbqn"
•Import "utils/get-libcbqn.bqn"

mingwbin ← At"bin"At"llvm-mingw"At"bin"
windres ← {Exists mingwbin?
    RealPath mingwbin At "windres.exe";
    "windres"
}

Out "Step 3: Compile manifest"
Exec ⟨windres, "-i", At"src"At"exe.rc", "-o", At"bin"At"exe.rc.o"⟩
