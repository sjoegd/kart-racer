extends Node3D

@onready var track: Track = $Track
@onready var kart_controllers = $Karts.get_children() as Array[KartController]

func _ready():
	track.create_basic_track()
	spawn_karts()

func spawn_karts():
	for i in range(kart_controllers.size()):
		kart_controllers[i].reset_kart(track.spawns[i])

func _on_track_kart_finished(kart: Kart) -> void:
	track.create_basic_track()
	spawn_karts()
