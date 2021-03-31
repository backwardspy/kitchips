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
            var body: RigidBody = motor.body
            var mult := -1 if motor.reversed else 1
            body.add_torque(body.transform.basis.y * v.current_value * mult)
        
        for rudder in v.hinges:
            var joint: HingeJoint = rudder.joint
            var mult := -1 if rudder.reversed else 1
            joint.set_param(
                HingeJoint.PARAM_LIMIT_LOWER,
                deg2rad(v.current_value * mult)
            )
            joint.set_param(
                HingeJoint.PARAM_LIMIT_UPPER,
                deg2rad(v.current_value * mult)
            )
            
        for jet in v.jets:
            var body: RigidBody = jet.body
            var mult := -1.0 if jet.reversed else 1.0
            var power: float = v.current_value * mult
            body.add_central_force(body.transform.basis.y * power)
            body.get_node("Flame").set_power(power)
        
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
