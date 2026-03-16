# Nonlinear Rubber Mount — Approach and Design Decisions

## Why Not `force create element_like bushing`?

`bushing` accepts only **numeric constant** stiffness values per DOF. The X-direction stiffness in this problem is nonlinear (force-displacement curve), so a bushing element cannot represent it. Instead, the correct approach is:

1. Encode the nonlinear curve as a **spline data element**.
2. Evaluate the spline at runtime using **AKISPL** inside a **general force (GFORCE)**.

---

## Build Strategy

The script follows the required build order:

```
model → units → parts → mass properties → markers → data elements → constraints → forces
```

### Parts
Both `chassis` and `subframe` are created as rigid bodies at the origin with mass = 10 kg and Ixx = Iyy = Izz = 1000 kg·mm².  
`part create rigid_body name_and_position` is used first (no mass), then `part modify rigid_body mass_properties` sets inertia separately — mass is never included in the create command.

### Markers
| Marker | Part | Purpose |
|---|---|---|
| `base_mkr` | ground | J side of fixed joint |
| `ref_mkr` | chassis | I side of fixed joint |
| `mount_j_mkr` | chassis | Reference frame for GFORCE; J-side location of rubber mount |
| `mount_i_mkr` | subframe | I-marker (floating body) for GFORCE |

Both mount markers are placed at (0, 0, 50) mm so that the initial relative displacement is zero in all directions.

### Nonlinear X-Stiffness Spline
The five-point force-displacement table is stored as a spline named `.rubber_mount_model.x_stiffness`. AKISPL performs Akima cubic interpolation within the table at each solver time step.

### General Force (GFORCE)
`force create direct general_force` accepts six function strings (three forces, three torques) expressed in the frame of `ref_marker_name` (`.rubber_mount_model.chassis.mount_j_mkr`).

| DOF | Function | Notes |
|---|---|---|
| X force | `AKISPL(DX(i, j), 0, spline, 0)` | Nonlinear lookup; 4th arg = 0 → value (not derivative) |
| Y force | `-5000.0 * DY(i, j)` | Linear 5000 N/mm |
| Z force | `-5000.0 * DZ(i, j)` | Linear 5000 N/mm |
| X torque | `(-200.0 / 1D) * AX(i, j)` | 200 N·mm/deg; AX returns radians, divide by 1D (π/180) for deg |
| Y torque | `(-200.0 / 1D) * AY(i, j)` | Same conversion |
| Z torque | `(-200.0 / 1D) * AZ(i, j)` | Same conversion |

`j_part_name` (not `j_marker_name`) is used — Adams auto-creates the floating J marker on the chassis reaction part.

### Fixed Joint
A fixed joint constrains the chassis to ground using `ref_mkr` (on chassis) and `base_mkr` (on ground). `adams_id` is never specified anywhere in the script.

---

## Key Rules Observed
- All keywords spelled in full — no abbreviations.
- Object names use full dot-path hierarchy throughout.
- Every multi-line command uses `&` continuation.
- All FUNCTION= expressions are wrapped in double quotes.
- `adams_id` is never specified.
- `center_of_mass_marker` is not passed to `part modify rigid_body mass_properties`.
