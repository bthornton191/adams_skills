# Cam-Follower Return Spring Force — FUNCTION= Expression

## Expression

```
FUNCTION = STEP5(DX(.model.follower.tip_mkr, .model.cam.ref_mkr), 0.0, 0.0, 20.0, 500.0) - 2.0 * VX(.model.follower.tip_mkr, .model.cam.ref_mkr)
```

## Explanation

### Spring term — `STEP5(...)`

`STEP5(x, x0, h0, x1, h1)` is the smoothest built-in Adams step function. It uses a quintic (5th-order) polynomial, giving **two continuous derivatives** at the transition boundaries (compared to the cubic `STEP` which provides only one). This eliminates higher-frequency excitation during the ramp transition.

| Argument | Value | Meaning |
|---|---|---|
| `x` | `DX(.model.follower.tip_mkr, .model.cam.ref_mkr)` | Follower X-displacement (mm) relative to cam reference marker |
| `x0` | `0.0` | Start of ramp (0 mm) |
| `h0` | `0.0` | Force at start of ramp (0 N) |
| `x1` | `20.0` | End of ramp (20 mm) |
| `h1` | `500.0` | Force at end of ramp (500 N) |

- For DX < 0 mm: force = 0 N (STEP5 holds at h0)
- For 0 mm ≤ DX ≤ 20 mm: force ramps smoothly 0 → 500 N
- For DX > 20 mm: force = 500 N (STEP5 holds at h1)

### Damping term — `- 2.0 * VX(...)`

`VX(.model.follower.tip_mkr, .model.cam.ref_mkr)` returns the X-component of the follower tip marker's velocity relative to the cam reference marker. Multiplying by `2.0` gives a linear viscous damping coefficient of 2.0 N·s/mm. The negative sign ensures the damping force opposes motion (positive velocity produces a force in the negative direction).

### Full context usage example

```adams_cmd
force create direct single_component_force &
    force_name = .model.return_spring_force &
    adams_id = 1 &
    i_marker_name = .model.follower.tip_mkr &
    j_marker_name = .model.cam.ref_mkr &
    action_only = off &
    function = "STEP5(DX(.model.follower.tip_mkr,.model.cam.ref_mkr),0.0,0.0,20.0,500.0) - 2.0*VX(.model.follower.tip_mkr,.model.cam.ref_mkr)"
```
