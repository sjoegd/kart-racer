extends RayCast3D

@export var kart: Kart
@export var vehicle_wheel: VehicleWheel3D
@export var mesh: MeshInstance3D
@export var offset: float = 0.0

func _ready():
	add_exception(kart)

func _process(delta: float) -> void:
	mesh.rotation = vehicle_wheel.rotation
	if is_colliding():
		mesh.global_position.y = lerp(mesh.global_position.y, get_collision_point().y + offset, 10.0*delta)
	else:
		mesh.position.y = lerp(mesh.position.y, 0.0, 10.0*delta)
