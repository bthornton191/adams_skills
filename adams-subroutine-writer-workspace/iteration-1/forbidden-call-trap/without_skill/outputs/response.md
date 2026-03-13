# Calling VFOSUB from CBKSUB in C

To call your VFOSUB from within your CBKSUB at the start of each iteration, you can invoke it as a regular C function call since both subroutines are compiled into the same shared library (DLL/.so).

## Approach

In your CBKSUB, check for the iteration-begin event and then call your VFOSUB directly. You can store the computed forces in static or global variables so they're available later when the solver formally calls VFOSUB.

## Example Code

```c
#include "slv_cbksub.h"
#include "slv_cbksub_util.h"
#include "slv_c_utils.h"

/* Shared storage for pre-calculated forces */
static double cached_forces[3] = {0.0, 0.0, 0.0};

/* Forward declaration of your VFOSUB */
extern void vfosub_(int *id, double *time, double *par, int *npar,
                    int *dflag, int *iflag, double *result);

void Cbksub(const struct sAdamsCbksub *cbk, double time, int event, int *data)
{
    switch (event)
    {
        case 4:  /* Iteration begin */
        {
            int vfo_id = 1;          /* your VFORCE ID */
            double t = time;
            double par[1] = {0.0};
            int npar = 0;
            int dflag = 0;
            int iflag = 1;
            double result[6];

            /* Pre-calculate forces by calling VFOSUB directly */
            vfosub_(&vfo_id, &t, par, &npar, &dflag, &iflag, result);

            /* Cache results for later use */
            cached_forces[0] = result[0];
            cached_forces[1] = result[1];
            cached_forces[2] = result[2];
            break;
        }

        case 1:  /* Initialize */
            break;

        case 2:  /* Terminate */
            break;

        default:
            break;
    }
}
```

## Key Points

1. **Forward-declare your VFOSUB** with the correct signature. If it was written using Fortran naming conventions, append an underscore (`vfosub_`).

2. **Use static/global variables** to store the pre-calculated results so they're accessible from both CBKSUB and VFOSUB.

3. **Event code 4** corresponds to the beginning of each iteration — this is when you'd trigger the pre-calculation.

4. **Pass appropriate parameters** — you'll need to set up the `id`, `time`, `par`, `npar`, `dflag`, and `iflag` values that your VFOSUB expects.

5. **Build both subroutines** into the same DLL/shared library so the linker resolves the function call:
   ```
   cl /I"%ADAMS_SDK%\sdk\include" /LD cbksub.c vfosub.c /Fe:mylib.dll /link /LIBPATH:"%ADAMS_SDK%\sdk\lib" mdi.lib
   ```

## Alternative: Shared Computation via Utility Functions

If you'd rather avoid a direct call, you can compute the values you need in CBKSUB using `c_sysfnc` or `c_sysary` and store them in global/static variables. Then your VFOSUB simply reads those cached values instead of recomputing:

```c
/* In CBKSUB at iteration begin: */
double disp[6];
int nstates = 6;
int errflg;
c_sysary("DISP", marker_id, ground_id, disp, &nstates, &errflg);
/* Store in globals for VFOSUB to use */

/* In VFOSUB: */
/* Read from the same globals instead of calling c_sysary again */
```

Both approaches work — the direct call is more straightforward if you want VFOSUB to run its full calculation logic early.
