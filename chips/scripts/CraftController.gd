extends Node

var _craft: Craft = null

var _held_keys := {}

func set_active_craft(craft: Craft):
    _craft = craft
    
func get_active_craft() -> Craft:
    return _craft

func _process(dt: float):
    if not _craft:
        return
        
    for v in _craft.vars():
        if _held_keys.get(v.positive_key, false):
            increase_var(v, dt)
        elif _held_keys.get(v.negative_key, false):
            decrease_var(v, dt)
        else:
            relax_var(v, dt)
        
        for motor in v.motors:
            var joint: Generic6DOFJoint = motor.joint
            var mult := -1 if motor.reversed else 1
            joint.set_param_z(Generic6DOFJoint.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, v.current_value * mult)
        
        for rudder in v.rudders:
            var joint: Generic6DOFJoint = rudder.joint
            var mult := -1 if rudder.reversed else 1
            joint.set_param_y(Generic6DOFJoint.PARAM_ANGULAR_LOWER_LIMIT, deg2rad(v.current_value * mult))
            joint.set_param_y(Generic6DOFJoint.PARAM_ANGULAR_UPPER_LIMIT, deg2rad(v.current_value * mult))
        
func _input(ev: InputEvent):
    if not _craft:
        return
        
    if ev is InputEventKey:
        _held_keys[ev.scancode] = ev.pressed

func increase_var(v: Craft.Var, dt: float):
    v.current_value = min(v.maximum, v.current_value + v.step * dt)
    
func decrease_var(v: Craft.Var, dt: float):
    v.current_value = max(v.minimum, v.current_value - v.step * dt)
    
func relax_var(v: Craft.Var, dt: float):
    if v.current_value > v.default:
        v.current_value = max(v.default, v.current_value - v.gravity * dt)
    elif v.current_value < v.default:
        v.current_value = min(v.default, v.current_value + v.gravity * dt)
