extends Spatial


func _ready():
    var err := $WorldLoader.connect("craft_spawned", CraftController, "set_active_craft")
    if err != OK:
        push_error("Failed to connect WorldLoader::craft_spawned to CraftController::set_active_craft")

    err = $WorldLoader.connect("craft_spawned", $Camera, "set_target")
    if err != OK:
        push_error("Failed to connect WorldLoader::craft_spawned to Camera::set_target")

    err = $WorldLoader.connect("craft_spawned", $Water, "set_craft")
    if err != OK:
        push_error("Failed to connect WorldLoader::craft_spawned to Water::set_craft")
