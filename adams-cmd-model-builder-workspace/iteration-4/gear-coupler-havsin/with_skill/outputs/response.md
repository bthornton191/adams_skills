# Gear Coupler and Motion Generator — Adams CMD

## 1. Gear Coupler Constraint (3:1, Opposite Directions)

```cmd
constraint create coupler &
    coupler_name = .model.gear_1_2 &
    joint_name   = .model.rev_input, .model.rev_output &
    type         = rotational &
    scales       = 1.0, -0.333
```

**How the scales work:**  
The coupler enforces `scales[1]*ω1 + scales[2]*ω2 = 0`, i.e.:

```
1.0 * ω_input + (-0.333) * ω_output = 0
→ ω_output = ω_input / 0.333 = 3 * ω_input   (magnitude)
```

The negative sign on the second scale means the joints rotate in **opposite directions**. A 3:1 speed ratio (input 3× faster than output) is achieved with `scales = 1.0, -0.333`.

> **No `adams_id` is specified.** Adams will assign the identifier automatically. Omitting `adams_id` is the correct practice for coupler constraints — do not specify it.

---

## 2. Motion Generator — Haversine Velocity Ramp

```cmd
constraint create motion_generator &
    motion_name     = .model.motion_input &
    joint_name      = .model.rev_input &
    type_of_freedom = rotational &
    function        = "HAVSIN(TIME, 0.0, 0.5, 0.0, 120D)"
```

This drives the input revolute joint. The `HAVSIN` expression smoothly transitions the value from **0** to **120 degrees** between `TIME = 0.0 s` and `TIME = 0.5 s`, providing the haversine-shaped ramp. After `TIME = 0.5 s`, the value remains at `120D`.

---

## 3. HAVSIN Argument Order (Critical — Differs from STEP)

| Function | Argument Order |
|----------|---------------|
| `HAVSIN` | `HAVSIN(x, Begin_At, End_At, Initial_Value, Final_Value)` |
| `STEP`   | `STEP(x, x0, h0, x1, h1)` — values are interleaved with boundaries |

**HAVSIN:** the two boundary values come *last*, after both time boundaries:
```
HAVSIN(TIME, 0.0, 0.5, 0.0, 120D)
         ^     ^    ^     ^
         x  begin  end  init  final
```

**STEP:** each value immediately follows its corresponding boundary:
```
STEP(TIME, 0.0, 0.0, 0.5, 120D)
            ^    ^    ^    ^
           x0   h0   x1   h1
```

Using STEP argument order with HAVSIN (or vice versa) will produce incorrect transition behaviour, so care is required when switching between the two functions.

---

## 4. Note on `adams_id`

The `constraint create coupler` command does **not** include an `adams_id` parameter. Adams View assigns the numeric identifier automatically when it is omitted. Specifying `adams_id` is unnecessary and should be avoided unless there is an explicit requirement to control the internal ID numbering.
