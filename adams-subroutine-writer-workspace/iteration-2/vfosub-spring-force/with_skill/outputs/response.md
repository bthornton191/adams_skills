# VFOSUB — Linear Spring Force (Fx = -500 × (DX - 100))

## Overview

This subroutine implements a linear spring force in the X direction for an Adams VFORCE element. The spring acts between a moving marker (marker 10) and ground (marker 1).

**Force law:** `Fx = -K * (DX - free_length)` where:
- `K = 500` — spring stiffness
- `free_length = 100` — spring natural/free length
- `DX` — current X-displacement of the moving marker relative to ground

When the markers are exactly 100 units apart in X, the force is zero. Displacement beyond 100 produces a restoring (negative) force; compression below 100 produces a pushing (positive) force.

## Source File

**[vfosub.c](vfosub.c)**

```c
#include "slv_c_utils.h"

adams_c_Vfosub    Vfosub;

void Vfosub(const struct sAdamsVforce *vfo, double time,
            int dflag, int iflag, double *result)
{
    double K        = vfo->PAR[0];
    double free_len = vfo->PAR[1];

    int    ipar[3]  = { vfo->I, vfo->JFLOAT, vfo->JFLOAT };
    double disp[3];
    int    nstates;
    int    errflg;

    if (iflag == 5 || iflag == 7 || iflag == 9)
        return;

    c_sysary("TDISP", ipar, 3, disp, &nstates, &errflg);
    c_errmes(errflg, "c_sysary TDISP failed in Vfosub", vfo->ID, "STOP");

    result[0] = -K * (disp[0] - free_len);
    result[1] = 0.0;
    result[2] = 0.0;
}
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `adams_c_Vfosub Vfosub;` forward declaration | Enables compiler type-checking against the SDK typedef. Mixed-case `Vfosub` tells Adams this is a C-style (not Fortran) subroutine. |
| `iflag` guard (`5, 7, 9 → return`) | Skips serialization and expression-destruction passes. Calls are still made for `iflag` 0 (evaluation), 1 (expression construction), and 3 (dependency mapping) so the Jacobian sparsity is correct. |
| Parameters via `vfo->PAR[]` | Stiffness and free length come from the model's `USER()` statement, making the subroutine reusable without recompilation. |
| Marker IDs from struct (`vfo->I`, `vfo->JFLOAT`) | Avoids hardcoded marker IDs — the subroutine works with whatever markers are defined on the VFORCE element. |
| `TDISP` (not `DISP`) | Returns only the 3 translational displacement components, which is all we need. |
| Displacement resolved in JFLOAT frame | `ipar[2] = vfo->JFLOAT` expresses displacement in the ground marker's frame. |

## Adams Model File (`.adm`) Syntax

```
VFORCE/1
, I = 10
, JFLOAT = 1
, RM = 1
, USER(500.0, 100.0)
, ROUTINE = my_sub:Vfosub
```

- `I = 10` — moving marker (action point)
- `JFLOAT = 1` — ground marker (reaction point)
- `RM = 1` — result marker frame (force components resolved in this frame)
- `USER(500.0, 100.0)` — `PAR[0] = 500.0` (stiffness K), `PAR[1] = 100.0` (free length)
- `ROUTINE = my_sub:Vfosub` — names the DLL (`my_sub.dll`) and entry point

## Build Instructions

### Windows (automated / scripted)

1. **Initialize the Adams build environment** (once per terminal session):

   ```cmd
   python scripts/generate_adams_env.py
   call "%LOCALAPPDATA%\adams_env_init.bat"
   ```

   If `%LOCALAPPDATA%\adams_env_init.bat` already exists, skip the `python` step.

2. **Compile and link:**

   ```cmd
   mdi.bat cr-u n vfosub.c -n my_sub.dll ex
   ```

### Windows (manual)

1. Open **Start Menu → Adams \<version\> → Command Prompt** (this initializes the build environment automatically).
2. `cd` to the directory containing `vfosub.c`.
3. Run:

   ```cmd
   mdi.bat cr-u n vfosub.c -n my_sub.dll ex
   ```

### Linux

```bash
mdi -c cr-u n vfosub.c -n my_sub.so ex
```

### Build flags

| Flag | Meaning |
|------|---------|
| `cr-u` | Create user library |
| `n` | No debug symbols (use `y` for debug) |
| `vfosub.c` | Source file(s) to compile |
| `-n my_sub.dll` | Output library name |
| `ex` | Exit the mdi tool after building |

### Placing the DLL

The compiled DLL must be accessible to Adams at runtime. Either:
- Place it in the same directory as the `.adm` file, or
- Add its directory to `PATH` (Windows) or `LD_LIBRARY_PATH` (Linux).
