# Build Reference — Adams User Subroutine DLLs

## Directory Layout Convention

```
my_subroutine/
├── cbksub.c          (or .f, .cpp)
├── vfosub.c
└── build/
    └── my_subroutine.dll
```

---

## Required SDK Environment Variable

The Adams SDK root must be set. On a default Adams 2023.1 Windows install:

```powershell
$env:ADAMS_SDK = "C:\Program Files\MSC.Software\Adams\2023_1"
```

Or set permanently via System Properties → Environment Variables.

---

## C — Compile to DLL (Windows, MSVC)

```cmd
cl /LD /I"%ADAMS_SDK%\sdk\include" cbksub.c /link "%ADAMS_SDK%\sdk\lib\adams_util.lib"
```

This produces `cbksub.dll` in the current directory.

### Multiple source files

```cmd
cl /LD /I"%ADAMS_SDK%\sdk\include" cbksub.c vfosub.c /link "%ADAMS_SDK%\sdk\lib\adams_util.lib" /OUT:my_subroutines.dll
```

### Key compiler flags

| Flag | Purpose |
|------|---------|
| `/LD` | Build a DLL |
| `/I"%ADAMS_SDK%\sdk\include"` | Find `slv_cbksub.h`, `slv_cbksub_util.h`, etc. |
| `/O2` | Optimize (recommended for release) |
| `/Zi` | Debug info (use during development) |

---

## C — Compile to Shared Object (Linux, GCC)

```bash
gcc -shared -fPIC -o my_subroutines.so \
    -I"$ADAMS_SDK/sdk/include" \
    cbksub.c vfosub.c \
    -L"$ADAMS_SDK/sdk/lib" -ladams_util
```

---

## Fortran — Compile to DLL (Windows, Intel Fortran)

```cmd
ifort /dll /I"%ADAMS_SDK%\sdk\include" cbksub.f vfosub.f ^
      /link "%ADAMS_SDK%\sdk\lib\adams_util.lib"
```

### Fortran include file placement

The include files (`slv_cbksub.inc`, `slv_cbksub_util.inc`) must be findable by the compiler. Either use `/include:"%ADAMS_SDK%\sdk\include"` or copy them next to your source files.

---

## Referencing the DLL in the Adams Model (`.adm`)

```
CBKSUB/1
, USER(1.0, 2.0)
, ROUTINE=my_subroutines:Cbksub
```

- `my_subroutines` is the DLL name (without `.dll` / `.so`)
- `Cbksub` is the exported function name (case-sensitive on Linux)
- `USER(...)` parameters are accessible via `cbk->PAR[]` (0-indexed in C) or `PAR(*)` in Fortran

The DLL must be on the `PATH` (Windows) or `LD_LIBRARY_PATH` (Linux), or placed in the same directory as the `.adm` file.

---

## Exporting Functions (Windows)

On Windows, MSVC exports all functions from a `/LD` DLL by default. To be explicit, add a `.def` file:

```def
EXPORTS
    Cbksub
    Vfosub
```

Or use `__declspec(dllexport)` in the source:

```c
__declspec(dllexport) void Cbksub( const struct sAdamsCbksub *cbk,
                                    double time, int event, int *data );
```

---

## Verifying Exports

```cmd
dumpbin /exports my_subroutines.dll
```

Confirm the exported name matches exactly what the `.adm` `ROUTINE=` line specifies.

---

## Common Build Errors

| Error | Likely Cause |
|-------|-------------|
| `LNK2019: unresolved external symbol c_sysary` | Missing `adams_util.lib` in link step |
| `fatal error C1083: Cannot open include file: 'slv_cbksub.h'` | `/I` path wrong or `ADAMS_SDK` not set |
| Adams reports "cannot find routine Cbksub" | DLL not on PATH, or function name case mismatch |
| Crash at startup | C++ CBKSUB not declared `extern "C"` |

---

## CMake (optional, cross-platform)

```cmake
cmake_minimum_required(VERSION 3.20)
project(adams_user_sub C)

set(ADAMS_SDK "C:/Program Files/MSC.Software/Adams/2023_1" CACHE PATH "Adams SDK root")

add_library(my_subroutines SHARED cbksub.c vfosub.c)
target_include_directories(my_subroutines PRIVATE "${ADAMS_SDK}/sdk/include")
target_link_libraries(my_subroutines PRIVATE "${ADAMS_SDK}/sdk/lib/adams_util.lib")
```
