# VFOSUB — Linear Spring Force for Adams VFORCE

## Overview

This is a C user subroutine (`vfosub`) for an Adams VFORCE element. It applies a linear spring force in the x-direction:

```
Fx = -500 * (DX(10, 1) - 100)
```

Where:
- **Marker 10** is the moving marker
- **Marker 1** is the ground/reference marker
- The spring has a stiffness of 500 and a free length of 100

The other five force/torque components (Fy, Fz, Tx, Ty, Tz) are set to zero.

## Generated File

- **`vfosub.c`** — The complete VFOSUB subroutine source code.

## How It Works

1. The subroutine is called by Adams/Solver whenever it needs to evaluate the VFORCE.
2. It calls `c_sysfnc("DX", ...)` to get the x-displacement of marker 10 relative to marker 1.
3. It computes `Fx = -500 * (DX - 100)` and writes the result into `result[0]`.
4. All other components (`result[1]` through `result[5]`) are zero.

## Function Signature

```c
void vfosub_(int *id, double *time, double *par, int *npar,
             int *dflag, int *iflag, double *result)
```

| Parameter | Description |
|-----------|-------------|
| `id`      | Pointer to the VFORCE element ID |
| `time`    | Pointer to the current simulation time |
| `par`     | Array of user parameters from the .adm statement |
| `npar`    | Pointer to the number of user parameters |
| `dflag`   | Pointer to partial-derivative flag |
| `iflag`   | Pointer to initialization flag |
| `result`  | Output array of 6 doubles: [Fx, Fy, Fz, Tx, Ty, Tz] |

## Compiling to a DLL

### Windows (MSVC)

```bat
cl /c /I"%ADAMS_SDK%\include" vfosub.c
link /DLL /OUT:vfosub.dll vfosub.obj "%ADAMS_SDK%\lib\adams_utils.lib"
```

### Linux (GCC)

```bash
gcc -shared -fPIC -I$ADAMS_SDK/include -o vfosub.so vfosub.c -L$ADAMS_SDK/lib -ladams_utils
```

> **Note:** The exact SDK include/lib paths and library names depend on your Adams installation. Check your `ADAMS_SDK` or Adams installation directory for the correct paths (e.g., `<Adams_install>/sdk/`).

## Adams Model (.adm) Reference

In your `.adm` file, reference the subroutine with a VFORCE statement like:

```
VFORCE/1
, I = 10
, JFLOAT = 1
, RM = 1
, FUNCTION = USER(0)
```

And specify the DLL in the Adams model or via environment settings so the solver can find `vfosub`.

## Limitations / Notes

- The marker IDs (10 and 1) are **hard-coded** in the subroutine. For a more flexible approach, you could pass them via the `par` array from the `.adm` FUNCTION = USER(...) parameters.
- The `dflag` parameter is not handled — if Adams requests analytical partial derivatives, this subroutine won't provide them (Adams will use finite differences instead).
- The `c_sysfnc` and `c_errmes` functions are Adams SDK utility functions declared in `slv_c_utils.h`.
