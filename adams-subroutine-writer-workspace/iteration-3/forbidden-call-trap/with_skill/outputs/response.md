# Calling VFOSUB from CBKSUB — Why It Fails and the Correct Pattern

## Short Answer: You Cannot Call VFOSUB from CBKSUB

VFOSUB is on CBKSUB's **forbidden call list**. Calling it from inside `Cbksub()` causes undefined behavior or a crash. The full forbidden list from the Adams SDK includes:

```
CFFSUB, CNFSUB, CONSUB, COUSUB, COUXX, COUXX2, CURSUB, DIFSUB, DMPSUB,
FIESUB, GFOSUB, GSE_DERIV, GSE_UPDATE, GSE_OUTPUT, GSE_SAMP, MFSUB,
MOTSUB, RELSUB, REQSUB, SAVSUB, SENSUB, SEVSUB, SFOSUB, SPLINE_READ,
SURSUB, TIRSUB, VARSUB, VFOSUB, VTOSUB
```

## The Correct Pattern: Cache at ev_ITERATION_BEG

What you actually want is achievable with the **CBKSUB caching pattern**:

1. In `Cbksub()` at `ev_ITERATION_BEG`, call `c_sysary()` directly to read the same solver state that your VFOSUB needs.
2. Run the same force calculation and store the result in a shared global struct.
3. In `Vfosub()`, read the cached values when available — fall back to a direct `c_sysary()` call when differencing (`dflag != 0`) or the cache is stale.

This achieves exactly what you wanted (forces pre-calculated once per iteration) without violating the forbidden call rule.

> **Key point:** CBKSUB *can* call `c_sysary` and `c_sysfnc` — but no Jacobian dependency is registered from those calls. That is intentional here: the caching is a performance pattern, and VFOSUB's own `c_sysary` calls (in the fallback path) handle Jacobian coupling correctly.

---

## Complete C Implementation

### File layout

```
cbksub.c    — defines g_vfo_cache, populates it at ev_ITERATION_BEG
vfosub.c    — extern-declares g_vfo_cache, uses it when valid
```

Both files are compiled into the same DLL.

---

### cbksub.c

```c
/* See cbksub.c in the output files */
```

### vfosub.c

```c
/* See vfosub.c in the output files */
```

---

## .adm Model File Syntax

```
$ CBKSUB element — drives the cache; PAR[0] = spring stiffness (N/mm)
CBKSUB/1
, USER(500.0)
, ROUTINE=my_forces:Cbksub

$ VFORCE element — consumes the cache
VFORCE/1
, I=101
, JFLOAT=201
, RM=101
, FUNCTION=USER(500.0, 101, 1, 1)
, ROUTINE=my_forces:Vfosub
```

> The stiffness `500.0` (N/mm) appears in both `USER()` lists and must be kept consistent.
> Replace marker IDs (`101`, `201`, `1`) with your actual model markers.

---

## Build

```cmd
call "%LOCALAPPDATA%\adams_env_init.bat"
mdi.bat cr-u n cbksub.c vfosub.c -n my_forces.dll ex
```

On Linux:

```bash
mdi -c cr-u n cbksub.c vfosub.c -n my_forces.so ex
```

---

## Summary of the Caching Logic

| Condition | Action |
|-----------|--------|
| `ev_ITERATION_BEG` fires in CBKSUB | Calls `c_sysary` → computes force → sets `g_vfo_cache.valid = 1` |
| VFOSUB called with `dflag == 0` and cache valid | Uses `g_vfo_cache` directly — no SYSARY needed |
| VFOSUB called with `dflag != 0` (differencing) | Calls `c_sysary` directly — solver needs slightly perturbed values |
| Any event other than `ev_ITERATION_BEG` | `g_vfo_cache.valid = 0` — cache invalidated |
| `iflag` is 5, 7, or 9 in VFOSUB | Returns immediately — no SYSARY, no cache read |
| `iflag` is 1 or 3 in VFOSUB | Falls through to direct `c_sysary` call — required for Jacobian sparsity mapping |
