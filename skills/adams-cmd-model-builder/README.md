# Adams CMD Model Builder Skill

A complete reference for building MSC Adams multibody dynamics models using Adams View CMD scripting.

## What this skill covers

- **CMD syntax rules** — keywords, dot-path object names, line continuation, comments, `EVAL()`
- **Build workflow** — model → parts → markers → geometry → constraints → forces/motions
- **Force type selection** — when to use spring_damper vs bushing vs SFORCE vs GFORCE vs motion_generator
- **FUNCTION= expressions** — the full run-time expression library: smoothing (STEP, HAVSIN), contact (IMPACT, BISTOP), splines (AKISPL, CUBSPL), kinematics (DX, VM, WZ, ACCX, AZ, PSI, ROLL…), force readback (FX, TX), data elements (VARVAL, ARYVAL), math (ABS, SQRT, ATAN2…), TIME, PI
- **Macros and scripting** — variables, FOR loops, IF conditionals, string operations, DB_EXISTS
- **Example scripts** — simple pendulum and parametric N-link chain

## Skill file

[SKILL.md](SKILL.md) — load this file to activate the skill in your AI assistant.

## Reference structure

```
references/
├── naming-conventions.md               Object hierarchy, ground part, naming best practices
├── commands/
│   ├── model-parts-markers.md          model create, part create, marker create/modify, units
│   ├── constraints.md                  Joints (revolute, translational, spherical…), coupler, motion
│   ├── forces.md                       spring_damper, bushing, beam, SFORCE, VFORCE, GFORCE, gravity
│   ├── geometry.md                     sphere, cylinder, box, torus, frustum, ellipsoid, link
│   └── scripting.md                    variable set, for/end, if/end, string ops, macro create/run
└── function-expressions/
    ├── README.md                       Master index table for all FUNCTION= expressions
    ├── step.md / step5.md / havsin.md  Smooth transition functions
    ├── impact.md / bistop.md           Contact force functions
    ├── akispl.md / cubspl.md           Spline interpolation
    ├── poly.md / cheby.md              Polynomial and Chebyshev approximations
    ├── forcos-forsin.md / shf.md       Fourier and sinusoidal functions
    ├── dx-dy-dz.md / dm.md             Displacement components and magnitude
    ├── vx-vy-vz.md / vm.md / vr.md     Velocity components, magnitude, radial velocity
    ├── wx-wy-wz.md / wm.md             Angular velocity components and magnitude
    ├── accx-accy-accz.md               Acceleration components
    ├── ax-ay-az.md                     Rotational displacement (angles)
    ├── psi-theta-phi.md                Body-313 Euler angles
    ├── yaw-pitch-roll.md               Body-321 Euler angles
    ├── fx-fy-fz.md / tx-ty-tz.md       Force and torque readback
    ├── varval.md / aryval.md           Data element readback
    ├── if.md                           Conditional expression
    ├── abs.md                          ABS + full math function table
    ├── delay.md                        Time-delay (DDE)
    ├── uv.md                           Unit vector
    └── time.md                         TIME and PI constants

assets/cmd_scripts/
├── simple_pendulum.cmd                 Single link, revolute joint, gravity
└── parametric_chain.cmd                N-link chain built with a for loop
```

## How to use

1. Open your AI assistant (GitHub Copilot, Claude, Cursor, etc.)
2. Add `SKILL.md` to context (attach the file or reference it in your prompt)
3. Ask your modelling question — e.g.:
   - *"Write a CMD script to create a double wishbone suspension"*
   - *"What FUNCTION= expression should I use for a bump-stop contact?"*
   - *"How do I build a parametric model with a variable number of links?"*
