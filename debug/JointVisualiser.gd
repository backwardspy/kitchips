extends MeshInstance3D


func _ready() -> void:
    mesh = ImmediateMesh.new()


func _process(_dt: float) -> void:
    var tree := get_tree().current_scene

    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    draw_joints(tree)
    mesh.surface_end()


func draw_joints(tree: Node) -> void:
    for i in range(0, tree.get_child_count()):
        var child := tree.get_child(i)
        if child is Joint3D:
            var t: Transform3D = child.global_transform
            mesh.surface_set_color(Color.RED)
            mesh.surface_add_vertex(t.origin)
            mesh.surface_add_vertex(t.origin + t.basis.x)
            mesh.surface_set_color(Color.GREEN)
            mesh.surface_add_vertex(t.origin)
            mesh.surface_add_vertex(t.origin + t.basis.y)
            mesh.surface_set_color(Color.BLUE)
            mesh.surface_add_vertex(t.origin)
            mesh.surface_add_vertex(t.origin + t.basis.z)

        draw_joints(child)
