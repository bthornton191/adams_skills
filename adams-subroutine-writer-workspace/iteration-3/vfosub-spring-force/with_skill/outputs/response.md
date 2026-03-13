# VFOSUB — Linear Spring Force (Fx = −500 × (DX − 100))

## Overview

This subroutine implements a linear spring force in the X direction for an Adams VFORCE element. The spring acts between a moving marker (marker 10) and a ground marker (marker 1).

**Force law:** `Fx = -K * (DX - free_length)` where:
- `K = 500` — spring stiffness (passed as `PAR[0]` via `USER()`)
- `free_length = 100` — spring natural/free length (passed as `PAR[1]`)
- `DX` — current X-displacement of marker 10 relative to marker 1, resolved in marker 1's frame

The force is zero when the markers are exactly 100 units apart. Extension beyond 100 produces a restoring (negative X) force; compression below 100 produces a pushing (positive X) force.

---

## Source File — `vfosub.c`

```c
#include "slv_c_utils.h"

adams_c_Vfosub    Vfosub;

/*
 * VFOSUB — Linear spring force acting in the X direction.
 *
 *   Fx = -K * (DX - free_length)
 *   Fy = 0
 *   Fz = 0
 *
 * USER() parameters (PAR array, 0-indexed in C):
 *   PAR[0] = K            — spring stiffness (e.g. 500)
 *   PAR[1] = free_length  — spring natural length (e.g. 100)
 *
 * VFORCE markers (set in the .adm model):
 *   I      = moving marker  (action point,   marker 10)
 *   JFLOAT = ground marker  (reaction point, marker  1)
 *   RM     = result marker  (force frame,    typically = JFLOAT)
 */
void Vfosub(const struct sAdamsVforce *vfo, double time,
            int dflag, int iflag, double *result)
{
    double K        = vfo->PAR[0];
    double free_len = vfo->PAR[1];

    /* TDISP ipar: [marker_i, marker_j, marker_k]
       marker_k = JFLOAT resolves displacement in the ground frame */
    int    ipar[3] = { vfo->I, vfo->JFLOAT, vfo->JFLOAT };
    double disp[3];
    int    nstates;
    int    errflg;

    /* Skip serialization / expression-destruction passes.
       Calls are still made for iflag 0, 1, and 3 so the
       Jacobian sparsity pattern is correctly registered.    */
    if (iflag == 5 || iflag == 7 || iflag == 9)
        return;

    /* Translational displacement of I relative to JFLOAT,
       expressed in the JFLOAT frame.
       disp[0] = DX, disp[1] = DY, disp[2] = DZ             */
    c_sysary("TDISP", ipar, 3, disp, &nstates, &errflg);
    c_errmes(errflg, "c_sysary TDISP failed in Vfosub", vfo->ID, "STOP");

    /* Linear spring: Fx = -K * (DX - free_length) */
    result[0] = -K * (disp[0] - free_len);
    result[1] = 0.0;
    result[2] = 0.0;
}
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `adams_c_Vfosub Vfosub;` forward declaration | Enables compiler type-checking against the SDK typedef. Mixed-case `Vfosub` signals to Adams that this is a C-style (not Fortran) subroutine. |
| Single `#include "slv_c_utils.h"` | This header provides `sAdamsVforce`, the `adams_c_Vfosub` typedef, and all utility function declarations (`c_sysary`, `c_errmes`). No other headers needed. |
| `iflag` guard (`5, 7, 9 → return`) | Skips serialization, unserialization, and expression-destruction passes where state access is invalid. Passes 0 (evaluation), 1 (expression construction), and 3 (dependency mapping) proceed normally so the Jacobian sparsity pattern is correctly registered. |
| `K` and `free_len` read from `vfo->PAR[]` | Stiffness and natural length come from the `USER()` statement in the model, keeping the subroutine reusable for any spring without recompilation. |
| Marker IDs from struct (`vfo->I`, `vfo->JFLOAT`) | Avoids hardcoded marker IDs — the model's `I=` and `JFLOAT=` attributes on the VFORCE statement set these at runtime. |
| `TDISP` (not `DISP`) | Returns 3 translational components only; avoids allocating 6 elements when rotations are not needed. |
| `ipar[2] = vfo->JFLOAT` | Resolves displacement components in the ground marker's frame, so `disp[0]` is the X-distance along the ground marker's X-axis. |

---

## Adams Model File (`.adm`) Syntax

```
VFORCE/1
, I = 10
, JFLOAT = 1
, RM = 1
, USER(500.0, 100.0)
, ROUTINE = my_sub:Vfosub
```

| Field | Value | Meaning |
|-------|-------|---------|
| `I` | `10` | Moving/action marker |
| `JFLOAT` | `1` | Ground/reaction marker |
| `RM` | `1` | Result marker — VFORCE components are expressed in this frame |
| `USER(500.0, 100.0)` | `PAR[0]=500`, `PAR[1]=100` | Spring stiffness and natural length |
| `ROUTINE` | `my_sub:Vfosub` | DLL name (`my_sub.dll`) and C entry point |

---

## Build — Compile to DLL

The code is ready to compile. I can run the build now using the agent workflow:

### Agent compilation (offer)

If `%LOCALAPPDATA%\adams_env_init.bat` does not yet exist, generate it first (one-time setup that finds your Adams installation):

```cmd
python scripts/generate_adams_env.py
```

Then initialize the environment and compile:

```cmd
call "%LOCALAPPDATA%\adams_env_init.bat"
mdi.bat cr-u n vfosub.c -n my_sub.dll ex
```

**Say the word and I will run these commands now.**

> If agent compilation fails for any reason, the fallback is to open **Start Menu → Adams \<version\> → Command Prompt**, `cd` to the folder containing `vfosub.c`, and run `mdi.bat cr-u n vfosub.c -n my_sub.dll ex` manually.

### Linux

```bash
mdi -c cr-u n vfosub.c -n my_sub.so ex
```

### Build flag reference

| Flag | Meaning |
|------|---------|
| `cr-u` | Create user subroutine library |
| `n` | No debug symbols (use `y` to enable) |
| `vfosub.c` | Source file(s) |
| `-n my_sub.dll` | Output library name |
| `ex` | Exit mdi after building |

### Placing the DLL

Place `my_sub.dll` in the same directory as the `.adm` file, or add its directory to `PATH`. Adams resolves `ROUTINE = my_sub:Vfosub` by searching `PATH` for `my_sub.dll` on Windows.
