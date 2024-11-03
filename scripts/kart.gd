extends VehicleBody3D
class_name Kart

@export var controller : KartController

@export var engine_power := 70.0
@export var max_steer := 21.0
@export var steer_speed := 20.0

var acceleration_input := 0.0
var steering_input := 0.0

@onready var steering_wheel: MeshInstance3D = $Body/SteeringWheelPivot/SteeringWheel

func _process(delta: float) -> void:
	engine_force = acceleration_input * engine_power
	steering = lerp(steering, steering_input * deg_to_rad(max_steer), steer_speed * delta)
	steering_wheel.rotation.y = -steering * 1.25
