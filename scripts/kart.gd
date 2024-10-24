extends RigidBody3D
class_name Kart

@export var controller : KartController

@export var front_left_wheel : Wheel
@export var front_right_wheel : Wheel
@export var back_left_wheel : Wheel
@export var back_right_wheel : Wheel

@export var front_wheel_mount : Node3D
@export var back_wheel_mount : Node3D
@export var body : Node3D
@export var body_offset := 0.0

@export var suspension_rest_dist := 0.66
@export var moving_spring_damper := 1.0
@export var still_spring_damper := 1.0

@export var engine_power := 2.0
@export var steering_angle := 30.0 # Degree

@export var debug := false

var accelerate_input := 0.0
var steering_input := 0.0

var steering_rotation := 0.0
var last_grounded_rotation := Vector3.ZERO

@onready var spring_damper := still_spring_damper

func _ready():
	center_of_mass = Vector3(0, -suspension_rest_dist * 2, 0)
	body.position.y += body_offset

func _process(delta: float) -> void:
	steering_rotation = steering_input * steering_angle
	handle_mount_positions()
	
func handle_mount_positions():
	var front_wheel_y = (front_left_wheel.wheel.global_position.y + front_right_wheel.wheel.global_position.y) / 2
	front_wheel_mount.global_position.y = front_wheel_y
	var back_wheel_y = (back_left_wheel.wheel.global_position.y + back_right_wheel.wheel.global_position.y) / 2
	back_wheel_mount.global_position.y = back_wheel_y

func _physics_process(delta: float) -> void:
	stabilize(delta)
	handle_damper(delta)

func handle_damper(delta: float) -> void:
	var desired_damper := still_spring_damper
	if linear_velocity.length() > 10.0:
		desired_damper = moving_spring_damper
	spring_damper = lerp(spring_damper, desired_damper, delta)

func stabilize(delta: float) -> void:
	var check_colliding = func (wheel: Wheel):
		return wheel.is_colliding()
	var in_air = not [front_left_wheel, front_right_wheel, back_left_wheel, back_right_wheel].all(check_colliding)
	if not in_air:
		last_grounded_rotation = global_rotation
	global_rotation.x = lerp(global_rotation.x, deg_to_rad(last_grounded_rotation.x - 10.0 if in_air else 0.0), 7.5*delta)
	global_rotation.z = lerp(global_rotation.z, 0.0, 20.0*delta)
