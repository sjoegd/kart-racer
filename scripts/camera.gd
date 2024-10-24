extends Camera3D
class_name Camera

@export var follow_distance := 5.0
@export var follow_height := 2.0
@export var speed := 20.0
@export var kart : Node3D

var start_rotation : Vector3
var start_position : Vector3

func _ready():
	start_rotation = rotation
	start_position = position

func reset():
	rotation = start_rotation
	position = start_position

func _process(_delta):
	var delta_v := global_transform.origin - kart.global_transform.origin
	delta_v.y = 0.0
	if (delta_v.length() > follow_distance):
		delta_v = delta_v.normalized() * follow_distance
		delta_v.y = follow_height
		global_position = kart.global_transform.origin + delta_v
	
	look_at(kart.global_transform.origin, Vector3.UP)
