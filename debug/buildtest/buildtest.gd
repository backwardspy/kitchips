extends Spatial

const Constants := preload("res://world/Constants.gd")

const CHIP := preload("res://chips/Chip.tscn")
const CORE := preload("res://chips/Core.tscn")
const FRAME := preload("res://chips/Frame.tscn")
const RUDDER := preload("res://chips/Rudder.tscn")
const TRIM := preload("res://chips/Trim.tscn")
const WHEEL := preload("res://chips/Wheel.tscn")

enum JointType {
    CHIP,
    RUDDER,
    TRIM,
}

class JointPlaceholder extends Spatial:
    var node_a: String
    var node_b: String
    var type: int   # a JointType value

var core_body: RigidBody = null

func _input(ev: InputEvent) -> void:
    if core_body == null:
        return
        
    if ev is InputEventKey and ev.pressed and ev.scancode == KEY_Y:
        var offset_ang := rand_range(0, TAU)
        var offset_radius := randf()
        var offset := Vector3(cos(offset_ang)*offset_radius, 0, sin(offset_ang)*offset_radius)
        core_body.add_force(Vector3.UP * 500, offset)

func _ready() -> void:
    # eventual container for the player's model
    var chips := Node.new()
    chips.name = "Chips"
    
    # we keep track of joint placeholders for easy replacement later
    var joint_placeholders := []
    
    # build model tree
    var core := CORE.instance()
    core.name = "Core"
    core_body = core
    
    var chip1 := CHIP.instance()
    chip1.name = "Chip 1"
    chip1.transform.origin = Vector3(0, 0, -1) * Constants.CHIP_SIZE
    core.add_child(chip1)
    
    var joint1 := make_joint(chip1, core, JointType.CHIP)
    joint1.transform.origin = Vector3(0, 0, 1) * Constants.CHIP_HALF_SIZE
    joint_placeholders.append(joint1)
    chip1.add_child(joint1)
    
    var rudder1 := RUDDER.instance()
    rudder1.name = "Rudder 1"
    rudder1.transform.origin = Vector3(0, 0, -1) * Constants.CHIP_SIZE
    chip1.add_child(rudder1)
    
    var joint2 := make_joint(rudder1, chip1, JointType.RUDDER)
    joint2.transform.origin = Vector3(0, 0, 1) * Constants.CHIP_HALF_SIZE
    joint_placeholders.append(joint2)
    rudder1.add_child(joint2)
    
    var trim1 := TRIM.instance()
    trim1.name = "Trim 1"
    trim1.transform.origin = Vector3(0, 0, -1) * Constants.CHIP_SIZE
    rudder1.add_child(trim1)
    
    var joint3 := make_joint(trim1, rudder1, JointType.TRIM)
    joint3.transform.origin = Vector3(0, 0, 1) * Constants.CHIP_HALF_SIZE
    joint_placeholders.append(joint3)
    trim1.add_child(joint3)
    
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
    
func make_joint(from: RigidBody, to: RigidBody, type: int) -> JointPlaceholder:
    var from_path := "../%s" % from.name
    var to_path := "../%s" % to.name
    var joint_name := "[CHP] %s -> %s" % [from.name, to.name]
    
    var joint := JointPlaceholder.new()
    joint.name = joint_name
    joint.node_a = from_path
    joint.node_b = to_path
    joint.type = type
    
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
    var joint := HingeJoint.new()
    joint.name = joint_placeholder.name
    joint.set_node_a(joint_placeholder.node_a)
    joint.set_node_b(joint_placeholder.node_b)
    joint.transform = joint_placeholder.transform
    
    match joint_placeholder.type:
        JointType.CHIP: joint.rotate(Vector3.UP, TAU / 4)
        JointType.RUDDER: joint.rotate(Vector3.RIGHT, TAU / 4)
        JointType.TRIM: pass
        
    return joint
