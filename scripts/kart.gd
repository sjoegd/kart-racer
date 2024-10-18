extends VehicleBody3D

const STEER := 0.8
const POWER := 4
const MAX_RPM := 1250
const MAX_TORQUE := 500

@onready var center: Marker3D = $Center

@onready var back_left: VehicleWheel3D = $BackLeft
@onready var back_right: VehicleWheel3D = $BackRight


@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D

@onready var camera_look_at := global_position

func _ready() -> void:
	self.center_of_mass = center.position
	camera_pivot.global_position = global_position
	camera_pivot.transform = transform

func _physics_process(delta: float) -> void:
	process_kart(delta)
	process_camera(delta)
	print(linear_velocity.length())

func process_kart(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("ui_right", "ui_left") * STEER, delta * 2.5)
	var acceleration = Input.get_axis("ui_down", "ui_up") * POWER
	var rpm = (back_left.get_rpm() + back_right.get_rpm()) / 2
	engine_force = acceleration * MAX_TORQUE * ( 1 - (rpm / MAX_RPM) )

# TODO:
# Make sure camera look_at doesn't go behind the car

func process_camera(delta: float) -> void:
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 25.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 7.5)
	camera_look_at = camera_look_at.lerp(global_position + linear_velocity, delta * 7.5)
	camera_3d.look_at(camera_look_at)
