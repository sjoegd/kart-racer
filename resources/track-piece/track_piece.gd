extends Resource
class_name TrackPiece

# Piece name
@export var name : String

# X Y Z Update needed beforehand
@export var before_update: Vector3i = Vector3i.ZERO

# X Y Z Update
@export var update : Vector3i = Vector3i.ZERO

# Mesh library item name
@export var mesh_name: String

# Mesh library item rotation
@export var rotate := 0

# Names of pieces that are able to follow up this piece
@export var follow_up_pieces: Array[String]

func total_update() -> Vector3i:
	return before_update + update

func _to_string() -> String:
	return "Piece: {0}".format([name])
