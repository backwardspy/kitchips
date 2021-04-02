extends "res://camera/BaseCamera.gd"

export(float) var height: float = 5
export(float) var distance: float = 15
export(float) var look_height_offset: float = 3

func _process(_dt: float):
    if not target:
        return

    var me := global_transform.origin
    var tgt := target.global_transform.origin
    
    var me2d := Vector2(me.x, me.z)
    var tgt2d := Vector2(tgt.x, tgt.z)
    
    var v := tgt2d - me2d
    if v.length_squared() > distance * distance:
        v = v.clamped(distance)
        me2d = tgt2d - v
        
    transform.origin = Vector3(me2d.x, tgt.y + height, me2d.y)
    transform = transform.looking_at(tgt + Vector3.UP * look_height_offset, Vector3.UP)
