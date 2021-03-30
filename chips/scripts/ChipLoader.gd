extends Object

const Craft = preload("res://chips/scripts/Craft.gd")

class_name ChipLoader

enum ChipType {
    CORE,
    CHIP,
    FRAME,
    RUDDER,
    TRIM,
    WHEEL_HUB,
}

var CHIP_TYPE_NAMES := {
    ChipType.CORE: "Core",
    ChipType.CHIP: "Chip",
    ChipType.FRAME: "Frame",
    ChipType.RUDDER: "Rudder",
    ChipType.TRIM: "Trim",
    ChipType.WHEEL_HUB: "Wheel Hub",
}

var CHIP_SCENES := {
    ChipType.CHIP: preload("res://chips/Chip.tscn"),
    ChipType.CORE: preload("res://chips/Core.tscn"),
    ChipType.FRAME: preload("res://chips/Frame.tscn"),
    ChipType.RUDDER: preload("res://chips/Rudder.tscn"),
    ChipType.TRIM: preload("res://chips/Trim.tscn"),
    ChipType.WHEEL_HUB: preload("res://chips/WheelHub.tscn"),
}
const WHEEL_SCENE := preload("res://chips/Wheel.tscn")

enum JointType {
    CHIP,
    RUDDER,
    TRIM,
    WHEEL,
}

var JOINT_TYPE_TAGS := {
    JointType.CHIP: "CHP",
    JointType.RUDDER: "RDR",
    JointType.TRIM: "TRM",
    JointType.WHEEL: "WHL",
}

enum Attachment {
    NEG_Z,
    POS_Z,
    NEG_X,
    POS_X,
}

var CHIP_TYPE_JOINTS := {
    ChipType.CHIP: JointType.CHIP,
    ChipType.FRAME: JointType.CHIP,
    ChipType.RUDDER: JointType.RUDDER,
    ChipType.TRIM: JointType.TRIM,
    ChipType.WHEEL_HUB: JointType.CHIP,
}

var JOINT_TYPE_AXES := {
    JointType.CHIP: Vector3.RIGHT,
    JointType.RUDDER: Vector3.UP,
    JointType.TRIM: Vector3.FORWARD,
}

# always around local Y axis
var ATTACH_ROTATION := {
    Attachment.NEG_Z: 0,
    Attachment.POS_Z: TAU / 2,
    Attachment.NEG_X: -TAU / 4,
    Attachment.POS_X: TAU / 4,
}

var SCANCODES := {
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

var CHIP_TYPE_STRING_TO_TYPE := {
    "core": ChipType.CORE,
    "chip": ChipType.CHIP,
    "frame": ChipType.FRAME,
    "rudder": ChipType.RUDDER,
    "trim": ChipType.TRIM,
    "wheel": ChipType.WHEEL_HUB,
}

var ATTACHMENT_STRING_TO_ATTACHMENT := {
    "+x": Attachment.POS_X,
    "-x": Attachment.NEG_X,
    "+z": Attachment.POS_Z,
    "-z": Attachment.NEG_Z,
}

enum VarConversion {
    NONE,
    DEG2RAD,
}

class VarConfig:
    var from_var: bool
    var constant_value: float
    var var_name: String
    var reverse: bool
    
    func _init(value, conversion: int = VarConversion.NONE):
        if value is String:
            from_var = true
            constant_value = 0
            if value[0] == "+":
                value.erase(0, 1)
            elif value[0] == "-":
                value.erase(0, 1)
                reverse = true
            var_name = value
        elif value is float:
            from_var = false
            constant_value = convert_value(value, conversion)
            var_name = ""
            reverse = false
        else:
            push_error("invalid value type in VarConfig::_init(): %s" % value.get_class())
            
    func convert_value(value: float, conversion: int) -> float:
        match conversion:
            VarConversion.DEG2RAD: return deg2rad(value)
            _: return value

class JointPlaceholder extends Spatial:
    var node_a: String
    var node_b: String
    var type: int   # a JointType value
    var angle_var: VarConfig
    var power_var: VarConfig

func json_from_file(file_path: String) -> JSONParseResult:
    var file := File.new()
    if file.open(file_path, File.READ) != OK:
        var error_string := "failed to open file: %s"
        push_error(error_string % file_path)
        return null
    var content := file.get_as_text()
    file.close()
    return JSON.parse(content)

func load_chips(file_path: String, temp_container: Node) -> Craft:
    var json := json_from_file(file_path)
    
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
        
    return parse_chips(json.result, temp_container)

func parse_chips(chips: Dictionary, temp_container: Node) -> Craft:
    var craft = Craft.new()
    parse_meta(craft, chips)
    parse_vars(craft, chips)
    parse_body(craft, chips, temp_container)
    return craft

func parse_meta(craft: Craft, chips: Dictionary):
    var meta: Dictionary = chips["meta"]
    craft.name = meta["name"]
    craft.author = meta["author"]

func parse_vars(craft: Craft, chips: Dictionary):
    var vars: Array = chips["vars"]
    for var_conf in vars:
        var v = Craft.Var.new()
        v.name = var_conf["name"]
        v.default = var_conf["default"]
        v.minimum = var_conf["min"]
        v.maximum = var_conf["max"]
        v.step = var_conf["step"]
        v.gravity = var_conf["gravity"]
        v.positive_key = SCANCODES[var_conf["+key"]]
        v.negative_key = SCANCODES[var_conf["-key"]]
        
        craft.add_var(v)

func parse_body(craft: Craft, chips: Dictionary, temp_container: Node):
    var root_chip: Dictionary = chips["body"]
    if root_chip["type"] != "core":
        var error_string := 'expected root chip to be of type "core", instead got "%s"'
        push_error(error_string % root_chip["type"])
        return null

    # we keep track of joint placeholders for easy replacement later
    var joint_placeholders := []
        
    craft.node = Node.new()
    craft.node.name = "Player Craft"

    craft.core_body = make_core()
    var id := 0
    for child in root_chip["children"]:
        id = attach_chip_tree(craft.core_body, child, joint_placeholders, id)

    # make godot calculate everybody's global transforms
    temp_container.add_child(craft.core_body)

    # scatter the model tree into the chips container
    # this is done to leverage godot's calculation of transforms so we can work
    # in local space before putting the model together at the end.
    flatten_craft_tree(craft.core_body, craft.node)
    
    # replace joint placeholders with actual joints
    create_joints(craft, joint_placeholders)

    return craft

func attach_chip_tree(
    parent_body: RigidBody,
    child_config: Dictionary,
    joint_placeholders: Array,
    id: int
) -> int:
    var chip_type: int = CHIP_TYPE_STRING_TO_TYPE[child_config["type"]]
    var attachment: int = ATTACHMENT_STRING_TO_ATTACHMENT[child_config["attached"]]
    
    var angle_var := VarConfig.new(child_config["angle"], VarConversion.DEG2RAD)
    var power_var := VarConfig.new(child_config.get("power", 0.0))

    var body := attach(
        chip_type,
        parent_body,
        attachment,
        angle_var,
        power_var,
        id,
        joint_placeholders
    )
    id += 1

    for child in child_config["children"]:
        id = attach_chip_tree(body, child, joint_placeholders, id)
        
    return id

func make_core() -> RigidBody:
    var core: RigidBody = CHIP_SCENES[ChipType.CORE].instance()
    core.name = "Core"
    return core

func attach(
    chip_type: int,
    parent: RigidBody,
    attachment: int,
    angle_var: VarConfig,
    power_var: VarConfig,
    id: int,
    joint_placeholders: Array
) -> RigidBody:
    var chip: RigidBody = CHIP_SCENES[chip_type].instance()
    chip.name = "%s %d" % [CHIP_TYPE_NAMES[chip_type], id]
    var joint_type: int = CHIP_TYPE_JOINTS[chip_type]
    
    # point chip in correct direction
    chip.rotate(chip.transform.basis.y, ATTACH_ROTATION[attachment])
    chip.translate(Vector3(0, 0, -Constants.CHIP_HALF_SIZE))
    chip.rotate(JOINT_TYPE_AXES[joint_type], angle_var.constant_value)
    chip.translate(Vector3(0, 0, -Constants.CHIP_HALF_SIZE))
    
    parent.add_child(chip)
    
    var joint := make_joint(
        chip,
        parent,
        joint_type,
        angle_var,
        power_var
    )
    joint.transform = chip.transform
    joint.translate(Vector3(0, 0, Constants.CHIP_HALF_SIZE))
    parent.add_child(joint)
    joint_placeholders.append(joint)
    
    match chip_type:
        ChipType.WHEEL_HUB: attach_wheel_to_hub(chip, power_var, joint_placeholders)
    
    return chip
    
func make_joint(
    from: RigidBody,
    to: RigidBody,
    joint_type: int,
    angle_var: VarConfig,
    power_var: VarConfig
) -> JointPlaceholder:
    var joint := JointPlaceholder.new()
    joint.name = "[%s] %s -> %s" % [JOINT_TYPE_TAGS[joint_type], from.name, to.name]
    joint.node_a = "../%s" % from.name
    joint.node_b = "../%s" % to.name
    joint.type = joint_type
    joint.angle_var = angle_var
    joint.power_var = power_var
    return joint
    
func attach_wheel_to_hub(hub: RigidBody, power_var: VarConfig, joint_placeholders: Array) -> void:
    var wheel := WHEEL_SCENE.instance()
    wheel.name = "Wheel on %s" % hub.name
    hub.add_child(wheel)
    
    var joint := make_joint(wheel, hub, JointType.WHEEL, null, power_var)
    wheel.add_child(joint)
    
    joint_placeholders.append(joint)
    
# recursively visits all rigidbodies & joints in the tree and reparents them.
func flatten_craft_tree(body: Spatial, container: Node) -> void:
    for child in body.get_children():
        if child is RigidBody or child is JointPlaceholder:
            flatten_craft_tree(child, container)
            
    # reparent body, preserving transform
    var transform := body.global_transform
    body.get_parent().remove_child(body)
    container.add_child(body)
    body.global_transform = transform

func create_joints(craft: Craft, joint_placeholders: Array) -> void:
    for joint_placeholder in joint_placeholders:
        var joint := create_joint_from_placeholder(craft, joint_placeholder)
        craft.node.remove_child(joint_placeholder)
        craft.node.add_child(joint)
        
func create_joint_from_placeholder(craft: Craft, joint_placeholder: JointPlaceholder) -> Joint:
    match joint_placeholder.type:
        JointType.CHIP, JointType.RUDDER, JointType.TRIM:
            return create_hinge_joint(craft, joint_placeholder)
        JointType.WHEEL:
            return create_wheel_joint(craft, joint_placeholder)
        _:
            return null

func create_hinge_joint(craft: Craft, joint_placeholder: JointPlaceholder) -> Joint:
    var joint := HingeJoint.new()
    joint.name = joint_placeholder.name
    joint.set_node_a(joint_placeholder.node_a)
    joint.set_node_b(joint_placeholder.node_b)
    joint.transform = joint_placeholder.transform
    
    match joint_placeholder.type:
        JointType.CHIP: joint.rotate(joint.transform.basis.y, TAU / 4)
        JointType.RUDDER: joint.rotate(joint.transform.basis.x, TAU / 4)
        JointType.TRIM: pass
        
    joint.set_param(HingeJoint.PARAM_LIMIT_LOWER, 0)
    joint.set_param(HingeJoint.PARAM_LIMIT_UPPER, 0)
    joint.set_flag(HingeJoint.FLAG_USE_LIMIT, true)
    
    if joint_placeholder.angle_var.from_var:
        craft.add_hinge(
            joint_placeholder.angle_var.var_name,
            joint,
            joint_placeholder.angle_var.reverse
        )
        
    return joint
    
func create_wheel_joint(craft: Craft, joint_placeholder: JointPlaceholder) -> Joint:
    var joint := Generic6DOFJoint.new()
    joint.name = joint_placeholder.name
    joint.set_node_a(joint_placeholder.node_a)
    joint.set_node_b(joint_placeholder.node_b)
    joint.transform = joint_placeholder.transform
    
    # work around a bullet bug that causes generic 6 DOF joints to freak out
    # when rotating in the Y axis
    joint.rotate(joint.transform.basis.x, TAU/4)
    joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_ANGULAR_LIMIT, false)
    
    if joint_placeholder.power_var.from_var:
        joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_MOTOR, true)
        craft.add_motor(
            joint_placeholder.power_var.var_name,
            joint,
            joint_placeholder.power_var.reverse
        )
    elif joint_placeholder.power_var.constant_value > 0:
        joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_MOTOR, true)
        joint.set_param_z(
            Generic6DOFJoint.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY,
            joint_placeholder.power_var.constant_value
        )
    
    return joint
    
