! ============================================================
! chain.cmd
!
! 8 point masses in a straight line along the X axis,
! spaced 50 mm apart, starting at the origin.
!
!   - Mass 1 is fixed to ground with a fixed joint.
!   - Adjacent masses are connected by spring-dampers:
!       stiffness = 100 N/mm
!       damping   = 1.0 N*s/mm
!       free len  = 50 mm
!   - Each mass = 0.25 kg
!   - FOR loop + EVAL + RTOI + // for parametric construction
!   - Simulation: 2.0 seconds transient
!
! Unit system: mm, kg, N, s
! ============================================================

model create model_name = chain

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! --- Model parameters stored as variables ---
variable set variable_name = .chain.n_masses  real_value = 8.0
variable set variable_name = .chain.spacing   real_value = 50.0
variable set variable_name = .chain.pt_mass   real_value = 0.25
variable set variable_name = .chain.stiffness real_value = 100.0
variable set variable_name = .chain.damping   real_value = 1.0
variable set variable_name = .chain.free_len  real_value = 50.0

! --- Gravity ---
force create body gravitational &
    gravity_field_name  = .chain.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- Ground anchor marker at origin ---
marker create &
    marker_name = .chain.ground.anchor_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- Parametric loop: create 8 point masses ---
!
! Mass i is placed at x = (i-1)*spacing, y = 0, z = 0
! EVAL() evaluates expressions; RTOI() converts real to integer
! string; // concatenates strings to build dot-path names.
!
for variable_name = i  start_value = 1  end_value = (eval(.chain.n_masses))

    part create point_mass name_and_position &
        point_mass_name = (eval(".chain.mass_" // RTOI(i))) &
        location        = (eval((i - 1) * .chain.spacing)), 0.0, 0.0

    marker create &
        marker_name = (eval(".chain.mass_" // RTOI(i) // ".cm")) &
        location    = 0.0, 0.0, 0.0 &
        orientation = 0.0D, 0.0D, 0.0D

    part modify point_mass mass_properties &
        point_mass_name       = (eval(".chain.mass_" // RTOI(i))) &
        mass                  = (eval(.chain.pt_mass)) &
        center_of_mass_marker = (eval(".chain.mass_" // RTOI(i) // ".cm"))

end

! --- Fix mass 1 to ground with a fixed joint ---
constraint create joint fixed &
    joint_name    = .chain.fix_gnd_1 &
    i_marker_name = .chain.mass_1.cm &
    j_marker_name = .chain.ground.anchor_mkr

! --- Parametric loop: create 7 spring-dampers ---
!
! Spring j connects mass_j to mass_(j+1).
! displacement_at_preload = free_len = 50 mm => zero initial force.
!
for variable_name = j  start_value = 1  end_value = (eval(.chain.n_masses - 1))

    force create element_like translational_spring_damper &
        spring_damper_name      = (eval(".chain.spr_" // RTOI(j) // "_" // RTOI(j + 1))) &
        i_marker_name           = (eval(".chain.mass_" // RTOI(j) // ".cm")) &
        j_marker_name           = (eval(".chain.mass_" // RTOI(j + 1) // ".cm")) &
        stiffness               = (eval(.chain.stiffness)) &
        damping                 = (eval(.chain.damping)) &
        preload                 = 0.0 &
        displacement_at_preload = (eval(.chain.free_len))

end

! --- Transient simulation: 2 seconds ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .chain &
    initial_static  = no

! ============================================================
! End of chain.cmd
! ============================================================
