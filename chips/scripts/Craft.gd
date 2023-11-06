extends Object

class_name Craft


class Motor:
    var body: RigidBody3D
    var reversed: bool


class Hinge:
    var joint: HingeJoint3D
    var reversed: bool


class Jet:
    var body: RigidBody3D
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


class CraftScript:
    # var lua_state: Lua
    pass


var name: String
var author: String
var node: Node
var core_body: RigidBody3D
var craft_script: CraftScript
var _vars: Array
var _name_to_var: Dictionary


func add_var(v: Var):
    v.current_value = v.default
    _vars.append(v)
    _name_to_var[v.name] = v


func add_motor(var_name: String, body: RigidBody3D, reverse: bool) -> void:
    var v: Var = _name_to_var[var_name]
    var motor := Motor.new()
    motor.body = body
    motor.reversed = reverse
    v.motors.append(motor)


func add_hinge(var_name: String, joint: HingeJoint3D, reverse: bool) -> void:
    var v: Var = _name_to_var[var_name]
    var hinge := Hinge.new()
    hinge.joint = joint
    hinge.reversed = reverse
    v.hinges.append(hinge)


func add_jet(var_name: String, body: RigidBody3D, reverse: bool) -> void:
    var v := get_var(var_name)
    var jet := Jet.new()
    jet.body = body
    jet.reversed = reverse
    v.jets.append(jet)


func vars() -> Array:
    return _vars


func get_var(var_name: String) -> Var:
    return _name_to_var[var_name]


# --- lua bindings --- #

# --- lua setup --- #


func lua_error_callback(err: String) -> void:
    push_error("Lua error: %s" % err)


func setup_lua_state(_script_path: String) -> void:
    # var lua := Lua.new()
    # lua.doFile(self, script_path, "lua_error_callback")

    craft_script = CraftScript.new()
    # craft_script.lua_state = lua
