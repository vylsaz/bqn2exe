#include <stdlib.h>
#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "bqnffi.h"

uint32_t *Utf32FromUtf16(const WCHAR *wstr, size_t len, size_t *outLen)
{
    if (!wstr) return NULL;
    uint32_t *utf32 = (uint32_t*)malloc(len * sizeof(uint32_t));
    if (!utf32) return NULL;

    size_t i = 0;
    size_t j = 0;
    while (i < len) {
        uint32_t codepoint = wstr[i++];
        if (codepoint >= 0xD800 && codepoint <= 0xDBFF) {
            if (i < len) {
                uint32_t trail = wstr[i];
                if (trail >= 0xDC00 && trail <= 0xDFFF) {
                    codepoint = ((codepoint - 0xD800) << 10) + (trail - 0xDC00) + 0x10000;
                    i++;
                }
            }
        } else if (codepoint >= 0xDC00 && codepoint <= 0xDFFF) {
            codepoint = 0xFFFD;
        }
        utf32[j++] = codepoint;
    }
    if (outLen) *outLen = j;
    return utf32;
}

BQNV MakeWstr(const WCHAR *wstr)
{
    size_t utf32Len = 0;
    uint32_t *utf32 = Utf32FromUtf16(wstr, wcslen(wstr), &utf32Len);
    BQNV r = bqn_makeC32Vec(utf32Len, utf32);
    free(utf32);
    return r;
}

BQNV GetExePath(void)
{
    WCHAR path[MAX_PATH] = {0};
    GetModuleFileNameW(NULL, path, MAX_PATH);
    return MakeWstr(path);
}

BQNV MakeState(int argc, WCHAR **argv)
{
    static const char makeState[] = "{w S x:((•file.Parent⋈•file.Name)w)∾<x}";
    BQNV makeStateV = bqn_evalCStr(makeState);

    int n = argc-1; if (n<0) n = 0;
    BQNV *args = (BQNV*)malloc(n * sizeof(BQNV));
    for (int i = 0; i < n; i++) {
        args[i] = MakeWstr(argv[i+1]);
    }
    BQNV argsV = bqn_makeObjVec(n, args);
    free(args);
    
    BQNV exePathV = GetExePath();

    BQNV r = bqn_call2(makeStateV, exePathV, argsV);
    bqn_free(makeStateV);
    bqn_free(argsV);
    bqn_free(exePathV);
    return r;
}

// owns state, should free it
BQNV bqn2exeMakeLoader(BQNV state);

#ifndef BQN2EXE_CUSTOM_LOADER
BQNV bqn2exeMakeLoader(BQNV state)
{
    static const char makeLoader[] = "{S x:b←•ReBQN{repl⇐\"none\"},x⊸B}";
    BQNV makeLoaderV = bqn_evalCStr(makeLoader);
    BQNV r = bqn_call1(makeLoaderV, state);
    bqn_free(makeLoaderV);
    bqn_free(state);
    return r;
}
#endif

#ifdef BQN2EXE_INC
#include BQN2EXE_INC
#else
static const char bqn2exeInc[] = "!\"nothing to run\"";
#endif

UINT outCP;
UINT inpCP;
void MyAtExit(void)
{
    SetConsoleOutputCP(outCP);
    SetConsoleCP(inpCP);
}

int wmain(int argc, WCHAR **argv)
{
    outCP = GetConsoleOutputCP();
    inpCP = GetConsoleCP();
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
    atexit(MyAtExit);

    bqn_init();
    BQNV loader = bqn2exeMakeLoader(MakeState(argc, argv));
    BQNV inc = bqn_makeUTF8Str(strlen(bqn2exeInc), bqn2exeInc);
    BQNV r = bqn_call1(loader, inc);
    bqn_free(r);
    bqn_free(inc);
    bqn_free(loader);
    return 0;
}
