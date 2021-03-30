extends Spatial

const Constants := preload("res://world/Constants.gd")

enum ChipType {
    CORE,
    CHIP,
    FRAME,
    RUDDER,
    TRIM,
    WHEEL,
}

enum JointType {
    CHIP,
    RUDDER,
    TRIM,
    WHEEL,
}

enum Attachment {
    NEG_Z,
    POS_Z,
    NEG_X,
    POS_X,
}

var CHIP_SCENES := {
    ChipType.CHIP: preload("res://chips/Chip.tscn"),
    ChipType.CORE: preload("res://chips/Core.tscn"),
    ChipType.FRAME: preload("res://chips/Frame.tscn"),
    ChipType.RUDDER: preload("res://chips/Rudder.tscn"),
    ChipType.TRIM: preload("res://chips/Trim.tscn"),
    ChipType.WHEEL: preload("res://chips/WheelHub.tscn"),
}

const WHEEL_SCENE := preload("res://chips/Wheel.tscn")

var CHIP_JOINT_TYPES := {
    ChipType.CHIP: JointType.CHIP,
    ChipType.FRAME: JointType.CHIP,
    ChipType.RUDDER: JointType.RUDDER,
    ChipType.TRIM: JointType.TRIM,
    ChipType.WHEEL: JointType.CHIP,
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

class JointPlaceholder extends Spatial:
    var node_a: String
    var node_b: String
    var type: int   # a JointType value
    var set_angle: float

var core: RigidBody = null

func _input(ev: InputEvent) -> void:
    if core == null:
        return
        
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_Y:
        var offset_ang := rand_range(0, TAU)
        var offset_radius := randf()
        var offset := Vector3(cos(offset_ang)*offset_radius, 0, sin(offset_ang)*offset_radius)
        core.add_force(Vector3.UP * 20000, offset)

func _ready() -> void:
    # eventual container for the player's model
    var chips := Node.new()
    chips.name = "Chips"
    
    # we keep track of joint placeholders for easy replacement later
    var joint_placeholders := []
    
    # build model tree
    core = make_core()
    
    var body1 := attach(
        ChipType.CHIP,
        core,
        Attachment.NEG_Z,
        0,
        "Body 1",
        joint_placeholders
    )
    
    var rudder := attach(
        ChipType.RUDDER,
        body1,
        Attachment.NEG_Z,
        0,
        "Steering",
        joint_placeholders
    )
    
    var axle_fr := attach(
        ChipType.FRAME,
        rudder,
        Attachment.POS_X,
        0,
        "FRAxle",
        joint_placeholders
    )
    
    var wheel_fr := attach(
        ChipType.WHEEL,
        axle_fr,
        Attachment.NEG_Z,
        -TAU/4,
        "FRWheel",
        joint_placeholders
    )
    
    var axle_fl := attach(
        ChipType.FRAME,
        rudder,
        Attachment.NEG_X,
        0,
        "FLAxle",
        joint_placeholders
    )
    
    var wheel_fl := attach(
        ChipType.WHEEL,
        axle_fl,
        Attachment.NEG_Z,
        -TAU/4,
        "FLWheel",
        joint_placeholders
    )
    
    var body2 := attach(
        ChipType.CHIP,
        core,
        Attachment.POS_Z,
        0,
        "Body 2",
        joint_placeholders
    )
    
    var axle_bl := attach(
        ChipType.FRAME,
        body2,
        Attachment.POS_X,
        0,
        "BLAxle",
        joint_placeholders
    )
    
    var wheel_bl := attach(
        ChipType.WHEEL,
        axle_bl,
        Attachment.NEG_Z,
        -TAU/4,
        "BLWheel",
        joint_placeholders
    )
    
    var axle_br := attach(
        ChipType.FRAME,
        body2,
        Attachment.NEG_X,
        0,
        "BRAxle",
        joint_placeholders
    )
    
    var wheel_br := attach(
        ChipType.WHEEL,
        axle_br,
        Attachment.NEG_Z,
        -TAU/4,
        "BRWheel",
        joint_placeholders
    )
    
    # we have to temporarily add the model to the scene so that godot calculates
    # all the node positions. this node is removed again in the call to
    # flatten_rigidbody_tree below.
    add_child(core)
    
    # scatter the model tree into the chips container
    # this is done to leverage godot's calculation of transforms so we can work
    # in local space before putting the model together at the end.
    flatten_craft_tree(core, chips)
    
    # replace joint placeholders with actual joints
    create_joints(chips, joint_placeholders)
    
    # instantiate the model
    add_child(chips)
    
func make_core() -> RigidBody:
    var core: RigidBody = CHIP_SCENES[ChipType.CORE].instance()
    core.name = "Core"
    return core
    
func attach(
    chip_type: int,
    parent: RigidBody,
    attachment: int,
    angle: float,
    name: String,
    joint_placeholders: Array
) -> RigidBody:
    var joint_type: int = CHIP_JOINT_TYPES[chip_type]
    
    var chip: RigidBody = CHIP_SCENES[chip_type].instance()
    chip.name = name
    
    # point chip in correct direction
    chip.rotate(chip.transform.basis.y, ATTACH_ROTATION[attachment])
    chip.translate(Vector3(0, 0, -Constants.CHIP_HALF_SIZE))
    chip.rotate(JOINT_TYPE_AXES[joint_type], angle)
    chip.translate(Vector3(0, 0, -Constants.CHIP_HALF_SIZE))
    
    parent.add_child(chip)
    
    var joint := make_joint(chip, parent, joint_type, angle)
    joint.transform = chip.transform
    joint.translate(Vector3(0, 0, Constants.CHIP_HALF_SIZE))
    parent.add_child(joint)
    joint_placeholders.append(joint)
    
    match chip_type:
        ChipType.WHEEL: attach_wheel_to_hub(chip, joint_placeholders)
    
    return chip
    
func make_joint(from: RigidBody, to: RigidBody, joint_type: int, set_angle: float) -> JointPlaceholder:
    var from_path := "../%s" % from.name
    var to_path := "../%s" % to.name
    var joint_name := "[CHP] %s -> %s" % [from.name, to.name]
    
    var joint := JointPlaceholder.new()
    joint.name = joint_name
    joint.node_a = from_path
    joint.node_b = to_path
    joint.type = joint_type
    joint.set_angle = set_angle
    
    return joint
    
func attach_wheel_to_hub(hub: RigidBody, joint_placeholders: Array):
    var wheel := WHEEL_SCENE.instance()
    wheel.name = "%s.Wheel" % hub.name
    hub.add_child(wheel)
    
    var joint := JointPlaceholder.new()
    joint.name = "[WHL] %s -> %s" % [wheel.name, hub.name]
    joint.node_a = "../%s" % wheel.name
    joint.node_b = "../%s" % hub.name
    joint.type = JointType.WHEEL
    wheel.add_child(joint)
    
    joint_placeholders.append(joint)
    
    return joint
    
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

func create_joints(chips: Node, joint_placeholders: Array) -> void:
    for joint_placeholder in joint_placeholders:
        var joint := create_joint_from_placeholder(joint_placeholder)
        chips.remove_child(joint_placeholder)
        chips.add_child(joint)
        
func create_joint_from_placeholder(joint_placeholder: JointPlaceholder) -> Joint:
    match joint_placeholder.type:
        JointType.CHIP, JointType.RUDDER, JointType.TRIM:
            return create_hinge_joint(joint_placeholder)
        JointType.WHEEL:
            return create_wheel_joint(joint_placeholder)
        _:
            return null

func create_hinge_joint(joint_placeholder: JointPlaceholder) -> Joint:
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
        
    return joint
    
func create_wheel_joint(joint_placeholder: JointPlaceholder) -> Joint:
    var joint := Generic6DOFJoint.new()
    joint.name = joint_placeholder.name
    joint.set_node_a(joint_placeholder.node_a)
    joint.set_node_b(joint_placeholder.node_b)
    joint.transform = joint_placeholder.transform
    
    # work around a bullet bug that causes generic 6 DOF joints to freak out
    # when rotating in the Y axis
    joint.rotate(joint.transform.basis.x, TAU/4)
    joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_ANGULAR_LIMIT, false)

    return joint
