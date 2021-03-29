extends Node

const Craft = preload("res://chips/scripts/Craft.gd")

func _ready():
    load_craft()
    
func _input(ev: InputEvent):
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_U:
        $"/root/World/PlayerChips".queue_free()
        load_craft()

func load_craft():
    var loader := ChipLoader.new()
    var craft := loader.load_chips("res://test/chips/basic.json")
    if craft:
        print("successfully loaded craft!")
        call_deferred("spawn_craft", craft)
    else:
        print("failed to load craft")

func spawn_craft(craft: Craft):
    $"/root/World".add_child(craft.node)
    craft.core_body.transform.origin = $"../SpawnPoint".transform.origin
    CraftController.set_active_craft(craft)
    
    $"/root/World/Camera".target = craft.core_body
