extends Control
class_name Speedometer

@export var view : View
@export var speed_interval := .075

@onready var speed_label: Label = $VBox/SpeedLabel

var speed_delta := 0.0

func _ready():
	view.race.race_reset.connect(_on_race_reset)

func _on_race_reset(_start: bool):
	update_speed(Vector3.ZERO)
	speed_delta = 0.0

func _process(delta: float) -> void:
	handle_speed(delta)

func handle_speed(delta: float):
	speed_delta += delta
	if speed_delta >= speed_interval:
		speed_delta = 0.0
		var vel = view._viewed_kart.kart.linear_velocity if view._viewed_kart else Vector3.ZERO
		update_speed(vel)

func update_speed(linear_velocity: Vector3):
	var ms = linear_velocity.length()
	var kmh = int(ms * 3.6)
	speed_label.text = str(kmh)
