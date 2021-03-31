extends ImmediateGeometry


func average(values: Array):
    var sum = values[0]
    for idx in range(1, len(values)):
        sum += values[idx]
    return sum / len(values)

func _process(dt: float) -> void:
    clear()
    begin(Mesh.PRIMITIVE_LINES)
    
    var coms := Array()
    
    set_color(Color.white)
    for body in get_tree().get_nodes_in_group("aerodynamics"):
        if body is RigidBody:
            var lift := Aerodynamics.calculate_lift_force(body)
            add_vertex(body.global_transform.origin)
            add_vertex(body.global_transform.origin + lift)
            
            coms.append(body.global_transform.origin)
            
    var com: Vector3 = average(coms)
    
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
