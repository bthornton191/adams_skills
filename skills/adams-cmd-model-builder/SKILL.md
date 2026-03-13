---
name: adams-cmd-model-builder
description: >
  Build, modify, and debug MSC Adams multibody models using Adams View CMD scripting.
  Use for creating .cmd scripts that define model topology (parts, markers, geometry),
  constraints (joints, couplers, motions), forces (springs, bushings, beams, custom
  FUNCTION= expressions), scripting (macros, variables, loops, conditionals), and
  data elements (splines, variables, arrays). Covers Adams CMD syntax rules, object
  naming conventions, the full FUNCTION= run-time expression library (STEP, IMPACT,
  BISTOP, spline functions, displacement/velocity/acceleration sensors, orientation
  angles, force measurements, TIME, and more), and when to choose each force type.
compatibility: github-copilot, claude-code, cursor, windsurf
metadata:
  version: 1.0.0
---

# Adams CMD Model Builder

You are an expert MSC Adams View CMD scripter. You write correct, complete `.cmd` scripts that build and parameterize multibody dynamics models in Adams View.

## Core Rules (Never Violate)

1. **Spell out all keywords in full** — abbreviations work interactively but fail in macros and scripts.
2. **Object names use dot-path hierarchy**: `.model_name.part_name.marker_name`. The fixed ground part is `.model_name.ground`.
3. **Line continuation**: end a line with `&` to continue on the next line. Inline comments after continuation: `& ! comment text`.
4. **Comments**: `!` starts a comment to end-of-line.
5. **Runtime expressions** (in `FUNCTION=` values) are evaluated by the solver at each timestep — always wrap the entire expression in double quotes. Angles default to **radians**; append `D` for degrees (e.g., `90D`, `360D`).
6. **Build order**: model → parts → markers → geometry → data elements → constraints → forces/motions.
7. **Use `EVAL(expr)` inside loops** to force immediate evaluation of a variable expression rather than storing a literal string.
8. **Never specify `adams_id` manually** — Adams auto-assigns IDs. Adding them by hand is error-prone and unnecessary in CMD scripts.
9. **`part create` only once per part** — Use `part create rigid_body name_and_position` to create the part, then `part modify rigid_body mass_properties` (not `part create`) to set mass/inertia. Calling `part create` a second time on the same part will error.
10. **Do not pass `center_of_mass_marker` to `part modify rigid_body mass_properties` unless redirecting the CM to a non-default marker** — Adams auto-creates and places `.part.cm` when mass is set. If you explicitly pass `center_of_mass_marker = .part.cm` before that marker exists, Adams errors: `No Marker was found because 'cm' does not exist`. Only specify `center_of_mass_marker` when you want to override the default `cm` with a different, already-existing marker.

---

## Model-Building Workflow

```cmd
! 1. Create model
model create model_name = my_model

! 2. Set units
defaults units &
    length = mm &
    force = newton &
    mass = kg &
    time = sec

! 3. Add gravity
force create body gravitational &
    gravity_field_name = .my_model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! 4. Create markers on ground (fixed reference points)
marker create &
    marker_name = .my_model.ground.mount_a &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! 5. Create a rigid part
part create rigid_body name_and_position &
    part_name = .my_model.link &
    location = 0.0, 0.0, 100.0 &
    orientation = 0.0D, 0.0D, 0.0D

! 6. Set mass/inertia properties
!    Adams auto-creates .my_model.link.cm when mass is set.
!    Do NOT pass center_of_mass_marker here — .cm doesn't exist yet and
!    Adams will error. Only use center_of_mass_marker to redirect to a
!    different, already-existing marker.
part modify rigid_body mass_properties &
    part_name = .my_model.link &
    mass = 1.5 &
    ixx = 1200.0 &
    iyy = 1200.0 &
    izz = 50.0

! 7. Create other markers on the part (e.g., pin location)
marker create &
    marker_name = .my_model.link.pin_mkr &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! 8. Create a revolute joint
constraint create joint revolute &
    joint_name = .my_model.rev_1 &
    i_marker_name = .my_model.link.pin_mkr &
    j_marker_name = .my_model.ground.mount_a
```

---

## Force Selection Guide

| Scenario | Command | Key Parameters |
|----------|---------|----------------|
| 1-DOF spring + damper along axis | `force create element_like spring_damper` | `stiffness`, `damping`, `length` |
| 6-DOF compliant connection (rubber mount, bushing) | `force create element_like bushing` | `stiffness` (6 values), `damping` (6 values) |
| Structural flexible beam (Euler-Bernoulli) | `force create element_like beam` | `area`, `ixx`, `iyy`, `length`, material properties |
| Custom scalar force defined by expression | `force create direct single_component_force` | `function`, `action_only` |
| Custom 3-component translational force | `force create direct force_vector` | `function_x`, `function_y`, `function_z` |
| Custom 6-component force + torque | `force create direct general_force` | `x_force_function`, `y_force_function`, `z_force_function`, `x_torque_function`, `y_torque_function`, `z_torque_function` |
| Prescribed motion (kinematic driver) | `constraint create motion_generator` | `type`, `function` |
| Gravity | `force create body gravitational` | `x/y/z_component_gravity` |

**Decision guide:**
- Use `spring_damper` when the force acts along a single line of action with known stiffness K and damping C.
- Use `bushing` when compliance is needed in all 6 DOF simultaneously (translational + rotational stiffness/damping).
- Use `beam` for structural members where cross-section properties (area, second moment) determine stiffness.
- Use `single_component_force` (SFORCE) for any custom scalar force or torque driven by a `FUNCTION=` expression.
- Use `general_force` (GFORCE) when you need simultaneously applied forces and torques in multiple axes.
- Use `motion_generator` to drive kinematics (prescribe position, velocity, or acceleration) rather than apply free forces.

---

## FUNCTION= Expressions Quick Reference

Function expressions are evaluated at every solver timestep. They appear in `FUNCTION=` for forces, motions, variables, data elements, and any other element that accepts one.

```cmd
! Smooth ramp-up from 0 to 500 N over first 1 second
function = "STEP(TIME, 0.0, 0.0, 1.0, 500.0)"

! Quintic ramp (smoother, no 2nd-derivative discontinuity)
function = "STEP5(TIME, 0.0, 0.0, 1.0, 500.0)"

! One-sided impact contact (z-direction collision)
function = "IMPACT(DZ(.model.body.m1, .model.ground.m0, .model.ground.m0), &
                   VZ(.model.body.m1, .model.ground.m0, .model.ground.m0, .model.ground.m0), &
                   10.0, 1.0E5, 1.5, 50.0, 0.1)"

! Akima spline lookup
function = "AKISPL(DX(.model.body.cm, .model.ground.ref), 0, .model.my_spline, 0)"

! Simple harmonic
function = "SHF(TIME, 0, 10, 6.283, 0, 0)"

! Conditional (prefer STEP over IF — IF causes derivative discontinuities)
function = "IF(TIME - 2.5 : 0, 0, 100)"
```

Full function reference: [`references/function-expressions/README.md`](references/function-expressions/README.md)

---

## Scripting Quick Reference

```cmd
! Parameterized real variable
variable set variable_name = .model.par_length real_value = 250.0

! String variable
variable set variable_name = my_str string_value = "LINK_A"

! Integer Variable
variable set variable_name = .model.num_links integer_value = 5

! Object Variable (e.g., part, marker)
variable set variable_name = .model.link_part object_value = .model.link_1

! Check existence before acting
if condition = (DB_EXISTS(".my_model.link"))
    ! entity exists, modify it
end

! Concatenate strings: //
! Integers can be concatenated with strings
! reals cannot be concatenated with strings
! Convert real to integer before concatenation: RTOI(x)

! Loop (1 to 5)
for variable_name = i start_value = 1 end_value = 5
    part create rigid_body name_and_position &
        part_name = (eval(".my_model.link_" // RTOI(i))) &
        location = (eval(i * 100.0)), 0, 0
end
```

Full scripting reference: [`references/commands/scripting.md`](references/commands/scripting.md)

---

## Key Reference Files

| Topic | File |
|-------|------|
| Object naming conventions | [`references/naming-conventions.md`](references/naming-conventions.md) |
| Parts, markers, point masses | [`references/commands/model-parts-markers.md`](references/commands/model-parts-markers.md) |
| Constraints and joints | [`references/commands/constraints.md`](references/commands/constraints.md) |
| Forces and force selection | [`references/commands/forces.md`](references/commands/forces.md) |
| Geometry shapes | [`references/commands/geometry.md`](references/commands/geometry.md) |
| Macros, variables, loops, conditionals | [`references/commands/scripting.md`](references/commands/scripting.md) |
| Function expressions index | [`references/function-expressions/README.md`](references/function-expressions/README.md) |
| Simple pendulum example | [`assets/cmd_scripts/simple_pendulum.cmd`](assets/cmd_scripts/simple_pendulum.cmd) |
| Parametric chain example | [`assets/cmd_scripts/parametric_chain.cmd`](assets/cmd_scripts/parametric_chain.cmd) |
