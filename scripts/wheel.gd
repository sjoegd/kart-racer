extends RayCast3D
class_name Wheel

@export var use_as_traction := false
@export var use_as_steering := false

@export var grip := 2.0
@export var radius := 0.33
@export var mesh_radius := 0.33
@export var rpm_per_kmh := 150
@export var spring_strength := 10.0

@onready var kart: Kart = get_parent()
@export var wheel : Node3D

var base_wheel_position : Vector3
var previous_spring_length := 0.0
var rpm := 0.0

func _ready():
	base_wheel_position = wheel.position

func _physics_process(delta: float) -> void:
	var colliding = is_colliding()
	var collision_point = get_collision_point() if colliding else Vector3.ZERO
	
	handle_position(colliding, collision_point, delta)
	handle_steering(delta)
	handle_rotation(delta)
	
	if colliding:
		suspension(delta, collision_point)
		acceleration(collision_point)
		apply_z_force(collision_point)
		apply_x_force(collision_point)

func handle_position(colliding: bool, collision_point: Vector3, delta: float):
	if colliding:
		wheel.global_position = wheel.global_position.lerp(collision_point + (global_basis.y * mesh_radius), 5.0*delta)
	else:
		wheel.position = wheel.position.lerp(base_wheel_position, 5.0*delta)

func handle_steering(delta: float):
	if not use_as_steering:
		return
	rotation_degrees.y = lerp(rotation_degrees.y, kart.steering_rotation, 20.0 * delta)

func handle_rotation(delta: float):
	var vel = (kart.linear_velocity * Vector3(1, 0, 1))
	var speed = vel.length()
	var new_rpm = speed * rpm_per_kmh
	var velocity_dot = vel.dot(kart.basis.z)
	var velocity_dir = 1 if velocity_dot > 0 else -1
	rpm = lerp(rpm, velocity_dir * new_rpm, 100.0 * delta)
	wheel.rotate_x(-rpm * delta / 100)

func suspension(delta: float, collision_point: Vector3):
	var susp_dir = global_basis.y
	
	var raycast_origin = global_position
	var raycast_dest = collision_point
	var distance = raycast_dest.distance_to(raycast_origin)
	
	var spring_length = clamp(distance - radius, 0, kart.suspension_rest_dist)
	var spring_force = spring_strength * (kart.suspension_rest_dist - spring_length)
	var spring_velocity = (previous_spring_length - spring_length) / delta
	previous_spring_length = spring_length
	
	var damper_force = kart.spring_damper * spring_velocity
	
	var suspension_force = basis.y * (spring_force + damper_force)
	var point = raycast_dest + Vector3(0, radius, 0)
	
	kart.apply_force(susp_dir * suspension_force, point - kart.global_position)
	
	if kart.debug:
		#DebugDraw3D.draw_sphere(point, 0.1)
		DebugDraw3D.draw_arrow(global_position, to_global(position + Vector3(-position.x, (suspension_force.y / 2), -position.z)), Color.BLUE, 0.01, true)
		DebugDraw3D.draw_line_hit_offset(global_position, to_global(position + Vector3(-position.x, -1, -position.z)), true, distance, 0.2, Color.RED, Color.RED)

func acceleration(collision_point: Vector3):
	if not use_as_traction:
		return
	
	var direction = -global_basis.z
	var input = kart.accelerate_input
	var torque = (input if input <= 0.0 else input / 2) * kart.engine_power
	
	var point = collision_point + Vector3(0, radius, 0)
	kart.apply_force(direction * torque, point - kart.global_position)
	
	if kart.debug:
		DebugDraw3D.draw_arrow(point, point + direction * torque, Color.LIGHT_BLUE, 0.1, true)

func apply_z_force(collision_point: Vector3):
	var direction := global_basis.z
	var tire_world_velocity := get_point_velocity(global_position)
	var z_force = direction.dot(tire_world_velocity) * kart.mass / 10
	kart.apply_force(-direction * z_force, collision_point - kart.global_position)
	
	var point = collision_point + Vector3(0, radius, 0)
	
	if kart.debug:
		DebugDraw3D.draw_arrow(point, point + (-direction * z_force * 2), Color.BLUE_VIOLET, 0.1, true)

func apply_x_force(collision_point: Vector3):
	var direction = global_basis.x
	var tire_world_velocity := get_point_velocity(global_position)
	var lateral_velocity = direction.dot(tire_world_velocity)
	var desired_velocity_change = -lateral_velocity * grip
	var x_force = desired_velocity_change
	kart.apply_force(direction * x_force, collision_point - kart.global_position)
	
	if kart.debug:
		DebugDraw3D.draw_arrow(global_position, global_position + (direction * x_force), Color.RED, 0.1, true)

func get_point_velocity(point: Vector3) -> Vector3:
	return kart.linear_velocity + kart.angular_velocity.cross(point - kart.global_position)
