# CBKSUB + VFOSUB: Caching Slider Y Displacement

## Overview

This solution uses two subroutines that work together:

| Subroutine | Role |
|-----------|------|
| **Cbksub** (CBKSUB) | Grabs the Y displacement of marker 5 relative to ground marker 1 once per Newton iteration and stores it in a shared global variable. |
| **Vfosub** (VFOSUB) | Reads the cached Y displacement on nominal evaluation passes (`dflag == 0`) to compute a spring force without calling `c_sysary` again. Falls back to a live `c_sysary` call during finite-differencing (`dflag == 1`). |

## How the Cache Works

1. At `ev_ITERATION_BEG`, the solver calls `Cbksub` **once** before evaluating any force elements.
2. `Cbksub` calls `c_sysary("TDISP", …)` to get the translational displacement (tx, ty, tz) of marker 5 w.r.t. marker 1, stores `tdisp[1]` (the Y component) in `g_cached_dy`, and sets `g_cache_valid = 1`.
3. When `Vfosub` is called with `iflag == 0` and `dflag == 0`, it reads `g_cached_dy` directly — no solver call needed.
4. When `iflag == 3` (dependency mapping) or `dflag == 1` (finite-differencing for Jacobian), `Vfosub` calls `c_sysary` itself to register dependencies and pick up perturbed values respectively. This keeps the Jacobian correct.

## Files

| File | Description |
|------|-------------|
| `cbksub.c` | CBKSUB — caches Y displacement at iteration start |
| `vfosub.c` | VFOSUB — applies spring force using cached value |

## Build Commands

### Windows

```cmd
mdi.bat cr-u n cbksub.c vfosub.c -n my_sub.dll ex
```

### Linux

```bash
mdi -c cr-u n cbksub.c vfosub.c -n my_sub.so ex
```

## Adams Model Syntax (`.adm`)

```adm
! ------------------------------------------------------------------
! CBKSUB — caches marker 5 Y-displacement relative to marker 1
! USER parameters: PAR[0]=moving marker (5), PAR[1]=ref marker (1)
! ------------------------------------------------------------------
CBKSUB/1
, USER(5.0, 1.0)
, ROUTINE=my_sub:Cbksub

! ------------------------------------------------------------------
! VFORCE — spring force in Y using the cached displacement
! USER parameters: PAR[0]=marker_i (5), PAR[1]=marker_j (1), PAR[2]=stiffness (k)
! Adjust stiffness (100.0) to your model requirements.
! ------------------------------------------------------------------
VFORCE/1
, I = 5
, JFLOAT = 1
, RM = 1
, FX = 0.0
, FY = 0.0
, FZ = 0.0
, USER(5.0, 1.0, 100.0)
, ROUTINE=my_sub:Vfosub
```

## Key Design Decisions

- **`TDISP` instead of `DISP`** — We only need the three translational components, so `TDISP` avoids fetching the three rotational components we'd discard.
- **Marker IDs passed via `USER()` parameters** — Both subroutines read marker IDs from `PAR[]` rather than hard-coding them, making it easy to reuse with different markers.
- **`iflag` guard in Vfosub** — Returns immediately for `iflag` values 5, 7, 9 (expression destruction, serialization, unserialization) per Adams SDK requirements. Calls for `iflag` 1 and 3 proceed normally to register solver dependencies.
- **`iflag` and `dflag` checks for cache bypass** — The cache is only used when `iflag == 0` (normal evaluation) **and** `dflag == 0` (nominal, not finite-differencing). During dependency mapping (`iflag == 3`), the solver needs to see the `c_sysary` call to build the Jacobian sparsity pattern. During finite-differencing (`dflag == 1`), the solver perturbs state variables and the cache holds the unperturbed value, so Vfosub must call `c_sysary` to get the correct perturbed displacement.
- **`ev_PRIVATE_EVENT1` / `ev_PRIVATE_EVENT2` ignored** — These internal solver events must never have their `data[]` read.
