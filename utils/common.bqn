AskDownload ⇐ { file 𝕊 url:
    •Out "This will download a file from the internet"
    •Out "url: "∾url
    •Out "out: "∾file
    •term.OutRaw "Continue to download? [y/N] ", (⊑<∊"y"‿"Y"˙)•GetLine @
}

Exec ⇐ {{ok‿out‿err: err!0≡ok, out} •SH 𝕩}
Pwsh ⇐ {Exec ⟨"Powershell", "-ExecutionPolicy", "RemoteSigned", "-Command", 𝕩⟩}

Download ⇐ { file 𝕊 url:
    Pwsh "Invoke-WebRequest "∾url∾" -OutFile '"∾file∾"' -UserAgent Wget"
}
UnzipTo ⇐ { file 𝕊 dst:
    Pwsh "Expand-Archive -LiteralPath '"∾file∾"' -DestinationPath '"∾dst∾"'"
}
CopyTo ⇐ { from 𝕊 to:
    Pwsh "Copy-Item -LiteralPath '"∾from∾"' -Destination '"∾to∾"'"
}
RemoveDir ⇐ {
    Pwsh "Remove-Item -Recurse -LiteralPath '"∾𝕩∾"'"
}
