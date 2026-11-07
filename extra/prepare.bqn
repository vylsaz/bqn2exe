⟨At, Exists, List, RealPath⟩ ← •file
⟨Exec, CopyTo⟩ ← •Import "../utils/common.bqn"
⟨GenInc⟩ ← •Import "../bqn2exe.bqn"
Out ← •Out

physfs ← At"physfs"
{ Exists physfs? @
; 0<≠List physfs? @
; !"run 'git submodule update --init --recursive'"
}

Out "Step 1: Get Cmake (optional)"
•Import "../utils/get-cmake.bqn"

path ← RealPath At".."

bin ← path At"bin"
cmakebin ← bin At"cmake"At"bin"
cmake ← {Exists cmakebin?
    RealPath cmakebin At "cmake.exe";
    "cmake"
}

mingw ← bin At"llvm-mingw"
gcc‿make ← {Exists mingw?
    {RealPath mingw At 𝕩}¨⟨"bin"At"gcc.exe", "busybox"At"bin"At"make.exe"⟩;
    "gcc"‿"make"
}

build ← bin At"physfs"
Out "Step 2: Compile physfs"
Exec ⟨cmake, "-S", physfs, "-B", build, "-G", "MinGW Makefiles"
    "-DCMAKE_C_COMPILER="∾gcc, "-DCMAKE_MAKE_PROGRAM="∾make⟩
Exec ⟨cmake, "--build", build⟩
(build At"libphysfs.a") CopyTo bin At"libphysfs.a"

loaderInc ← At"physfs-loader.inc"
loaderBqn ← At"physfs-loader.bqn"
Out "Step3: Generate loader"
loaderInc •FChars "static const char loader[]" GenInc •FBytes loaderBqn

src ← At "physfs-loader.c"
Out "Step4: Compile custome loader"
Exec ⟨gcc, src, "-c", "-o", bin At "physfs-loader.o"⟩
