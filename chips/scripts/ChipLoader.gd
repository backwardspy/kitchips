extends Object

const Craft = preload("res://chips/scripts/Craft.gd")

class_name ChipLoader

# maps chip "type" fields to physical models
var chip_scenes := {
    "core": preload("res://chips/Core.tscn"),
    "chip": preload("res://chips/Chip.tscn"),
    "wheel": preload("res://chips/Wheel.tscn"),
    "frame": preload("res://chips/Frame.tscn"),
    "rudder": preload("res://chips/Rudder.tscn"),
}

var attachment_offsets := {
    "+x": Vector3.RIGHT * Constants.CHIP_SIZE,
    "-x": Vector3.LEFT * Constants.CHIP_SIZE,
    "+z": Vector3.BACK * Constants.CHIP_SIZE,
    "-z": Vector3.FORWARD * Constants.CHIP_SIZE,
}

var attachment_pivots := {
    "+x": Vector3.RIGHT * Constants.CHIP_HALF_SIZE,
    "-x": Vector3.LEFT * Constants.CHIP_HALF_SIZE,
    "+z": Vector3.BACK * Constants.CHIP_HALF_SIZE,
    "-z": Vector3.FORWARD * Constants.CHIP_HALF_SIZE,
}

var attachment_axes := {
    "+x": Vector3.BACK,
    "-x": Vector3.FORWARD,
    "+z": Vector3.LEFT,
    "-z": Vector3.RIGHT,
}

var scancodes := {
    "up": KEY_UP,
    "down": KEY_DOWN,
    "left": KEY_LEFT,
    "right": KEY_RIGHT,
    "q": KEY_Q,
    "w": KEY_W,
    "e": KEY_E,
    "r": KEY_R,
    "a": KEY_A,
    "s": KEY_S,
    "d": KEY_D,
    "f": KEY_F,
    "z": KEY_Z,
    "x": KEY_X,
    "c": KEY_C,
    "v": KEY_V,
}

func _json_from_file(file_path: String) -> JSONParseResult:
    var file := File.new()
    if file.open(file_path, File.READ) != OK:
        var error_string := "failed to open file: %s"
        push_error(error_string % file_path)
        return null
    var content := file.get_as_text()
    file.close()
    return JSON.parse(content)

func load_chips(file_path: String) -> Craft:
    var json := _json_from_file(file_path)
    
    if not json:
        return null
    
    if json.error != OK:
        var error_string := "(%d) error loading chips on line %d of %s: %s"
        push_error(error_string % [json.error, json.error_line, file_path, json.error_string])
        return null
        
    if typeof(json.result) != TYPE_DICTIONARY:
        var error_string := "error loading chips from %s: expected dictionary at top level"
        push_error(error_string % file_path)
        return null
        
    return _parse_chips(json.result)

func _parse_chips(chips: Dictionary) -> Craft:
    var craft = Craft.new()
    _parse_meta(craft, chips)
    _parse_vars(craft, chips)
    _parse_body(craft, chips)
    return craft
    
func _parse_body(craft: Craft, chips: Dictionary):
    var root_chip: Dictionary = chips["body"]
    if root_chip["type"] != "core":
        var error_string := 'expected root chip to be of type "core", instead got "%s"'
        push_error(error_string % root_chip["type"])
        return null
        
    craft.node = Node.new()
    craft.node.name = "PlayerChips"
    
    var core_body := RigidBody.new()
    core_body.name = "CoreBody"
    craft.core_body = core_body
    craft.node.add_child(core_body)
    
    var core := _make_shape(root_chip["type"])
    core_body.add_child(core)
    
    for child in root_chip["children"]:
        _add_chip_to_body(craft, core_body, core, child)

func _parse_meta(craft: Craft, chips: Dictionary):
    var meta: Dictionary = chips["meta"]
    craft.name = meta["name"]
    craft.author = meta["author"]

func _parse_vars(craft: Craft, chips: Dictionary):
    var vars: Array = chips["vars"]
    for var_conf in vars:
        var v = Craft.Var.new()
        v.name = var_conf["name"]
        v.default = var_conf["default"]
        v.minimum = var_conf["min"]
        v.maximum = var_conf["max"]
        v.step = var_conf["step"]
        v.gravity = var_conf["gravity"]
        v.positive_key = scancodes[var_conf["+key"]]
        v.negative_key = scancodes[var_conf["-key"]]

        craft.add_var(v)

func _add_chip_to_body(craft: Craft, body: RigidBody, parent: CollisionShape, chip: Dictionary):
    var type: String = chip["type"]
    var attachment: String = chip["attached"].to_lower()
    var angle: float = 0
    if chip["angle"] is float:
        angle = deg2rad(chip["angle"])
    var children: Array = chip["children"]
    
    var working_body := body
    
    match type:
        "wheel": working_body = attach_wheel(craft, chip, working_body, parent, attachment, angle)
        "rudder": working_body = attach_rudder(craft, chip, working_body, parent, attachment, angle)
    
    var shape := _make_shape(type)
    # we only need to shift the shape if it's an extension of an existing body
    if working_body == body:
        shape.transform = _calculate_chip_transform(shape.transform, parent, attachment, angle)
    
    working_body.add_child(shape)
    
    for child in children:
        _add_chip_to_body(craft, working_body, shape, child)
    
func _calculate_chip_transform(original: Transform, parent: CollisionShape, attachment: String, angle: float) -> Transform:
    var axis: Vector3 = attachment_axes[attachment]
    var pivot: Vector3 = attachment_pivots[attachment]
    var transform := original
    transform = transform.translated(parent.transform.origin + attachment_offsets[attachment] - pivot)
    transform.basis = transform.basis.rotated(axis, angle)
    transform = transform.translated(pivot)
    return transform
    
func _make_shape(type: String) -> CollisionShape:
    var scene: PackedScene = chip_scenes[type]
    var body: CollisionShape = scene.instance()
    body.name = type
    return body
    
func attach_wheel(
    craft: Craft,
    chip: Dictionary,
    parent_body: RigidBody,
    parent_shape: CollisionShape,
    attachment: String,
    angle: float
) -> RigidBody:
    var wheel_body := RigidBody.new()
    wheel_body.name = "wheel"
    wheel_body.transform = _calculate_chip_transform(wheel_body.transform, parent_shape, attachment, angle)
    craft.node.add_child(wheel_body)
    
    var joint := Generic6DOFJoint.new()
    joint.name = "Axle: %s -> %s" % [wheel_body.name, parent_body.name]
    joint.transform = _calculate_chip_transform(joint.transform, parent_shape, attachment, angle)
    joint.transform.basis = joint.transform.basis.rotated(joint.transform.basis.x, deg2rad(90))
    joint.set_node_a("../%s" % wheel_body.name)
    joint.set_node_b("../%s" % parent_body.name)
    joint.set_param_z(Generic6DOFJoint.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, 0)
    joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_ANGULAR_LIMIT, false)
    joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_MOTOR, true)
    craft.node.add_child(joint)
    
    var power_string: String = chip["power"]
    var reversed := false
    var marker := power_string[0]
    if marker == "+":
        power_string.erase(0, 1)
    elif marker == "-":
        power_string.erase(0, 1)
        reversed = true
    craft.add_motor(power_string, joint, reversed)
    
    return wheel_body
    
func attach_rudder(
    craft: Craft,
    chip: Dictionary,
    parent_body: RigidBody,
    parent_shape: CollisionShape,
    attachment: String,
    angle: float
) -> RigidBody:
    var rudder_body := RigidBody.new()
    rudder_body.name = "rudder"
    rudder_body.transform = _calculate_chip_transform(rudder_body.transform, parent_shape, attachment, angle)
    craft.node.add_child(rudder_body)
    
    var joint := Generic6DOFJoint.new()
    joint.name = "Axle: %s -> %s" % [rudder_body.name, parent_body.name]
    joint.transform.origin = attachment_offsets[attachment]
    joint.set_node_a("../%s" % rudder_body.name)
    joint.set_node_b("../%s" % parent_body.name)
    craft.node.add_child(joint)
    
    var angle_string: String = chip["angle"]
    var reversed := false
    var marker := angle_string[0]
    if marker == "+":
        angle_string.erase(0, 1)
    elif marker == "-":
        angle_string.erase(0, 1)
        reversed = true
    craft.add_rudder(angle_string, joint, reversed)
    
    return rudder_body
