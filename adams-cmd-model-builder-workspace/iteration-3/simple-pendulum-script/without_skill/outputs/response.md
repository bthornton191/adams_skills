# Simple Pendulum — Adams/View CMD Script

## Approach

To model a simple pendulum in Adams/View, the script needs to:

1. **Create the model** and set units to mm/kg/N/s (MMKS system).
2. **Set gravity** to −9806.65 mm/s² in the Y direction.
3. **Define the ground pivot marker** at the world origin (0, 0, 0).
4. **Create the pendulum rigid body** (Part 2) with the correct mass and inertia, placed at its initial 45-degree position.
5. **Add markers** on the pendulum: one at the pivot (top of link) and one at the CM (midpoint).
6. **Create a revolute joint** connecting the top-of-link marker to the ground marker — constraining all DOF except rotation about Z.
7. **Run a 5-second dynamic simulation**.

---

## Key Physical Properties

| Property | Value |
|---|---|
| Link length | 200 mm |
| Link mass | 1 kg |
| CM location | 100 mm below pivot (midpoint) |
| Gravity | −9806.65 mm/s² in Y |
| Initial angle | 45° from vertical |
| Izz (about CM) | m·L²/12 = 1 × 200² / 12 = **3333.33 kg·mm²** |

### Initial CM position at 45°

With the pivot at the origin and the pendulum displaced 45° from the downward vertical:

```
X_cm =  100 · sin(45°) =  70.711 mm
Y_cm = −100 · cos(45°) = −70.711 mm
```

The pendulum link bottom end is at (141.421, −141.421, 0) mm.

---

## Notes on Syntax

- Adams/View CMD uses `&` for line continuation.
- Comments begin with `!`.
- Object names follow the dotted hierarchy: `.model_name.part_name.marker_name`.
- The `ground` part always exists implicitly; you only need to add markers to it.
- `part create rigid_body name_and_position` sets initial location/orientation; `mass_properties` sets inertia.
- The revolute joint's `i_marker` (on the moving part) and `j_marker` (on ground) must be coincident and aligned at the start of the simulation — both are placed at (0, 0, 0).
- `simulation single_run` with `initial_static = no` releases from the specified position without first finding static equilibrium, which is required for this "released from 45°" scenario.

---

## Generated Script

See [`pendulum.cmd`](pendulum.cmd) for the complete Adams/View CMD script.
