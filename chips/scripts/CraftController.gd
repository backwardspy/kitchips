extends Node

var craft: Craft = null

var held_keys := {}

func set_active_craft(c: Craft):
    craft = c
    
func get_active_craft() -> Craft:
    return craft

func _process(dt: float):
    if not craft:
        return
        
    for v in craft.vars():
        if held_keys.get(v.positive_key, false):
            increase_var(v, dt)
        elif held_keys.get(v.negative_key, false):
            decrease_var(v, dt)
        else:
            relax_var(v, dt)
        
        for motor in v.motors:
            var body: RigidBody = motor.body
            var mult := -1 if motor.reversed else 1
            body.add_torque(body.transform.basis.y * v.current_value * mult)
        
        for hinge in v.hinges:
            var joint: HingeJoint = hinge.joint
            var mult := -1 if hinge.reversed else 1
            var setpoint := deg2rad(v.current_value * mult - v.default)
            joint.set_param(HingeJoint.PARAM_LIMIT_LOWER, setpoint)
            joint.set_param(HingeJoint.PARAM_LIMIT_UPPER, setpoint)
            
        for jet in v.jets:
            var body: RigidBody = jet.body
            var mult := -1.0 if jet.reversed else 1.0
            var power: float = v.current_value * mult
            body.add_central_force(body.transform.basis.y * power)
            body.get_node("Flame").set_power(power)
            
    for body in get_tree().get_nodes_in_group("aerodynamics"):
        if body is RigidBody:
            var height: float = body.global_transform.origin.y
            var below_water := height < 0
            
            var lift := Aerodynamics.calculate_lift_force(body, below_water)
            
            var bouyancy := Vector3.ZERO
            if below_water:
                var factor := min(1, -height)   # get depth between 0 and 1
                bouyancy = Vector3.UP * factor * 100.0
            
            body.add_central_force(lift + bouyancy)
        
func _input(ev: InputEvent):
    if not craft:
        return
        
    if ev is InputEventKey:
        held_keys[ev.scancode] = ev.pressed

func increase_var(v: Craft.Var, dt: float):
    v.current_value = min(v.maximum, v.current_value + v.step * dt)
    
func decrease_var(v: Craft.Var, dt: float):
    v.current_value = max(v.minimum, v.current_value - v.step * dt)
    
func relax_var(v: Craft.Var, dt: float):
    if v.current_value > v.default:
        v.current_value = max(v.default, v.current_value - v.gravity * dt)
    elif v.current_value < v.default:
        v.current_value = min(v.default, v.current_value + v.gravity * dt)
