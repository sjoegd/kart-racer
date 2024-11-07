extends Node3D
class_name View

@export var race: Race

@export var camera_follow_distance := 2.4
@export var camera_follow_height := 1.4

@onready var follow_camera: Camera3D = $Cameras/FollowCamera
@onready var rear_follow_camera: Camera3D = $Cameras/RearFollowCamera

@onready var speed_label: Label = $CanvasLayer/HUD/SpeedLabel
@onready var leaderboard_label: Label = $CanvasLayer/HUD/LeaderboardLabel

var current_kart_id : int
var _viewed_kart: KartController
var rear_view := false

func _ready():
	race.race_reset.connect(_on_race_race_reset)

func _on_race_race_reset(start: bool) -> void:
	if start:
		current_kart_id = race.get_default_view_id()
	var viewed_kart = race.find_kart_by_id(current_kart_id)
	if viewed_kart != null:
		reset_view_to_kart(viewed_kart)

func reset_view_to_kart(kart: KartController):
	_viewed_kart = kart
	reset_cameras()

func reset_cameras():
	var kart = _viewed_kart.kart
	follow_camera.global_position = kart.global_position + Vector3(0, camera_follow_height, camera_follow_distance).rotated(Vector3.UP, kart.global_rotation.y)
	follow_camera.look_at(kart.global_transform.origin, Vector3.UP)
	rear_follow_camera.global_position = kart.global_position + Vector3(0, camera_follow_height, -camera_follow_distance).rotated(Vector3.UP, kart.global_rotation.y)
	rear_follow_camera.look_at(kart.global_transform.origin, Vector3.UP)

func _process(_delta):
	handle_input()
	if _viewed_kart != null:
		handle_cameras()
		handle_hud()

func handle_input():
	if Input.is_action_just_pressed("CycleView"):
		cycle_viewed_kart()
	rear_view = Input.is_action_pressed("RearView")

func cycle_viewed_kart():
	current_kart_id = (current_kart_id + 1) % race.karts.size()
	var kart = race.find_kart_by_id(current_kart_id)
	if kart != null:
		reset_view_to_kart(kart)

func handle_cameras():
	follow_camera.current = not rear_view
	rear_follow_camera.current = rear_view
	handle_follow_camera()
	handle_rear_follow_camera()

func handle_follow_camera():
	var kart = _viewed_kart.kart
	var delta_v = follow_camera.global_transform.origin - kart.global_transform.origin
	delta_v.y = 0.0

	if (delta_v.length() > camera_follow_distance):
		delta_v = delta_v.normalized() * camera_follow_distance
		delta_v.y = camera_follow_height
		follow_camera.global_position = kart.global_transform.origin + delta_v

	follow_camera.look_at(kart.global_transform.origin, Vector3.UP)

func handle_rear_follow_camera():
	var kart = _viewed_kart.kart
	rear_follow_camera.global_position = kart.global_position + Vector3(0, camera_follow_height, -camera_follow_distance).rotated(Vector3.UP, kart.global_rotation.y)
	rear_follow_camera.look_at(kart.global_transform.origin, Vector3.UP)

func handle_hud():
	var kart = _viewed_kart.kart
	
	var ms = kart.linear_velocity.length()
	var kmh = int(ms * 3.6)
	speed_label.text = str(kmh, " km/h")
	
	var leaderboard = ""
	for i in race.karts.size():
		leaderboard += str(i+1, ": ", race.karts[i], "\n")
	leaderboard_label.text = leaderboard
