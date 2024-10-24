extends KartController
class_name Player

@onready var camera: Camera = $Camera3D

func reset_kart(marker: Marker3D):
	super.reset_kart(marker)
	camera.reset()

func handle_input():
	kart.accelerate_input = Input.get_axis("Accelerate", "Brake")
	kart.steering_input = Input.get_axis("SteerRight", "SteerLeft")
