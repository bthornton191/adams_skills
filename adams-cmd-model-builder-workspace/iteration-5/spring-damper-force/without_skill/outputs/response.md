# Creating a Spring-Damper Force in Adams CMD

To create a spring-damper force between two parts in Adams/View using CMD scripting, use the `force create element_like springdamper` command.

## Basic Syntax

```
force create element_like springdamper &
    spring_damper_name = <name> &
    adams_id = <id> &
    i_marker_name = <part1_marker> &
    j_marker_name = <part2_marker> &
    stiffness_coefficient = <k> &
    damping_coefficient = <c> &
    free_length = <L0>
```

## Example

Assuming you have two parts (`PART_1` and `PART_2`) each with a marker defining the attachment point:

```cmd
! Create markers on each part at the connection point
marker create &
    marker_name = PART_1.MAR_SPRING &
    location = 0.0, 0.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

marker create &
    marker_name = PART_2.MAR_SPRING &
    location = 0.0, 250.0, 0.0 &
    orientation = 0.0, 0.0, 0.0

! Create the spring-damper force
force create element_like springdamper &
    spring_damper_name = .MODEL_1.SPRING_1 &
    adams_id = 1 &
    i_marker_name = .MODEL_1.PART_1.MAR_SPRING &
    j_marker_name = .MODEL_1.PART_2.MAR_SPRING &
    stiffness_coefficient = 5000.0 &
    damping_coefficient = 100.0 &
    free_length = 250.0
```

## Parameter Notes

| Parameter | Value | Notes |
|---|---|---|
| `stiffness_coefficient` | `5000.0` | Units: N/mm |
| `damping_coefficient` | `100.0` | Units: N·s/mm |
| `free_length` | `250.0` | Units: mm — the natural (unstretched) length |
| `i_marker_name` | marker on first part | The spring acts along the line between I and J markers |
| `j_marker_name` | marker on second part | |

## Important Notes

1. **Units**: Adams uses the unit system defined in your model. Confirm your model is set to mm/N/s before using these values. You can check with:
   ```cmd
   defaults units &
       length = mm &
       force = newton &
       time = second &
       mass = kg
   ```

2. **Free Length**: The `free_length` is the length at which the spring exerts zero force. If the distance between the I and J markers equals 250 mm, the spring force is zero.

3. **Force Direction**: The spring-damper force acts along the line connecting the I and J markers. It is a translational (linear) spring-damper.

4. **Model Name**: Replace `.MODEL_1` with your actual model name. You can check the current model name using:
   ```cmd
   model list
   ```

5. **Preload**: If you want an initial preload instead of specifying free length, you can use `lin_stiff_preload` in place of `free_length`, but `free_length` is more common.

## Verification

After creation, verify the spring-damper was created correctly:
```cmd
force list spring_damper = .MODEL_1.SPRING_1
```

Or view its properties in the Adams/View interface via **Forces > Springs** in the model tree.
