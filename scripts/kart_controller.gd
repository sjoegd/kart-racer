extends Node3D
class_name KartController

enum TYPE {PLAYER, BOT}

@export var kart : Kart
@export var kart_id : int = 0
@export var color: Color = Color('ae2012')

func reset(global_pos: Vector3, global_rot: Vector3):
	kart.linear_velocity = Vector3.ZERO
	kart.angular_velocity = Vector3.ZERO
	kart.global_position = global_pos
	kart.global_rotation = global_rot
	kart.acceleration_input = 0.0
	kart.steering_input = 0.0

func _physics_process(_delta):
	process_input()

func process_input():
	push_error("NOT IMPLEMENTED!")

func _to_string() -> String:
	return str("Controller ", kart_id)
