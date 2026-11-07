{state 𝕊 ⟨
    FsInit
    FsDeinit
    FsMkdir
    FsDelete
    FsExists
    FsList
    FsSize
    FsType
    FsGetTimes
    FsReadBytes
    FsWriteBytes
    FsGetPrefDir
    FsGetRealDir
    FsGetWriteDir
    FsSetWriteDir
    FsUnsetWriteDir
    FsMount
    FsMountAppend
    FsUnmount
    FsGetLastError
⟩:

⟨path, name, args⟩ ← state

Chk0 ← {𝕩? 1; !FsGetLastError@}
ChkNull ← {@: !FsGetLastError@; 𝕩}

GetSint64 ← {𝕊⟨hi, lo⟩:
    "Too large"!(2097152>|hi)∨(0=lo)∧2097152=|hi
    lo+4294967296×hi
}

SplitAt ← (⊢-˜+`×¬)⊸⊔

cr‿lf ← @+13‿10

DivideLines ← {
    x ← (¬0∾˜cr‿lf⍷𝕩)/𝕩
    (lf=x)SplitAt x
}

JoinLines ← {""(⊣∾lf∾⊢)´𝕩}

currentFileStack ← ⟨"/"⟩
CurrentFile ← {𝕊: ¯1⊑currentFileStack}
PushCurrentFile ← {currentFileStack ∾↩ <𝕩, @}
PopCurrentFile ← {𝕊: currentFileStack ↓˜↩ ¯1, @}

sep ← '/'
Parent ← {
    "Path must be non-empty"!0≢≠𝕩
    m ← sep=x ← 𝕩
    {∧´m? ⋈sep;
        m 0⌾(¯1⊸⊑)↩
        m ∨`⌾⌽↩
        {∨´m? m/x; "./"}
    }
}
GetPath ← Parent CurrentFile
IsAbsolute ← {"": 0; sep≡⊑𝕩}
IsTrailingSep ← {"": 0; sep≡¯1⊑𝕩}

IsString ← {1≡=𝕩? 1≡≡𝕩? ∧´∞<𝕩; 0}
CheckPath ← {"Path must be a list of characters"!IsString 𝕩, 𝕩}
CheckW ← {"𝕨 must be a string"!IsString 𝕩, 𝕩}

SimpAt ← {𝕨∾(<sep)∾𝕩}
AtRaw ← {
    𝕊 𝕩: (GetPath @)𝕊 𝕩;
    "" 𝕊 𝕩: 𝕩; 𝕨 𝕊 "": 𝕨; 
    IsAbsolute 𝕩? 𝕩;
    IsTrailingSep 𝕨? 𝕨∾𝕩;
    𝕨 SimpAt 𝕩
}
At ← (AtRaw CheckPath)⊘(CheckW⊸AtRaw⟜CheckPath)
RelPath ← {IsAbsolute 𝕩? 𝕩; At 𝕩}
SplitPath ← {(sep=𝕩)SplitAt 𝕩}
ParsePath ← {
    abs ← IsAbsolute 𝕩
    parts ← SplitPath 𝕩
    newParts ← 0⥊<"", {
        0=≠𝕩? @;
        𝕩≡"."? @;
        𝕩≡".."? newParts ↓˜↩ ¯1, @;
        newParts ∾↩ <𝕩, @
    }¨parts
    {abs? (<"")∾newParts; newParts}
}
NormPath ← {
    "": "";
    p ← ParsePath 𝕩
    {p≡⟨""⟩? ⋈sep; SimpAt´p}
}

VPath ← {NormPath RelPath WinSepToSep CheckPath 𝕩}

GetName ← {
    "Path must be non-empty"!0≢≠𝕩
    ("File path ended with a slash: """∾𝕩∾"""")!¬IsTrailingSep 𝕩
    ¯1⊑SplitPath 𝕩
}

WinSepToSep ← {sep¨⌾(('\'=𝕩)⊸/)𝕩}
SepToWinSep ← {'\'¨⌾((sep=𝕩)⊸/)𝕩}

DropLeadingSep ← {𝕩/˜¬∧`sep=𝕩}

Exists ← {FsExists VPath 𝕩}

RealPath ← {
    𝕩 VPath ↩
    Exists 𝕩? 𝕩;
    !"Failed to resolve """∾𝕩∾""""
}

ReadBytes ← {ChkNull FsReadBytes VPath 𝕩}

WriteBytes ← {Chk0 (r ← VPath 𝕨) FsWriteBytes 𝕩, r}

List ← {ChkNull FsList VPath 𝕩}

Size ← {GetSint64 ChkNull FsSize VPath 𝕩}

Type ← {ChkNull FsType VPath 𝕩}

GetTimes ← {ChkNull FsGetTimes VPath 𝕩}

Accessed ← GetSint64 0⊑GetTimes
Created  ← GetSint64 1⊑GetTimes
Modified ← GetSint64 2⊑GetTimes

CreateDir ← {Chk0 FsMkdir r ← VPath 𝕩, r}

Remove ← {Chk0 FsDelete VPath 𝕩, 1}

Rename ← {new 𝕊 old:
    old VPath↩
    new VPath↩
    "Failed to rename file"!¬Exists new
    "Failed to rename file"!Exists old
    new WriteBytes ReadBytes old
    Remove old
    new
}

PhysFsInit ← {Chk0 FsInit 𝕩}
PhysFsDeInit ← FsDeinit
SetWriteDir ← {Chk0 FsSetWriteDir 𝕩, 𝕩}
UnsetWriteDir ← {Chk0 FsUnsetWriteDir 𝕩}
GetWriteDir ← {FsGetWriteDir 𝕩}
GetPrefDir ← {org 𝕊 app: ChkNull org FsGetPrefDir app}
GetRealDir ← {ChkNull FsGetRealDir 𝕩}
Mount0 ← {mp 𝕊 dir: Chk0 mp FsMount dir, mp}
Mount  ← {mp 𝕊 dir: Chk0 mp FsMountAppend dir, mp}
Unmount ← {Chk0 FsUnmount 𝕩}

NoMon ← {𝕊: !"This function can't be called monadically"}
NoDya ← {𝕊: !"This function can't be called dyadically"}

physfs ← {
    SetWriteDir ⇐ SetWriteDir
    UnsetWriteDir ⇐ UnsetWriteDir
    GetWriteDir ⇐ GetWriteDir
    GetPrefDir ⇐ GetPrefDir
    GetRealDir ⇐ GetRealDir
    Mount0 ⇐ Mount0 
    Mount ⇐ Mount
    Unmount ⇐ Unmount

    file ⇐ {
        Path ⇐ GetPath
        At ⇐ At
        Name ⇐ GetName⊘NoDya
        Parent ⇐ Parent⊘NoDya

        Exists ⇐ Exists⊘NoDya

        RealPath ⇐ RealPath⊘NoDya

        List ⇐ List⊘NoDya
        Size ⇐ Size⊘NoDya
        Type ⇐ Type⊘NoDya
        Accessed ⇐ Accessed⊘NoDya
        Created  ⇐ Created ⊘NoDya
        Modified ⇐ Modified⊘NoDya

        Bytes ⇐ ReadBytes⊘WriteBytes
        Chars ⇐ (•FromUTF8   ReadBytes)⊘{𝕨 WriteBytes   •ToUtf8 𝕩}
        Lines ⇐ (DivideLines ReadBytes)⊘{𝕨 WriteBytes JoinLines 𝕩}
        MapBytes ⇐ ReadBytes⊘NoDya

        CreateDir ⇐ CreateDir⊘NoDya
        Remove ⇐ Remove⊘NoDya
        Rename ⇐ NoMon⊘Rename
    }
}

myDllDict ← ⟨⟩ •HashMap ⟨⟩

ResolveForeign ← {⟨x, ·⟩: x≡{↑}? 𝕩;
    f ← VPath 𝕩
    d ← GetRealDir f
    { myDllDict.Has f?
        myDllDict.Get f
    ; 'd'≡•file.Type d? 
        d •file.At SepToWinSep DropLeadingSep f
    ;
        {"/": @; 𝕊 Parent 𝕩, CreateDir 𝕩, @} Parent f
        f WriteBytes ReadBytes f
        nd ← GetWriteDir @
        np ← nd •file.At SepToWinSep DropLeadingSep f
        f myDllDict.Set np, np
    }
}

FFI ← ResolveForeign⊸•FFI
foreign ← {
    Function ⇐ •foreign.Function⊘FFI
    Pointer ⇐ ResolveForeign⊸•foreign.Pointer
    Value ⇐ ResolveForeign⊸•foreign.Value
    null ⇐ •foreign.null
    SizeOf ⇐ •foreign.SizeOf
    ReadBytesTo0 ⇐ •foreign.ReadBytesTo0
    ReadCharsTo0 ⇐ •foreign.ReadCharsTo0
}

SH ← {𝕊: !"•SH is disabled"}

Import ← {
    impArgs ← 𝕨 ⊣ ⟨⟩
    file ← VPath 𝕩
    PushCurrentFile file
    state ← ⟨path, name∾";physfs:/"∾file, impArgs⟩
    code ← •FromUTF8 ReadBytes file
    ret ← state Shim code
    PopCurrentFile @
    ret
}

shim ← •ReBQN {
    repl ⇐ "none"
    system ⇐ {𝕩∾•listSys(¬∘∊/⊣)⊑¨𝕩}⟨
        "sh"‿SH
        "import"‿Import
        "ffi"‿FFI
        "foreign"‿foreign
        "file"‿physfs.file
        "fbytes"‿physfs.file.bytes
        "fchars"‿physfs.file.chars
        "flines"‿physfs.file.lines
        "path"‿physfs.file.path
        "wdpath"‿"/"
    ⟩
}

bqn ← •ReBQN {
    repl ⇐ "none"
    system ⇐ {𝕩∾•listSys(¬∘∊/⊣)⊑¨𝕩}⟨
        "physfs"‿physfs
        "currentfile"‿{
            Push ⇐ PushCurrentFile
            Pop ⇐ PopCurrentFile
            Get ⇐ CurrentFile
        }
        "bqnshim"‿shim
    ⟩
}

{
    PhysFsInit path •file.At name
    state BQN 𝕩
    PhysFsDeInit @
}
}
