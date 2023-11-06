extends Node3D


func _ready():
    var err := $WorldLoader.connect("craft_spawned", Callable(CraftController, "set_active_craft"))
    if err != OK:
        push_error("Failed to connect WorldLoader::craft_spawned to CraftController::set_active_craft")

    err = $WorldLoader.connect("craft_spawned", Callable($Camera3D, "set_target"))
    if err != OK:
        push_error("Failed to connect WorldLoader::craft_spawned to Camera3D::set_target")

    err = $WorldLoader.connect("craft_spawned", Callable($Water, "set_craft"))
    if err != OK:
        push_error("Failed to connect WorldLoader::craft_spawned to Water::set_craft")
