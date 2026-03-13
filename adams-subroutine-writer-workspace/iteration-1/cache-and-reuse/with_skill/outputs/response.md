# Cache-and-Reuse: CBKSUB + VFOSUB

## Overview

This solution uses two subroutines:

1. **`cbksub.c`** — A CBKSUB lifecycle callback that runs once per Newton iteration (`ev_ITERATION_BEG`). It reads the Y displacement of marker 5 relative to ground marker 1 via `c_sysary("DISP", ...)` and stores it in a global variable.

2. **`vfosub.c`** — A VFOSUB vector-force subroutine that applies a spring force `Fy = -k * y`. During normal evaluation (`dflag==0`), it reads the cached Y displacement instead of calling `c_sysary` again. During finite-differencing (`dflag==1`) or dependency-mapping passes (`iflag==1` or `3`), it falls back to a direct `c_sysary` call so the solver can build the correct Jacobian.

## Why this pattern works

- Adams calls CBKSUB at `ev_ITERATION_BEG` **before** evaluating any force subroutines for that iteration.
- VFOSUB may be called many times within a single iteration (once per force element, plus Jacobian perturbations). The cached value avoids redundant `c_sysary` calls on the nominal pass.
- The `dflag` / `iflag` guard ensures Jacobian correctness: the solver **must** see the `c_sysary("DISP", ...)` call during differencing passes so it knows VFOSUB depends on marker 5's state.
- Calling `c_sysary` from CBKSUB does **not** register a Jacobian dependency (by design), which is exactly what we want for a cache — no spurious coupling.

## How the cache flows

```
ev_ITERATION_BEG
  └─ Cbksub() runs
       └─ c_sysary("DISP") → states[1] = Y displacement
       └─ g_cached_y_disp = states[1];  g_cache_valid = 1

Force evaluation (nominal, dflag==0)
  └─ Vfosub() runs
       └─ g_cache_valid == 1 → uses g_cached_y_disp
       └─ result[1] = -k * g_cached_y_disp

Force evaluation (differencing, dflag==1)
  └─ Vfosub() runs
       └─ calls c_sysary("DISP") directly (Jacobian needs the dependency)
       └─ result[1] = -k * states[1]
```

## Model file (.adm) entries

```
! --- Callback to cache Y displacement each iteration ---
CBKSUB/1
, USER(5.0, 1.0)
, ROUTINE=my_sub:Cbksub
!  USER(1) = moving marker ID  (5, slider on part 2)
!  USER(2) = reference marker  (1, ground)

! --- Spring force on the slider ---
VFORCE/1
, I = 5
, JFLOAT = 1
, RM = 1
, FX = 0
, FY = 0
, FZ = 0
, USER(30.0, 5.0, 1.0)
, ROUTINE=my_sub:Vfosub
!  USER(1) = stiffness k = 30.0
!  USER(2) = moving marker (5)
!  USER(3) = reference marker (1, ground)
```

## Build commands

### Windows (MSVC)
```cmd
cl /LD /I"%ADAMS_SDK%\sdk\include" cbksub.c vfosub.c ^
   /link "%ADAMS_SDK%\sdk\lib\adams_util.lib" /OUT:my_sub.dll
```

### Linux (GCC)
```bash
gcc -shared -fPIC -I"$ADAMS_SDK/sdk/include" \
    cbksub.c vfosub.c \
    -L"$ADAMS_SDK/sdk/lib" -ladams_util -o my_sub.so
```

## Key design decisions

| Decision | Reason |
|----------|--------|
| Invalidate cache at every CBKSUB entry (`g_cache_valid = 0`) | Guarantees staleness is impossible — only set valid inside `ev_ITERATION_BEG` |
| Use `extern` globals (not static) | VFOSUB in a separate translation unit must see the cache |
| `c_errmes` with `"STOP"` | Halts the simulation on SYSARY failure rather than producing garbage forces |
| `iflag` guard (skip 5, 7, 9) | Required — these are non-evaluation passes where SYSARY must not be called |
| Marker IDs from `USER()` params, not hard-coded | Makes the subroutines reusable across different models |
