extends KartController
class_name Player

func process_input():
	kart.acceleration_input = Input.get_axis("Brake", "Accelerate")
	kart.steering_input = Input.get_axis("SteerRight", "SteerLeft")

func _to_string() -> String:
	return str("Player ", kart_id)
