# Calling VFOSUB from CBKSUB in Adams/Solver C Subroutines

## Overview

To call your VFOSUB at the start of each iteration from your CBKSUB, there are a few approaches you can take. The most straightforward is to **directly call your VFOSUB function** from within your CBKSUB, since in C they are simply functions you can invoke. However, you need to be mindful of how you structure this.

## Recommended Approach: Shared Computation with Direct Call

The cleanest approach is to **extract your force calculation logic into a shared helper function**, then call it from both your CBKSUB (for pre-calculation) and your VFOSUB (for returning forces to the solver).

### Step 1: Create a Shared Force Calculation Function

```c
#include "slv_c_utils.h"

/* Shared state for pre-calculated forces */
static double precalc_fx = 0.0;
static double precalc_fy = 0.0;
static double precalc_fz = 0.0;
static int forces_valid = 0;

/* Shared force computation logic */
void compute_my_forces(double time, double *fx, double *fy, double *fz)
{
    /* Your force calculation logic here */
    /* Use c_sysfnc, c_sysary, c_rcnvrt, etc. to get state info */
    
    double marker_pos[3];
    int nstates = 3;
    int errflg = 0;
    
    /* Example: get displacement of a marker */
    c_sysary("DISP", marker_id, jflag, &marker_pos[0], &nstates, &errflg);
    
    *fx = -100.0 * marker_pos[0];  /* example spring force */
    *fy = -100.0 * marker_pos[1];
    *fz = -100.0 * marker_pos[2];
}
```

### Step 2: CBKSUB — Call at Start of Each Iteration

```c
#include "slv_c_utils.h"

void cbksub(int *itype, double *par, int *npar, int *flags, int *nflags,
            double *states, int *nstates, int *errflg)
{
    double time;
    int iflag = 0;
    
    *errflg = 0;
    
    /* itype indicates the callback event:
     * 1 = beginning of simulation
     * 2 = beginning of a step  
     * 3 = beginning of an iteration
     * 4 = end of an iteration
     * 5 = end of a step
     * 6 = end of simulation
     */
    
    if (*itype == 3)  /* Beginning of iteration */
    {
        /* Get current simulation time */
        c_sysfnc("TIME", &par[0], 0, &time, &errflg);
        
        /* Pre-calculate forces by calling VFOSUB directly */
        {
            /* Set up the arguments your VFOSUB expects */
            int id = 1;          /* VFORCE ID */
            double vfopar[1];    /* parameters from VFORCE statement */
            int nvfopar = 0;
            double dflag = 0.0;
            double iflag_d = 0.0;
            double result[3] = {0.0, 0.0, 0.0};
            
            /* Call VFOSUB directly to pre-compute forces */
            vfosub(&id, &time, vfopar, &nvfopar, &dflag, &iflag_d,
                   result, errflg);
            
            /* Store results in shared/cached variables if needed */
            precalc_fx = result[0];
            precalc_fy = result[1];
            precalc_fz = result[2];
            forces_valid = 1;
        }
    }
}
```

### Step 3: VFOSUB — Use Pre-Calculated Values or Compute Fresh

```c
#include "slv_c_utils.h"

void vfosub(int *id, double *time, double *par, int *npar,
            int *dflag, int *iflag, double *result, int *errflg)
{
    *errflg = 0;
    
    if (forces_valid)
    {
        /* Use pre-calculated values from CBKSUB */
        result[0] = precalc_fx;
        result[1] = precalc_fy;
        result[2] = precalc_fz;
    }
    else
    {
        /* Compute forces directly */
        compute_my_forces(*time, &result[0], &result[1], &result[2]);
    }
}
```

## Alternative: Direct Function Call (Simpler)

If you don't need the caching pattern, you can simply call your `vfosub` function directly from `cbksub`:

```c
void cbksub(int *itype, double *par, int *npar, int *flags, int *nflags,
            double *states, int *nstates, int *errflg)
{
    *errflg = 0;
    
    if (*itype == 3)  /* Beginning of iteration */
    {
        double time;
        int vfo_id = 1;
        double vfo_par[1];
        int vfo_npar = 0;
        int dflag = 0;
        int iflag = 0;
        double result[3];
        
        c_sysfnc("TIME", &par[0], 0, &time, errflg);
        
        /* Call VFOSUB directly */
        vfosub(&vfo_id, &time, vfo_par, &vfo_npar, &dflag, &iflag, 
               result, errflg);
        
        /* result[] now contains the pre-calculated forces */
        /* You can store/log/use them as needed */
    }
}
```

## Build Instructions

### On Linux

```bash
# Compile the subroutines into a shared library
gcc -shared -fPIC -o libusrsub.so cbksub.c vfosub.c \
    -I${ADAMS_HOME}/include \
    -L${ADAMS_HOME}/lib -ladams

# Or compile as object files for linking
gcc -c -fPIC cbksub.c -I${ADAMS_HOME}/include -o cbksub.o
gcc -c -fPIC vfosub.c -I${ADAMS_HOME}/include -o vfosub.o
gcc -shared -o libusrsub.so cbksub.o vfosub.o -L${ADAMS_HOME}/lib -ladams
```

### On Windows

```bat
REM Using MSVC
cl /LD /I "%ADAMS_HOME%\include" cbksub.c vfosub.c /Fe:usrsub.dll /link /LIBPATH:"%ADAMS_HOME%\lib" adams.lib
```

### Running with Adams

Reference the compiled library in your Adams model:

```
CALLBACK/1, ROUTINE=cbksub
VFORCE/1, ..., ROUTINE=vfosub
```

Or specify at runtime:

```bash
adamssolve model.adm library=libusrsub.so
```

## Important Notes

1. **Function visibility**: Since both `cbksub` and `vfosub` are in your user library, they are visible to each other. Make sure the function signatures match exactly.

2. **Shared state**: Use `static` file-scope variables or a shared header to pass pre-calculated data between subroutines.

3. **Thread safety**: If running in a multi-threaded context, be careful with shared static variables. Consider using thread-local storage if needed.

4. **Iteration convergence**: Be aware that pre-calculating at the start of each iteration means the forces may be based on values from the previous iteration. This is generally fine for caching/optimization but could affect convergence if the solver expects consistent force evaluations.

5. **The `dflag` and `iflag` parameters**: When calling VFOSUB from CBKSUB, set `dflag=0` (no derivatives needed) and `iflag=0` (normal evaluation). The solver sets these when it calls VFOSUB directly.
