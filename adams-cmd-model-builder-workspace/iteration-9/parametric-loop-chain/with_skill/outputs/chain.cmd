! ============================================================
! Spring-Damper Chain of 8 Point Masses
!
! 8 point masses along the X axis, 50 mm apart, starting at
! the origin. Mass 1 is fixed to ground via a spherical joint.
! Adjacent masses are connected by translational spring-dampers:
!   K = 100 N/mm, C = 1.0 N*s/mm, free length = 50 mm
! Each mass = 0.25 kg
!
! Uses FOR loops with EVAL / RTOI / // for parameterisation.
! ============================================================

! --- 1. Model ---
model create model_name = chain_masses

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- 2. Parameters ---
variable set variable_name = .chain_masses.n_mass    real_value = 8.0
variable set variable_name = .chain_masses.spacing   real_value = 50.0
variable set variable_name = .chain_masses.mass_val  real_value = 0.25
variable set variable_name = .chain_masses.stiffness real_value = 100.0
variable set variable_name = .chain_masses.damping   real_value = 1.0
variable set variable_name = .chain_masses.free_len  real_value = 50.0

! --- 3. Gravity ---
force create body gravitational &
    gravity_field_name  = .chain_masses.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- 4. Ground anchor marker at origin ---
marker create &
    marker_name = .chain_masses.ground.anchor_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- 5. Create point masses in a loop ---
!
! mass_i placed at global x = (i-1)*50 mm.
!
for variable_name = i  start_value = 1  end_value = (eval(.chain_masses.n_mass))

    part create point_mass name_and_position &
        point_mass_name = (eval(".chain_masses.mass_" // RTOI(i))) &
        location        = (eval((i - 1) * .chain_masses.spacing)), 0.0, 0.0

    ! CM marker at local origin of the part (needed for joint reference)
    marker create &
        marker_name = (eval(".chain_masses.mass_" // RTOI(i) // ".cm")) &
        location    = 0.0, 0.0, 0.0 &
        orientation = 0.0D, 0.0D, 0.0D

    part modify point_mass mass_properties &
        point_mass_name       = (eval(".chain_masses.mass_" // RTOI(i))) &
        mass                  = (eval(.chain_masses.mass_val)) &
        center_of_mass_marker = (eval(".chain_masses.mass_" // RTOI(i) // ".cm"))

    ! Ellipsoid geometry (visual)
    geometry create shape ellipsoid &
        ellipsoid_name = (eval(".chain_masses.mass_" // RTOI(i) // ".sph")) &
        center_marker  = (eval(".chain_masses.mass_" // RTOI(i) // ".cm")) &
        x_scale_factor = 8.0 &
        y_scale_factor = 8.0 &
        z_scale_factor = 8.0

end  ! end for loop (point masses)

! --- 6. Fix mass 1 to ground with a spherical joint ---
! (point masses do not support fixed joints; spherical removes all 3 translational DOF)
constraint create joint spherical &
    joint_name    = .chain_masses.sph_fix &
    i_marker_name = .chain_masses.mass_1.cm &
    j_marker_name = .chain_masses.ground.anchor_mkr

! --- 7. Create spring-dampers between adjacent masses ---
!
! Use loop variable j to connect mass_j to mass_(j+1).
!
for variable_name = j  start_value = 1  end_value = 7

    force create element_like translational_spring_damper &
        spring_damper_name      = (eval(".chain_masses.sd_" // RTOI(j) // "_" // RTOI(j + 1))) &
        i_marker_name           = (eval(".chain_masses.mass_" // RTOI(j) // ".cm")) &
        j_marker_name           = (eval(".chain_masses.mass_" // RTOI(j + 1) // ".cm")) &
        stiffness               = (eval(.chain_masses.stiffness)) &
        damping                 = (eval(.chain_masses.damping)) &
        preload                 = 0.0 &
        displacement_at_preload = (eval(.chain_masses.free_len))

end  ! end for loop (spring-dampers)

! --- 8. Simulate for 2 seconds ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .chain_masses &
    initial_static  = no
