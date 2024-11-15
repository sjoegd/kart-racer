extends AIController3D
class_name RLBotAIController

@export var rl_bot: RLBot

@onready var border_sensor: RayCastSensor3D = $"../Kart/BorderSensor"
@onready var kart_sensor: RayCastSensor3D = $"../Kart/KartSensor"

'''
OBSERVATION SPACE:
	- Sensors (64x)
		Border Sensors - 32x
		Kart Sensors - 32x
	
	- Wheels (4x)
		Wheel Contacts - 4x
	
	- Kart (7x)
		Forward Velocity / Max Speed
		Sideways Velocity / Max Speed
		X Angle / PI
		Z Angle / PI
		Speed / Max Speed
		Throttle
		Steering
	
	- Track (6x)
		Facing Towards Target
		Next Pieces One Hot Encoding - 5x ->(9 pieces) 45x

	TOTAL: 121
'''
func get_obs() -> Dictionary:
	var obs: Array = []
	
	obs += get_sensor_obs()
	obs += get_wheel_obs()
	obs += get_kart_obs()
	obs += get_track_obs()
	
	return {"obs": obs}

func get_sensor_obs() -> Array:
	var sensor_obs: Array = []
	
	# Sensors
	sensor_obs += border_sensor.get_observation()
	sensor_obs += kart_sensor.get_observation()
	
	return sensor_obs

func get_wheel_obs() -> Array:
	var wheel_obs: Array = []
	
	var wheel_contacts = rl_bot.kart.get_wheel_contacts().map(func(c: bool): return 1.0 if c else 0.0)
	wheel_obs += wheel_contacts

	return wheel_obs

func get_kart_obs() -> Array:
	var forward_velocity_obs = rl_bot.kart.get_forward_velocity() / rl_bot.kart.max_speed
	var sideways_velocity_obs = rl_bot.kart.get_sideways_velocity() / rl_bot.kart.max_speed
	var x_angle_obs = rl_bot.rotation.x / PI
	var z_angle_obs = rl_bot.rotation.z / PI
	var speed_obs = rl_bot.kart.get_speed() / rl_bot.kart.max_speed
	var throttle_obs = rl_bot.kart.throttle_input
	var steering_obs = rl_bot.kart.steering_input

	var kart_obs: Array = [
		forward_velocity_obs,
		sideways_velocity_obs,
		x_angle_obs,
		z_angle_obs,
		speed_obs,
		throttle_obs,
		steering_obs,
	]

	return kart_obs

func get_track_obs() -> Array:
	var track_obs: Array = []

	var target = rl_bot.race.track.get_kart_target_position(rl_bot.kart_id, false, 1)
	var facing_towards_target_obs = 1.0 if rl_bot.kart.facing_towards_target(target) else -1.0

	var next_pieces_obs = rl_bot.race.track.get_kart_one_hot_encoded_next_pieces(rl_bot.kart_id, 5)

	track_obs += [facing_towards_target_obs]
	track_obs += next_pieces_obs

	return track_obs

'''
REWARD SPACE:
	10.0 | FINISHED - On finishing track
	1.0 | PROGRESS - On reaching next piece
	-0.01 | COLLIDING - If colliding with border
	0.01 | SPEED - Every step: Speed / Max Speed
	0.025 | FACING_TOWARDS_TARGET - Every step: Facing towards target
'''

enum RewardType { 
	FINISHED,
	PROGRESS,
	COLLIDING,
	SPEED,
	FACING_TOWARDS_TARGET,
}

var reward_space: Dictionary = {
	RewardType.FINISHED: 10.0,
	RewardType.PROGRESS: 1.0,
	RewardType.COLLIDING: -0.01,
	RewardType.SPEED: 0.01,
	RewardType.FACING_TOWARDS_TARGET: 0.025,
}

func give_reward(type: RewardType, value: float) -> void:
	var multiplier = reward_space[type] if reward_space.has(type) else 0.0
	reward += value * multiplier

func get_reward() -> float:
	return reward

'''
ACTION SPACE:
	Throttle - -1.0 -> 1.0
	Steering - -1.0 -> 1.0
'''
var throttle_action := 0.0
var steering_action := 0.0

func get_action_space() -> Dictionary:
	return {
		"throttle": {"size": 1, "action_type": "continuous"},
		"steering": {"size": 1, "action_type": "continuous"},
	}

func set_action(action) -> void:
	throttle_action = clamp(action["throttle"][0], -1.0, 1.0)
	steering_action = clamp(action["steering"][0], -1.0, 1.0)
