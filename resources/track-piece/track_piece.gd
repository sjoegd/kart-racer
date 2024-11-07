extends Resource
class_name TrackPiece

# Piece name
@export var name : String
# Mesh library item name
@export var mesh_name: String

# X Y Z Updates
@export var before_update: Vector3 = Vector3.ZERO
@export var update : Vector3 = Vector3.ZERO

# For big pieces, specify the area that is used by the piece
@export var mesh_before_update: Vector3 = Vector3.ZERO
@export var mesh_update: Vector3 = Vector3.ZERO

# Rotation update in degrees
@export var rotation_update : float = 0.0
# Added rotation to the mesh
@export var mesh_rotation : float = 0.0

# Target position change (percentage of cell_size that should be added)
@export var target_position_change : Vector3 = Vector3.ZERO
# A multiplier that can help improve the target position prediction using successors
@export var target_position_prediction_mult : Vector3 = Vector3.ONE

# Names of pieces that are able to follow up this piece
@export var follow_up_pieces: Array[String]

static func rotate_update(_update: Vector3, rot: float) -> Vector3:
	return _update.rotated(Vector3.UP, deg_to_rad(rot))

static func pos_vector3i(pos: Vector3) -> Vector3i:
	return Vector3i(roundi(pos.x), roundi(pos.y), roundi(pos.z))

func total_update() -> Vector3:
	return before_update + update

func _to_string() -> String:
	return "Piece: {0}".format([name])
