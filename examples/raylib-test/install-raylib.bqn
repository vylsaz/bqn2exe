#!usr/bin/env bqn
# Modified from 
# https://github.com/Brian-ED/rayed-bqn/blob/864b5b6d7659f48ef8c38f6a6f5893e0dc127ade/install-raylib.bqn
⟨Realpath⋄At⋄Exists⋄CreateDir⋄Remove⋄List⋄Bytes⋄path⟩ ← •file
⟨os⟩←•platform
version ← "5.0"
binariesPath ← ⊑•args

⟨               ext     ⋄ libFile         ⋄ raylibFolder
⟩←{"darwin":  ⟨".tar.gz"⋄"libraylib.dylib"⋄"raylib-"∾version∾"_macos"       ⟩
;  "linux":   ⟨".tar.gz"⋄"libraylib.so"   ⋄"raylib-"∾version∾"_linux_amd64" ⟩
;  "windows": ⟨".zip"   ⋄"raylib.dll"     ⋄"raylib-"∾version∾"_win64_msvc16"⟩
} os

git_clone_path ← "https://www.github.com/raysan5/raylib/releases/download/"∾version∾"/"∾raylibFolder∾ext

# Expected library to not exist
{Exists binariesPath At libFile? @;

# ---------------
# download raylib
# ---------------

Exec ← {e‿·‿o:o!0≡e}•SH

# Download raylib zip/tar file
Exec {"windows"≡os?
  ⟨
    "Powershell.exe" ⋄ "-Command"
    "Invoke-WebRequest "∾git_clone_path∾" -OutFile '"∾(At"temp"∾ext)∾"'"
  ⟩
;
  ⟨"curl" ⋄ "-o" ⋄ At"temp"∾ext ⋄ git_clone_path, "-L"⟩
}
"Downloading raylib failed from github failed. Likely due to redirects not being followed."!⟨⟩≢•FBytes "temp"∾ext

# Unzip/untar/unarchive raylib
Exec {"windows"≡os?
  ⟨
    "Powershell.exe" ⋄ "-ExecutionPolicy" ⋄ "RemoteSigned" ⋄ "-Command"
    "Expand-Archive -LiteralPath '"∾(Realpath"temp"∾ext)∾"' -DestinationPath '"∾path∾"'"
  ⟩
;
  ⟨"tar" ⋄ "-xzf" ⋄ Realpath"temp"∾ext ⋄ "-C" ⋄ path⟩
}
Remove Realpath"temp"∾ext
"Extracting raylib failed"!Exists raylibFolder At "lib" At libFile

# ---------------------
# Copy binary file to binariesPath
# ---------------------
CreateDir⍟(¬Exists) binariesPath
(binariesPath At libFile) Bytes Bytes Realpath raylibFolder At "lib" At libFile

# -----------------
# Clean away raylib
# -----------------
filesToBeDeleted ← raylibFolder⊸At¨ ∾⟨
  "lib"    ⊸At¨•file.List raylibFolder At"lib"
  "include"⊸At¨"raylib.h"‿"raymath.h"‿"rlgl.h"
  "CHANGELOG"‿"LICENSE"‿"README.md"
⟩
!∘{𝕊:"Unexpected files in "∾raylibFolder∾", "∾•Repr filesToBeDeleted
}⍟(0≠≠)¬∘Exists¨⊸/filesToBeDeleted
Remove¨filesToBeDeleted
cleaupErrorMsg ← "Cleanup unsuccessful. Please delete "∾raylibFolder∾" manually "
RMDirCmd ← {
  os≡"windows"?
    ⟨"Powershell.exe" ⋄ "-Command" ⋄ "Remove-Item -Recurse -LiteralPath '"∾𝕩∾"'"⟩
; "rmdir"⋈𝕩
}
{cleaupErrorMsg!0‿⟨⟩‿⟨⟩≡•SH RMDirCmd Realpath raylibFolder At𝕩}¨"lib"‿"include"‿""

•Out "raylib installed successfully"
}
binariesPath At libFile
