extends PanelContainer
class_name LeaderBoardEntry

@export var kart: KartController
@export var entry_position : int

@onready var position_label: Label = $Margin/Position
@onready var name_label: Label = $Margin/Margin/Name

func _ready():
	name_label.text = str(kart)

func _process(_delta: float) -> void:
	position_label.text = str(entry_position, ".")
