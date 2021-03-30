extends Object

class_name Craft

class Motor:
    var joint: Generic6DOFJoint
    var reversed: bool
    
class Hinge:
    var joint: HingeJoint
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

func add_motor(var_name: String, joint: Generic6DOFJoint, reverse: bool):
    var v: Var = _name_to_var[var_name]
    var motor := Motor.new()
    motor.joint = joint
    motor.reversed = reverse
    v.motors.append(motor)
    
func add_hinge(var_name: String, joint: HingeJoint, reverse: bool):
    var v: Var = _name_to_var[var_name]
    var hinge := Hinge.new()
    hinge.joint = joint
    hinge.reversed = reverse
    v.hinges.append(hinge)

func vars() -> Array:
    return _vars
