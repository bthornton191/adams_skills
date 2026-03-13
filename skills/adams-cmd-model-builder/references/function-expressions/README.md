# Adams Function Expressions

Function expressions appear in the `FUNCTION=` parameter of forces, motions, variables, data elements, and any other model element that accepts a `FUNCTION=` field. They are evaluated by the Adams Solver at every timestep.

## Syntax rules

- Wrap the entire expression in double quotes: `function = "..."`
- Use `&` to continue a long expression across lines
- All angles default to **radians**; append `D` to a value for degrees (e.g., `90D`)
- Marker arguments are always **object names** (dot-path), not IDs
- `TIME` is the current simulation time (a built-in variable, no parentheses)

## Function Index

| Function | Category | Signature | Description |
|----------|----------|-----------|-------------|
| `STEP` | Smoothing | `STEP(x, x0, h0, x1, h1)` | Cubic polynomial step; continuous 1st derivative |
| `STEP5` | Smoothing | `STEP5(x, x0, h0, x1, h1)` | Quintic polynomial step; continuous 1st and 2nd derivatives |
| `HAVSIN` | Smoothing | `HAVSIN(x, Begin At, End At, Initial Val, Final Val)` | Haversine step; smoothest transition, slightly larger derivatives |
| `IF` | Conditional | `IF(expr1: expr2, expr3, expr4)` | Returns expr2/3/4 when expr1 < 0, = 0, > 0. **Prefer STEP** — IF causes derivative discontinuities |
| `IMPACT` | Contact | `IMPACT(disp, vel, trigger, K, e, C, d)` | One-sided collision; force active when disp < trigger |
| `BISTOP` | Contact | `BISTOP(disp, vel, lo, hi, K, e, C, d)` | Two-sided collision; force active when disp < lo or disp > hi |
| `AKISPL` | Spline | `AKISPL(x, y, SplineName, n)` | Akima spline evaluation; better local smoothness than cubic |
| `CUBSPL` | Spline | `CUBSPL(x, y, SplineName, n)` | Cubic spline evaluation; standard global smoothness |
| `POLY` | Polynomial | `POLY(x, shift, c0, c1, ...)` | Standard polynomial; up to 31 coefficients |
| `CHEBY` | Polynomial | `CHEBY(x, shift, c0, c1, ...)` | Chebyshev polynomial; up to 31 coefficients |
| `FORCOS` | Fourier | `FORCOS(x, shift, freq, c0, c1, ...)` | Fourier cosine series; up to 31 coefficients |
| `FORSIN` | Fourier | `FORSIN(x, shift, freq, c0, c1, ...)` | Fourier sine series; up to 31 coefficients |
| `SHF` | Harmonic | `SHF(x, x0, a, omega, phi, b)` | Simple harmonic: `a*SIN(omega*(x-x0) - phi) + b` |
| `DX` | Displacement | `DX(To, From, Along)` | x-component of displacement vector |
| `DY` | Displacement | `DY(To, From, Along)` | y-component of displacement vector |
| `DZ` | Displacement | `DZ(To, From, Along)` | z-component of displacement vector |
| `DM` | Displacement | `DM(To, From)` | Magnitude of displacement vector (always ≥ 0) |
| `VX` | Velocity | `VX(To, From, Along, RefFrame)` | x-component of relative velocity |
| `VY` | Velocity | `VY(To, From, Along, RefFrame)` | y-component of relative velocity |
| `VZ` | Velocity | `VZ(To, From, Along, RefFrame)` | z-component of relative velocity |
| `VM` | Velocity | `VM(To, From, RefFrame)` | Magnitude of relative velocity vector |
| `VR` | Velocity | `VR(To, From, RefFrame)` | Radial (line-of-sight) velocity; positive = separating |
| `WX` | Ang. Velocity | `WX(To, From, About)` | x-component of relative angular velocity |
| `WY` | Ang. Velocity | `WY(To, From, About)` | y-component of relative angular velocity |
| `WZ` | Ang. Velocity | `WZ(To, From, About)` | z-component of relative angular velocity |
| `WM` | Ang. Velocity | `WM(To, From)` | Magnitude of relative angular velocity vector |
| `ACCX` | Acceleration | `ACCX(To, From, Along, RefFrame)` | x-component of relative translational acceleration |
| `ACCY` | Acceleration | `ACCY(To, From, Along, RefFrame)` | y-component of relative translational acceleration |
| `ACCZ` | Acceleration | `ACCZ(To, From, Along, RefFrame)` | z-component of relative translational acceleration |
| `AX` | Angle | `AX(To, From)` | Rotation of To about x-axis of From (radians) |
| `AY` | Angle | `AY(To, From)` | Rotation of To about y-axis of From (radians) |
| `AZ` | Angle | `AZ(To, From)` | Rotation of To about z-axis of From (radians) |
| `PSI` | Orientation | `PSI(To, From)` | Body-313: 1st rotation angle (radians) |
| `THETA` | Orientation | `THETA(To, From)` | Body-313: 2nd rotation angle (radians) |
| `PHI` | Orientation | `PHI(To, From)` | Body-313: 3rd rotation angle (radians) |
| `YAW` | Orientation | `YAW(To, From)` | Body-321: 1st rotation angle (radians) |
| `PITCH` | Orientation | `PITCH(To, From)` | Body-321: 2nd rotation angle (radians) |
| `ROLL` | Orientation | `ROLL(To, From)` | Body-321: 3rd rotation angle (radians) |
| `FX` | Force meas. | `FX(AppliedTo, AppliedFrom, Along)` | x-component of net force at a marker |
| `FY` | Force meas. | `FY(AppliedTo, AppliedFrom, Along)` | y-component of net force at a marker |
| `FZ` | Force meas. | `FZ(AppliedTo, AppliedFrom, Along)` | z-component of net force at a marker |
| `TX` | Torque meas. | `TX(AppliedTo, AppliedFrom, About)` | x-component of net torque at a marker |
| `TY` | Torque meas. | `TY(AppliedTo, AppliedFrom, About)` | y-component of net torque at a marker |
| `TZ` | Torque meas. | `TZ(AppliedTo, AppliedFrom, About)` | z-component of net torque at a marker |
| `VARVAL` | Data element | `VARVAL(VarName)` | Current value of a state variable element |
| `ARYVAL` | Data element | `ARYVAL(ArrName, n)` | Value of element n of an array element |
| `DELAY` | Special | `DELAY(expr, delay, init, logicArr)` | Returns expr evaluated at (TIME - delay) |
| `UV` | Special | `UV(vectorExpr)` | Unit vector in the direction of a vector expression |
| `TIME` | Constant | `TIME` | Current simulation time (no parentheses) |
| `ABS` | Math | `ABS(x)` | Absolute value |
| `SQRT` | Math | `SQRT(x)` | Square root |
| `SIN` | Math | `SIN(x)` | Sine (radians) |
| `COS` | Math | `COS(x)` | Cosine (radians) |
| `ATAN2` | Math | `ATAN2(y, x)` | Four-quadrant arctangent |
| `MIN` | Math | `MIN(a, b)` | Minimum of two values |
| `MAX` | Math | `MAX(a, b)` | Maximum of two values |
| `MOD` | Math | `MOD(a, b)` | Modulo: a mod b |
| `INT` | Math | `INT(x)` | Truncate to integer |
| `PI` | Constant | `PI` | π ≈ 3.14159265… (no parentheses) |

## Detailed documentation

- [step.md](step.md) — STEP
- [step5.md](step5.md) — STEP5
- [havsin.md](havsin.md) — HAVSIN
- [impact.md](impact.md) — IMPACT
- [bistop.md](bistop.md) — BISTOP
- [akispl.md](akispl.md) — AKISPL
- [cubspl.md](cubspl.md) — CUBSPL
- [poly.md](poly.md) — POLY
- [cheby.md](cheby.md) — CHEBY
- [forcos-forsin.md](forcos-forsin.md) — FORCOS, FORSIN
- [shf.md](shf.md) — SHF
- [dx-dy-dz.md](dx-dy-dz.md) — DX, DY, DZ
- [dm.md](dm.md) — DM
- [vx-vy-vz.md](vx-vy-vz.md) — VX, VY, VZ
- [vm.md](vm.md) — VM
- [vr.md](vr.md) — VR
- [wx-wy-wz.md](wx-wy-wz.md) — WX, WY, WZ
- [wm.md](wm.md) — WM
- [accx-accy-accz.md](accx-accy-accz.md) — ACCX, ACCY, ACCZ
- [ax-ay-az.md](ax-ay-az.md) — AX, AY, AZ
- [psi-theta-phi.md](psi-theta-phi.md) — PSI, THETA, PHI (Body-313)
- [yaw-pitch-roll.md](yaw-pitch-roll.md) — YAW, PITCH, ROLL (Body-321)
- [fx-fy-fz.md](fx-fy-fz.md) — FX, FY, FZ
- [tx-ty-tz.md](tx-ty-tz.md) — TX, TY, TZ
- [varval.md](varval.md) — VARVAL
- [aryval.md](aryval.md) — ARYVAL
- [if.md](if.md) — IF
- [abs.md](abs.md) — ABS and common math functions
- [delay.md](delay.md) — DELAY
- [uv.md](uv.md) — UV
- [time.md](time.md) — TIME, PI
