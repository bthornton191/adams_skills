! ============================================================
! Parametric Chain of 8 Point Masses
! Units: kg, mm, s  (gravity in mm/s^2)
! ============================================================

model create &
    model_name = .model

! --- Gravity ---
force create body gravitational &
    gravity_field_name  = .model.gravity &
    x_component_gravity = 0.0 &
    y_component_gravity = -9806.65 &
    z_component_gravity = 0.0

! --- Ground marker (anchor for fixed joint on mass_1) ---
marker create &
    marker_name = .model.ground.fix_mkr &
    location    = 0.0, 0.0, 0.0 &
    orientation = 0.0D, 0.0D, 0.0D

! --- Parametric loop: create masses, markers, joint, and spring-dampers ---
for variable_name = i  start_value = 1  end_value = 8

    part create point_mass name_and_position &
        point_mass_name = (eval(".model.mass_" // RTOI(i))) &
        location        = (eval((i-1) * 50.0)), 0.0, 0.0

    marker create &
        marker_name = (eval(".model.mass_" // RTOI(i) // ".cm")) &
        location    = 0.0, 0.0, 0.0 &
        orientation = 0.0D, 0.0D, 0.0D

    part modify point_mass mass_properties &
        point_mass_name       = (eval(".model.mass_" // RTOI(i))) &
        mass                  = 0.25 &
        center_of_mass_marker = (eval(".model.mass_" // RTOI(i) // ".cm"))

    marker create &
        marker_name = (eval(".model.mass_" // RTOI(i) // ".ref_mkr")) &
        location    = 0.0, 0.0, 0.0 &
        orientation = 0.0D, 0.0D, 0.0D

    if condition = (i == 1)
        constraint create joint spherical &
            joint_name    = .model.fix_mass_1 &
            i_marker_name = .model.mass_1.ref_mkr &
            j_marker_name = .model.ground.fix_mkr
    end

    if condition = (i > 1)
        force create element_like translational_spring_damper &
            spring_damper_name      = (eval(".model.spring_" // RTOI(i-1) // "_" // RTOI(i))) &
            i_marker_name           = (eval(".model.mass_" // RTOI(i-1) // ".ref_mkr")) &
            j_marker_name           = (eval(".model.mass_" // RTOI(i) // ".ref_mkr")) &
            stiffness               = 100.0 &
            damping                 = 1.0 &
            displacement_at_preload = 50.0
    end

end

! --- Transient simulation ---
simulation single_run transient &
    type            = auto_select &
    end_time        = 2.0 &
    number_of_steps = 2000 &
    model_name      = .model &
    initial_static  = no
