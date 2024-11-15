extends KartController
class_name Bot

@export var ray_count := 32
@export var ray_length := 10.0
@export var ray_angle_correct := 2.85

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

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_handle_ray_alignment(delta)

func _handle_ray_alignment(delta: float):
	if abs(kart.rotation.x) <= deg_to_rad(ray_angle_correct):
		ray_container.rotation.x = -kart.rotation.x
	else:
		ray_container.rotation.x = lerp(ray_container.rotation.x, 0.0, 10.0 * delta)

func _process_input(_viewed: bool):
	var interest = _calculate_interest()
	var danger = _calculate_danger()
	var direction = _calculate_direction(interest, danger)
	_perform_bot_input(direction)

func _calculate_interest() -> Array[float]:
	var target_position = (race.track.get_kart_target_position(kart_id, false, 1) - kart.global_position).normalized()
	var ray_to_interest = func(ray: RayCast3D) -> float:
		var ray_target = (ray.to_global(ray.target_position) - kart.global_position).normalized()
		return max(0, ray_target.dot(target_position))
	var interest: Array[float]
	interest.assign(rays.map(ray_to_interest))
	return interest

func _calculate_danger() -> Array[float]:
	var ray_to_danger = func(ray: RayCast3D) -> float:
		if not ray.is_colliding():
			return 0.0
		var collision_point = ray.get_collision_point()
		var distance = (collision_point - ray.global_position).length()
		return clamp(1.0 - (distance / ray_length), 0.0, 1.0)
	var danger: Array[float]
	danger.assign(rays.map(ray_to_danger))
	return danger

func _calculate_direction(interest: Array[float], danger: Array[float]) -> Vector3:
	var direction = Vector3.ZERO
	for i in rays.size():
		var direction_weight = clamp(interest[i] - (1.25 * danger[i]), -interest[i] / 8 if interest[i] > 0.65 else 0.0, 1.0)
		if debug:
			DebugDraw3D.draw_arrow(kart.global_position, rays[i].to_global(rays[i].target_position.normalized() * 2.0 * direction_weight), Color.YELLOW, 0.1, true)
		direction += rays[i].target_position.normalized() * direction_weight
	return direction

func _perform_bot_input(direction: Vector3):
	direction = -direction.normalized()
	
	var throttle = direction.z
	var steering = direction.x
	
	# brake for turning
	if kart.linear_velocity.length() >= 12.5:
		throttle -= 3.0 * abs(steering)
	elif kart.linear_velocity.length() >= 7.5:
		throttle -= 1.5 * abs(steering)
	
	# limit speed/steering for ramp
	if abs(kart.linear_velocity.y) > 1 and kart.linear_velocity.length() >= 10.0:
		throttle = clamp(throttle, -1.0, .25)
		steering = steering / 2
	
	# limit speed
	if kart.linear_velocity.length() >= 17.5:
		throttle = clamp(throttle, -1.0, 0.0)
		
	kart.throttle_input = clamp(throttle, -1.0, 1.0)
	kart.steering_input = steering
	
	if debug:
		DebugDraw3D.draw_arrow(kart.global_position, race.track.get_kart_target_position(kart_id, false, 1), Color.GREEN, 0.1, true)
		DebugDraw3D.draw_arrow(kart.global_position, race.track.kart.to_global(-direction * 5.0), Color.PURPLE, 0.1, true)

func get_controller_name() -> String:
	return "Bot"
