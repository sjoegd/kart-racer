extends Node3D
class_name KartController

@export var kart_id := 0
@export var kart : Kart

func _process(_delta: float) -> void:
	handle_input()

func reset_kart(marker: Marker3D):
	kart.linear_velocity = Vector3.ZERO
	kart.angular_velocity = Vector3.ZERO
	kart.global_position = marker.global_position
	kart.global_rotation = marker.global_rotation

func handle_input():
	push_error("NOT IMPLEMENTED")
