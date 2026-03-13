# Cache-and-Reuse: CBKSUB + VFOSUB

## Overview

The pattern uses two subroutines compiled into the same shared library:

| Subroutine | Role |
|---|---|
| **CBKSUB** | Called once per iteration by the solver callback mechanism. Evaluates `DY(5,1)` and stores the result in a file-scope static variable. |
| **VFOSUB** | Called potentially many times per force evaluation. Reads the cached displacement via `get_cached_dy()` instead of re-calling `c_sysfnc`. |

## cbksub.c

```c
#include "slv_c_utils.h"

static double g_cached_dy = 0.0;

double get_cached_dy(void)
{
    return g_cached_dy;
}

void cbksub(int *id, double *time, double *par, int *npar,
            int *flag, int *iflag)
{
    int    markers[2];
    int    nmarks = 2;
    int    errflg = 0;
    double dy     = 0.0;

    markers[0] = 5;   /* slider marker on part 2 */
    markers[1] = 1;   /* ground marker */

    c_sysfnc("DY", markers, nmarks, &dy, &errflg);

    if (errflg != 0) {
        *iflag = 1;
        return;
    }

    g_cached_dy = dy;
    *iflag = 0;
}
```

### Key points

* `g_cached_dy` is `static` to this translation unit; other subroutines access it through the `get_cached_dy()` function.
* `c_sysfnc("DY", ...)` evaluates the Adams `DY` measure — the Y-component of translational displacement between two markers.
* If the utility call fails, the subroutine sets `*iflag = 1` so the solver knows something went wrong.

## vfosub.c

```c
#include "slv_c_utils.h"

extern double get_cached_dy(void);

void vfosub(int *id, double *time, double *par, int *npar,
            int *dflag, int *iflag, double *result)
{
    double dy        = get_cached_dy();
    double stiffness = par[0];

    result[0] =  0.0;
    result[1] = -stiffness * dy;   /* restoring spring force */
    result[2] =  0.0;

    *iflag = 0;
}
```

### Key points

* No call to `c_sysfnc` here — displacement is read from the cache, avoiding redundant evaluations.
* `par[0]` carries the spring stiffness, passed in from the Adams dataset.
* The force is applied purely in the Y direction as a simple linear spring.

## Adams dataset (.adm) setup

```adm
! ---- Callback: fires once per iteration ----
CALLBACK/1
, ROUTINE = cbksub
, FUNCTION = USER(0)
, CALLBACK_EVENT = ITEREND

! ---- Vector force using cached displacement ----
VFORCE/1
, I = 5
, JFLOAT = 1
, RM = 1
, ROUTINE = vfosub
, FUNCTION = USER(1000.0)
!                     ^ stiffness value passed as par[0]
```

* `CALLBACK_EVENT = ITEREND` ensures the cache is refreshed at the end of every corrector iteration (adjust to `STEPEND` if once-per-step is sufficient).
* Both `cbksub` and `vfosub` are compiled and linked into the same solver shared library, so the `extern` linkage of `get_cached_dy()` resolves normally.

## Build

Compile both files together into your solver library. For example on Linux:

```bash
gcc -shared -fPIC -o libusersub.so cbksub.c vfosub.c \
    -I$ADAMS_HOME/include
```

On Windows with MSVC:

```bat
cl /LD cbksub.c vfosub.c /I"%ADAMS_HOME%\include" /Fe:usersub.dll
```

Make sure the Adams SDK headers (`slv_c_utils.h`, etc.) are on your include path.
