extends MeshInstance3D

var craft: Craft = null

func set_craft(c: Craft):
    craft = c
    
func _process(_dt: float) -> void:
    if not craft:
        return
        
    global_transform.origin.x = craft.core_body.global_transform.origin.x
    global_transform.origin.z = craft.core_body.global_transform.origin.z
    
    var mat: StandardMaterial3D = get_surface_override_material(0)
    mat.uv1_offset.x = global_transform.origin.x * 0.01
    mat.uv1_offset.y = global_transform.origin.z * 0.01
