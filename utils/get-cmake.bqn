⟨At, RealPath, Rename, Remove⟩ ← •file
⟨AskDownload, Download, UnzipTo⟩ ← •Import "common.bqn"

path ← RealPath At".."

arch ← "x86_64"
v ← "4.4.5"

inner ← "cmake-"∾v∾"-windows-"∾arch
url ← "https://github.com/Kitware/CMake/releases/download/v"∾v∾"/"∾inner∾".zip"
bin ← path At"bin"
zip ← bin At"cmake.zip"
fin ← bin At"cmake"

{ zip AskDownload url?
    zip Download url
    zip UnzipTo bin
    Remove zip
    fin Rename bin At inner
    ; @
}
