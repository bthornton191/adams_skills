! ============================================================
! Parametric Spring-Damper Chain — Adams CMD script
!
! 8 point masses in a line along the X axis, spaced 50 mm
! apart, starting at the origin.  The first mass is pinned
! (spherical joint) to ground.  Each adjacent pair of masses
! is connected by a translational spring-damper.
!
! Parameters are stored in variables so the chain length,
! spacing, mass, and spring properties can all be changed
! from a single location.
!
! Demonstrates:
!   - variable set / EVAL()
!   - for / end loop
!   - string concatenation with // and RTOI()
!   - point_mass create / modify workflow
!   - translational_spring_damper
!   - simulation single_run transient
! ============================================================

! ---- 1. Model and units ----
model create model_name = chain

defaults units &
    length = mm &
    force  = newton &
    mass   = kg &
    time   = sec

! ---- 2. Model parameters ----
variable set variable_name = .chain.n_masses   real_value = 8      ! number of masses
variable set variable_name = .chain.spacing    real_value = 50.0   ! mm between masses
variable set variable_name = .chain.pt_mass    real_value = 0.25   ! kg per mass
variable set variable_name = .chain.stiffness  real_value = 100.0  ! N/mm spring stiffness
variable set variable_name = .chain.damping    real_value = 1.0    ! N·s/mm damping
variable set variable_name = .chain.free_len   real_value = 50.0   ! mm free length

! ---- 3. Gravity ----
force create body gravitational &
    gravity_field_name  = .chain.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! ---- 4. Ground anchor marker at the origin ----
marker create &
    marker_name = .chain.ground.anchor_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! ---- 5. Create all point masses in a parametric loop ----
!
! Mass i is placed at global x = (i-1)*spacing, y = 0, z = 0
! Each mass needs:
!   a) part create point_mass
!   b) .cm marker (required before mass_properties)
!   c) part modify mass_properties with center_of_mass_marker
!   d) sphere geometry for visualisation
!
for variable_name = i  start_value = 1  end_value = (eval(.chain.n_masses))

    ! --- Create point mass ---
    part create point_mass name_and_position &
        point_mass_name = (eval(".chain.mass_" // RTOI(i))) &
        location        = ((i-1) * eval(.chain.spacing)), 0.0, 0.0

    ! --- CM marker (must exist before mass_properties call) ---
    marker create &
        marker_name = (eval(".chain.mass_" // RTOI(i) // ".cm")) &
        location    = 0.0, 0.0, 0.0 &
        orientation = 0.0D, 0.0D, 0.0D

    ! --- Set mass properties ---
    part modify point_mass mass_properties &
        point_mass_name       = (eval(".chain.mass_" // RTOI(i))) &
        mass                  = (eval(.chain.pt_mass)) &
        center_of_mass_marker = (eval(".chain.mass_" // RTOI(i) // ".cm"))

    ! --- Ellipsoid geometry for visualisation ---
    geometry create shape ellipsoid &
        ellipsoid_name = (eval(".chain.mass_" // RTOI(i) // ".ellips")) &
        center_marker  = (eval(".chain.mass_" // RTOI(i) // ".cm")) &
        x_scale_factor = 5.0 &
        y_scale_factor = 5.0 &
        z_scale_factor = 5.0

end  ! end mass-creation loop

! ---- 6. Fix first mass to ground ----
!
! Adams does not allow a fixed joint on a point mass.
! A spherical joint removes all 3 translational DOF; since a
! point mass carries no rotational DOF this fully constrains it.
!
constraint create joint spherical &
    joint_name    = .chain.sph_gnd_1 &
    i_marker_name = .chain.mass_1.cm &
    j_marker_name = .chain.ground.anchor_mkr

! ---- 7. Create spring-dampers between consecutive masses ----
!
! Spring j connects mass_j to mass_{j+1}.
! displacement_at_preload = free length = 50 mm (equal to the
! initial separation, so initial spring force is zero).
!
for variable_name = j  start_value = 1  end_value = (eval(.chain.n_masses - 1))

    force create element_like translational_spring_damper &
        spring_damper_name      = (eval(".chain.spr_" // RTOI(j) // "_" // RTOI(j+1))) &
        i_marker_name           = (eval(".chain.mass_" // RTOI(j) // ".cm")) &
        j_marker_name           = (eval(".chain.mass_" // RTOI(j+1) // ".cm")) &
        stiffness               = (eval(.chain.stiffness)) &
        damping                 = (eval(.chain.damping)) &
        preload                 = 0.0 &
        displacement_at_preload = (eval(.chain.free_len))

end  ! end spring-damper loop

! ---- 8. Transient simulation — 2 seconds ----
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .chain &
    initial_static  = no

! ============================================================
! End of parametric_chain.cmd
!
! To change the chain length, edit n_masses above and re-run.
! To change spring properties, edit stiffness / damping / free_len.
! ============================================================
