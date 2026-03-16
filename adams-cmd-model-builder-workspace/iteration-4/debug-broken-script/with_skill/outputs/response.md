# Bug Report: Adams CMD Script Fixes

## Bugs Found

### Bug 1 — `model cre` (line 1)
**Rule violated:** Core Rule 1 — All keywords must be spelled out in full.  
`cre` is an abbreviation of `create`. Adams CMD may accept abbreviations interactively, but the canonical script form requires the full keyword: `model create`.

---

### Bug 2 — `part cre rig nam` (line 5)
**Rule violated:** Core Rule 1 — All keywords must be spelled out in full.  
`cre`, `rig`, and `nam` are abbreviations of `create`, `rigid_body`, and `name_and_position` respectively. All three must be written in full: `part create rigid_body name_and_position`.

---

### Bug 3 — `part create rigid_body mass_properties` (line 9)
**Rule violated:** Core Rule 4 — `part create` is only called once per part; subsequent property assignments use `part modify`.  
The part `.pendulum.link` was already created in the previous block. Using `part create` again attempts to create a duplicate object, which will error. The correct command is `part modify rigid_body mass_properties`.

---

### Bug 4 — `adams_id = 3` (line 11)
**Rule violated:** Core Rule 3 — Never specify `adams_id` manually.  
Adams assigns IDs automatically. Manually specifying `adams_id` can cause ID conflicts and is disallowed. This line must be removed.

---

### Bug 5 — `center_of_mass_marker = .pendulum.link.cm` (line 13)
**Rule violated:** Core Rule 5 — Do NOT pass `center_of_mass_marker` to `part modify rigid_body mass_properties`.  
Adams automatically creates the `.part.cm` marker when mass properties are set. Passing `center_of_mass_marker` at this point references a marker that does not yet exist at command execution time, causing an error. This line must be removed.

---

### Bug 6 — `marker_name = pendulum.link.pin_mkr` (line 19)
**Rule violated:** Core Rule 2 — Object names must use the full dot-path hierarchy with a leading dot.  
`pendulum.link.pin_mkr` is missing the leading dot. The correct path is `.pendulum.link.pin_mkr`.

---

### Bug 7 — `i_marker_name = pendulum.link.pin_mkr` (line 23)
**Rule violated:** Core Rule 2 — Object names must use the full dot-path hierarchy with a leading dot.  
Same issue as Bug 6: `pendulum.link.pin_mkr` must be `.pendulum.link.pin_mkr`.

---

## Corrected Script

```
model create model_name = .pendulum

defaults units length = mm mass = kg

part create rigid_body name_and_position &
    part_name = .pendulum.link &
    location  = 0.0, 0.0, 0.0

part modify rigid_body mass_properties &
    part_name = .pendulum.link &
    mass      = 1.0 &
    ixx       = 3333.0 &
    iyy       = 3333.0 &
    izz       = 100.0

marker create &
    marker_name = .pendulum.link.pin_mkr &
    location    = 0.0, 0.0, 0.0

constraint create joint revolute &
    joint_name    = .pendulum.rev_pin &
    i_marker_name = .pendulum.link.pin_mkr &
    j_marker_name = .pendulum.ground.pin_j_mkr
```

## Summary of Changes

| # | Original | Fixed | Rule |
|---|----------|-------|------|
| 1 | `model cre` | `model create` | Rule 1: full keywords |
| 2 | `part cre rig nam` | `part create rigid_body name_and_position` | Rule 1: full keywords |
| 3 | `part create rigid_body mass_properties` | `part modify rigid_body mass_properties` | Rule 4: create once, then modify |
| 4 | `adams_id = 3` | *(removed)* | Rule 3: never set adams_id |
| 5 | `center_of_mass_marker = .pendulum.link.cm` | *(removed)* | Rule 5: cm auto-created by Adams |
| 6 | `marker_name = pendulum.link.pin_mkr` | `marker_name = .pendulum.link.pin_mkr` | Rule 2: leading dot required |
| 7 | `i_marker_name = pendulum.link.pin_mkr` | `i_marker_name = .pendulum.link.pin_mkr` | Rule 2: leading dot required |
