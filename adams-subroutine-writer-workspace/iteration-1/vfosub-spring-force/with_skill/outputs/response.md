# VFOSUB — Linear Spring Force

## Task

Implement a C user subroutine for an Adams VFORCE that applies a linear spring:

```
Fx = -500 * (DX - 100)
```

- Moving marker (I): 10
- Ground marker (J): 1

## Generated Code

### vfosub.c

```c
#include "slv_c_utils.h"

adams_c_Vfosub  Vfosub;   /* forward declaration — enables compiler type-checking */

void Vfosub( const struct sAdamsVforce *vfo, double time,
             int dflag, int iflag, double *result )
{
    double stiffness   = vfo->PAR[0];
    double free_length = vfo->PAR[1];
    int    marker_i    = (int) vfo->PAR[2];
    int    marker_j    = (int) vfo->PAR[3];

    int    ipar[3];
    double disp[3];
    int    nstates;
    int    errflg;

    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    ipar[0] = marker_i;
    ipar[1] = marker_j;
    ipar[2] = marker_j;

    c_sysary( "TDISP", ipar, 3, disp, &nstates, &errflg );
    c_errmes( errflg, "SYSARY TDISP failed in Vfosub", vfo->ID, "STOP" );

    result[0] = -stiffness * ( disp[0] - free_length );
    result[1] = 0.0;
    result[2] = 0.0;
}
```

## Explanation

### Signature

Uses the modern C struct-based signature via `adams_c_Vfosub` typedef from `slv_c_utils.h`. The struct `sAdamsVforce` provides access to `ID`, `NPAR`, `PAR[]`, and marker IDs. The forward declaration `adams_c_Vfosub Vfosub;` enables the compiler to type-check the function against the Adams SDK typedef.

### iflag guard

The subroutine returns immediately when `iflag` is 5, 7, or 9. These correspond to expression destruction, serialization, and unserialization passes where SYSARY must not be called. During `iflag` 0 (normal evaluation), 1 (expression construction), and 3 (dependency mapping), the SYSARY call is executed — this is required so the solver can correctly build the Jacobian sparsity pattern.

### Displacement query

`c_sysary("TDISP", ipar, 3, disp, &nstates, &errflg)` retrieves the translational displacement of marker I (10) relative to marker J (1), expressed in the J marker's reference frame. The output `disp[0]` is DX, `disp[1]` is DY, `disp[2]` is DZ.

### Error handling

`c_errmes` checks `errflg` after the SYSARY call. If SYSARY failed, it prints the error message and halts the simulation (`"STOP"`).

### Force computation

The spring force `Fx = -500 * (DX - 100)` is applied in the x-direction; Fy and Fz are zero. The stiffness and free length are read from `PAR[]` so they can be adjusted from the `.adm` file without recompiling.

## Model File (.adm) Syntax

```
VFORCE/1
, I = 10
, JFLOAT = 1
, RM = 1
, FX = USER(500.0, 100.0, 10.0, 1.0)
, FY = 0
, FZ = 0
, ROUTINE = my_subroutines:Vfosub
```

- `USER(500.0, 100.0, 10.0, 1.0)` maps to `PAR[0..3]`: stiffness, free length, I marker, J marker.
- `ROUTINE = my_subroutines:Vfosub` — `my_subroutines` is the DLL name (without `.dll`), `Vfosub` is the function name.

## Build Commands

### Windows (MSVC)

```cmd
cl /LD /I"%ADAMS_SDK%\sdk\include" vfosub.c ^
   /link "%ADAMS_SDK%\sdk\lib\adams_util.lib" /OUT:my_subroutines.dll
```

### Linux (GCC)

```bash
gcc -shared -fPIC -I"$ADAMS_SDK/sdk/include" \
    vfosub.c \
    -L"$ADAMS_SDK/sdk/lib" -ladams_util -o my_subroutines.so
```

Ensure the `ADAMS_SDK` environment variable points to your Adams installation root (e.g., `C:\Program Files\MSC.Software\Adams\2023_1`).

Place the resulting DLL/SO in the same directory as the `.adm` file, or on `PATH` (Windows) / `LD_LIBRARY_PATH` (Linux).
