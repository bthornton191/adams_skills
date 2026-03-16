! ============================================================
! Adams CMD Script: Rubber Mount - Nonlinear Bushing
! Chassis (fixed to ground) to Subframe
! ============================================================
! Units: MMKS  (millimetre, kilogram, Newton, second)
!
! Chassis : 10 kg, Ixx=Iyy=Izz=1000 kg·mm²,  fixed to ground
! Subframe: 10 kg, Ixx=Iyy=Izz=1000 kg·mm²,  free (restrained by mount)
!
! Rubber Mount stiffness (no damping modelled):
!   X translational : nonlinear spline
!                     dx(mm)   Fx(N)
!                     -10     -8000
!                      -5     -3000
!                       0         0
!                       5      3000
!                      10      8000
!   Y translational : linear 5000 N/mm
!   Z translational : linear 5000 N/mm
!   Rotational (all): 200 N·mm/deg  (≈ 11 459 N·mm/rad)
!
! Layout (global X-axis):
!   Chassis CM      @ (  0, 0, 0) mm
!   Bushing point   @ (100, 0, 0) mm
!   Subframe CM     @ (200, 0, 0) mm
! ============================================================


! ============================================================
!  MODEL UNITS
! ============================================================
MODEL/model_1
, UNITS = MMKS
, LABEL = Rubber_Mount_Nonlinear_Bushing


! ============================================================
!  GRAVITY  (-Y global direction)
! ============================================================
ACCGRAV/1
, JGRAV = -9810.0


! ============================================================
!  PARTS AND MARKERS
! ============================================================

! --- Ground (inertial reference) ---
PART/1
, GROUND
, LABEL = ground

MARKER/10
, PART = 1
, QP = 0, 0, 0
, REULER = 0D, 0D, 0D
, LABEL = ground_origin


! --- Chassis ---
!     Mass  : 10 kg
!     Inertia: Ixx=Iyy=Izz=1000 kg·mm², products of inertia = 0
!     CM     : marker 20 at global (0,0,0)
PART/2
, MASS = 10.0
, IP = 1000.0, 1000.0, 1000.0
, CM = 20
, LABEL = chassis

MARKER/20
, PART = 2
, QP = 0, 0, 0
, REULER = 0D, 0D, 0D
, LABEL = chassis_cm

! Co-located with ground_origin; used as the I-marker of the fixed joint
MARKER/21
, PART = 2
, QP = 0, 0, 0
, REULER = 0D, 0D, 0D
, LABEL = chassis_ground_ref

! Bushing attachment point on chassis  →  J-marker of GFORCE, RMID frame
MARKER/22
, PART = 2
, QP = 100, 0, 0
, REULER = 0D, 0D, 0D
, LABEL = chassis_bushing_J


! --- Subframe ---
!     Mass  : 10 kg
!     Inertia: Ixx=Iyy=Izz=1000 kg·mm², products of inertia = 0
!     CM     : marker 30 at global (200,0,0)
PART/3
, MASS = 10.0
, IP = 1000.0, 1000.0, 1000.0
, CM = 30
, LABEL = subframe

MARKER/30
, PART = 3
, QP = 200, 0, 0
, REULER = 0D, 0D, 0D
, LABEL = subframe_cm

! Bushing attachment point on subframe  →  I-marker of GFORCE
MARKER/31
, PART = 3
, QP = 100, 0, 0
, REULER = 0D, 0D, 0D
, LABEL = subframe_bushing_I


! ============================================================
!  FIXED JOINT: Chassis locked to ground
! ============================================================
JOINT/1
, LABEL = chassis_fixed_to_ground
, TYPE = FIXED
, I = 21
, J = 10


! ============================================================
!  SPLINE: Nonlinear X Force-Displacement
! ============================================================
!  Columns:  X = displacement (mm),  Y = bushing reaction force (N)
!  Physically: the rubber mount produces increasing resistance with
!  displacement; the GFORCE negates this to make it a restoring force.
!  LINEAR_EXTRAPOLATE extends tangentially beyond the ±10 mm data range.
SPLINE/1
, LABEL = x_nonlinear_stiffness
, LINEAR_EXTRAPOLATE = ON
, X = -10.0, -5.0, 0.0, 5.0, 10.0
, Y = -8000.0, -3000.0, 0.0, 3000.0, 8000.0


! ============================================================
!  GFORCE: Rubber Mount Elastic Joint
! ============================================================
!
!  I    = subframe_bushing_I  (marker 31, on subframe  — action side)
!  J    = chassis_bushing_J   (marker 22, on chassis   — reaction side)
!  RMID = chassis_bushing_J   (marker 22, defines the force/torque axes)
!
!  Relative displacement (bushing deformation) resolved in chassis frame:
!    dx = DX(31, 22, 22)   mm  (X: nonlinear)
!    dy = DY(31, 22, 22)   mm  (Y: linear)
!    dz = DZ(31, 22, 22)   mm  (Z: linear)
!
!  Relative rotation (small angle, Euler decomposition, returns radians):
!    ax = AX(31, 22)   rad
!    ay = AY(31, 22)   rad
!    az = AZ(31, 22)   rad
!
!  Force/torque applied ON the I marker (subframe) — restoring convention:
!
!    FX = -AKISPL(dx, 0, spline_1)
!         Akima spline lookup: at dx=+5mm → spline returns +3000 N
!         negated  → FX = -3000 N  (restores subframe toward chassis)
!
!    FY = -5000 * dy   N          (linear 5000 N/mm)
!    FZ = -5000 * dz   N          (linear 5000 N/mm)
!
!    TX = -200 * RTOD * ax   N·mm    (200 N·mm/deg = 200×RTOD N·mm/rad)
!    TY = -200 * RTOD * ay   N·mm    RTOD = 180/π ≈ 57.2958 (Adams constant)
!    TZ = -200 * RTOD * az   N·mm
!
GFORCE/1
, LABEL = rubber_mount_gforce
, I = 31
, J = 22
, RMID = 22
, FX = -AKISPL(DX(31,22,22),0,1)
, FY = -5000.0*DY(31,22,22)
, FZ = -5000.0*DZ(31,22,22)
, TX = -200.0*RTOD*AX(31,22)
, TY = -200.0*RTOD*AY(31,22)
, TZ = -200.0*RTOD*AZ(31,22)


! ============================================================
!  END OF SCRIPT
! ============================================================
