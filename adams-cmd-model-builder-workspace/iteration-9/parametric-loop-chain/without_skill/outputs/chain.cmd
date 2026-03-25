! ============================================================
! Parametric Chain of 8 Point Masses with Spring-Dampers
!
! 8 point masses along the X axis, spaced 50 mm apart,
! starting at the origin.
! Mass 1 is fixed to ground.
! Adjacent masses connected by spring-dampers:
!   K = 100 N/mm,  C = 1.0 N*s/mm,  free length = 50 mm
! Each mass = 0.25 kg
!
! FOR loops with EVAL / RTOI / // used for parametric creation.
! ============================================================

! --- 1. Model and units ---
model create model_name = chain

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Gravity ---
force create body gravitational &
    gravity_field_name  = .chain.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 3. Ground anchor marker at origin ---
marker create &
    marker_name = .chain.ground.anchor_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 4. Create 8 point masses via FOR loop ---
!    mass_i is placed at x = (i-1)*50 mm, y=0, z=0.
!    A .cm marker at local origin is required for point_mass parts.

for variable_name = i  start_value = 1  end_value = 8

    part create point_mass name_and_position &
        point_mass_name = (eval(".chain.mass_" // RTOI(i))) &
        location        = (eval((i - 1) * 50.0)), 0.0, 0.0

    marker create &
        marker_name = (eval(".chain.mass_" // RTOI(i) // ".cm")) &
        location    = 0.0, 0.0, 0.0 &
        orientation = 0.0D, 0.0D, 0.0D

    part modify point_mass mass_properties &
        point_mass_name       = (eval(".chain.mass_" // RTOI(i))) &
        mass                  = 0.25 &
        center_of_mass_marker = (eval(".chain.mass_" // RTOI(i) // ".cm"))

end

! --- 5. Fix mass 1 to ground ---
!    Spherical joint removes all translational DOF for the point mass.
constraint create joint spherical &
    joint_name    = .chain.fix_1 &
    i_marker_name = .chain.mass_1.cm &
    j_marker_name = .chain.ground.anchor_mkr

! --- 6. Create spring-dampers between adjacent masses ---
!    Loop variable j to avoid name conflict with loop variable i above.
!    displacement_at_preload sets the natural (free) length = 50 mm.

for variable_name = j  start_value = 1  end_value = 7

    force create element_like translational_spring_damper &
        spring_damper_name      = (eval(".chain.spr_" // RTOI(j) // "_" // RTOI(j + 1))) &
        i_marker_name           = (eval(".chain.mass_" // RTOI(j) // ".cm")) &
        j_marker_name           = (eval(".chain.mass_" // RTOI(j + 1) // ".cm")) &
        stiffness               = 100.0 &
        damping                 = 1.0 &
        preload                 = 0.0 &
        displacement_at_preload = 50.0

end

! --- 7. Simulate for 2 seconds ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 200 &
    model_name      = .chain &
    initial_static  = no

! ============================================================
! End of chain.cmd
! ============================================================
