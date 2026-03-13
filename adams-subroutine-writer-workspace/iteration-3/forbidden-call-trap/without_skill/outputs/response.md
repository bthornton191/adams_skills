# Calling VFOSUB from CBKSUB to Pre-Calculate Forces

## Short Answer

The most straightforward approach is to **call your VFOSUB function directly** from within CBKSUB at the `ev_ITERATION_BEG` event. Since both subroutines are compiled into the same shared library (DLL/.so), you can simply invoke it like any other C function.

## Example

```c
#include "slv_cbksub.h"
#include "slv_cbksub_util.h"

/* Declare the VFOSUB signature so we can call it here */
extern void Vfosub(int *id, double *time, double *par, int *npar,
                   int *marker, int *dflag, int *iflag, double *result);

/* Shared cache populated by CBKSUB, consumed by VFOSUB */
double g_cached_force[6] = {0};

void Cbksub(const struct sAdamsCbksub *cbk, double time, int event, int *data)
{
    switch (event)
    {
        case 4: /* ev_ITERATION_BEG — start of each Newton-Raphson iteration */
        {
            int    id     = cbk->ID;
            int    npar   = cbk->NPAR;
            int    marker = 0;   /* fill in the appropriate marker ID */
            int    dflag  = 0;
            int    iflag  = 0;
            double result[6] = {0};

            /* Pre-calculate by calling VFOSUB directly */
            Vfosub(&id, (double*)&time, (double*)cbk->PAR, &npar,
                   &marker, &dflag, &iflag, result);

            /* Cache the result for use elsewhere */
            for (int i = 0; i < 6; i++)
                g_cached_force[i] = result[i];

            break;
        }

        default:
            break;
    }
}

void Vfosub(int *id, double *time, double *par, int *npar,
            int *marker, int *dflag, int *iflag, double *result)
{
    /*
     * If called from CBKSUB above, just compute normally.
     * If called by Adams, same logic runs — no duplication needed.
     */
    result[0] = par[0] * 100.0; /* Fx — replace with real logic */
    result[1] = 0.0;
    result[2] = 0.0;
    result[3] = 0.0;
    result[4] = 0.0;
    result[5] = 0.0;
}
```

## Why This Works

- Both `Cbksub` and `Vfosub` are plain C functions in the same translation unit (or linked library). There is nothing architecturally preventing a direct call.
- Using event `4` (`ev_ITERATION_BEG`) fires at the start of every Newton-Raphson iteration, which is exactly the right hook for pre-computation.
- The `iflag` argument lets VFOSUB know whether it is being called for a real evaluation or an initialization pass — pass `0` for a normal evaluation.

## Alternative: Shared Helper Function

If you want to avoid coupling the two subroutines, extract the force calculation into a static helper and call it from both:

```c
static void compute_force(double time, const double *par, int npar, double result[6])
{
    result[0] = par[0] * 100.0;
    /* ... */
}

void Cbksub(const struct sAdamsCbksub *cbk, double time, int event, int *data)
{
    if (event == 4) /* ev_ITERATION_BEG */
    {
        double result[6];
        compute_force(time, cbk->PAR, cbk->NPAR, result);
        /* cache result in a global */
    }
}

void Vfosub(int *id, double *time, double *par, int *npar,
            int *marker, int *dflag, int *iflag, double *result)
{
    compute_force(*time, par, *npar, result);
}
```

This is cleaner for unit-testing and avoids passing Adams-specific in/out parameters just to call a force calculation.

## Summary

| Approach | Pros | Cons |
|---|---|---|
| Direct `Vfosub(...)` call from CBKSUB | Simple, no extra code | Tight coupling; must pass correct marker/dflag/iflag |
| Shared `compute_force()` helper | Clean separation | Requires refactoring existing VFOSUB logic |
