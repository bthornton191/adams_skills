# CBKSUB + VFOSUB: Cache-and-Reuse Pattern for Adams/Solver C Subroutines

## Problem Statement

In an Adams model with a slider (marker 5 on part 2, ground reference marker 1), a VFOSUB may be evaluated many times per time step — once for each Newton-Raphson iteration and once for each partial-derivative direction Adams needs.  Calling `c_sysfnc("DY", ...)` inside VFOSUB on every evaluation is redundant when the force law only depends on the displacement at the *beginning* of the step.

The standard solution is to let a **CBKSUB** (Callback Subroutine) capture `DY` once per step and store it in a shared variable.  VFOSUB then reads that variable directly.

---

## Architecture

```
Adams Solver
│
├─ CBKSUB  (iflag == 2  →  start of each time step)
│     └─ c_sysfnc("DY", {5, 1, 0}, ...)
│           └─ writes  g_y_disp_cache
│
└─ VFOSUB  (called many times per step)
      └─ reads   g_y_disp_cache
            └─ result[1] = -k * g_y_disp_cache
```

The two files are compiled into the **same shared library** so the linker can resolve the `g_y_disp_cache` symbol between translation units.

---

## File: cbksub.c

```c
double g_y_disp_cache = 0.0;   /* definition – one copy per process */

extern void c_sysfnc(char *sysnam, int *ipar, int *nsipar,
                     double *states, int *errflg);

void CBKSUB(int *id, double *time, double *par, int *npar,
            int *dflag, int *iflag)
{
    if (*iflag != 2) return;   /* act only at start of each time step */

    int    ipar_fn[3] = {5, 1, 0};  /* DY(I=5, J=1, K=0) */
    int    nsipar     = 3;
    double dy_val     = 0.0;
    int    errflg     = 0;

    c_sysfnc("DY", ipar_fn, &nsipar, &dy_val, &errflg);
    if (errflg == 0)
        g_y_disp_cache = dy_val;
}
```

### Key details

| Item | Explanation |
|------|-------------|
| `iflag == 2` | Filters to "start of time step" only; confirmed against MSC Adams 2020+ docs. Change to `3` if you need the value refreshed after every converged iteration instead. |
| `ipar_fn[2] = 0` | Third argument to `DY` specifies the reference frame; `0` means the global (ground) frame. |
| Error guard | If `c_sysfnc` fails the old cached value is preserved — the simulation does not crash. |

---

## File: vfosub.c

```c
extern double g_y_disp_cache;   /* declaration – links to cbksub definition */

void VFOSUB(int *id, double *time, double *par, int *npar,
            int *dflag, int *iflag, double *result)
{
    double k  = par[0];           /* stiffness from FUNCTION=USER(k) */
    double dy = g_y_disp_cache;   /* cached once per step by CBKSUB  */

    result[0] = 0.0;
    result[1] = -k * dy;          /* restoring spring force along Y  */
    result[2] = 0.0;
    result[3] = 0.0;
    result[4] = 0.0;
    result[5] = 0.0;
}
```

The `result` array maps to `{Fx, Fy, Fz, Tx, Ty, Tz}` expressed in the frame of the RM marker specified on the VFORCE statement.

---

## Adams Model Commands

Add the following to your `.adm` (or run interactively in Adams/View):

```
! Register the callback subroutine
CBKSUB/1, ROUTINE=USER_LIB::cbksub

! Attach the vector force to the slider
VFORCE/1, I=5, JFLOAT=1, RM=5, &
          FUNCTION=USER(500.0), &
          ROUTINE=USER_LIB::vfosub
```

`USER(500.0)` passes stiffness `k = 500` as `par[0]`.  Add more comma-separated values for additional parameters (e.g. damping).

Replace `USER_LIB` with the name you register the shared library under (case-sensitive on Linux).

---

## Build Instructions

### Prerequisites

- MSC Adams/Solver installed (provides `slv_c_utils.h` and the export stubs)
- A C compiler visible on `PATH` (`cl.exe` on Windows, `gcc` on Linux)

### Option A — Adams-supplied build script (recommended)

Adams ships a helper that sets all compiler flags automatically:

```bash
# Linux
cd /your/source/directory
${MDI_HOME}/bin/adams2024 gcc -c cbksub.c -o cbksub.o
${MDI_HOME}/bin/adams2024 gcc -c vfosub.c -o vfosub.o
${MDI_HOME}/bin/adams2024 gcc -shared -o USER_LIB.so cbksub.o vfosub.o
```

```bat
REM Windows (Visual Studio developer prompt)
cd C:\your\source\directory
"%MDI_HOME%\bin\adams2024.bat" cl /c cbksub.c
"%MDI_HOME%\bin\adams2024.bat" cl /c vfosub.c
"%MDI_HOME%\bin\adams2024.bat" link /DLL /OUT:USER_LIB.dll cbksub.obj vfosub.obj
```

### Option B — Manual GCC (Linux)

```bash
ADAMS_INC="${MDI_HOME}/solver/src"   # adjust to your installation

gcc -c -fPIC -O2 \
    -I"${ADAMS_INC}" \
    cbksub.c -o cbksub.o

gcc -c -fPIC -O2 \
    -I"${ADAMS_INC}" \
    vfosub.c -o vfosub.o

gcc -shared -o USER_LIB.so cbksub.o vfosub.o
```

### Option C — Manual MSVC (Windows)

```bat
set ADAMS_INC=%MDI_HOME%\solver\src

cl /c /O2 /I"%ADAMS_INC%" cbksub.c
cl /c /O2 /I"%ADAMS_INC%" vfosub.c
link /DLL /OUT:USER_LIB.dll cbksub.obj vfosub.obj
```

### Loading the library in Adams

```
! In the Adams/Solver command file or interactively:
FILE/USER_LIB, NAME="C:\path\to\USER_LIB.dll"
```

On Linux use the `.so` path.  After this, the `USER_LIB::cbksub` and `USER_LIB::vfosub` routine references on the CBKSUB and VFORCE statements will resolve correctly.

---

## Threading Note

Adams/Solver can multi-thread force evaluations.  Because `g_y_disp_cache` is a plain `double` written by CBKSUB *before* any concurrent VFOSUB calls begin (the write and reads are in separate solver phases), no mutex is required in this pattern.  If you ever need to update the cache *during* force evaluation, protect it with a mutex or use the Adams user-partition mechanism.

---

## Verification Checklist

1. Run a short simulation and add a `RESULTS` request for `DY(5,1)`.
2. In post-processing, confirm that the VFOSUB output force equals $-k \times DY(5,1)$ at every output time.
3. Compare run times with and without the cache to quantify the saving (typically measurable when VFOSUB is called O(100+) times per step).
