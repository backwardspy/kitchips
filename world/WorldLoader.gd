extends Node

signal craft_spawned

const Craft = preload("res://chips/scripts/Craft.gd")

var last_loaded_path: String

func _ready():
    load_craft("res://test/chips/basic.json")
    
func _input(ev: InputEvent):
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_U and last_loaded_path:
        load_craft(last_loaded_path)

func load_craft(path: String):
    var active_craft := CraftController.get_active_craft()
    if active_craft:
        CraftController.set_active_craft(null)
        active_craft.node.queue_free()
    
    var loader := ChipLoader.new()
    var craft := loader.load_chips(
        path,
        self,
        $SpawnPoint.global_transform.origin
    )
    if craft:
        call_deferred("spawn_craft", craft)
    else:
        push_error("failed to load craft")
    
    last_loaded_path = path

func spawn_craft(craft: Craft):
    get_tree().current_scene.add_child(craft.node)
    emit_signal("craft_spawned", craft)
