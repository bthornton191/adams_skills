# Adams Function Expressions

This folder documents two families of Adams View functions:

- **Runtime functions** — appear in the `FUNCTION=` parameter of forces, motions, variables, and data elements. They are evaluated by the Adams Solver at every integration timestep.
- **Design-time functions** — appear in parametric expressions on object properties (e.g. marker locations, geometry parameters). They are evaluated by Adams View during model construction and parametric updates.

## Syntax rules (runtime)

- Wrap the entire expression in double quotes: `function = "..."`
- Use `&` to continue a long expression across lines
- All angles default to **radians**; append `D` to a value for degrees (e.g., `90D`)
- Marker arguments are always **object names** (dot-path), not IDs
- `TIME` is the current simulation time (a built-in variable, no parentheses)

---

## Simulation Runtime Functions

| Function | Category | Signature | Description |
|----------|----------|-----------|-------------|
| `STEP` | Smoothing | `STEP(x, x0, h0, x1, h1)` | Cubic polynomial step; continuous 1st derivative |
| `STEP5` | Smoothing | `STEP5(x, x0, h0, x1, h1)` | Quintic polynomial step; continuous 1st and 2nd derivatives |
| `HAVSIN` | Smoothing | `HAVSIN(x, Begin At, End At, Initial Val, Final Val)` | Haversine step; smoothest transition, slightly larger derivatives |
| `IF` | Conditional | `IF(expr1: expr2, expr3, expr4)` | Returns expr2/3/4 when expr1 < 0, = 0, > 0. **Prefer STEP** — IF causes derivative discontinuities |
| `IMPACT` | Contact | `IMPACT(disp, vel, trigger, K, e, C, d)` | One-sided collision; force active when disp < trigger |
| `BISTOP` | Contact | `BISTOP(disp, vel, lo, hi, K, e, C, d)` | Two-sided collision; force active when disp < lo or disp > hi |
| `CONTACT` | Contact | `CONTACT(id, jflag, comp, rm)` | Returns component of force in a contact element in the coordinate system of marker rm |
| `AKISPL` | Spline | `AKISPL(x, y, SplineName, n)` | Akima spline evaluation; better local smoothness than cubic |
| `CUBSPL` | Spline | `CUBSPL(x, y, SplineName, n)` | Cubic spline evaluation; standard global smoothness |
| `CURVE` | Spline | `CURVE(x, n, dir, CurveName)` | Returns a B-spline or user-written curve created by a CURVE data element |
| `INTERP` | Spline | `INTERP(x, method, SplineName, n)` | Returns the nth derivative of the interpolated spline value; supports time-series splines |
| `POLY` | Polynomial | `POLY(x, shift, c0, c1, ...)` | Standard polynomial; up to 31 coefficients |
| `CHEBY` | Polynomial | `CHEBY(x, shift, c0, c1, ...)` | Chebyshev polynomial; up to 31 coefficients |
| `FORCOS` | Fourier | `FORCOS(x, shift, freq, c0, c1, ...)` | Fourier cosine series; up to 31 coefficients |
| `FORSIN` | Fourier | `FORSIN(x, shift, freq, c0, c1, ...)` | Fourier sine series; up to 31 coefficients |
| `SHF` | Harmonic | `SHF(x, x0, a, omega, phi, b)` | Simple harmonic: `a*SIN(omega*(x-x0) - phi) + b` |
| `SWEEP` | Harmonic | `SWEEP(x, A, x0, f0, x1, f1, dx)` | Constant-amplitude sinusoidal with linearly increasing frequency |
| `DX` | Displacement | `DX(To, From, Along)` | x-component of displacement vector |
| `DY` | Displacement | `DY(To, From, Along)` | y-component of displacement vector |
| `DZ` | Displacement | `DZ(To, From, Along)` | z-component of displacement vector |
| `DM` | Displacement | `DM(To, From)` | Magnitude of displacement vector (always ≥ 0) |
| `DXYZ` | Displacement | `DXYZ(i[,j][,k])` | Translational displacement vector as a 3-element array |
| `VX` | Velocity | `VX(To, From, Along, RefFrame)` | x-component of relative velocity |
| `VY` | Velocity | `VY(To, From, Along, RefFrame)` | y-component of relative velocity |
| `VZ` | Velocity | `VZ(To, From, Along, RefFrame)` | z-component of relative velocity |
| `VM` | Velocity | `VM(To, From, RefFrame)` | Magnitude of relative velocity vector |
| `VR` | Velocity | `VR(To, From, RefFrame)` | Radial (line-of-sight) velocity; positive = separating |
| `VXYZ` | Velocity | `VXYZ(i[,j][,k][,l])` | Difference between translational velocity vectors as a 3-element array |
| `WX` | Ang. Velocity | `WX(To, From, About)` | x-component of relative angular velocity |
| `WY` | Ang. Velocity | `WY(To, From, About)` | y-component of relative angular velocity |
| `WZ` | Ang. Velocity | `WZ(To, From, About)` | z-component of relative angular velocity |
| `WM` | Ang. Velocity | `WM(To, From)` | Magnitude of relative angular velocity vector |
| `WXYZ` | Ang. Velocity | `WXYZ(i[,j][,k])` | Difference between angular velocity vectors as a 3-element array |
| `ACCX` | Acceleration | `ACCX(To, From, Along, RefFrame)` | x-component of relative translational acceleration |
| `ACCY` | Acceleration | `ACCY(To, From, Along, RefFrame)` | y-component of relative translational acceleration |
| `ACCZ` | Acceleration | `ACCZ(To, From, Along, RefFrame)` | z-component of relative translational acceleration |
| `ACCM` | Acceleration | `ACCM(To, From, RefFrame)` | Magnitude of relative translational acceleration vector |
| `WDTX` | Ang. Acceleration | `WDTX(To, From, About, RefFrame)` | x-component of relative angular acceleration |
| `WDTY` | Ang. Acceleration | `WDTY(To, From, About, RefFrame)` | y-component of relative angular acceleration |
| `WDTZ` | Ang. Acceleration | `WDTZ(To, From, About, RefFrame)` | z-component of relative angular acceleration |
| `WDTM` | Ang. Acceleration | `WDTM(To, From, RefFrame)` | Magnitude of relative angular acceleration vector |
| `WDTXYZ` | Ang. Acceleration | `WDTXYZ(i[,j][,k][,l])` | Difference between angular acceleration vectors as a 3-element array |
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
| `FM` | Force meas. | `FM(AppliedTo, AppliedFrom)` | Magnitude of the net translational force at a marker |
| `FXYZ` | Force meas. | `FXYZ(i[,j][,k])` | Net translational force vector as a 3-element array |
| `TX` | Torque meas. | `TX(AppliedTo, AppliedFrom, About)` | x-component of net torque at a marker |
| `TY` | Torque meas. | `TY(AppliedTo, AppliedFrom, About)` | y-component of net torque at a marker |
| `TZ` | Torque meas. | `TZ(AppliedTo, AppliedFrom, About)` | z-component of net torque at a marker |
| `TM` | Torque meas. | `TM(AppliedTo, AppliedFrom)` | Magnitude of the net torque at a marker |
| `TXYZ` | Torque meas. | `TXYZ(i[,j][,k])` | Net torque vector as a 3-element array |
| `VARVAL` | Data element | `VARVAL(VarName)` | Current value of a state variable element |
| `ARYVAL` | Data element | `ARYVAL(ArrName, n)` | Value of element n of an array element |
| `DIF` | Data element | `DIF(DiffVarName)` | Integrated value of a differential equation variable |
| `DIF1` | Data element | `DIF1(DiffVarName)` | Current (un-integrated) value of a differential equation variable |
| `PINVAL` | Control | `PINVAL(PinName, n)` | Run-time value of element n of a plant input |
| `POUVAL` | Control | `POUVAL(PouName, n)` | Run-time value of element n of a plant output |
| `DELAY` | Special | `DELAY(expr, delay, init, logicArr)` | Returns expr evaluated at (TIME - delay) |
| `UV` | Special | `UV(vectorExpr)` | Unit vector in the direction of a vector expression |
| `UVX` | Special | `UVX(i[,k])` | Unit vector along the x-axis of marker i, resolved in marker k |
| `UVY` | Special | `UVY(i[,k])` | Unit vector along the y-axis of marker i, resolved in marker k |
| `UVZ` | Special | `UVZ(i[,k])` | Unit vector along the z-axis of marker i, resolved in marker k |
| `TRANS` | Special | `TRANS(exp, i[,j])` | Transforms a vector expression from marker j's frame to marker i's frame |
| `INVPSD` | Special | `INVPSD(x, SplineName, fMin, fMax, nFreq, useLog, seed)` | Regenerates a time signal from a power spectral density description |
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

---

## Design-Time Functions (Adams View)

Design-time functions are evaluated by Adams View during model construction and parametric updates. They use `{}` array/object syntax instead of explicit marker IDs and are not available inside solver runtime `FUNCTION=` expressions.

### Math & Type Conversion

| Function | Description |
|----------|-------------|
| `ABS(x)` | Absolute value |
| `AINT(x)` | Truncate to integer (towards zero) |
| `ANINT(x)` | Round to nearest integer |
| `CEIL(x)` | Ceiling (smallest integer ≥ x) |
| `COSH(x)` | Hyperbolic cosine |
| `DIM(x, y)` | Positive difference: max(x − y, 0) |
| `FLOOR(x)` | Floor (largest integer ≤ x) |
| `MAG({v})` | Magnitude of a vector |
| `NINT(x)` | Round to nearest integer (alias of ANINT) |
| `RAND(seed)` | Pseudo-random number in [0, 1) |
| `RTOI(x)` | Convert real to integer |
| `SINH(x)` | Hyperbolic sine |
| `SQRT(x)` | Square root |
| `TANH(x)` | Hyperbolic tangent |
| `STOI(s)` | String to integer |
| `STOR(s)` | String to real |
| `STOO(s, type)` | String to object reference |

See [abs.md](abs.md) and [type-conversion.md](type-conversion.md).

### Location Functions (LOC_)

| Function | Description |
|----------|-------------|
| `LOC_ALONG_LINE(p1, p2, d)` | Point on a line at distance d from p1 |
| `LOC_BISECTOR(p1, p2, p3)` | Point on the angle bisector at p2 |
| `LOC_CAM_FOLLOWER(c, p, r)` | Contact point between cam curve and follower |
| `LOC_CENTROID(pts)` | Centroid/average of a set of points |
| `LOC_CLOSEST_POINT_ON_LINE(p, p1, p2)` | Foot of perpendicular from p onto a line |
| `LOC_DELTA(ref, dx, dy, dz)` | Offset a location by [dx, dy, dz] in ref frame |
| `LOC_FRAME(ref, u, v, w)` | Point by giving coordinates in a custom frame |
| `LOC_GLOBAL(ref, x, y, z)` | Transform local coords to global |
| `LOC_LOCAL(ref, x, y, z)` | Express a global point in a local frame |
| `LOC_MIDPOINT(p1, p2)` | Midpoint between two locations |
| `LOC_ON_CURVE(curve, t)` | Point on a curve at parameter t |
| `LOC_ORTHO_POINT(p1, p2, p3)` | Orthocenter of a triangle |
| `LOC_POINT_ON_CURVE(curve, ref, n)` | Point on curve nearest to ref, nth occurrence |
| `LOC_REFLECT(p, p1, p2)` | Reflect point p across the line p1–p2 |
| `LOC_RELATIVE_TO(p, origin, x_axis, xy_plane)` | Express p relative to a user-defined frame |
| `LOC_SYMMETRIC_ABOUT_PLANE(p, plane)` | Mirror p across a plane |
| `LOC_TRANSLATE(p, v)` | Translate p by vector v |
| `LOC_X_AXIS(ref)` | Unit x-axis direction of ref frame as a location |
| `LOC_Z_AXIS(ref)` | Unit z-axis direction of ref frame as a location |

See [loc-functions.md](loc-functions.md).

### Orientation Functions (ORI_)

| Function | Description |
|----------|-------------|
| `ORI_GLOBAL(ref)` | Orientation of ref relative to global frame |
| `ORI_LOCAL(ref1, ref2)` | Relative orientation of ref1 in ref2 |
| `ORI_ORI(ref)` | Euler angles (3-1-3) of ref |
| `ORI_ALL_AXES(x_vec, z_vec)` | Build orientation from x and z axis vectors |
| `ORI_BODY_313(psi, theta, phi)` | Body-fixed 3-1-3 Euler angles to orientation |
| `ORI_BODY_321(yaw, pitch, roll)` | Body-fixed 3-2-1 (yaw-pitch-roll) to orientation |
| `ORI_IN_PLANE(p1, p2, p3)` | Z-axis normal to plane, x-axis toward p2 |
| `ORI_POINT_TO_POINT(from, to)` | Z-axis along from→to |
| `ORI_RELATIVE_TO(ori, ref)` | Express orientation relative to ref frame |
| `ORI_SYMMETRIC_ABOUT_PLANE(ori, plane)` | Reflect orientation across a plane |
| `ORI_TRANSLATE(ori, v)` | Translate only (orientation unchanged) |
| `ORI_XZ_AXES(x_vec, z_vec)` | Build orientation matrix from x and z vectors |
| `ORI_ZX_AXES(z_vec, x_vec)` | Build orientation matrix from z and x vectors |

See [ori-functions.md](ori-functions.md).

### Interpolation & Signal Processing

| Category | Functions |
|----------|-----------|
| Spline/interpolation | AKIMA_SPLINE, CSPLINE, HERMITE_SPLINE, LINEAR_SPLINE, NOTAKNOT_SPLINE, SPLINE, INTERP1, INTERP2, INTERPFT, GRIDDATA, MESHGRID, POLYFIT, POLYVAL |
| FFT / filtering | FFTMAG, FFTPHASE, FREQUENCY, PSD, PWELCH, FILTER, FILTFILT, RESAMPLE, DETREND, UNWRAP |
| Window functions | BARTLETT, BLACKMAN, HAMMING, HANNING, PARZEN, RECTANGULAR, TRIANGULAR, WELCH (+ `_WINDOW` aliases) |
| Bode / Butterworth | BODEABCD, BODELSE, BODELSM, BODESEQ, BODETFCOEF, BODETFS, BUTTER_NUMERATOR, BUTTER_DENOMINATOR, BUTTER_FILTER |

See [spline-interpolation.md](spline-interpolation.md), [signal-processing.md](signal-processing.md), [window-functions.md](window-functions.md), [bode-control.md](bode-control.md).

### Matrix & Array

| Category | Functions |
|----------|-----------|
| Matrix algebra | ALLM, ANYM, APPEND, BALANCE, CLIP, COLS, COMPRESS, COND, CONVERT_ANGLES, CROSS, DET, DMAT, DOT, ELEMENT, EXCLUDE, INVERSE, NORMALIZE, PROD, RESHAPE, REVERSE, ROWS, SHAPE, SORT, SORT_BY, SORT_INDEX, STACK, TILDE, TMAT, TMAT3, TRANSPOSE, UNIQUE |
| Array utilities | ALIGN, ANGLES, CENTER, FIRST, FIRST_N, LAST, LAST_N, SERIES, SERIES2, SIM_TIME |
| Statistics / calculus | DIFF, DIFFERENTIATE, INTEGR, INTEGRATE, MAX, MAXI, MEAN, MIN, MINI, NORM, NORM2, RMS, SSQ, SUM |
| Eigenvalues | EIG_DI, EIG_DR, EIG_VI, EIG_VR, EIGENVALUES_I, EIGENVALUES_R |
| DOE | DOE_MATRIX, DOE_NUM_TERMS |
| Value lookup | VAL, VALAT, VALI |

See [matrix-operations.md](matrix-operations.md), [array-helpers.md](array-helpers.md), [statistics.md](statistics.md), [eigenvalue.md](eigenvalue.md), [doe-functions.md](doe-functions.md), [val-functions.md](val-functions.md).

### String Functions (STR_)

| Function | Description |
|----------|-------------|
| `STR_CASE(s, mode)` | Convert case (upper/lower/title) |
| `STR_CHR(n)` | Character from ASCII code |
| `STR_COMPARE(s1, s2)` | Lexicographic compare |
| `STR_DATE()` | Current date as string |
| `STR_DELETE(s, i, n)` | Delete n characters at position i |
| `STR_FIND(s, sub)` | First position of substring |
| `STR_FIND_COUNT(s, sub)` | Number of occurrences |
| `STR_FIND_IN_STRINGS(arr, sub)` | Search array of strings |
| `STR_FIND_N(s, sub, n)` | Nth occurrence of substring |
| `STR_INSERT(s, i, ins)` | Insert string at position i |
| `STR_IS_REAL(s)` | True if s parses as a real |
| `STR_IS_SPACE(s)` | True if s is all whitespace |
| `STR_LENGTH(s)` | Length in characters |
| `STR_MATCH(s, pattern)` | Wildcard/pattern match |
| `STR_MERGE_STRINGS(arr)` | Join an array of strings |
| `STR_PRINT(val)` | Convert value to string |
| `STR_REMOVE_WHITESPACE(s)` | Strip leading/trailing spaces |
| `STR_REPLACE_ALL(s, old, new)` | Replace all occurrences |
| `STR_SPLIT(s, delim)` | Split into array |
| `STR_SPRINTF(fmt, ...)` | Formatted string (printf-style) |
| `STR_SUBSTR(s, i, n)` | Extract substring |
| `STR_TIMESTAMP()` | Current date + time as string |
| `STR_XLATE(s, from, to)` | Character-for-character translation |
| `STATUS_PRINT(msg)` | Print message to message window |

See [str-functions.md](str-functions.md).

### Database Functions (DB_)

| Category | Functions |
|----------|-----------|
| Existence / query | DB_ACTIVE, DB_CHANGED, DB_COUNT, DB_EXISTS, DB_OBJ_EXISTS, DB_OBJ_EXISTS_EXHAUSTIVE, DB_OBJ_FROM_NAME_TYPE, DB_OF_CLASS, DB_OF_TYPE_EXISTS, DB_OBJECT_COUNT |
| Hierarchy traversal | DB_ANCESTOR, DB_OLDEST_ANCESTOR, DB_CHILDREN, DB_IMMEDIATE_CHILDREN, DB_DESCENDANTS, DB_DEPENDENTS, DB_DEPENDENTS_EXHAUSTIVE, DB_DEL_PARAM_DEPENDENTS, DB_DEL_UNPARAM_DEPENDENTS, DB_DELETE_DEPENDENTS, DB_REFERENTS, DB_REFERENTS_EXHAUSTIVE, DB_TWO_WAY |
| Type / name metadata | DB_DEFAULT, DB_DEFAULT_NAME, DB_DEFAULT_NAME_FOR_TYPE, DB_FIELD_FILTER, DB_FIELD_TYPE, DB_FILTER_NAME, DB_FILTER_TYPE, DB_FULL_NAME_FROM_SHORT, DB_FULL_TYPE_FIELDS, DB_SHORT_NAME, DB_TYPE, DB_TYPE_FIELDS, EXPR_STRING, PARAM_STRING, USER_STRING |
| Unique names / units | UNIQUE_FILE_NAME, UNIQUE_FULL_NAME, UNIQUE_ID, UNIQUE_LOCAL_NAME, UNIQUE_NAME, UNIQUE_NAME_IN_HIERARCHY, UNIQUE_PARTIAL_NAME, UNITS_CONVERSION_FACTOR, UNITS_STRING, UNITS_TYPE, UNITS_VALUE |

See [db-query.md](db-query.md), [db-navigation.md](db-navigation.md), [db-metadata.md](db-metadata.md), [unique-units.md](unique-units.md).

### GUI / System Functions

| Category | Functions |
|----------|-----------|
| GUI selection dialogs | PICK_OBJECT, SELECT_DIRECTORY, SELECT_FIELD, SELECT_FILE, SELECT_MULTI_TEXT, SELECT_OBJECT, SELECT_OBJECTS, SELECT_REQUEST_IDS, SELECT_TEXT, SELECT_TYPE |
| Alerts & utilities | ALERT, ALERT2, ALERT3, FILE_ALERT, ON_OFF, AGGREGATE_MASS, SECURITY_CHECK, FIND_MACRO_FROM_COMMAND |
| Flexible-body nodes | NODE_ID_CLOSEST, NODE_IDS_CLOSEST_TO, NODE_IDS_IN_VOLUME, NODE_ID_IS_INTERFACE, NODE_IDS_WITHIN_RADIUS, NODE_NODE_CLOSEST |
| Table widgets | TABLE_COLUMN_SELECTED_CELLS, TABLE_GET_CELLS, TABLE_GET_DIMENSION, TABLE_GET_REALS, TABLE_GET_SELECTED_COLS, TABLE_GET_SELECTED_ROWS |
| File / env / system | BACKUP_FILE, CHDIR, COPY_FILES, EXECUTE_VIEW_COMMAND, FILE_EXISTS, GETCWD, GETENV, LOCAL_FILE_NAME, MKDIR, PARSE_STATUS, PUTENV, REMOVE_FILE, RENAME_FILE, RMDIR, SIM_STATUS, SYS_INFO, TERM_STATUS, TIMER_CPU, TIMER_ELAPSED |

See [gui-select.md](gui-select.md), [alert-functions.md](alert-functions.md), [node-functions.md](node-functions.md), [table-functions.md](table-functions.md), [file-system.md](file-system.md).

---

## Detailed documentation

### Runtime function files

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

### Design-time function files

- [abs.md](abs.md) — ABS and all math functions (AINT, ANINT, CEIL, COSH, DIM, FLOOR, MAG, NINT, RAND, RTOI, SINH, SQRT, TANH)
- [type-conversion.md](type-conversion.md) — STOI, STOR, STOO
- [loc-functions.md](loc-functions.md) — LOC_ location functions (19)
- [ori-functions.md](ori-functions.md) — ORI_ orientation functions (13)
- [spline-interpolation.md](spline-interpolation.md) — spline/interpolation functions (15)
- [signal-processing.md](signal-processing.md) — FFT/filter functions (10)
- [window-functions.md](window-functions.md) — window functions (16)
- [bode-control.md](bode-control.md) — Bode/Butterworth functions (9)
- [matrix-operations.md](matrix-operations.md) — matrix algebra (32)
- [array-helpers.md](array-helpers.md) — array generation/slice utilities (10)
- [statistics.md](statistics.md) — statistics and calculus functions (14)
- [eigenvalue.md](eigenvalue.md) — eigenvalue functions (6)
- [doe-functions.md](doe-functions.md) — DOE matrix generation (2)
- [val-functions.md](val-functions.md) — VAL, VALAT, VALI (3)
- [str-functions.md](str-functions.md) — string functions (24)
- [db-query.md](db-query.md) — DB existence/query functions (10)
- [db-navigation.md](db-navigation.md) — DB hierarchy traversal (13)
- [db-metadata.md](db-metadata.md) — DB type/name metadata (15)
- [unique-units.md](unique-units.md) — unique name generators + units (11)
- [gui-select.md](gui-select.md) — GUI selection dialogs (10)
- [alert-functions.md](alert-functions.md) — alerts and utilities (8)
- [node-functions.md](node-functions.md) — flexible-body node functions (6)
- [table-functions.md](table-functions.md) — table widget functions (6)
- [file-system.md](file-system.md) — file/directory/system functions (19)
