extends Spatial


func _ready():
    $WorldLoader.connect("craft_spawned", CraftController, "set_active_craft")
    $WorldLoader.connect("craft_spawned", $Camera, "set_target")
    $WorldLoader.connect("craft_spawned", $Water, "set_craft")
