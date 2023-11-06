extends MeshInstance3D


func average(values: Array):
	var sum = values[0]
	for idx in range(1, len(values)):
		sum += values[idx]
	return sum / len(values)


func _ready() -> void:
	mesh = ImmediateMesh.new()


func _process(_dt: float) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var com := Vector3.ZERO
	var weights := 0.0

	mesh.surface_set_color(Color.WHITE)
	for body in get_tree().get_nodes_in_group("aerodynamics"):
		if body is RigidBody3D:
			var lift := Aerodynamics.calculate_lift_force(body, false)
			mesh.surface_add_vertex(body.global_transform.origin)
			mesh.surface_add_vertex(body.global_transform.origin + lift * 0.003)

			com += body.global_transform.origin * body.mass
			weights += body.mass

	com /= weights

	mesh.surface_set_color(Color.PURPLE)
	mesh.surface_add_vertex(com)
	mesh.surface_add_vertex(com + Vector3.UP)
	mesh.surface_add_vertex(com)
	mesh.surface_add_vertex(com + Vector3.DOWN)
	mesh.surface_add_vertex(com)
	mesh.surface_add_vertex(com + Vector3.RIGHT)
	mesh.surface_add_vertex(com)
	mesh.surface_add_vertex(com + Vector3.LEFT)
	mesh.surface_add_vertex(com)
	mesh.surface_add_vertex(com + Vector3.FORWARD)
	mesh.surface_add_vertex(com)
	mesh.surface_add_vertex(com + Vector3.BACK)

	mesh.surface_end()
