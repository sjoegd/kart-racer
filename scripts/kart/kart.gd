extends VehicleBody3D
class_name Kart

signal border_collision_start
signal border_collision_end

@export var controller : KartController

@export var max_speed := 35 # m/s
@export var engine_power := 70.0
@export var brake_power := 1.75
@export var max_steer := 21.0
@export var steer_speed := 20.0
@export var wheels: Array[VehicleWheel3D] = []
@export var engine: KartEngine

@onready var steering_wheel: MeshInstance3D = $Body/SteeringWheelPivot/SteeringWheel
@onready var frame: MeshInstance3D = $Body/Frame
@onready var front_wheel_axle: MeshInstance3D = $Body/FrontWheelAxle

var throttle_input := 0.0
var brake_input := 0.0
var steering_input := 0.0

func _ready():
	_set_frame_color(controller.color)

func _set_frame_color(_color: Color):
	var material = frame.get_active_material(0)
	var override_material = material.duplicate()
	override_material.albedo_color = _color
	frame.set_surface_override_material(0, override_material)

func _process(_delta: float) -> void:
	_handle_steering_wheel()
	_handle_front_axle()

func _physics_process(delta: float) -> void:
	engine_force = throttle_input * engine_power
	steering = lerp(steering, steering_input * deg_to_rad(max_steer), steer_speed * delta)
	brake = brake_input * brake_power + 0.05
	_limit_speed()

func _limit_speed():
	if get_speed() > max_speed:
		var non_y_velocity = (linear_velocity * Vector3(1, 0, 1)).limit_length(max_speed)
		linear_velocity = Vector3(non_y_velocity.x, linear_velocity.y, non_y_velocity.z)

func _handle_steering_wheel():
	steering_wheel.rotation.y = -steering * 1.33

func _handle_front_axle():
	front_wheel_axle.position.x = -steering * 0.015

func get_rpm():
	var total_rpm := 0.0
	for wheel in wheels:
		total_rpm += abs(wheel.get_rpm())
	return int(total_rpm / wheels.size())

func get_wheel_contacts():
	var contacts = []
	for wheel in wheels:
		contacts.append(wheel.is_in_contact())
	return contacts

func get_forward_velocity() -> float:
	var forward_dir = -global_basis.z
	return linear_velocity.dot(forward_dir)

func get_sideways_velocity() -> float:
	var sideways_dir = global_basis.x
	return linear_velocity.dot(sideways_dir)

func get_speed() -> float:
	return (linear_velocity * Vector3(1, 0, 1)).length()

func facing_towards_target(target_pos: Vector3) -> bool:
	var kart_pos = global_position
	var kart_dir = -global_basis.z
	var target_dir = (target_pos - kart_pos).normalized()
	return kart_dir.dot(target_dir) >= .25

func _on_body_entered(body: Node) -> void:
	if body is GridMap:
		_handle_grid_map_collision_start(body)

func _handle_grid_map_collision_start(grid_map: GridMap):
	if _is_border(grid_map):
		border_collision_start.emit()

func _on_body_exited(body: Node) -> void:
	if body is GridMap:
		_handle_grid_map_collision_end(body)

func _handle_grid_map_collision_end(grid_map: GridMap):
	if _is_border(grid_map):
		border_collision_end.emit()

func _is_border(grid_map: GridMap):
	return grid_map.get_collision_layer_value(4)
