extends ImmediateGeometry

func _process(_dt: float) -> void:
    var tree := get_tree().current_scene
        
    clear()
    begin(Mesh.PRIMITIVE_LINES)
    draw_joints(tree)
    end()
    
func draw_joints(tree: Node) -> void:
    for i in range(0, tree.get_child_count()):
        var child := tree.get_child(i)
        if child is Joint:
            var transform: Transform = child.global_transform
            set_color(Color.red)
            add_vertex(transform.origin)
            add_vertex(transform.origin + transform.basis.x)
            
            set_color(Color.green)
            add_vertex(transform.origin)
            add_vertex(transform.origin + transform.basis.y)
            
            set_color(Color.blue)
            add_vertex(transform.origin)
            add_vertex(transform.origin + transform.basis.z)
            
        draw_joints(child)
