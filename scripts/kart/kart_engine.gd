extends AudioStreamPlayer3D
class_name KartEngine

@export var kart: Kart
@export var sample_rpm := 1300.0
@export var min_rpm := 200.0
@export var exhaust_marker : Marker3D
@export var db := -30.0

var rpm := min_rpm
var c_db := db

func _ready():
	max_db = c_db
	play(randf())

func set_viewed_db():
	c_db = db + 5.0

func remove_viewed_db():
	c_db = db

func _physics_process(delta: float) -> void:
	rpm = lerp(rpm, min_rpm + kart.get_rpm(), 30.0 * delta)
	pitch_scale = clamp(0.2 + (rpm / sample_rpm), 0.4, 1.3)
	max_db = c_db + linear_to_db(clamp((2 * rpm) / sample_rpm, 0.5, 1.0))
