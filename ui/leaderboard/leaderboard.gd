extends Control
class_name LeaderBoard

var entry_scene : PackedScene = preload("res://ui/leaderboard/entry.tscn")

@export var view : View

@onready var entry_container: VBoxContainer = $EntryContainer

var entries: Array[LeaderBoardEntry] = []

func _ready():
	view.race.race_reset.connect(_on_race_reset)
	view.race.progression_tick.connect(_on_race_progression_tick)

func _on_race_reset(start: bool):
	if start:
		entries.clear()
		for i in view.race.karts.size():
			add_entry(create_entry(view.race.karts[i], i + 1))
	else:
		update_entries()

func _on_race_progression_tick():
	update_entries()

func update_entries():
	for i in view.race.karts.size():
		var entry = find_kart_entry(view.race.karts[i])
		if not entry:
			entry = create_entry(view.race.karts[i], i + 1)
			add_entry(entry)
		update_entry(entry, i + 1)
		entry_container.move_child(entry, i)

func create_entry(kart: KartController, entry_position: int) -> LeaderBoardEntry:
	var entry: LeaderBoardEntry = entry_scene.instantiate()
	entry.kart = kart
	entry.entry_position = entry_position
	return entry

func add_entry(entry: LeaderBoardEntry):
	entries.append(entry)
	entry_container.add_child(entry)

func update_entry(entry: LeaderBoardEntry, new_entry_position: int):
	entry.entry_position = new_entry_position

func find_kart_entry(kart: KartController) -> LeaderBoardEntry:
	for entry in entries:
		if entry.kart.kart_id == kart.kart_id:
			return entry
	return null
