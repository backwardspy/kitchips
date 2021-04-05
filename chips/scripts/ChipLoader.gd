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
    JET,
    WEIGHT,
}

var CHIP_TYPE_NAMES := {
    ChipType.CORE: "Core",
    ChipType.CHIP: "Chip",
    ChipType.FRAME: "Frame",
    ChipType.RUDDER: "Rudder",
    ChipType.TRIM: "Trim",
    ChipType.WHEEL_HUB: "Wheel Hub",
    ChipType.JET: "Jet",
    ChipType.WEIGHT: "Weight",
}

var CHIP_SCENES := {
    ChipType.CHIP: preload("res://chips/Chip.tscn"),
    ChipType.CORE: preload("res://chips/Core.tscn"),
    ChipType.FRAME: preload("res://chips/Frame.tscn"),
    ChipType.RUDDER: preload("res://chips/Rudder.tscn"),
    ChipType.TRIM: preload("res://chips/Trim.tscn"),
    ChipType.WHEEL_HUB: preload("res://chips/WheelHub.tscn"),
    ChipType.JET: preload("res://chips/Jet.tscn"),
    ChipType.WEIGHT: preload("res://chips/Weight.tscn"),
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
    ChipType.JET: JointType.CHIP,
    ChipType.WEIGHT: JointType.CHIP,
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
    "jet": ChipType.JET,
    "weight": ChipType.WEIGHT,
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
            push_error("Invalid value type in VarConfig::_init(): %s" % value.get_class())
            
    func convert_value(value: float, conversion: int) -> float:
        match conversion:
            VarConversion.DEG2RAD: return deg2rad(value)
            _: return value

class JointPlaceholder extends Spatial:
    var node_a: RigidBody
    var node_b: RigidBody
    var type: int   # a JointType value
    var angle_var: VarConfig
    var power_var: VarConfig

func json_from_file(file_path: String) -> JSONParseResult:
    var file := File.new()
    if file.open(file_path, File.READ) != OK:
        var error_string := "Failed to open file: %s"
        push_error(error_string % file_path)
        return null
    var content := file.get_as_text()
    file.close()
    return JSON.parse(content)
    
func try_load_lua_script(craft: Craft, file_path: String) -> void:
    var name := file_path.replace(".json", "")
    var script_path := "%s.lua" % name
    var file := File.new()
    if not file.file_exists(script_path):
        print("No associated script found for %s" % file_path)
        return
        
    craft.setup_lua_state(script_path)
    

func load_chips(file_path: String, temp_container: Node, spawn_position: Vector3) -> Craft:
    var json := json_from_file(file_path)
    
    if not json:
        return null
    
    if json.error != OK:
        var error_string := "(%d) Error loading chips on line %d of %s: %s"
        push_error(error_string % [json.error, json.error_line, file_path, json.error_string])
        return null
        
    if typeof(json.result) != TYPE_DICTIONARY:
        var error_string := "Error loading chips from %s: expected dictionary at top level"
        push_error(error_string % file_path)
        return null
        
    var craft := parse_chips(json.result, temp_container, spawn_position)
    try_load_lua_script(craft, file_path)
    return craft

func parse_chips(chips: Dictionary, temp_container: Node, spawn_position: Vector3) -> Craft:
    var craft = Craft.new()
    parse_meta(craft, chips)
    parse_vars(craft, chips)
    parse_body(craft, chips, temp_container, spawn_position)
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

func parse_body(craft: Craft, chips: Dictionary, temp_container: Node, spawn_position: Vector3):
    var root_chip: Dictionary = chips["body"]
    if root_chip["type"] != "core":
        var error_string := 'Expected root chip to be of type "core", instead got "%s"'
        push_error(error_string % root_chip["type"])
        return null

    # we keep track of joint placeholders for easy replacement later
    var joint_placeholders := []
        
    craft.node = Node.new()
    craft.node.name = "Player Craft"

    craft.core_body = make_core(spawn_position)
    var id := 0
    for child in root_chip.get("children", []):
        id = attach_chip_tree(craft, craft.core_body, child, joint_placeholders, id)

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
    craft: Craft,
    parent_body: RigidBody,
    child_config: Dictionary,
    joint_placeholders: Array,
    id: int
) -> int:
    var chip_type: int = CHIP_TYPE_STRING_TO_TYPE[child_config["type"]]
    var attachment: int = ATTACHMENT_STRING_TO_ATTACHMENT[child_config["attached"]]
    var option: int = child_config.get("option", 0)
    
    var angle_var := VarConfig.new(child_config.get("angle", 0.0), VarConversion.DEG2RAD)
    var power_var := VarConfig.new(child_config.get("power", 0.0))

    var body := attach(
        craft,
        chip_type,
        parent_body,
        attachment,
        option,
        angle_var,
        power_var,
        id,
        joint_placeholders
    )
    id += 1

    for child in child_config.get("children", []):
        id = attach_chip_tree(craft, body, child, joint_placeholders, id)
        
    return id

func make_core(spawn_position: Vector3) -> RigidBody:
    var core: RigidBody = CHIP_SCENES[ChipType.CORE].instance()
    core.name = "Core"
    core.transform.origin = spawn_position
    return core

func attach(
    craft: Craft,
    chip_type: int,
    parent: RigidBody,
    attachment: int,
    option: int,
    angle_var: VarConfig,
    power_var: VarConfig,
    id: int,
    joint_placeholders: Array
) -> RigidBody:
    var chip: RigidBody = CHIP_SCENES[chip_type].instance()
    var name := "%s %d" % [CHIP_TYPE_NAMES[chip_type], id]
    chip.name = name
    var joint_type: int = CHIP_TYPE_JOINTS[chip_type]
    
    if chip_type in [ChipType.CHIP, ChipType.RUDDER, ChipType.TRIM]:
        chip.add_to_group("aerodynamics")
        
    if chip_type == ChipType.WHEEL_HUB:
        chip.add_to_group("wheel hubs")
        
    var attach_angle := angle_var.constant_value
    if angle_var.from_var:
        attach_angle = deg2rad(craft.get_var(angle_var.var_name).default)
    
    # point chip in correct direction
    chip.rotate(chip.transform.basis.y, ATTACH_ROTATION[attachment])
    chip.translate(Vector3(0, 0, -Constants.CHIP_HALF_SIZE))
    chip.rotate(get_joint_axis(chip, joint_type), attach_angle)
    chip.translate(Vector3(0, 0, -Constants.CHIP_HALF_SIZE))
    
    if parent.is_in_group("wheel hubs"):
        for child in parent.get_children():
            if child.is_in_group("wheels"):
                parent = child
                break
    
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
        ChipType.JET:
            if power_var.from_var:
                craft.add_jet(power_var.var_name, chip, power_var.reverse)
        ChipType.WEIGHT: chip.mass = 1 + clamp(option, 0, 8)
    
    return chip
    
func get_joint_axis(chip: RigidBody, joint_type: int) -> Vector3:
    match joint_type:
        JointType.CHIP: return chip.transform.basis.x
        JointType.RUDDER: return chip.transform.basis.y
        JointType.TRIM: return chip.transform.basis.z
        _:
            push_error("Unsupported joint type in get_joint_axis - defaulting to x axis")
            return chip.transform.basis.x
    
func make_joint(
    from: RigidBody,
    to: RigidBody,
    joint_type: int,
    angle_var: VarConfig,
    power_var: VarConfig
) -> JointPlaceholder:
    var joint := JointPlaceholder.new()
    joint.name = "[%s] %s -> %s" % [JOINT_TYPE_TAGS[joint_type], from.name, to.name]
    joint.node_a = from
    joint.node_b = to
    joint.type = joint_type
    joint.angle_var = angle_var
    joint.power_var = power_var
    return joint
    
func attach_wheel_to_hub(hub: RigidBody, power_var: VarConfig, joint_placeholders: Array) -> void:
    var wheel := WHEEL_SCENE.instance()
    wheel.name = "Wheel on %s" % hub.name
    wheel.add_to_group("wheels")
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
    joint.set_node_a("../%s" % joint_placeholder.node_a.name)
    joint.set_node_b("../%s" % joint_placeholder.node_b.name)
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
    joint.set_node_a("../%s" % joint_placeholder.node_a.name)
    joint.set_node_b("../%s" % joint_placeholder.node_b.name)
    joint.transform = joint_placeholder.transform
    
    # work around a bullet bug that causes generic 6 DOF joints to freak out
    # when rotating in the Y axis
    joint.rotate(joint.transform.basis.x, TAU/4)
    joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_ANGULAR_LIMIT, false)
    
    if joint_placeholder.power_var.from_var:
        craft.add_motor(
            joint_placeholder.power_var.var_name,
            joint_placeholder.node_a,
            joint_placeholder.power_var.reverse
        )
    
    return joint
    
