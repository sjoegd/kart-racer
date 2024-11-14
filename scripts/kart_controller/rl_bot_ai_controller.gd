extends AIController3D
class_name RLBotAIController

@export var rl_bot: RLBot

@onready var border_sensor: RayCastSensor3D = $"../Kart/BorderSensor"
@onready var kart_sensor: RayCastSensor3D = $"../Kart/KartSensor"

var throttle_action := 0.0
var steering_action := 0.0

func get_obs() -> Dictionary:
	var obs = []
	
	obs += border_sensor.get_observation()
	obs += kart_sensor.get_observation()
	
	return {"obs": obs}

func get_reward() -> float:
	var temp_reward := reward
	zero_reward()
	return temp_reward

func get_action_space() -> Dictionary:
	return {
		"throttle": {"size": 2, "action_type": "continuous"},
		"steering": {"size": 2, "action_type": "continuous"},
	}

func set_action(action) -> void:
	print(action)
	throttle_action = action["throttle"][0]
	steering_action = action["steering"][0]
