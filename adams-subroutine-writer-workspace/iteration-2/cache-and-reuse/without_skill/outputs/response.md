# Cache-and-Reuse: CBKSUB + VFOSUB (Without Skill)

## Overview

This solution uses a **CALLBACK subroutine (CBKSUB)** to evaluate the Y-displacement of marker 5 relative to ground marker 1 once per corrector pass. The result is stored in a global variable that the **VFOSUB** reads directly, avoiding repeated `c_sysfnc` calls every time the force is evaluated.

---

## How It Works

1. **CBKSUB** is registered with `CALLBACK_EVENT = CORRECTOR_PASS` so it fires once per iteration.
2. Inside CBKSUB, `c_sysfnc("DY", ...)` evaluates `DY(5, 1)` and writes the result to the global variable `cached_dy_marker5`.
3. **VFOSUB** declares `cached_dy_marker5` as `extern` and reads it directly — no solver-function call required.

---

## Source Files

### cbksub.c

```c
#include "slv_c_utils.h"

double cached_dy_marker5 = 0.0;

void cbksub_(int *id, double *time, double *par, int *npar,
             int *istate, int *nflag, int *errflg)
{
    double args[2];
    int    nargs = 2;

    *errflg = 0;

    args[0] = 5.0;
    args[1] = 1.0;

    c_sysfnc("DY", args, &nargs, &cached_dy_marker5, errflg);

    if (*errflg != 0) {
        c_errmes(1, "Error in CBKSUB: c_sysfnc(DY) failed", *id, "CBKSUB");
    }
}
```

### vfosub.c

```c
#include "slv_c_utils.h"

extern double cached_dy_marker5;

void vfosub_(int *id, double *time, double *par, int *npar,
             int *dflag, int *iflag, double *result)
{
    double k  = par[0];
    double dy = cached_dy_marker5;

    result[0] = 0.0;
    result[1] = -k * dy;
    result[2] = 0.0;
}
```

---

## Adams Dataset Statements

Add these to your Adams model (`.adm` file):

```
! -- Callback to cache DY(5,1) once per iteration --
CALLBACK/1
, ROUTINE = cbksub
, FUNCTION = USER(0)
, CALLBACK_EVENT = CORRECTOR_PASS

! -- Vector force using the cached displacement --
VFORCE/1
, I = 5
, JFLOAT = 1
, RM = 1
, FUNCTION = USER(1000.0)
```

- `USER(1000.0)` passes the spring stiffness *k = 1000 N/m* as `par[0]` to VFOSUB. Adjust as needed.

---

## Build Instructions

### Prerequisites

- MSC Adams installation (with Solver SDK headers: `slv_c_utils.h`, etc.)
- A C compiler (MSVC on Windows, GCC on Linux)

### Windows (MSVC)

```bat
REM Set up Adams environment variables (adjust path to your install)
call "C:\MSC.Software\Adams\2023\common\mdi.bat"

REM Compile both source files into object files
cl /c /I"%ADAMS_INSTALL%\solver\include" cbksub.c vfosub.c

REM Link into a shared library
link /DLL /OUT:myusrsubs.dll cbksub.obj vfosub.obj ^
     "%ADAMS_INSTALL%\solver\lib\slv_c_utils.lib"
```

### Linux (GCC)

```bash
# Source the Adams environment
source /opt/MSC.Software/Adams/2023/common/mdi.sh

# Compile
gcc -fPIC -c -I"$ADAMS_INSTALL/solver/include" cbksub.c vfosub.c

# Link into a shared library
gcc -shared -o myusrsubs.so cbksub.o vfosub.o \
    -L"$ADAMS_INSTALL/solver/lib" -lslv_c_utils
```

### Running the Model

Point Adams Solver at your library when executing:

```
adams_solver input=model.adm lib=myusrsubs.dll   (Windows)
adams_solver input=model.adm lib=myusrsubs.so    (Linux)
```

Or set the `ADAMS_USR_LIB` environment variable to the path of your compiled library.

---

## Notes

- The global `cached_dy_marker5` is defined in `cbksub.c` and referenced via `extern` in `vfosub.c`. Both files must be linked into the same shared library for this to work.
- The CBKSUB fires once per corrector pass, so displacement is evaluated once per iteration regardless of how many times VFOSUB is called during that iteration.
- Modify the force law in `vfosub.c` (the `result[]` assignments) to match your actual force model. The simple spring `Fy = -k * dy` is provided as an example.
