extends Node
class_name Aerodynamics

const AIR_DENSITY := 0.2
const WATER_DENSITY := 5.0

static func calculate_lift_force(body: RigidBody, below_water: bool) -> Vector3:
    var velocity: Vector3 = body.linear_velocity
    var direction := velocity.normalized()
    var normal: Vector3 = body.transform.basis.y
    var deflection := -velocity.dot(normal)
    var density := WATER_DENSITY if below_water else AIR_DENSITY
    var lift := body.transform.basis.y * deflection * velocity.length() * density
    
    var drag := -direction * velocity.length_squared() * density * density * 0.02
    
    return lift + drag
