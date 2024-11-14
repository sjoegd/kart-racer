extends KartController
class_name Player

func process_input(viewed: bool):
	if not viewed:
		kart.throttle_input = 0.0
		kart.steering_input = 0.0
		kart.brake_input = 0.0
		return
	kart.throttle_input = Input.get_axis("Reverse", "Accelerate")
	kart.steering_input = Input.get_axis("SteerRight", "SteerLeft")
	kart.brake_input = Input.get_action_strength("Brake")

func get_controller_name() -> String:
	return "Player"
