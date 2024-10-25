extends KartController
class_name Player

@onready var camera: Camera = $Camera

func reset(global_pos: Vector3, global_rot: Vector3):
	super.reset(global_pos, global_rot)
	camera.reset()

func process_input():
	kart.acceleration_input = Input.get_axis("Brake", "Accelerate")
	kart.steering_input = Input.get_axis("SteerRight", "SteerLeft")
