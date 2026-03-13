# Calling VFOSUB from CBKSUB — Why You Can't, and What to Do Instead

## The Short Answer

**You cannot call VFOSUB from CBKSUB.** Adams explicitly forbids calling any user subroutine from within CBKSUB. Doing so causes undefined behavior or a crash. The full list of forbidden calls includes:

> CFFSUB, CNFSUB, CONSUB, COUSUB, COUXX, COUXX2, CURSUB, DIFSUB, DMPSUB,
> FIESUB, GFOSUB, GSE_DERIV, GSE_UPDATE, GSE_OUTPUT, GSE_SAMP, MFSUB,
> MOTSUB, RELSUB, REQSUB, SAVSUB, SENSUB, SEVSUB, SFOSUB, SPLINE_READ,
> SURSUB, TIRSUB, VARSUB, **VFOSUB**, VTOSUB

## What You Should Do Instead: The Caching Pattern

The standard approach is to **move the shared computation into CBKSUB itself** (using `c_sysary`/`c_sysfnc`, which CBKSUB *can* call), store the results in a shared cache, and then have VFOSUB read from that cache.

At `ev_ITERATION_BEG`, CBKSUB runs once per Newton iteration — before any user force subroutines are evaluated. This makes it the ideal place to pre-compute values that multiple subroutines need.

Here's the pattern:

1. **CBKSUB** queries solver state via `c_sysary` at `ev_ITERATION_BEG` and stores results in a file-scope (global) cache struct.
2. **VFOSUB** checks the cache first. If valid and not in a finite-differencing pass (`dflag == 0`), it uses the cached value. Otherwise it computes directly as a fallback.

The fallback is necessary because during finite-differencing passes (`dflag == 1`), the solver perturbs states to compute numerical Jacobians, and the cached (unperturbed) value would be incorrect.

### Example: Caching a displacement-based force

Suppose your VFOSUB computes a spring force based on marker displacement. Instead of trying to call VFOSUB from CBKSUB, you cache the displacement in CBKSUB and let VFOSUB consume it:

```c
/* force_cache.h — shared cache declaration */
#ifndef FORCE_CACHE_H
#define FORCE_CACHE_H

struct ForceCache {
    double force[3];   /* pre-computed force components */
    int    valid;       /* 1 = cache is fresh, 0 = stale */
};

extern struct ForceCache g_force_cache;

#endif
```

```c
/* cbksub.c */
#include "slv_c_utils.h"
#include "slv_cbksub.h"
#include "slv_cbksub_util.h"
#include "force_cache.h"

adams_c_Callback  Cbksub;

/* Definition of the shared cache */
struct ForceCache g_force_cache = { {0.0, 0.0, 0.0}, 0 };

void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    /* Invalidate cache on every call */
    g_force_cache.valid = 0;

    switch ( event )
    {
        case ev_ITERATION_BEG:
        {
            int    ipar[3], nv, errflg;
            double states[6];

            /* Query displacement of marker PAR[0] relative to marker PAR[1],
               expressed in marker PAR[1]'s frame.
               Replace these marker IDs with your actual model values. */
            ipar[0] = (int)cbk->PAR[0];   /* moving marker ID   */
            ipar[1] = (int)cbk->PAR[1];   /* reference marker   */
            ipar[2] = (int)cbk->PAR[1];   /* result frame       */
            errflg  = 0;

            c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
            if ( errflg )
            {
                int id = cbk->ID;
                c_errmes( &errflg, "c_sysary DISP failed in Cbksub", &id, "STOP" );
                return;
            }

            /* Pre-compute the force (example: spring Fy = -k * y) */
            g_force_cache.force[0] = 0.0;
            g_force_cache.force[1] = -states[1] * 30.0;
            g_force_cache.force[2] = 0.0;
            g_force_cache.valid    = 1;
            break;
        }

        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;   /* MUST ignore — never read data[] */

        default:
            break;
    }
}
```

```c
/* vfosub.c */
#include "slv_c_utils.h"
#include "force_cache.h"

adams_c_Vfosub  Vfosub;

void Vfosub( const struct sAdamsVforce *vfo, double time,
             int dflag, int iflag, double *result )
{
    int    ipar[3], nv, errflg;
    double states[6];

    /* Skip non-evaluation passes */
    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    /* Use the cached value when:
       - not in a finite-differencing pass (dflag == 0), AND
       - the cache is valid */
    if ( dflag == 0 && g_force_cache.valid )
    {
        result[0] = g_force_cache.force[0];
        result[1] = g_force_cache.force[1];
        result[2] = g_force_cache.force[2];
        return;
    }

    /* Fallback: compute directly.
       This path is taken during differencing (dflag == 1) and
       during dependency mapping (iflag == 1 or 3). */
    ipar[0] = (int)vfo->PAR[0];
    ipar[1] = (int)vfo->PAR[1];
    ipar[2] = (int)vfo->PAR[1];
    errflg  = 0;

    c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
    c_errmes( errflg, "c_sysary DISP failed in Vfosub", vfo->ID, "STOP" );

    result[0] = 0.0;
    result[1] = -states[1] * 30.0;
    result[2] = 0.0;
}
```

## Why This Works

- **`ev_ITERATION_BEG`** fires once per Newton iteration, before any force subroutines are called. So CBKSUB populates the cache first, then VFOSUB reads it.
- **CBKSUB can call `c_sysary` and `c_sysfnc`** — these utility routines are allowed. It just cannot call other *user subroutines* (VFOSUB, GFOSUB, etc.).
- **No Jacobian coupling from CBKSUB** — `c_sysary` calls made inside CBKSUB do not register dependencies in the Jacobian. This is by design and is fine for caching.
- **The fallback in VFOSUB** guarantees correct Jacobian computation: during finite-differencing (`dflag == 1`), the solver perturbs states, so VFOSUB must re-evaluate from the current (perturbed) solver state, not the cached value.
- **Dependency mapping** (`iflag == 1` or `3`) must still make the same `c_sysary` calls — the solver uses these to build the Jacobian sparsity pattern. That's why the fallback path doesn't skip them.

## Model File (`.adm`)

```
! CBKSUB element — passes marker IDs as USER parameters
CBKSUB/1
, USER(16.0, 1.0)
, ROUTINE=my_sub:Cbksub

! VFORCE element — same marker IDs for its own fallback path
VFORCE/1
, I=16
, JFLOAT=1
, USER(16.0, 1.0)
, ROUTINE=my_sub:Vfosub
```

## Build Instructions

### Automated (agent/script)

```cmd
python scripts/generate_adams_env.py
call "%LOCALAPPDATA%\adams_env_init.bat"
mdi.bat cr-u n cbksub.c vfosub.c -n my_sub.dll ex
```

If `%LOCALAPPDATA%\adams_env_init.bat` already exists, skip the `python` step.

### Manual (user)

1. Open **Start Menu → Adams \<version\> → Command Prompt**
2. `cd` to the directory containing your source files
3. Run:
   ```
   mdi.bat cr-u n cbksub.c vfosub.c -n my_sub.dll ex
   ```

### Linux

```bash
mdi -c cr-u n cbksub.c vfosub.c -n my_sub.so ex
```
