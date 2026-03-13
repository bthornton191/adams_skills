# Adams VFORCE User Subroutine: Linear Spring

## Overview

This is a C user subroutine (`VFOSUB`) for an Adams VFORCE element that applies a linear spring force in the X direction:

```
Fx = -500 * (DX - 100)
```

- **Moving marker:** 10
- **Ground marker:** 1
- **Spring stiffness:** 500
- **Free length:** 100

The force is computed using the `DX` system function to get the X-displacement of marker 10 relative to marker 1. All other force and torque components (Fy, Fz, Tx, Ty, Tz) are set to zero.

## Source Code

The complete source is in `vfosub.c`.

### Key Details

- **Function name:** `vfosub_` (lowercase with trailing underscore, per Adams C subroutine naming convention)
- **Signature:** `void vfosub_(int *id, double *time, double *par, int *npar, int *dflag, int *iflag, double *result)`
- **Result array:** 6-element array — `[Fx, Fy, Fz, Tx, Ty, Tz]`
- **Utility functions used:**
  - `c_sysfnc` — evaluates Adams system functions (e.g., `DX`)
  - `c_errmes` — reports errors back to the solver
- **iflag handling:** When `iflag != 0`, the subroutine returns zero-initialized results for initialization purposes.

## Build Instructions

### Prerequisites

- **Adams installation** with the Solver SDK (headers and libraries)
- **C compiler:** Microsoft Visual C++ (MSVC) on Windows, or GCC on Linux
- Adams environment variables set (run the Adams environment setup script first)

### Windows (MSVC)

1. Open a Visual Studio Developer Command Prompt.

2. Set up the Adams environment by running the Adams configuration script:
   ```
   call "%ADAMS_HOME%\bin\adams_env.bat"
   ```

3. Compile and link the DLL:
   ```
   cl /LD /I"%ADAMS_HOME%\include" vfosub.c /Fe:vfosub.dll "%ADAMS_HOME%\lib\adams_solver_c.lib"
   ```

   - `/LD` — produce a DLL
   - `/I` — include directory for Adams headers (`slv_c_utils.h`, etc.)
   - `/Fe:` — output DLL name
   - Link against the Adams solver library

### Linux (GCC)

1. Source the Adams environment:
   ```bash
   source $ADAMS_HOME/bin/adams_env.sh
   ```

2. Compile to a shared library:
   ```bash
   gcc -shared -fPIC -I$ADAMS_HOME/include -o vfosub.so vfosub.c -L$ADAMS_HOME/lib -ladams_solver_c
   ```

### Using the DLL in Adams

In your Adams model, reference the compiled library on the VFORCE statement:

```
VFORCE/1
, I = 10
, JFLOAT = 1
, RM = 1
, ROUTINE = vfosub::vfosub
, USER(0)
```

Or in Adams/View, set the VFORCE properties to point to the user subroutine library and function name.

## Notes

- The marker IDs (10 and 1) are hardcoded in the subroutine. For a more flexible approach, pass them via the `USER()` parameter array on the VFORCE statement and read them from `par`.
- The free length (100) and stiffness (500) are also hardcoded. These could similarly be parameterized through the `USER()` array.
- The `dflag` parameter indicates whether partial derivatives are being requested. This simple implementation does not compute analytical partial derivatives; the solver will use finite differencing instead.
