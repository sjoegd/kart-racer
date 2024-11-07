extends KartController
class_name Bot

@export var track: Track

@export var ray_count := 16
@export var ray_length := 10.0

@export var debug := false

@onready var base_ray: RayCast3D = $Kart/BaseRay
@onready var ray_container: Node3D = $Kart/RayContainer

var rays: Array[RayCast3D] = []

func _ready() -> void:
	for i in ray_count:
		var ray: RayCast3D = base_ray.duplicate()
		var ray_direction = (Vector3.FORWARD * ray_length).rotated(Vector3.UP, i * 2 * PI / ray_count)
		ray.target_position = ray_direction
		ray.add_exception(kart)
		ray_container.add_child(ray)
		rays.append(ray)

func process_input():
	var interest = calculate_interest()
	var danger = calculate_danger()
	var direction = calculate_direction(interest, danger)
	perform_bot_input(direction)

func calculate_interest() -> Array[float]:
	var target_position = (track.get_kart_target_position(kart_id, false, 1) - kart.global_position).normalized()
	var ray_to_interest = func(ray: RayCast3D) -> float:
		var ray_target = (ray.to_global(ray.target_position) - kart.global_position).normalized()
		return max(0, ray_target.dot(target_position))
	var interest: Array[float]
	interest.assign(rays.map(ray_to_interest))
	return interest

func calculate_danger() -> Array[float]:
	var ray_to_danger = func(ray: RayCast3D) -> float:
		if not ray.is_colliding():
			return 0.0
		var collision_point = ray.get_collision_point()
		var distance = (collision_point - ray.global_position).length()
		return clamp(1.0 - (distance / ray_length), 0.0, 1.0)
	var danger: Array[float]
	danger.assign(rays.map(ray_to_danger))
	return danger

func calculate_direction(interest: Array[float], danger: Array[float]) -> Vector3:
	var direction = Vector3.ZERO
	for i in rays.size():
		var direction_weight = clamp(interest[i] - (1.5 * danger[i]), -0.20, 1.0)
		if debug:
			DebugDraw3D.draw_arrow(kart.global_position, rays[i].to_global(rays[i].target_position.normalized() * direction_weight), Color.YELLOW, 0.1)
		direction += rays[i].target_position.normalized() * direction_weight
	return direction

func perform_bot_input(direction: Vector3):
	direction = -direction.normalized()
	
	var acceleration = direction.z
	var steering = direction.x
	
	# brake for turning
	if kart.linear_velocity.length() >= 15.0:
		acceleration -= 2.0 * abs(steering)
	elif kart.linear_velocity.length() >= 10.0:
		acceleration -= 1.25 * abs(steering)
	elif kart.linear_velocity.length() >= 5.0:
		acceleration -= abs(steering) / 2
	
	# limit speed for ramp
	if abs(kart.linear_velocity.y) > 1 and kart.linear_velocity.length() >= 10.0:
		acceleration = clamp(acceleration, -1.0, .2)
	
	# limit speed
	if kart.linear_velocity.length() >= 16.0:
		acceleration = clamp(acceleration, -1.0, 0.0)
		
	kart.acceleration_input = clamp(acceleration, -1.0, 1.0)
	kart.steering_input = steering
	
	if debug:
		DebugDraw3D.draw_arrow(kart.global_position, kart.to_global(-direction * ray_length), Color.PURPLE, 0.1)

func _to_string() -> String:
	return str("Bot ", kart_id)
