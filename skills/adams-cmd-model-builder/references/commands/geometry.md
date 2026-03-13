# Geometry — CMD Reference

Geometry in Adams is purely visual — it does not affect the dynamics. All geometry is attached to a marker on a part and follows that part's motion in the animation.

## Common Parameters

| Parameter | Description |
|-----------|-------------|
| `part_name` | Part the geometry belongs to |
| `marker_name` | Reference marker defining position and orientation of the geometry |
| `color` | Named color: `red`, `green`, `blue`, `white`, `yellow`, `cyan`, `magneta`, `black` |

---

## Sphere

```cmd
geometry create shape sphere &
    sphere_name  = .model.part.sphere_tip &
    adams_id     = 1 &
    part_name    = .model.part &
    center_marker = .model.part.tip_mkr &
    radius       = 10.0
```

---

## Cylinder

```cmd
geometry create shape cylinder &
    cylinder_name  = .model.link.cyl_body &
    adams_id       = 2 &
    part_name      = .model.link &
    center_marker  = .model.link.base_mkr &
    angle_extent   = 360.0D &
    length         = 200.0 &
    radius         = 8.0 &
    side_count_for_perimeter = 16
```

- `center_marker` is at one **end** of the cylinder; the cylinder extends along its z-axis.
- `angle_extent = 360D` = full cylinder. Reduce for partial cylinder (tube cut).

---

## Box

```cmd
geometry create shape box &
    box_name     = .model.frame.box_body &
    adams_id     = 3 &
    part_name    = .model.frame &
    corner_marker = .model.frame.corner_mkr &
    x_dimension  = 100.0 &
    y_dimension  = 50.0 &
    z_dimension  = 25.0
```

- `corner_marker` is at one corner; the box extends in the +x, +y, +z directions from that marker.

---

## Torus

```cmd
geometry create shape torus &
    torus_name   = .model.wheel.torus_rim &
    adams_id     = 4 &
    part_name    = .model.wheel &
    center_marker = .model.wheel.hub_mkr &
    outer_radius  = 150.0 &
    inner_radius  = 120.0
```

- Torus axis = z-axis of `center_marker`.

---

## Frustum (Cone / Truncated Cone)

```cmd
geometry create shape frustum &
    frustum_name  = .model.piston.frus_tip &
    adams_id      = 5 &
    part_name     = .model.piston &
    center_marker = .model.piston.base_mkr &
    length        = 50.0 &
    bottom_radius = 15.0 &
    top_radius    = 5.0 &
    angle_extent  = 360.0D
```

- For a full cone set `top_radius = 0.0`.

---

## Ellipsoid

```cmd
geometry create shape ellipsoid &
    ellipsoid_name = .model.body.ellips_1 &
    adams_id       = 6 &
    part_name      = .model.body &
    center_marker  = .model.body.cm &
    x_scale_factor = 30.0 &
    y_scale_factor = 15.0 &
    z_scale_factor = 10.0
```

---

## Link (Bar / Rod Shape)

A `link` geometry draws a bar between two markers, with optional width and depth.

```cmd
geometry create shape link &
    link_name    = .model.link.shape_link &
    adams_id     = 7 &
    part_name    = .model.link &
    i_marker_name = .model.link.end_a_mkr &
    j_marker_name = .model.link.end_b_mkr &
    width        = 10.0 &
    depth        = 5.0
```

---

## Modifying Geometry Color

```cmd
geometry modify shape sphere &
    sphere_name = .model.part.sphere_tip &
    color       = red
```

---

## See also

- [Model, Parts, and Markers](model-parts-markers.md)
