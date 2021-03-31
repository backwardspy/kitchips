extends Spatial

onready var original_transform := transform

var power := 0.0

func _process(dt: float) -> void:
    var time := OS.get_ticks_usec() / 1000000.0
    var flicker := 1 + sin(time * 30) * 0.1
    var length := clamp(power / 1000, -1.0, 1.0)
    transform = original_transform.scaled(Vector3(1, flicker * length, 1))
    
func set_power(power: float) -> void:
    self.power = power
