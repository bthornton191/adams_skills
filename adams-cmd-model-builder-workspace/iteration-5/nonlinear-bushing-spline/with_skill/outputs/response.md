# Nonlinear Rubber Mount — Adams CMD Script

## Summary

This Adams CMD script models a rubber mount between a chassis (fixed to ground) and a subframe. The X-direction stiffness is nonlinear and specified via a force-displacement table; Y and Z translational stiffness is linear at 5000 N/mm; rotational stiffness is 200 N·mm/deg about all three axes.

---

## Key Design Decision: Why a Bushing Alone Cannot Model This

The Adams `bushing` element (and `field` element) accept only **constant numeric stiffness values**. They cannot accept a FUNCTION= expression or spline reference for their stiffness — the stiffness must be a fixed scalar. This means the nonlinear X-direction force-displacement characteristic cannot be implemented directly using the bushing's Tx stiffness parameter.

**Correct approach:**
- Set the bushing's **X stiffness to 0** (the bushing contributes no X force)
- Create a `data_element spline` containing the nonlinear force-displacement table
- Apply the nonlinear X restoring force via a `force create direct force_vector` (VFORCE) that evaluates `AKISPL(...)` at each timestep

The bushing still handles the remaining 5 DOFs (Ty, Tz, Rx, Ry, Rz) with their linear stiffness values.

---

## Model Structure

### Parts

| Part | Location | Mass | Ixx = Iyy = Izz | Constraint |
|------|----------|------|-----------------|------------|
| `.rubber_mount.chassis` | 0, 0, 0 mm | 10 kg | 1000 kg·mm² | Fixed to ground |
| `.rubber_mount.subframe` | 0, 0, 0 mm | 10 kg | 1000 kg·mm² | Free (6 DOF, spring-supported) |

### Mount Markers

Both mount markers are placed at the global origin (coincident at the nominal undeformed position):

| Marker | Role |
|--------|------|
| `.rubber_mount.chassis.bush_j` | J marker (chassis side) — reference frame for bushing and VFORCE |
| `.rubber_mount.subframe.bush_i` | I marker (subframe side) — force application point |

The bushing and VFORCE both measure the relative displacement of `bush_i` with respect to `bush_j`, expressed in the chassis (`bush_j`) coordinate frame.

---

## Force Implementation

### Spline Data Element

```cmd
data_element create spline &
    spline_name = .rubber_mount.x_force_spline &
    x = -10.0, -5.0, 0.0, 5.0, 10.0 &
    y = -8000.0, -3000.0, 0.0, 3000.0, 8000.0
```

The spline encodes the reaction-force magnitude at each displacement. Its sign convention matches the displacement direction (progressive/hardening spring).

### Bushing (Y, Z, Rx, Ry, Rz)

```cmd
force create element_like bushing &
    bushing_name  = .rubber_mount.mount_bushing &
    i_marker_name = .rubber_mount.subframe.bush_i &
    j_marker_name = .rubber_mount.chassis.bush_j &
    stiffness     = 0.0, 5000.0, 5000.0, 200.0, 200.0, 200.0 &
    damping       = 0.0, 50.0, 50.0, 2.0, 2.0, 2.0
```

Stiffness vector order: `[Tx, Ty, Tz, Rx, Ry, Rz]`
- **Tx = 0** — X stiffness intentionally zero; handled by VFORCE
- **Ty = Tz = 5000 N/mm** — linear translational stiffness in Y and Z
- **Rx = Ry = Rz = 200 N·mm/deg** — rotational stiffness about all three axes

Nominal damping values (50 N·s/mm translational, 2 N·mm·s/deg rotational) added for numerical stability. These can be adjusted to match measured rubber damping loss factor.

### Nonlinear X Force — VFORCE with AKISPL

```cmd
force create direct force_vector &
    force_vector_name = .rubber_mount.x_nonlin_force &
    i_marker_name     = .rubber_mount.subframe.bush_i &
    j_part_name       = .rubber_mount.chassis &
    ref_marker_name   = .rubber_mount.chassis.bush_j &
    function_x        = "-AKISPL(DX(.rubber_mount.subframe.bush_i, &
                          .rubber_mount.chassis.bush_j, &
                          .rubber_mount.chassis.bush_j), 0, .rubber_mount.x_force_spline, 0)" &
    function_y        = "0.0" &
    function_z        = "0.0"
```

**`DX(bush_i, bush_j, bush_j)`** returns the X-component of the position of `bush_i` relative to `bush_j`, expressed in the coordinate frame of `bush_j` (the chassis frame at the mount). This is the physical relative displacement of the subframe in X.

**Restoring force on subframe:**

| DX (mm) | Spline output (N) | Applied force on subframe |
|---------|-------------------|--------------------------|
| +10 | +8000 | −8000 N (pulls back toward 0) |
| +5 | +3000 | −3000 N |
| 0 | 0 | 0 N |
| −5 | −3000 | +3000 N |
| −10 | −8000 | +8000 N |

The `−` prefix negates the spline value to produce the restoring force. An equal-and-opposite reaction is applied to the chassis via `j_part_name = .rubber_mount.chassis`.

The force components `function_y = "0.0"` and `function_z = "0.0"` ensure the VFORCE contributes no Y or Z force (those are entirely handled by the bushing).

---

## Adams CMD Core Rules Applied

- **No `adams_id`** specified anywhere — Adams auto-assigns IDs (Core Rule 8)
- **`part modify rigid_body mass_properties`** used to set mass/inertia, not `part create` a second time (Core Rule 9)
- **No `center_of_mass_marker`** passed to `part modify mass_properties` — Adams auto-creates `.cm` (Core Rule 10)
- **All keywords spelled in full** — no abbreviations (Core Rule 1)
- **Dot-path naming** throughout: `.rubber_mount.part.marker` (Core Rule 2)
- **Geometry added** to both parts (Core Rule 15) — box shapes on chassis and subframe

---

## Simulation

A 1-second free-dynamic simulation is included (`initial_static = no`). Under gravity (−Y direction), the subframe will settle at an equilibrium position determined by the combination of gravity load and the mount stiffness. The simulation can be extended and `initial_static = yes` set if a static equilibrium solve is desired before running dynamics.
