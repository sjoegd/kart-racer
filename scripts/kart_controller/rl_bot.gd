extends KartController
class_name RLBot

@export var final_reset_after := 10000
@export var reset_after_step := 100

@onready var ai: RLBotAIController = $RLBotAIController

var _finished := false
var _progressed_to_next_piece := false
var _colliding_with_border := false

func _ready():
	setup_reward_handlers()

func setup_reward_handlers():
	race.track.kart_progressed_to_next_piece.connect(
		func (_kart_id: int):
			if _kart_id == kart_id:
				_progressed_to_next_piece = true
	)
	race.race_reset.connect(
		func (_start: bool):
			ai.reset_after = clamp(ai.reset_after + reset_after_step, 1000, final_reset_after)
	)
	kart.border_collision_start.connect(
		func():
			_colliding_with_border = true
	)
	kart.border_collision_end.connect(
		func():
			_colliding_with_border = false
	)

func reset(global_pos: Vector3, global_rot: Vector3):
	super.reset(global_pos, global_rot)
	ai.reset()

func _physics_process(delta: float) -> void:
	_handle_rewards()
	if ai.needs_reset:
		request_reset.emit(self)
	super._physics_process(delta)

func _handle_rewards() -> void:
	# FINISHED
	if _finished:
		ai.give_reward(ai.RewardType.FINISHED, 1.0)
		_finished = false
	# PROGRESS
	if _progressed_to_next_piece:
		ai.give_reward(ai.RewardType.PROGRESS, 1.0)
		_progressed_to_next_piece = false
	# COLLIDING
	if _colliding_with_border:
		ai.give_reward(ai.RewardType.COLLIDING, 1.0)
	# SPEED
	var speed_reward = clamp(kart.get_speed() / kart.max_speed, 0.0, 1.0)
	ai.give_reward(ai.RewardType.SPEED, speed_reward)
	# FACING TOWARDS TARGET
	var target = race.track.get_kart_target_position(kart_id, false, 1)
	var facing_torwards_target_reward = 1.0 if kart.facing_towards_target(target) else -1.0
	ai.give_reward(ai.RewardType.FACING_TOWARDS_TARGET, facing_torwards_target_reward)

func _process_input(_viewed: bool):
	kart.throttle_input = ai.throttle_action
	kart.steering_input = ai.steering_action
	kart.brake_input = 0.0

func on_finished(_place: int) -> void:
	_finished = true
	ai.needs_reset = true
	ai.done = true

func get_controller_name() -> String:
	return "RLBot"
