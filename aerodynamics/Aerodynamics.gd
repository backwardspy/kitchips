extends Node
class_name Aerodynamics

const AIR_DENSITY := 0.2

static func calculate_lift_force(body: RigidBody) -> Vector3:
    var velocity: Vector3 = body.linear_velocity
    var up: Vector3 = body.transform.basis.y
    var deflection := -velocity.dot(up)
    return body.transform.basis.y * deflection * velocity.length() * AIR_DENSITY
