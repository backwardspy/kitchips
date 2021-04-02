extends Object

class_name Craft

class Motor:
    var body: RigidBody
    var reversed: bool
    
class Hinge:
    var joint: HingeJoint
    var reversed: bool

class Jet:
    var body: RigidBody
    var reversed: bool

class Var:
    var name: String
    var default: float
    var minimum: float
    var maximum: float
    var step: float
    var gravity: float
    var positive_key: int
    var negative_key: int
    
    var current_value: float
    
    var motors: Array
    var hinges: Array
    var jets: Array
    
var name: String
var author: String
var node: Node
var core_body: RigidBody
var _vars: Array
var _name_to_var: Dictionary

func add_var(v: Var):
    v.current_value = v.default
    _vars.append(v)
    _name_to_var[v.name] = v

func add_motor(var_name: String, body: RigidBody, reverse: bool) -> void:
    var v: Var = _name_to_var[var_name]
    var motor := Motor.new()
    motor.body = body
    motor.reversed = reverse
    v.motors.append(motor)
    
func add_hinge(var_name: String, joint: HingeJoint, reverse: bool) -> void:
    var v: Var = _name_to_var[var_name]
    var hinge := Hinge.new()
    hinge.joint = joint
    hinge.reversed = reverse
    v.hinges.append(hinge)
    
func add_jet(var_name: String, body: RigidBody, reverse: bool) -> void:
    var v := get_var(var_name)
    var jet := Jet.new()
    jet.body = body
    jet.reversed = reverse
    v.jets.append(jet)

func vars() -> Array:
    return _vars
    
func get_var(name: String) -> Var:
    return _name_to_var[name]
