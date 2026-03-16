# Cam-Follower Return Spring Force Expression

## FUNCTION= Expression

```
function = "STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0) + 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)"
```

---

## Explanation

### Why STEP5 Instead of STEP

`STEP5` uses a **quintic (5th-degree) polynomial** to transition between the start and end values. This guarantees continuous first **and** second derivatives at both endpoints (x = 0 mm and x = 20 mm). By contrast, `STEP` uses only a cubic polynomial, which produces a discontinuous second derivative at the transition boundaries. In dynamic simulations — especially cam-follower mechanisms where the follower experiences rapid acceleration changes — a discontinuous second derivative causes impulsive force spikes and can cause the integrator to take very small steps or even fail. `STEP5` avoids this by ensuring the force ramps on and off with zero velocity and zero acceleration at both ends of the transition, producing a much smoother load profile.

### How the Hold-at-500 N Behavior Works

The `STEP5` function is defined as:

```
STEP5(x, x0, h0, x1, h1)
```

- When `x ≤ x0` (i.e., DX ≤ 0 mm): the function returns `h0 = 0.0 N`
- When `x0 < x < x1` (i.e., 0 mm < DX < 20 mm): the function smoothly interpolates from 0 N to 500 N using the quintic polynomial
- When `x ≥ x1` (i.e., DX ≥ 20 mm): the function **saturates** and returns `h1 = 500.0 N`

This saturation behavior is built into `STEP5` — once the argument exceeds `x1`, the output is clamped at `h1` indefinitely. No additional logic is needed to achieve the hold-at-500 N requirement.

### Damping Term

The term `2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)` adds a **velocity-proportional damping force**:

- `VX(marker1, marker2)` returns the X-velocity of `marker1` relative to `marker2` (in mm/s or consistent model units)
- Multiplying by `2.0` gives a damping coefficient of 2.0 (force units per velocity unit)
- This term opposes relative motion, dissipating energy and stabilizing the follower response — particularly important at the moment of cam contact and release where velocity transients are largest

The total force is the sum of the spring ramp (from `STEP5`) and the velocity damping term.
