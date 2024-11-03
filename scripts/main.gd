extends Node3D

@onready var track: Track = $Track
@onready var karts := $Karts.get_children()

func _ready():
	reset()
	pass

func reset():
	track.create_basic_track()
	for i in range(karts.size()):
		var kart: KartController = karts[i]
		var spawn = track.spawns[i]
		kart.reset(spawn.global_position, spawn.global_rotation)

func _on_track_kart_finished(kart: Kart) -> void:
	print(kart.controller.kart_id)
	reset()
