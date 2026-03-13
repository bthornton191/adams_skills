# Cache-and-Reuse Pattern: CBKSUB + VFOSUB for Slider Y Displacement

## Summary

Two files are delivered — `cbksub.c` and `vfosub.c` — compiled into a single DLL
(`slider_sub.dll`).  `Cbksub` runs once per Newton iteration and stores the slider's
Y displacement in a shared global.  `Vfosub` reads that global on every force
evaluation instead of calling `c_sysary` again.

---

## How it works

| Phase | What happens |
|-------|-------------|
| Every Newton iteration starts | Adams fires `ev_ITERATION_BEG` → `Cbksub` calls `c_sysary("DISP", …)` and writes `g_slider_y_disp` |
| Force evaluation (normal, `dflag=0`) | `Vfosub` checks `g_slider_cache_valid == 1` → reads the cached value directly — no solver re-entry |
| Differencing pass (`dflag≠0`) | Cache not used; `Vfosub` calls `c_sysary` directly so partial derivatives are correct |
| Dependency-mapping pass (`iflag=1/3`) | Cache is stale (invalidated at top of every `Cbksub` call); `Vfosub` falls through to `c_sysary` to register Jacobian dependencies |

---

## Model configuration

Your model has:
- **Marker 5** — on the slider body (part 2), the moving marker
- **Marker 1** — ground reference marker

Both subroutines use `ipar = { 5, 1, 1 }` for `SYSARY "DISP"`:

| `ipar` slot | Value | Meaning |
|-------------|-------|---------|
| `ipar[0]` | 5 | Moving marker (slider, part 2) |
| `ipar[1]` | 1 | Reference marker (ground) |
| `ipar[2]` | 1 | Express result in marker 1 / ground frame |

`c_sysary("DISP", …)` returns `states[6] = { tx, ty, tz, rx, ry, rz }`.
`states[1]` is the Y translational displacement — the value being cached.

---

## `cbksub.c` — full listing

```c
#include "slv_c_utils.h"
#include "slv_cbksub.h"
#include "slv_cbksub_util.h"

adams_c_Callback  Cbksub;

double g_slider_y_disp    = 0.0;
int    g_slider_cache_valid = 0;

void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    g_slider_cache_valid = 0;   /* invalidate unconditionally */

    switch ( event )
    {
        case ev_INITIALIZE:
            break;

        case ev_TERMINATE:
            break;

        case ev_ITERATION_BEG:
        {
            int    ipar[3] = { 5, 1, 1 };
            double states[6];
            int    nv, errflg;

            errflg = 0;
            c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
            if ( errflg )
            {
                int id = cbk ? cbk->ID : 0;
                c_errmes( errflg, "c_sysary DISP failed in Cbksub", id, "STOP" );
                return;
            }

            g_slider_y_disp     = states[1];
            g_slider_cache_valid = 1;
            break;
        }

        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;

        default:
            break;
    }
}
```

---

## `vfosub.c` — full listing

```c
#include "slv_c_utils.h"

extern double g_slider_y_disp;
extern int    g_slider_cache_valid;

adams_c_Vfosub  Vfosub;

void Vfosub( const struct sAdamsVforce *vfo, double time, int dflag, int iflag, double *result )
{
    double k = vfo->PAR[0];

    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    if ( dflag == 0 && g_slider_cache_valid )
    {
        result[0] = 0.0;
        result[1] = -k * g_slider_y_disp;
        result[2] = 0.0;
        return;
    }

    /* fallback: direct SYSARY (differencing + dependency mapping) */
    {
        int    ipar[3] = { 5, 1, 1 };
        double states[6];
        int    nv, errflg;

        errflg = 0;
        c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
        c_errmes( errflg, "c_sysary DISP failed in Vfosub", vfo->ID, "STOP" );

        result[0] = 0.0;
        result[1] = -k * states[1];
        result[2] = 0.0;
    }
}
```

---

## Adams model file (`.adm`) snippets

```
! Lifecycle callback — no USER() parameters needed
CBKSUB/1
, ROUTINE=slider_sub:Cbksub

! Vector force — PAR[0] is spring stiffness k
! I=5      : force application marker (slider body, part 2)
! JFLOAT=1001 : floating marker that tracks marker 5
! RM=1     : result expressed in the ground frame (marker 1)
VFORCE/1, I=5, JFLOAT=1001, RM=1
, FUNCTION=USER(5000.0)
, ROUTINE=slider_sub:Vfosub
```

> Adjust `JFLOAT` to a free marker ID that exists (or is auto-created) in
> your model.  `RM=1` keeps forces expressed in the ground frame, consistent
> with how `SYSARY "DISP"` was called.

---

## Key design decisions

### Why `ev_ITERATION_BEG` and not `ev_OUTPUT_STEP_BEG`?

Adams may call `Vfosub` multiple times per output step during the Newton
iteration loop.  `ev_ITERATION_BEG` fires **once per Newton iteration**, which
is the finest-grained synchronisation point available from `CBKSUB`.
`ev_OUTPUT_STEP_BEG` is too coarse — the cache would be stale for all
iterations within a step except the first.

### Why must the fallback path also call `c_sysary`?

During `iflag == 1` or `iflag == 3` (dependency-mapping passes) Adams builds
the Jacobian sparsity pattern by recording which state variables your
subroutine reads.  If `Vfosub` skips the `c_sysary` call on those passes, the
solver will not know that the force depends on marker 5's displacement and will
compute a structurally incorrect (incomplete) Jacobian — leading to poor
convergence or wrong results.

### Why is the cache invalidated unconditionally at the top of `Cbksub`?

Placing `g_slider_cache_valid = 0` before the `switch` ensures the flag is
cleared on **every** event, not just the events you handle.  This guards
against the cache appearing valid during `ev_INITIALIZE`, `ev_STATICS_BEG`, or
any other event that fires before `ev_ITERATION_BEG` has run in the current
context.

### `c_errmes` value semantics (not pointer)

The SDK header declares `c_errmes(int errflg, const char*, int id, const char*)`.
Both `errflg` and `id` are passed **by value** — consistent with the Adams 2023.1
SDK examples (`vfosub.c`).  The pointer form (`&errflg`, `&id`) that appears in
some older code samples is incorrect per the current header.

---

## Build

After reviewing the code above, I can compile it for you using the agent
workflow:

```cmd
python scripts/generate_adams_env.py
call "%LOCALAPPDATA%\adams_env_init.bat"
cd <directory containing cbksub.c and vfosub.c>
mdi.bat cr-u n cbksub.c vfosub.c -n slider_sub.dll ex
```

Would you like me to go ahead and run the build now?
