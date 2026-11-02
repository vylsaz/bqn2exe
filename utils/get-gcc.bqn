⟨At, RealPath, Rename, Remove⟩ ← •file
⟨AskDownload, Download, UnzipTo⟩ ← •Import "common.bqn"

path ← RealPath At".."

crt ← "ucrt"
arch ← "x86_64"
v ← "20261020"

inner ← "llvm-mingw-"∾v∾"-"∾crt∾"-"∾arch
url ← "https://github.com/mstorsjo/llvm-mingw/releases/download/"∾v∾"/"∾inner∾".zip"
bin ← path At"bin"
zip ← bin At"llvm-mingw.zip"
fin ← bin At "llvm-mingw"

{ zip AskDownload url?
    zip Download url
    zip UnzipTo bin
    Remove zip
    fin Rename bin At inner
    ; @
}
