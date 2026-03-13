# Adams/Solver VFORCE Subroutine — Linear Spring

## Overview

`vfosub.c` implements an Adams/Solver **VFORCE** (vector force) user subroutine
that models a linear spring acting along the X-axis between two markers:

| Parameter | Value |
|-----------|-------|
| Force law | `Fx = -500 * (DX - 100)` |
| Stiffness k | 500 (model force/length units) |
| Free length x₀ | 100 (model length units) |
| Action marker (I) | Marker 10 (moving body) |
| Reaction marker (J) | Marker 1 (ground) |
| Fy, Fz, Tx, Ty, Tz | 0 |

---

## Files

| File | Description |
|------|-------------|
| `vfosub.c` | C source — compile into a shared library / DLL |

---

## Adams Model Setup

### Hardcoded Statement (.adm)

Add the following element to your Adams dataset:

```
VFORCE/1
, I=10
, JFLOAT=1
, FUNCTION=USER()
```

- `I=10` — the action marker on the moving body (force is applied here)
- `JFLOAT=1` — the floating reaction marker (ground); Adams creates this automatically when `JFLOAT` is used, or you can reference a fixed marker
- `FUNCTION=USER()` — no parameters are passed because the marker IDs are hardcoded in the subroutine

### Adams/View (GUI)

1. **Insert → Force → Vector Force**
2. Set **I Marker** = Marker 10, **J Marker** = Marker 1
3. Under *Function*, select **User Written Subroutine**
4. Leave the parameter list empty (the markers are hardcoded)

---

## Loading the DLL at Run Time

### Adams/View

**Settings → Solver → External Libraries** → browse to `vfosub.dll` and add it.

### Adams/Solver Command File (.acf)

```
file/user_lib = "path\to\vfosub.dll"
simulate/...
```

The `file/user_lib` command must appear **before** any `simulate` command.

### Adams/Solver Interactive

```
ACF> file/user_lib = "vfosub.dll"
```

---

## Build Instructions

### Prerequisites

- **Adams SDK headers** — typically found in `<Adams install>\sdk\include\`
  (`slv_c_utils.h`, `slv_cbksub.h`, etc.)
- A compatible C compiler (see Adams Installation Guide for the supported
  compiler version for your Adams release — mixing compiler versions can cause
  runtime crashes)

The solver utility functions (`c_sysfnc`, `c_errmes`, …) are **not linked
against a separate import library**; the Adams solver resolves them at load
time via the OS dynamic loader. No `-ladams` flag is needed.

---

### Windows — Microsoft Visual C++ (MSVC)

Open a **Developer Command Prompt** for the Visual Studio version supported by
your Adams release, then:

```bat
rem --- adjust the include path to your Adams installation ---
set ADAMS_INC=C:\MSC.Software\Adams\2024\sdk\include

cl /LD /MD /O2 ^
   /I "%ADAMS_INC%" ^
   vfosub.c ^
   /link /DLL /OUT:vfosub.dll
```

| Flag | Purpose |
|------|---------|
| `/LD` | Build a DLL |
| `/MD` | Use the Multi-threaded DLL runtime (must match Adams) |
| `/O2` | Optimise |
| `/I` | Include path for Adams SDK headers |
| `/OUT:vfosub.dll` | Output filename |

The output `vfosub.dll` (and `vfosub.lib`, `vfosub.exp`) will be placed in the
current directory. Only `vfosub.dll` is needed at run time.

---

### Windows — Adams Built-in Build Utility

Many Adams installations ship a helper script that sets up the correct compiler
environment automatically:

```bat
rem Example for Adams 2024 — path varies by installation
"C:\MSC.Software\Adams\2024\bin\adams2024.bat" gcc src=vfosub.c
```

or for the MSVC back-end:

```bat
"C:\MSC.Software\Adams\2024\bin\adams2024.bat" cl src=vfosub.c
```

This is the safest approach because it uses the exact compiler and flags that
Adams was built with.

---

### Linux — GCC

```bash
ADAMS_INC=/opt/MSC.Software/Adams/2024/sdk/include

gcc -shared -fPIC -O2 \
    -I "$ADAMS_INC" \
    -o vfosub.so \
    vfosub.c
```

Load with `file/user_lib = "vfosub.so"` in the ACF.

---

## How the Subroutine Works

```
VFOSUB called each function evaluation
│
├─ c_sysfnc("DX", {10, 1}, 2, &dx, &istat)
│     Asks the solver for the current X-displacement of marker 10
│     relative to marker 1, expressed in the ground frame.
│
├─ Check istat — abort with c_errmes if the call failed
│
└─ result[0] = -500.0 * (dx - 100.0)   ← spring force Fx
   result[1..5] = 0.0                   ← no force in Y/Z, no torques
```

### Key API: `c_sysfnc`

```c
void c_sysfnc(char *sysnam, int *ipar, int npar, double *value, int *istat);
```

| Argument | Description |
|----------|-------------|
| `sysnam` | Adams function name: `"DX"`, `"DY"`, `"DZ"`, `"VX"`, … |
| `ipar` | Integer parameter array (marker IDs for displacement functions) |
| `npar` | Length of `ipar` |
| `value` | Returned scalar value |
| `istat` | 0 = success; non-zero = error |

### Result Array Layout

```
index 0 → Fx   (force along X of I-marker frame)
index 1 → Fy
index 2 → Fz
index 3 → Tx   (torque about X)
index 4 → Ty
index 5 → Tz
```

---

## Notes and Limitations

1. **Marker IDs are hardcoded.** For a reusable subroutine, pass the IDs as
   `USER(10, 1, 500, 100)` parameters and read them from the `par` / `npar`
   arguments instead.

2. **Units.** The stiffness (500) and free length (100) must be consistent with
   the unit system defined in your Adams model (e.g. mm-N-kg or m-N-kg).

3. **Jacobian / linearisation.** Adams will finite-difference `vfosub` to form
   the stiffness matrix for eigenvalue analysis and implicit integration. No
   analytical partial derivatives are implemented here.

4. **Thread safety.** This subroutine uses only stack-allocated variables and
   is therefore thread-safe for multi-threaded Adams/Solver runs.
