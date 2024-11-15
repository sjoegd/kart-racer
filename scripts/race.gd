extends Node3D
class_name Race

signal race_reset(start: bool)
signal progression_tick

var player_scene: PackedScene = preload("res://scenes/kart_controller/player.tscn")
var bot_scene: PackedScene = preload("res://scenes/kart_controller/bot.tscn")
var rl_bot_scene: PackedScene = preload("res://scenes/kart_controller/rl_bot.tscn")

@export var main : Main
@export var track: Track
@export var progession_interval := .25

@onready var kart_instances: Array[KartInstance] = main.get_kart_instances()

var kart_container: Node3D
var karts: Array[KartController] = []
var finished_kart_ids: Array[int] = []
var progression_delta = 0.0

func _ready():
	track.kart_finished.connect(_on_track_kart_finished)
	_create_kart_container()
	for i in kart_instances.size():
		_spawn_kart(kart_instances[i], i + 1)
	_reset(true)

func _create_kart_container():
	kart_container = Node3D.new()
	kart_container.name = "KartContainer"
	add_child(kart_container)

func _spawn_kart(kart_instance: KartInstance, id: int):
	var controller_scene = _get_controller_scene(kart_instance.controller_type)
	var controller = controller_scene.instantiate() as KartController
	controller.kart_id = id
	controller.color = kart_instance.kart_color
	controller.user_name = kart_instance.name if kart_instance.name != "" else controller.get_controller_name()
	controller.name = str(controller)
	controller.race = self
	controller.request_reset.connect(_on_kart_request_reset)
	kart_container.add_child(controller)
	karts.append(controller)

func _get_controller_scene(controller_type: KartController.TYPE) -> PackedScene:
	match controller_type:
		KartController.TYPE.PLAYER:
			return player_scene
		KartController.TYPE.BOT:
			return bot_scene
		KartController.TYPE.RLBOT:
			return rl_bot_scene
	return null

func _reset(start: bool = false):
	var created_track := false
	while not created_track:
		created_track = track.create_basic_track()
	for i in karts.size():
		var kart: KartController = karts[i]
		var spawn = track.spawns[i]
		kart.reset(spawn.global_position, spawn.global_rotation)
	race_reset.emit(start)

func _physics_process(delta: float) -> void:
	progression_delta += delta
	if progression_delta > progession_interval:
		_sort_karts_by_progression()
		progression_delta = 0.0

func _sort_karts_by_progression():
	karts.sort_custom(
		func(kart_a: KartController, kart_b: KartController):
			return track.compare_kart_progression(kart_a.kart, kart_b.kart)
	)
	progression_tick.emit()

func find_kart_by_id(kart_id: int) -> KartController:
	for kart in karts:
		if kart.kart_id == kart_id:
			return kart
	return null

func get_default_view_id() -> int:
	for i in kart_instances.size():
		if kart_instances[i].view:
			return i + 1
	return 0

func _on_track_kart_finished(kart: Kart) -> void:
	finished_kart_ids.append(kart.controller.kart_id)
	kart.controller.on_finished(finished_kart_ids.size())
	print(kart.controller.kart_id, " FINISHED!")

func _on_kart_request_reset(_controller: KartController):
	_reset()
