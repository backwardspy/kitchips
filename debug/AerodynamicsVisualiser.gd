extends ImmediateGeometry


func average(values: Array):
    var sum = values[0]
    for idx in range(1, len(values)):
        sum += values[idx]
    return sum / len(values)

func _process(_dt: float) -> void:
    clear()
    begin(Mesh.PRIMITIVE_LINES)

    var com := Vector3.ZERO
    var weights := 0.0

    set_color(Color.white)
    for body in get_tree().get_nodes_in_group("aerodynamics"):
        if body is RigidBody:
            var lift := Aerodynamics.calculate_lift_force(body, false)
            add_vertex(body.global_transform.origin)
            add_vertex(body.global_transform.origin + lift * 0.003)

            com += body.global_transform.origin * body.mass
            weights += body.mass

    com /= weights

    set_color(Color.purple)
    add_vertex(com)
    add_vertex(com + Vector3.UP)
    add_vertex(com)
    add_vertex(com + Vector3.DOWN)
    add_vertex(com)
    add_vertex(com + Vector3.RIGHT)
    add_vertex(com)
    add_vertex(com + Vector3.LEFT)
    add_vertex(com)
    add_vertex(com + Vector3.FORWARD)
    add_vertex(com)
    add_vertex(com + Vector3.BACK)

    end()
