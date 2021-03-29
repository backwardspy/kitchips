extends Node

onready var lbl_craft_vars := $UI/CraftVars

func _input(ev: InputEvent):
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_Y:
        var player_chips: RigidBody = $"/root/World/PlayerChips/CoreBody"
        if player_chips:
            var offset := Vector3(
                rand_range(-0.05, 0.05),
                0,
                rand_range(-0.05, 0.05)
            )
            player_chips.add_force(Vector3.UP * 500, offset)

func _process(_dt: float):
    var craft := CraftController.get_active_craft()
    if not craft:
        return
        
    var vars_text := ""
    for v in craft.vars():
        vars_text += "\n%s: %f" % [v.name, v.current_value]
    lbl_craft_vars.text = vars_text
