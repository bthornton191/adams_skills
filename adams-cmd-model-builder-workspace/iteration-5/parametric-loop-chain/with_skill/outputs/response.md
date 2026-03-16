# Parametric Spring-Damper Chain — Adams CMD Script

## Overview

This script builds a chain of 8 point masses arranged in a straight line along the X axis, each separated by 50 mm, starting at the origin. The first mass is fixed to ground. Every adjacent pair is connected by a translational spring-damper. A 2-second transient simulation is appended.

---

## Script: `parametric_chain.cmd`

### Model structure

| Element | Count | Details |
|---------|-------|---------|
| Point masses | 8 | 0.25 kg each, at X = 0, 50, 100, …, 350 mm |
| Ground constraint | 1 | Spherical joint on `mass_1` |
| Spring-dampers | 7 | K = 100 N/mm, C = 1.0 N·s/mm, L₀ = 50 mm |
| Sphere geometry | 8 | r = 5 mm, for visualisation |

### Parametric design

All chain parameters are stored in Adams variables at the top of the script:

```cmd
variable set variable_name = .chain.n_masses   real_value = 8
variable set variable_name = .chain.spacing    real_value = 50.0
variable set variable_name = .chain.pt_mass    real_value = 0.25
variable set variable_name = .chain.stiffness  real_value = 100.0
variable set variable_name = .chain.damping    real_value = 1.0
variable set variable_name = .chain.free_len   real_value = 50.0
```

To add more masses, increase `n_masses`. No other edits are needed.

### Loop pattern — mass creation

```cmd
for variable_name = i  start_value = 1  end_value = (eval(.chain.n_masses))

    part create point_mass name_and_position &
        point_mass_name = (eval(".chain.mass_" // RTOI(i))) &
        location        = ((i-1) * eval(.chain.spacing)), 0.0, 0.0

    marker create &
        marker_name = (eval(".chain.mass_" // RTOI(i) // ".cm")) &
        ...

    part modify point_mass mass_properties &
        point_mass_name       = (eval(".chain.mass_" // RTOI(i))) &
        mass                  = (eval(.chain.pt_mass)) &
        center_of_mass_marker = (eval(".chain.mass_" // RTOI(i) // ".cm"))

end
```

- `RTOI(i)` converts the loop counter to the string `"1"`, `"2"`, …, `"8"`.
- `//` concatenates the prefix `".chain.mass_"` with the index to produce `.chain.mass_1`, `.chain.mass_2`, etc.
- `EVAL()` forces Adams to evaluate the expression immediately rather than storing a literal string.
- The `.cm` marker is created **before** `mass_properties` is called; Adams requires this for point masses.

### Loop pattern — spring-dampers

```cmd
for variable_name = j  start_value = 1  end_value = (eval(.chain.n_masses - 1))

    force create element_like translational_spring_damper &
        spring_damper_name      = (eval(".chain.spr_" // RTOI(j) // "_" // RTOI(j+1))) &
        i_marker_name           = (eval(".chain.mass_" // RTOI(j) // ".cm")) &
        j_marker_name           = (eval(".chain.mass_" // RTOI(j+1) // ".cm")) &
        stiffness               = (eval(.chain.stiffness)) &
        damping                 = (eval(.chain.damping)) &
        preload                 = 0.0 &
        displacement_at_preload = (eval(.chain.free_len))

end
```

- The loop runs from 1 to 7 (n_masses − 1), producing springs `spr_1_2` through `spr_7_8`.
- `displacement_at_preload = 50 mm` sets the free length. Since the masses start exactly 50 mm apart, the initial spring force is zero.

### Ground constraint

The task requests a "fixed joint" for the first mass. Adams does not permit `constraint create joint fixed` on a point mass — only spherical, atpoint, inline, and inplane primitives are supported. A **spherical joint** is used instead: it removes all three translational DOF, and since a point mass has no rotational DOF, this fully constrains the mass (equivalent to a fixed joint for this element type).

```cmd
constraint create joint spherical &
    joint_name    = .chain.sph_gnd_1 &
    i_marker_name = .chain.mass_1.cm &
    j_marker_name = .chain.ground.anchor_mkr
```

### Simulation

```cmd
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .chain &
    initial_static  = no
```

`initial_static = no` skips the static equilibrium pre-step. The masses begin at their initial positions and immediately experience gravity, so the chain will sag and oscillate under gravity loading during the 2-second run.

---

## Expected dynamics

- At t = 0 the springs are at their natural length (no pre-load).
- Gravity (−Y) pulls each free mass downward.
- The springs resist the resulting elongation and lateral displacement, producing oscillatory motion in all three axes.
- The first mass remains stationary at the origin.
