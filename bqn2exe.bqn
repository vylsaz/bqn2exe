⟨At, Exists, RealPath, Remove, Parent, Name, Type
⟩ ← •file

src ← At"src"
srcMain ← src At"main.c"
bin ← At"bin"
bins ← ⟨
    cbqnDll ← bin At"cbqn.dll"
    cbqnLib ← bin At"libcbqn.a"
    exeRc ← bin At"exe.rc.o"
⟩

extraBins ← ⟨
    physfsLib ← bin At"libphysfs.a"
    physfsLoader ← bin At"physfs-loader.o"
⟩

hasPhysFs ⇐ ∧´Exists¨extraBins

mingwbin ← At"bin"At"llvm-mingw"At"bin"
gcc ← {Exists mingwbin?
    RealPath mingwbin At "gcc.exe";
    "gcc"
}

nl ← @+10
WinSepToSep ← {'/'¨⌾(('\'=𝕩)⊸/)𝕩}
SepToWinSep ← {'\'¨⌾(('/'=𝕩)⊸/)𝕩}
Quote ← {∨´𝕩∊" "? "'"∾𝕩∾"'"; 𝕩}
EndsWith ← {𝕨≡𝕩∾˜𝕨↑˜0⌈𝕨-○≠𝕩}
StartsWith ← (⊣≡⌊○≠↑⊢)˜
DropThis ← {𝕩↓˜2×∨´𝕩⊸StartsWith¨"./"‿".\"}
DropIfEndsWith ← {𝕨≡𝕩? !"Cannot use name "∾𝕨; 𝕨 EndsWith 𝕩? (-≠𝕩)↓𝕨; 𝕨}

TempPath ⇐ {path 𝕊 pre‿suf:
    rand ← •MakeRand •rand.Range 10000
    c ← "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
    file ← @
    attemps ← 10000
    i ← 0
    loop ← 1, {𝕊: i +↩ 1
        name ← c⊏˜rand.Range¨8⥊<≠c
        file ↩ path At pre∾name∾suf
        Exists file? file ↩ @; loop ↩ 0
    } •_while_ {𝕊: loop∧i<attemps} @

    file
}

GenInc ⇐ {def 𝕊 b:
    m ← "\x"⊸∾˘⊏⟜"0123456789ABCDEF"⍉16‿16{𝕨|>⌊∘÷`⌾⌽𝕨«˜<𝕩}b-@
    s ← ∾{<""""∾(' '⊸≠⊸/𝕩)∾""""∾nl}˘↑‿(20×4)⥊m
    def∾" ="∾nl∾s∾""""";"∾nl
}

_NsGetOr ← {k X _𝕣 v: {x•ns.Has k? {@: v; 𝕩}x•ns.Get k; v}}

MakeOpts ← {
    GetOr ← 𝕩 _NsGetOr 

    path ⇐ •wdpath At "path" GetOr ""
    Rel ← path⊸At

    input ⇐ SepToWinSep Rel DropThis 𝕩.input
    output ⇐ SepToWinSep {𝕩 EndsWith ".exe"? 𝕩; 𝕩∾".exe"}{
        o ← "output" GetOr (Name input) DropIfEndsWith ".bqn"
        {∨´'/'=WinSepToSep o? Rel DropThis o; (Parent input)At o}
    }
    cc ⇐ "cc" GetOr gcc
    ccOpts ⇐ "ccOpts" GetOr ⟨⟩
    static ⇐ "static" GetOr 0

    physfs ⇐ {hasPhysFs? "physfs" GetOr 0; 0}

    verbose ⇐ "verbose" GetOr 0
    print ← {verbose? •out; @˙}
    Info ⇐ Print "[INFO] "⊸∾
    _CmdWith ⇐ {
        Print "[CMD] "∾""{(Quote 𝕨)∾" "∾𝕩}´𝕩
        ⟨r, o, e⟩ ← •SH 𝕩
        𝔽 @
        {o≡""? @; •term.OutRaw •ToUtf8 o}
        {e≡""? @; •term.ErrRaw •ToUtf8 e}
        !r≡0
    }
}

Bqn2Exe ⇐ {
    o ← MakeOpts 𝕩

    {∧´Exists¨bins? @; !"please run 'prepare.bqn' to populate the bin folder"}

    o.Info "Generating include file"
    inc ← o.path TempPath ""‿".inc"
    inc •FChars "static const char bqn2exeInc[]" GenInc •FBytes o.input

    o.Info "Compiling '"∾o.output∾"'"
    output ← ⟨"-o", o.output⟩
    inputs ← ⟨srcMain, exeRc⟩∾<{o.static? cbqnLib; cbqnDll}
    extras ← {o.physfs? ⟨physfsLib, physfsLoader, "-DBQN2EXE_CUSTOM_LOADER"⟩;
        ⟨⟩}
    cflags ← ⟨"-Wall", "-pthread", "-static", "-municode"⟩
    incDef ← ⟨"-DBQN2EXE_INC="""∾(WinSepToSep inc)∾""""⟩

    {𝕊: Remove inc} o._CmdWith ⟨o.cc⟩∾output∾inputs∾extras∾o.ccOpts∾incDef∾cflags

    {
        ¬o.static?
        dst ← (Parent o.output)At"cbqn.dll"
        ¬Exists dst?
        o.Info "Copying libcbqn to '"∾dst∾"'"
        dst •FBytes •FBytes cbqnDll
        @;@
    }

    o.output
}

# to use as a library: •Import "bqn2exe.bqn"
{(⟨⟩≡•args)∧•name EndsWith ".bqn"? @;
# cli starts here
    exe ← •path At •name

    usage ← "Usage: "∾exe∾" input [options] [-- cc-options]
Options:
    -h, --help              Print help message
    -o, --output <file>     Output <file>
    -s, --static            Use static libcbqn
    -v, --verbose           Display details
        --cc <compiler>     Use C compiler <compiler>"∾{hasPhysFs?"
        --physfs            Use PhysFs loader
";"
"}

    myErrs ← 0⥊<""
    Err ← {myErrs ∾↩ <•ToUtf8 "Error: "∾𝕩∾nl}
    ErrIf ← {𝕩? Err 𝕨; @}
    ErrFinal ← {0=≠myErrs? 𝕩; •term.ErrRaw¨myErrs, •Exit 1}

    Help ← {𝕊: •Out usage, •Exit ErrFinal 0}

    options ← ⟨
        "help"‿'h'
        "output"‿'o'
        "static"‿'s'
        "verbose"‿'v'
        "cc"‿@
    ⟩∾{hasPhysFs?
        ⟨"physfs"‿@⟩; ⟨⟩
    }

    args ← •args
    {⟨⟩≡args? Help@; @}

    ShiftArgs ← {𝕊: e ← ⟨⟩≡args, "one more argument is required"ErrIf e, r ← {e? @; ⊑args}, args 1⊸↓↩, r}
    InsertArgs ← {args ∾˜↩ 𝕩}
    ShiftAllArgs ← {𝕊: r ← args, args ↩ ⟨⟩, r}

    myArgs ← ⟨⟩ •HashMap ⟨⟩
    MyArgsPush ← {k 𝕊 v: k myArgs.Set {myArgs.Has k? myArgs.Get k; ⟨⟩}∾<v}
    MyArgsGetN ← {𝕊 k: myArgs.Has k? myArgs.Get k; @}
    MyArgsGet1 ← {𝕊 k: myArgs.Has k? {("'"∾k∾"' should only be set once")ErrIf 1<≠𝕩, ⊑𝕩}myArgs.Get k; @}

    HandleArg ← {short 𝕊 arg:
        a ← short⊑¨options
        Unknown ← {𝕊: Err"Unknown command '"∾((2-short)⥊"-")∾arg∾"'"}
        {
            "help": Help@;
            "output": 𝕩 MyArgsPush ShiftArgs@;
            "static": 𝕩 MyArgsPush 1;
            "verbose": 𝕩 MyArgsPush 1;
            "cc": 𝕩 MyArgsPush ShiftArgs@;
            "physfs": {hasPhysFs? 𝕩 MyArgsPush 1; Unknown@} 𝕩;
            Unknown@
        }(⊑a⊐<arg)⊑(⊑¨options)∾<@
    }

    {𝕊:
        x ← ShiftArgs@
        {
            ""≡x? Err"Empty argument";
            "-"≡x? Err"Unknown option '-'";
            '-'≠⊑x? "input" MyArgsPush x;
            "--"≡x? "ccOpts" myArgs.Set ShiftAllArgs @;
            {∨´eq ← '='=x? 
                a ← eq (⊢-˜+`×¬)⊸⊔ x
                x ↩ ⊑a, InsertArgs 1↓a
            ;@}
            '-'=1⊑x? # long option
                0 HandleArg 2↓x;
            1 HandleArg¨1↓x
        }
    }•_while_ {𝕊: ⟨⟩≢args} @

    Bqn2Exe ErrFinal {
        path ⇐ •wdpath
        input ⇐ {@: Err"input is not set";
            {¬Exists 𝕩? Err"cannot find input file '"∾𝕩∾"'";
            'd'≡Type 𝕩? Err"cannot find input file '"∾𝕩∾"'";
            @}SepToWinSep path At DropThis 𝕩
            𝕩
        } MyArgsGet1 "input"
        output ⇐ MyArgsGet1 "output"
        static ⇐ MyArgsGet1 "static"
        verbose ⇐ MyArgsGet1 "verbose"
        cc ⇐ MyArgsGet1 "cc"
        ccOpts ⇐ MyArgsGetN "ccOpts"
        physfs ⇐ {hasPhysFs? MyArgsGet1 "physfs"; @}
    }
}
