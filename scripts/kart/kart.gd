extends VehicleBody3D
class_name Kart

@export var controller : KartController

@export var engine_power := 70.0
@export var brake_power := 2.5
@export var max_steer := 21.0
@export var steer_speed := 20.0
@export var wheels: Array[VehicleWheel3D] = []
@export var engine: KartEngine

@onready var steering_wheel: MeshInstance3D = $Body/SteeringWheelPivot/SteeringWheel
@onready var frame: MeshInstance3D = $Body/Frame
@onready var front_wheel_axle: MeshInstance3D = $Body/FrontWheelAxle

var throttle_input := 0.0
var brake_input := 0.0
var steering_input := 0.0

func _ready():
	_set_frame_color(controller.color)

func _set_frame_color(_color: Color):
	var material = frame.get_active_material(0)
	var override_material = material.duplicate()
	override_material.albedo_color = _color
	frame.set_surface_override_material(0, override_material)

func _process(delta: float) -> void:
	engine_force = throttle_input * engine_power
	steering = lerp(steering, steering_input * deg_to_rad(max_steer), steer_speed * delta)
	brake = brake_input * brake_power + 0.05
	handle_steering_wheel()
	handle_front_axle()

func handle_steering_wheel():
	steering_wheel.rotation.y = -steering * 1.25

func handle_front_axle():
	front_wheel_axle.position.x = -steering * 0.015

func get_rpm():
	var total_rpm := 0.0
	for wheel in wheels:
		total_rpm += abs(wheel.get_rpm())
	return int(total_rpm / wheels.size())
