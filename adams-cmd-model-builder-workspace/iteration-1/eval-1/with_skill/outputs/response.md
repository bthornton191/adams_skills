# Creating a Spring-Damper Force Between Two Parts in Adams CMD

A spring-damper force in Adams CMD connects two markers — one on each part — along their line of action. You use the `force create element_like spring_damper` command and supply the stiffness, damping, and free length directly as scalar parameters.

---

## How It Works

Adams calculates the spring-damper force as:

$$F = -K \cdot (L - L_0) - C \cdot \dot{L}$$

Where:
- $K$ = stiffness (N/mm)
- $C$ = damping coefficient (N·s/mm)
- $L$ = current distance between the two markers
- $L_0$ = free (natural) length
- Positive force = compression

The force acts along the line joining the I and J markers.

---

## Step-by-Step CMD Script

The script below shows the complete build sequence: model → parts → markers → spring-damper force. Units are mm, N, kg, s throughout.

```cmd
! ============================================================
! Spring-Damper Force Example
! K = 5000 N/mm, C = 100 N.s/mm, Free Length = 250 mm
! ============================================================

! 1. Create the model and set units
model create model_name = SPRING_MODEL

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! 2. Gravity (optional — include if dynamics simulation)
forces create body_force gravity_field &
    gravity_field_name  = .SPRING_MODEL.GRAVITY &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ============================================================
! 3. Create the two parts
! ============================================================

! Part A — fixed base (or upper mounting body)
part create rigid_body name_and_position &
    part_name   = .SPRING_MODEL.PART_A &
    adams_id    = 2 &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

part create rigid_body mass_properties &
    part_name              = .SPRING_MODEL.PART_A &
    mass                   = 5.0 &
    center_of_mass_marker  = .SPRING_MODEL.PART_A.cm &
    ixx = 1000.0 &
    iyy = 1000.0 &
    izz = 1000.0

! Part B — the moving body (e.g., suspended mass below PART_A)
part create rigid_body name_and_position &
    part_name   = .SPRING_MODEL.PART_B &
    adams_id    = 3 &
    location    = 0.0, -250.0, 0.0 &  ! 250 mm below PART_A at free length
    orientation = 0.0D, 0.0D, 0.0D

part create rigid_body mass_properties &
    part_name              = .SPRING_MODEL.PART_B &
    mass                   = 10.0 &
    center_of_mass_marker  = .SPRING_MODEL.PART_B.cm &
    ixx = 2000.0 &
    iyy = 2000.0 &
    izz = 2000.0

! ============================================================
! 4. Create the spring attachment markers
!    I-marker on PART_A, J-marker on PART_B.
!    Place them so that the initial distance equals the free length (250 mm).
! ============================================================

marker create &
    marker_name = .SPRING_MODEL.PART_A.M_SPR_I &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

marker create &
    marker_name = .SPRING_MODEL.PART_B.M_SPR_J &
    location    = 0.0, -250.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ============================================================
! 5. Create the spring-damper force
! ============================================================

force create element_like spring_damper &
    spring_damper_name = .SPRING_MODEL.SPR_MAIN &
    adams_id           = 1 &
    i_marker_name      = .SPRING_MODEL.PART_A.M_SPR_I &
    j_marker_name      = .SPRING_MODEL.PART_B.M_SPR_J &
    stiffness          = 5000.0 &
    damping            = 100.0 &
    length             = 250.0
```

---

## Key Parameters Explained

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `stiffness` | `5000.0` | Spring rate — 5000 N per mm of deformation |
| `damping` | `100.0` | Damping coefficient — 100 N·s/mm of velocity |
| `length` | `250.0` | Free (natural) length — no force when the markers are 250 mm apart |
| `i_marker_name` | On PART_A | The "action" attachment point |
| `j_marker_name` | On PART_B | The "reaction" attachment point |

---

## Important Notes

1. **Marker placement matters**: The initial distance between `M_SPR_I` and `M_SPR_J` determines the initial deformation. In the script above, both markers are 250 mm apart, matching the free length, so the initial spring force is zero.

2. **Units must be consistent**: With `length = mm` and `force = newton`, stiffness is in N/mm, damping in N·s/mm, and length in mm. Do not mix MKS values into an mm model.

3. **The spring force is always along the line joining the two markers** — the marker orientation does not affect the force direction for `spring_damper`.

4. **Pre-loaded spring**: If you want the spring to start with a preload, offset the initial marker distance from the free length. For example, placing `M_SPR_J` at `y = -300.0` (50 mm compression at start) would produce an initial force of $5000 \times 50 = 250{,}000$ N.

5. **Build order**: Always create markers before the force that references them. The order in the script above follows: model → parts → markers → forces.

---

## Verifying in Adams View

After running the script, you can verify the spring in Adams View:

- In the **Model Browser**, the spring appears under **Forces → Spring-Dampers**.
- Right-click `SPR_MAIN` → **Modify** to inspect or update K, C, and free length.
- Add a **Result Set** for `Element_Force` on `SPR_MAIN` to plot force vs. time after simulation.
