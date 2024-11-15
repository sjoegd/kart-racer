extends PanelContainer
class_name LeaderBoardEntry

@export var kart: KartController
@export var entry_position : int:
	set(pos):
		entry_position = pos
		if position_label:
			position_label.text = str(pos, ".")

@onready var position_label: Label = $Margin/Position
@onready var name_label: Label = $Margin/Margin/Name

func _ready():
	name_label.text = str(kart)
	position_label.text = str(entry_position, ".")
