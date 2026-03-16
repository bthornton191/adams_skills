! ============================================================
! Nonlinear Rubber Mount between Chassis and Subframe
! Adams/View CMD Script
!
! Units : mm, kg, N, s
! Axes  : standard right-hand (X forward, Y lateral, Z up)
!
! Force elements:
!   1. BUSHING  — linear Y/Z translation + linear rotational (all axes)
!   2. GFORCE   — nonlinear X translation via AKISPL spline
! ============================================================

! --- Set working units --------------------------------------------------
defaults units                    &
    length          = mm          &
    mass            = kg          &
    force           = newton      &
    time            = sec

! --- Create model -------------------------------------------------------
model create                      &
    model_name = .rubber_mount_model

defaults model                    &
    model_name = .rubber_mount_model

! ============================================================
! SPLINE — Nonlinear X force-displacement table
!   x : displacement of subframe relative to chassis in X [mm]
!   y : characteristic force value [N]
!
! Used in GFORCE as:  FX = -AKISPL(DX(I,J,J), 0, spline)
!   → positive displacement produces negative (restoring) force
! ============================================================
data_element create spline        &
    spline_name = .rubber_mount_model.x_stiffness_spline  &
    x = -10.0, -5.0, 0.0, 5.0, 10.0                      &
    y = -8000.0, -3000.0, 0.0, 3000.0, 8000.0

! ============================================================
! PART: chassis
!   Location : origin (0, 0, 0) mm
!   Mass     : 10 kg
!   Inertia  : Ixx = Iyy = Izz = 1000 kg·mm²
!   This part will be fixed to ground.
! ============================================================
part create rigid_body name_and_position  &
    part_name   = .rubber_mount_model.chassis  &
    location    = 0.0, 0.0, 0.0               &
    orientation = 0.0d, 0.0d, 0.0d

part modify rigid_body mass_properties    &
    part_name = .rubber_mount_model.chassis  &
    mass      = 10.0                         &
    ixx       = 1000.0                       &
    iyy       = 1000.0                       &
    izz       = 1000.0                       &
    ixy       = 0.0                          &
    iyz       = 0.0                          &
    izx       = 0.0

! ============================================================
! PART: subframe
!   Location : (0, 0, 100) mm — 100 mm above chassis in Z
!   Mass     : 10 kg
!   Inertia  : Ixx = Iyy = Izz = 1000 kg·mm²
! ============================================================
part create rigid_body name_and_position  &
    part_name   = .rubber_mount_model.subframe  &
    location    = 0.0, 0.0, 100.0              &
    orientation = 0.0d, 0.0d, 0.0d

part modify rigid_body mass_properties    &
    part_name = .rubber_mount_model.subframe  &
    mass      = 10.0                          &
    ixx       = 1000.0                        &
    iyy       = 1000.0                        &
    izz       = 1000.0                        &
    ixy       = 0.0                           &
    iyz       = 0.0                           &
    izx       = 0.0

! ============================================================
! MARKERS
!   mount_j : J-side (chassis), at z = 50 mm (midpoint)
!   mount_i : I-side (subframe), co-located initially
!   Axes aligned with global frame.
! ============================================================

! Ground reference marker (for fixed joint J-side)
marker create                                         &
    marker_name = .rubber_mount_model.ground.ground_ref  &
    location    = 0.0, 0.0, 0.0                         &
    orientation = 0.0d, 0.0d, 0.0d

! Chassis CM marker (for fixed joint I-side)
marker create                                              &
    marker_name = .rubber_mount_model.chassis.chassis_cm  &
    location    = 0.0, 0.0, 0.0                           &
    orientation = 0.0d, 0.0d, 0.0d

! Chassis mount J-marker (J-side of bushing and GFORCE)
marker create                                            &
    marker_name = .rubber_mount_model.chassis.mount_j   &
    location    = 0.0, 0.0, 50.0                        &
    orientation = 0.0d, 0.0d, 0.0d

! Subframe mount I-marker (I-side of bushing and GFORCE)
marker create                                             &
    marker_name = .rubber_mount_model.subframe.mount_i   &
    location    = 0.0, 0.0, 50.0                         &
    orientation = 0.0d, 0.0d, 0.0d

! ============================================================
! CONSTRAINT — Fix chassis to ground
! ============================================================
constraint create joint fixed                                    &
    joint_name    = .rubber_mount_model.chassis_ground           &
    i_marker_name = .rubber_mount_model.chassis.chassis_cm       &
    j_marker_name = .rubber_mount_model.ground.ground_ref

! ============================================================
! FORCE 1: BUSHING — linear elastic joint
!
!   KX   = 0.0  N/mm   (X stiffness provided by GFORCE below)
!   KY   = 5000 N/mm
!   KZ   = 5000 N/mm
!
!   Rotational stiffness conversion:
!     200 N·mm/deg × (180/π) deg/rad = 11459.156 N·mm/rad
!
!   KROTX = KROTY = KROTZ = 11459.156 N·mm/rad
!
!   All damping coefficients = 0 (not specified in problem).
! ============================================================
force create element_like bushing                                     &
    bushing_name          = .rubber_mount_model.rubber_mount_linear   &
    i_marker_name         = .rubber_mount_model.subframe.mount_i      &
    j_marker_name         = .rubber_mount_model.chassis.mount_j       &
    stiffness             = 0.0, 5000.0, 5000.0                       &
    damping               = 0.0, 0.0, 0.0                             &
    rotational_stiffness  = 11459.156, 11459.156, 11459.156           &
    rotational_damping    = 0.0, 0.0, 0.0

! ============================================================
! FORCE 2: GFORCE — nonlinear X restoring force
!
!   Applied to subframe (I-marker) relative to chassis (J-marker).
!   Reference frame: chassis mount_j (J-marker frame).
!
!   FX = -AKISPL(DX(I,J,J), 0, x_stiffness_spline)
!     DX(I,J,J) = X displacement of subframe marker relative to
!                 chassis marker, resolved in chassis marker frame.
!     AKISPL performs Akima spline interpolation.
!     Negation produces a restoring force:
!       DX = +5 mm → AKISPL = +3000 N → FX = -3000 N (pushes back)
!       DX = -5 mm → AKISPL = -3000 N → FX = +3000 N (pushes back)
!
!   FY = FZ = TX = TY = TZ = 0 (handled by bushing above)
! ============================================================
force create direct general_force                                               &
    general_force_name = .rubber_mount_model.rubber_mount_x_nonlinear          &
    i_marker_name      = .rubber_mount_model.subframe.mount_i                  &
    j_marker_name      = .rubber_mount_model.chassis.mount_j                   &
    ref_marker_name    = .rubber_mount_model.chassis.mount_j                   &
    fx_expression      = "-AKISPL(DX(.rubber_mount_model.subframe.mount_i,.rubber_mount_model.chassis.mount_j,.rubber_mount_model.chassis.mount_j),0,.rubber_mount_model.x_stiffness_spline)"  &
    fy_expression      = "0.0"                                                 &
    fz_expression      = "0.0"                                                 &
    tx_expression      = "0.0"                                                 &
    ty_expression      = "0.0"                                                 &
    tz_expression      = "0.0"

! ============================================================
! END OF SCRIPT
!
! Summary of stiffness properties:
!   X translation : nonlinear (spline) — 600 N/mm at ±5 mm,
!                                        800 N/mm at ±10 mm (secant)
!   Y translation : 5000 N/mm (linear)
!   Z translation : 5000 N/mm (linear)
!   Rotational X  : 11459.156 N·mm/rad = 200 N·mm/deg (linear)
!   Rotational Y  : 11459.156 N·mm/rad = 200 N·mm/deg (linear)
!   Rotational Z  : 11459.156 N·mm/rad = 200 N·mm/deg (linear)
! ============================================================
