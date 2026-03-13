# Creating a Spring-Damper Force in Adams CMD

In Adams/View, a spring-damper (also called a translational spring-damper) between two parts is created using the `force` element with a `translational_spring_damper` type in the CMD scripting language.

## Basic Approach

Adams CMD uses the `force create element translational_spring_damper` command to define a spring-damper between two bodies. You need to specify:

- The two bodies (parts) involved
- The attachment points (markers) on each body
- Stiffness coefficient (k)
- Damping coefficient (c)
- Free length

## Example CMD Script

```
! Create two markers on the parts to serve as attachment points
! (assuming PART_1 and PART_2 already exist in the model)

marker create  &
    marker_name = .model_1.PART_1.spring_point  &
    adams_id = 10  &
    location = 0.0, 0.0, 0.0  &
    orientation = 0.0, 0.0, 0.0

marker create  &
    marker_name = .model_1.PART_2.spring_point  &
    adams_id = 11  &
    location = 0.0, 250.0, 0.0  &
    orientation = 0.0, 0.0, 0.0

! Create the spring-damper force
force create element translational_spring_damper  &
    spring_damper_name = .model_1.spring_damper_1  &
    i_marker_name = .model_1.PART_1.spring_point  &
    j_marker_name = .model_1.PART_2.spring_point  &
    stiffness = 5000.0  &
    damping = 100.0  &
    free_length = 250.0
```

## Parameter Notes

| Parameter | Value | Notes |
|-----------|-------|-------|
| `stiffness` | 5000.0 | Spring stiffness in N/mm |
| `damping` | 100.0 | Damping coefficient in N·s/mm |
| `free_length` | 250.0 | Natural (unstretched) length in mm |

## Unit Considerations

Make sure your Adams model is set to the correct unit system (e.g., `mmks` — millimeters, kilograms, seconds, Newtons). If your model uses SI units (meters), you would need to convert:

- Stiffness: 5,000,000 N/m
- Damping: 100,000 N·s/m
- Free length: 0.25 m

## Notes

- `i_marker_name` and `j_marker_name` define the two attachment points. The spring acts along the line connecting these markers.
- The `free_length` determines when the spring force is zero (no compression or extension).
- The full dotted path (e.g., `.model_1.PART_1.spring_point`) must reference the actual model and part names in your simulation.
- You can also define stiffness/damping as spline references (for nonlinear behavior) using `stiffness_spline_name` and `damping_spline_name` instead.
