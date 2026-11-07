#include <stdlib.h>
#include <string.h>
#include "physfs/src/physfs.h"
#include "../src/bqnffi.h"

// don't consume a
char *ReadUTF8Str(BQNV a)
{
    static BQNV toUtf8 = 0;
    if (!toUtf8) toUtf8 = bqn_evalCStr("•toUtf8");

    BQNV utf8 = bqn_call1(toUtf8, a);
    if (bqn_directArrType(utf8) != elt_c8) {
        bqn_evalCStr("!\"Expected a UTF-8 array\"");
    }
    size_t len = bqn_bound(utf8);
    const uint8_t *data = bqn_directC8(utf8);
    char *str = malloc(len + 1);
    if (!str) return NULL;
    memcpy(str, data, len);
    str[len] = '\0';
    return str;
}

BQNV mySuccess(int r)
{
    return bqn_makeF64(r!=0);
}
BQNV myNull(void)
{
    return bqn_makeChar(0);
}

BQNV MakeSint64(int64_t v)
{
    uint64_t uv = (uint64_t)v;
    uint32_t hi = (uint32_t)(uv >> 32);
    int32_t shi = (int32_t)hi;
    uint32_t lo = (uint32_t)(uv & 0xFFFFFFFF);
    return bqn_makeF64Vec(2, (double[]){shi, lo});
}

BQNV fsInit(BQNV obj, BQNV x)
{
    char *argv0 = ReadUTF8Str(x);
    int r = PHYSFS_init(argv0);
    bqn_free(obj);
    bqn_free(x);
    free(argv0);
    return mySuccess(r);
}
BQNV fsDeinit(BQNV obj, BQNV x)
{
    PHYSFS_deinit();
    bqn_free(obj);
    bqn_free(x);
    return myNull();
}
BQNV fsMkdir(BQNV obj, BQNV x)
{
    char *dir = ReadUTF8Str(x);
    int r = PHYSFS_mkdir(dir);
    bqn_free(obj);
    bqn_free(x);
    free(dir);
    return mySuccess(r);
}
BQNV fsDelete(BQNV obj, BQNV x)
{
    char *file = ReadUTF8Str(x);
    int r = PHYSFS_delete(file);
    bqn_free(obj);
    bqn_free(x);
    free(file);
    return mySuccess(r);
}
BQNV fsExists(BQNV obj, BQNV x)
{
    char *file = ReadUTF8Str(x);
    int r = PHYSFS_exists(file);
    bqn_free(obj);
    bqn_free(x);
    free(file);
    return mySuccess(r);
}
BQNV fsList(BQNV obj, BQNV x)
{
    char *dir = ReadUTF8Str(x);
    char **files = PHYSFS_enumerateFiles(dir);
    bqn_free(obj);
    bqn_free(x);
    free(dir);
    if (files == NULL) {
        return myNull();
    }

    size_t count = 0;
    for (char **it = files; *it != NULL; ++it) {
        ++count;
    }
    BQNV *filesVec = malloc(count * sizeof(BQNV));
    for (size_t i = 0; i<count; ++i) {
        filesVec[i] = bqn_makeUTF8Str(strlen(files[i]), files[i]);
    }
    BQNV r = bqn_makeObjVec(count, filesVec);
    free(filesVec);
    PHYSFS_freeList(files);
    return r;
}
BQNV fsSize(BQNV obj, BQNV x)
{
    char *file = ReadUTF8Str(x);
    PHYSFS_Stat stat;
    int r = PHYSFS_stat(file, &stat);
    bqn_free(obj);
    bqn_free(x);
    free(file);
    if (!r) {
        return myNull();
    }
    PHYSFS_sint64 size = stat.filesize;
    if (r < 0) {
        return myNull();
    }
    return MakeSint64(size);
}
BQNV fsType(BQNV obj, BQNV x)
{
    char *file = ReadUTF8Str(x);
    PHYSFS_Stat stat;
    int r = PHYSFS_stat(file, &stat);
    bqn_free(obj);
    bqn_free(x);
    free(file);
    if (!r) {
        return myNull();
    }
    PHYSFS_FileType ft = stat.filetype;
    switch (ft) {
    case PHYSFS_FILETYPE_REGULAR: return bqn_makeChar('f');
    case PHYSFS_FILETYPE_DIRECTORY: return bqn_makeChar('d');
    case PHYSFS_FILETYPE_SYMLINK: return bqn_makeChar('l');
    case PHYSFS_FILETYPE_OTHER: return bqn_makeChar('c');
    default: return myNull();
    }
}
BQNV fsGetTimes(BQNV obj, BQNV x)
{
    char *file = ReadUTF8Str(x);
    PHYSFS_Stat stat;
    int r = PHYSFS_stat(file, &stat);
    bqn_free(obj);
    bqn_free(x);
    free(file);
    if (!r) {
        return myNull();
    }
    BQNV times = bqn_makeObjVec(3, (BQNV[]){
        MakeSint64(stat.accesstime), 
        MakeSint64(stat.createtime), 
        MakeSint64(stat.modtime)
    });
    return times;
}
BQNV fsReadBytes(BQNV obj, BQNV x)
{
    char *file = ReadUTF8Str(x);
    PHYSFS_File *f = PHYSFS_openRead(file);
    bqn_free(obj);
    bqn_free(x);
    free(file);
    if (f == NULL) {
        return myNull();
    }
    PHYSFS_Stat stat;
    int r = PHYSFS_stat(file, &stat);
    if (!r) {
        PHYSFS_close(f);
        return myNull();
    }
    PHYSFS_sint64 size = stat.filesize;
    if (size < 0) {
        PHYSFS_close(f);
        return myNull();
    }
    uint8_t *buf = malloc(size);
    PHYSFS_sint64 read = PHYSFS_readBytes(f, buf, size);
    PHYSFS_close(f);
    if (read != size) {
        free(buf);
        return myNull();
    }
    BQNV out = bqn_makeC8Vec(size, buf);
    free(buf);
    return out;
}
BQNV fsWriteBytes(BQNV obj, BQNV w, BQNV x)
{
    char *file = ReadUTF8Str(w);
    size_t size = bqn_bound(x);
    uint8_t *buf = malloc(size);
    bqn_readC8Arr(x, buf);
    PHYSFS_File *f = PHYSFS_openWrite(file);
    bqn_free(obj);
    bqn_free(w);
    bqn_free(x);
    free(file);
    if (f == NULL) {
        free(buf);
        return mySuccess(0);
    }
    PHYSFS_sint64 written = PHYSFS_writeBytes(f, buf, size);
    PHYSFS_close(f);
    free(buf);
    if (written != size) {
        return mySuccess(0);
    }
    return mySuccess(1);
}
BQNV fsGetPrefDir(BQNV obj, BQNV w, BQNV x)
{
    char *org = ReadUTF8Str(w);
    char *app = ReadUTF8Str(x);
    bqn_free(obj);
    bqn_free(w);
    bqn_free(x);
    const char *dir = PHYSFS_getPrefDir(org, app);
    free(app);
    free(org);
    if (!dir) {
        return myNull();
    }
    BQNV r = bqn_makeUTF8Str(strlen(dir), dir);
    return r;
}
BQNV fsGetRealDir(BQNV obj, BQNV x)
{
    char *dir = ReadUTF8Str(x);
    bqn_free(obj);
    bqn_free(x);
    const char *realDir = PHYSFS_getRealDir(dir);
    free(dir);
    if (!realDir) {
        return myNull();
    }
    BQNV r = bqn_makeUTF8Str(strlen(realDir), realDir);
    return r;
}
BQNV fsGetWriteDir(BQNV obj, BQNV x)
{
    bqn_free(obj);
    bqn_free(x);
    const char *dir = PHYSFS_getWriteDir();
    if (!dir) {
        return myNull();
    }
    BQNV r = bqn_makeUTF8Str(strlen(dir), dir);
    return r;
}
BQNV fsSetWriteDir(BQNV obj, BQNV x)
{
    char *dir = ReadUTF8Str(x);
    int r = PHYSFS_setWriteDir(dir);
    bqn_free(obj);
    bqn_free(x);
    free(dir);
    return mySuccess(r);
}
BQNV fsUnsetWriteDir(BQNV obj, BQNV x)
{
    int r = PHYSFS_setWriteDir(NULL);
    bqn_free(obj);
    bqn_free(x);
    return mySuccess(r);
}
BQNV fsMount(BQNV obj, BQNV w, BQNV x)
{
    char *mountPoint = ReadUTF8Str(w);
    char *dir = ReadUTF8Str(x);
    bqn_free(obj);
    bqn_free(w);
    bqn_free(x);
    int r = PHYSFS_mount(dir, mountPoint, 0);
    free(dir);
    free(mountPoint);
    return mySuccess(r);
}
BQNV fsMountAppend(BQNV obj, BQNV w, BQNV x)
{
    char *mountPoint = ReadUTF8Str(w);
    char *dir = ReadUTF8Str(x);
    bqn_free(obj);
    bqn_free(w);
    bqn_free(x);
    int r = PHYSFS_mount(dir, mountPoint, 1);
    free(dir);
    free(mountPoint);
    return mySuccess(r);
}
BQNV fsUnmount(BQNV obj, BQNV w)
{
    char *dir = ReadUTF8Str(w);
    bqn_free(obj);
    bqn_free(w);
    int r = PHYSFS_unmount(dir);
    free(dir);
    return mySuccess(r);
}
BQNV fsGetLastError(BQNV obj, BQNV x)
{
    bqn_free(obj);
    bqn_free(x);
    PHYSFS_ErrorCode errCode = PHYSFS_getLastErrorCode();
    const char *err = PHYSFS_getErrorByCode(errCode);
    if (!err) {
        return myNull();
    }
    return bqn_makeUTF8Str(strlen(err), err);
}

#include "physfs-loader.inc"

extern
BQNV bqn2exeMakeLoader(BQNV state)
{
    BQNV functions[] = {
        bqn_makeBoundFn1(fsInit, myNull()),
        bqn_makeBoundFn1(fsDeinit, myNull()),
        bqn_makeBoundFn1(fsMkdir, myNull()),
        bqn_makeBoundFn1(fsDelete, myNull()),
        bqn_makeBoundFn1(fsExists, myNull()),
        bqn_makeBoundFn1(fsList, myNull()),
        bqn_makeBoundFn1(fsSize, myNull()),
        bqn_makeBoundFn1(fsType, myNull()),
        bqn_makeBoundFn1(fsGetTimes, myNull()),
        bqn_makeBoundFn1(fsReadBytes, myNull()),
        bqn_makeBoundFn2(fsWriteBytes, myNull()),
        bqn_makeBoundFn2(fsGetPrefDir, myNull()),
        bqn_makeBoundFn1(fsGetRealDir, myNull()),
        bqn_makeBoundFn1(fsGetWriteDir, myNull()),
        bqn_makeBoundFn1(fsSetWriteDir, myNull()),
        bqn_makeBoundFn1(fsUnsetWriteDir, myNull()),
        bqn_makeBoundFn2(fsMount, myNull()),
        bqn_makeBoundFn2(fsMountAppend, myNull()),
        bqn_makeBoundFn1(fsUnmount, myNull()),
        bqn_makeBoundFn1(fsGetLastError, myNull())
    };
    BQNV functionsV = bqn_makeObjVec(sizeof(functions)/sizeof(BQNV), functions);
    BQNV getLoaderV = bqn_evalCStr(loader);

    BQNV r = bqn_call2(getLoaderV, state, functionsV);
    bqn_free(getLoaderV);
    bqn_free(functionsV);
    bqn_free(state);
    return r;
}
