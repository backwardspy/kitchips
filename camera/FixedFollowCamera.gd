extends Camera

var target: Spatial = null

func _process(_dt: float):
    if not target:
        return

    var tgt := target.global_transform.origin
    transform = transform.looking_at(tgt + Vector3.UP, Vector3.UP)
