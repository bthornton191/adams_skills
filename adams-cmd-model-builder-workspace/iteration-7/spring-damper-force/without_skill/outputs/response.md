# Creating a Spring-Damper Force in Adams CMD

To create a translational spring-damper force between two parts in Adams/View CMD, use the `force create element_like translational_spring_damper` command.

## Prerequisites

Each part needs a marker at the point where the spring-damper will attach. The two markers define the spring's line of action — Adams measures spring deformation along the vector from `j_marker` to `i_marker`.

```
! Create attachment markers (if not already defined)
marker create &
  marker_name = .MODEL.PART_1.MAR_SPRING_I &
  location = (0.0, 0.0, 0.0) &
  orientation = (0.0, 0.0, 0.0)

marker create &
  marker_name = .MODEL.PART_2.MAR_SPRING_J &
  location = (0.0, 250.0, 0.0) &
  orientation = (0.0, 0.0, 0.0)
```

## Creating the Spring-Damper

```
force create element_like translational_spring_damper &
  spring_damper_name = .MODEL.spring_damper_1 &
  i_marker_name = .MODEL.PART_1.MAR_SPRING_I &
  j_marker_name = .MODEL.PART_2.MAR_SPRING_J &
  stiffness = 5000.0 &
  damping = 100.0 &
  free_length = 250.0
```

### Parameter Notes

| Parameter | Value | Description |
|-----------|-------|-------------|
| `stiffness` | `5000.0` | Spring stiffness in N/mm (MMKS units) |
| `damping` | `100.0` | Damping coefficient in N·s/mm |
| `free_length` | `250.0` | Natural (unstretched) length in mm |
| `i_marker_name` | on PART_1 | The "action" marker |
| `j_marker_name` | on PART_2 | The "reaction" marker |

## Unit System

The values above assume the **MMKS** unit system (millimetres, kilograms, seconds, Newtons), which is the default in many Adams models. Verify with:

```
units set units_name = MMKS
```

If your model uses MKS (metres), convert: 5 000 000 N/m stiffness, 100 000 N·s/m damping, 0.25 m free length.

## Verify the Element

```
force list_info element_like translational_spring_damper &
  spring_damper_name = .MODEL.spring_damper_1
```

## How It Works

Adams computes the spring-damper force as:

$$F = -k(x - L_0) - c\dot{x}$$

where:
- $k$ = stiffness (5000 N/mm)
- $L_0$ = free length (250 mm)
- $c$ = damping coefficient (100 N·s/mm)
- $x$ = current distance between `i_marker` and `j_marker`
- $\dot{x}$ = rate of change of that distance

A positive force value is compressive (pushing the markers apart toward the free length); a negative value is tensile.
