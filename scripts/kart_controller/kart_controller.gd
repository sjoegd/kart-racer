extends Node3D
class_name KartController

enum TYPE {PLAYER, BOT}

@export var kart : Kart
@export var kart_id : int = 0
@export var color: Color = Color('ae2012')
@export var being_viewed := false
@export var user_name := "Kart"
@export var race : Race

func reset(global_pos: Vector3, global_rot: Vector3):
	kart.linear_velocity = Vector3.ZERO
	kart.angular_velocity = Vector3.ZERO
	kart.global_position = global_pos
	kart.global_rotation = global_rot
	kart.throttle_input = 0.0
	kart.steering_input = 0.0
	kart.brake_input = 0.0

func _physics_process(_delta):
	process_input(being_viewed)

func process_input(_viewed: bool):
	push_error("NOT IMPLEMENTED!")

func get_controller_name() -> String:
	push_error("NOT IMPLEMENTED!")
	return "KartController"

func _to_string() -> String:
	return str(user_name, " (", kart_id, ")")
