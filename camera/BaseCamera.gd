extends Camera3D

const above_water_environment := preload("res://environment/above_water.tres")
const below_water_environment := preload("res://environment/below_water.tres")

var above_water := true

var target: Node3D = null

func _process(_dt: float) -> void:
    if above_water and global_transform.origin.y < 0:
        above_water = false
        environment = below_water_environment
    elif not above_water and global_transform.origin.y >= 0:
        above_water = true
        environment = above_water_environment

func set_target(craft: Craft) -> void:
    target = craft.core_body
