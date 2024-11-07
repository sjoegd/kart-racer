extends Node3D
class_name Race

signal race_reset(start: bool)

var bot_scene: PackedScene = preload("res://scenes/bot.tscn")
var player_scene: PackedScene = preload("res://scenes/player.tscn")

@export var kart_instances: Array[KartInstance] = []
@export var progession_interval := .25

@export var track: Track

var kart_container: Node3D
var karts: Array[KartController] = []
var progression_delta = 0.0

func _ready():
	track.kart_finished.connect(_on_track_kart_finished)
	create_kart_container()
	for i in kart_instances.size():
		spawn_kart(kart_instances[i], i)
	reset(true)

func create_kart_container():
	kart_container = Node3D.new()
	kart_container.name = "KartContainer"
	add_child(kart_container)

func spawn_kart(kart_instance: KartInstance, id: int):
	match kart_instance.controller_type:
		KartController.TYPE.PLAYER:
			spawn_player(kart_instance, id)
		KartController.TYPE.BOT:
			spawn_bot(kart_instance, id)

func spawn_player(kart_instance: KartInstance, id: int):
	var player = player_scene.instantiate() as Player
	player.kart_id = id
	player.color = kart_instance.kart_color
	player.name = str(player)
	kart_container.add_child(player)
	karts.append(player)

func spawn_bot(kart_instance: KartInstance, id: int):
	var bot = bot_scene.instantiate() as Bot
	bot.kart_id = id
	bot.color = kart_instance.kart_color
	bot.track = track
	bot.name = str(bot)
	kart_container.add_child(bot)
	karts.append(bot)

func reset(start: bool = false):
	track.create_basic_track()
	for i in karts.size():
		var kart: KartController = karts[i]
		var spawn = track.spawns[i]
		kart.reset(spawn.global_position, spawn.global_rotation)
	race_reset.emit(start)

func _process(delta: float) -> void:
	progression_delta += delta
	if progression_delta > progession_interval:
		sort_karts_by_progression()
		progression_delta = 0.0

func sort_karts_by_progression():
	karts.sort_custom(
		func(kart_a: KartController, kart_b: KartController):
			return track.compare_kart_progression(kart_a.kart, kart_b.kart)
	)

func find_kart_by_id(kart_id: int) -> KartController:
	for kart in karts:
		if kart.kart_id == kart_id:
			return kart
	return null

func get_default_view_id() -> int:
	for i in kart_instances.size():
		if kart_instances[i].view:
			return i
	return 0

func _on_track_kart_finished(kart: Kart) -> void:
	print(kart.controller, " won!")
	reset()
