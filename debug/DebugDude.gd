extends Node

onready var lbl_craft_vars := $UI/CraftVars

func _input(ev: InputEvent):
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_Y:
        var craft := CraftController.get_active_craft()
        if craft:
            var offset := Vector3(
                rand_range(-0.5, 0.5),
                0,
                rand_range(-0.5, 0.5)
            )
            
            for child in craft.node.get_children():
                if child is RigidBody:
                    child.add_force(Vector3.UP * 1500, offset)

func _process(_dt: float):
    var craft := CraftController.get_active_craft()
    if not craft:
        return
        
    var vars_text := ""
    for v in craft.vars():
        vars_text += "\n%s: %f" % [v.name, v.current_value]
    lbl_craft_vars.text = vars_text
