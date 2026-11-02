⟨At, RealPath, Remove⟩ ← •file
⟨AskDownload, Download, UnzipTo, CopyTo, RemoveDir⟩ ← •Import "common.bqn"

path ← RealPath At".."

crt ← "ucrt"
arch ← "x86_64"
v ← "auto"

url ← "https://github.com/vylsaz/cbqn-win-docker-build/releases/download/"∾v∾"/cbqn-"∾crt∾"-"∾arch∾".zip"
bin ← path At"bin"
zip ← bin At"cbqn.zip"
dir ← bin At"bqn"
lib ← dir At"libcbqn"

{ zip AskDownload url?
    zip Download url
    zip UnzipTo bin
    Remove zip
    {(lib At 𝕩) CopyTo bin}¨"cbqn.dll"‿"cbqn.lib"‿"libcbqn.a"
    RemoveDir dir
    ; @
}
