extends VehicleBody3D
class_name Kart

@export var controller : KartController

@export var engine_power := 70.0
@export var max_steer := 21.0
@export var steer_speed := 20.0

var acceleration_input := 0.0
var steering_input := 0.0

@onready var steering_wheel: MeshInstance3D = $Body/SteeringWheelPivot/SteeringWheel
@onready var frame: MeshInstance3D = $Body/Frame

func _ready():
	_set_frame_color(controller.color)

func _set_frame_color(_color: Color):
	var material = frame.get_active_material(0)
	var override_material = material.duplicate()
	override_material.albedo_color = _color
	frame.set_surface_override_material(0, override_material)

func _process(delta: float) -> void:
	engine_force = acceleration_input * engine_power
	steering = lerp(steering, steering_input * deg_to_rad(max_steer), steer_speed * delta)
	steering_wheel.rotation.y = -steering * 1.25
	# TODO: Find a better way to apply friction, like what?
	brake = 0.05
