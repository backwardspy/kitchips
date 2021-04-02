extends Node

signal craft_spawned

const Craft = preload("res://chips/scripts/Craft.gd")

func _ready():
    load_craft()
    
func _input(ev: InputEvent):
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_U:
        var craft := CraftController.get_active_craft()
        if craft:
            CraftController.set_active_craft(null)
            craft.node.queue_free()
            call_deferred("load_craft")

func load_craft():
    var loader := ChipLoader.new()
    var craft := loader.load_chips(
        "res://test/chips/plane.json",
        self,
        $SpawnPoint.global_transform.origin
    )
    if craft:
        call_deferred("spawn_craft", craft)
    else:
        push_error("failed to load craft")

func spawn_craft(craft: Craft):
    get_tree().current_scene.add_child(craft.node)
    emit_signal("craft_spawned", craft)
    
    # CraftController.set_active_craft(craft)
    # get_viewport().get_camera().target = craft.core_body
