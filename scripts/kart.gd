extends VehicleBody3D
class_name Kart

@export var controller : KartController

@export var engine_power := 60.0
@export var max_steer := 20.0
@export var steer_speed := 5.0

var acceleration_input := 0.0
var steering_input := 0.0

func _process(delta: float) -> void:
	engine_force = acceleration_input * engine_power
	steering = steering_input * deg_to_rad(max_steer)
