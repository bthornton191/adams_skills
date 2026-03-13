# You Cannot Call VFOSUB from CBKSUB

**VFOSUB is on the forbidden call list for CBKSUB.** Calling it will cause undefined behavior or a crash. The Adams Solver documentation explicitly prohibits calling any of these user subroutines from within CBKSUB:

> CFFSUB, CNFSUB, CONSUB, COUSUB, COUXX, COUXX2, CURSUB, DIFSUB, DMPSUB,
> FIESUB, GFOSUB, GSE_DERIV, GSE_UPDATE, GSE_OUTPUT, GSE_SAMP, MFSUB,
> MOTSUB, RELSUB, REQSUB, SAVSUB, SENSUB, SEVSUB, SFOSUB, SPLINE_READ,
> SURSUB, TIRSUB, VARSUB, **VFOSUB**, VTOSUB

## What You Should Do Instead: The Caching Pattern

The correct approach is to **move the shared computation into CBKSUB** (using `c_sysary`/`c_sysfnc`, which *are* allowed) and store the result in a shared cache. Then VFOSUB reads from the cache instead of being called directly.

CBKSUB *can* call: `c_sysary`, `c_sysfnc`, `c_errmes`, `c_rcnvrt` — these are utility routines, not user subroutines.

### cbksub.c — cache the expensive calculation at `ev_ITERATION_BEG`

```c
#include "slv_c_utils.h"
#include "slv_cbksub.h"

/* Shared cache — visible to both CBKSUB and VFOSUB */
static struct {
    double force[3];
    int    valid;
} g_cache;

adams_c_Callback Cbksub;

void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    int    ipar[3], nv, errflg;
    double states[6];

    switch ( event )
    {
        case ev_ITERATION_BEG:
            errflg  = 0;
            ipar[0] = 16;  /* marker ID       */
            ipar[1] = 1;   /* ref marker ID   */
            ipar[2] = 1;   /* result marker   */

            c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
            if ( errflg )
            {
                g_cache.valid = 0;
                return;
            }

            /* Pre-calculate the force here instead of in VFOSUB */
            g_cache.force[0] = -states[1] * 30.0;
            g_cache.force[1] = 0.0;
            g_cache.force[2] = 0.0;
            g_cache.valid    = 1;
            break;

        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;  /* MUST ignore — never read data[] */

        default:
            g_cache.valid = 0;
            break;
    }
}
```

### vfosub.c — read from the cache, with a direct-compute fallback

```c
#include "slv_c_utils.h"

/* Same cache struct — declared extern to share with cbksub.c */
extern struct {
    double force[3];
    int    valid;
} g_cache;

adams_c_VForce Vfosub;

void Vfosub( int *id, double *time, double *par, int *npar,
             int *dflag, int *iflag, double *result )
{
    int    ipar[3], nv, errflg;
    double states[6];

    /* Skip non-evaluation passes */
    if ( *iflag == 5 || *iflag == 7 || *iflag == 9 )
        return;

    /* Use cached value when not differencing */
    if ( *dflag == 0 && g_cache.valid )
    {
        result[0] = g_cache.force[0];
        result[1] = g_cache.force[1];
        result[2] = g_cache.force[2];
        return;
    }

    /* Fallback: compute directly (required during differencing, dflag=1) */
    errflg  = 0;
    ipar[0] = 16;
    ipar[1] = 1;
    ipar[2] = 1;
    c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
    c_errmes( &errflg, "c_sysary DISP failed in Vfosub", id, "STOP" );

    result[0] = -states[1] * 30.0;
    result[1] = 0.0;
    result[2] = 0.0;
}
```

## Why This Works

1. **CBKSUB fires `ev_ITERATION_BEG` before VFOSUB is called** — so the cache is always fresh at the start of each iteration.
2. **`c_sysary` is allowed inside CBKSUB** — it's a utility routine, not a user subroutine.
3. **VFOSUB still computes directly when `dflag == 1`** (differencing pass) — this is required for correct Jacobian computation. The cache is only used during normal evaluation (`dflag == 0`).
4. **No dependency registration occurs from CBKSUB** — this is intentional and correct for the caching use case.

## Build

```cmd
cl /LD /I"%ADAMS_SDK%\sdk\include" cbksub.c vfosub.c ^
   /link "%ADAMS_SDK%\sdk\lib\adams_util.lib" /OUT:my_sub.dll
```

## Model File (.adm)

```
CBKSUB/1
, USER(1.0)
, ROUTINE=my_sub:Cbksub

VFORCE/1
, ...
, ROUTINE=my_sub:Vfosub
```
