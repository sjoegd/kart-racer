extends Main
class_name Train

var view_scene : PackedScene = preload("res://scenes/view.tscn")
var base_environment : PackedScene = preload("res://scenes/base_environment.tscn")

@export var preview := false

@onready var race: Race = $Race

func _ready():
	if preview:
		_initialize_view()
		_initialize_env()

func _initialize_view():
	var view: View = view_scene.instantiate()
	view.race = race
	race.add_child(view)
	view._on_race_race_reset(true)

func _initialize_env():
	var env = base_environment.instantiate()
	add_child(env)

func _get_kart_instance_view(type: KartController.TYPE) -> bool:
	return type == KartController.TYPE.RLBOT && preview
