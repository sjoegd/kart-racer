extends KartController
class_name RLBot

@onready var ai: RLBotAIController = $RLBotAIController

func process_input(_viewed: bool):
	kart.throttle_input = ai.throttle_action
	kart.steering_input = ai.steering_action
	kart.brake_input = 0.0

func get_controller_name() -> String:
	return "RLBot"
