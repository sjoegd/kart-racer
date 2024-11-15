extends Node3D
class_name Main

@export var players := 1
@export var bots := 3
@export var rl_bots := 0

@export var colors : Array[Color] = [
	Color('36ad11'),
	Color('118ead'),
	Color('9611ad'),
	Color('ae2012')
]

func get_kart_instances() -> Array[KartInstance]:
	var instances: Array[KartInstance] = []
	var type_instances = [
		{"type": KartController.TYPE.BOT, "count": bots},
		{"type": KartController.TYPE.RLBOT, "count": rl_bots},
		{"type": KartController.TYPE.PLAYER, "count": players}
	]
	for type_instance in type_instances:
		for _i in type_instance["count"]:
			instances.append(
				_create_kart_instance(type_instance["type"], instances.size())
			)
	return instances

func _create_kart_instance(type: KartController.TYPE, num: int) -> KartInstance:
	var instance = KartInstance.new()
	instance.kart_color = colors[clamp(num, 0, colors.size() - 1)]
	instance.controller_type = type
	instance.view = _get_kart_instance_view(type)
	instance.name = ""
	return instance

func _get_kart_instance_view(type: KartController.TYPE) -> bool:
	return type == KartController.TYPE.PLAYER
