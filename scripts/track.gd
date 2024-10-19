extends Node3D
class_name Track

@export var track_pieces: Array[TrackPiece] = []

@export var left_turn_weight := 1.0
@export var right_turn_weight := 1.0
@export var ramp_weight := 1.0

@onready var piece_weights = {
	'->': right_turn_weight,
	'<-': left_turn_weight,
	'|': ramp_weight
}

@onready var grid_map: GridMap = $GridMap

func _ready():
	grid_map.clear()
	create_basic_track()

func create_basic_track():
	var pos := Vector3i.ZERO
	var c_piece: TrackPiece = find_piece_by_name("Forward")
	for i in range(250):
		pos += c_piece.before_update
		place_piece(c_piece, pos)
		pos += c_piece.update
		var successor = get_valid_successor(pos, get_piece_successors(c_piece))
		if successor == null:
			print("No valid successor!")
			break
		c_piece = successor

func get_piece_successors(piece: TrackPiece):
	var successors: Array[TrackPiece] = []

	for other_piece in track_pieces:
		if other_piece.name in piece.follow_up_pieces:
			successors.append(other_piece)

	if successors.size() == 0:
		return null

	return successors

func find_piece_by_name(piece_name: String):
	for piece in track_pieces:
		if piece.name == piece_name:
			return piece
	return null

func place_piece(piece: TrackPiece, pos: Vector3i):
	var item = grid_map.mesh_library.find_item_by_name(piece.mesh_name)
	var item_basis = Basis.IDENTITY.rotated(Vector3.UP, (PI / 2) * piece.rotate)
	grid_map.set_cell_item(pos, item, grid_map.get_orthogonal_index_from_basis(item_basis))

# Picks a random valid successor if there is any
func get_valid_successor(pos: Vector3i, successors: Array[TrackPiece]):
	var valid_filter = func(successor: TrackPiece):
		return is_valid_piece_for_path(pos, successor, 10)

	var valid_successors = successors.filter(valid_filter)

	if valid_successors.is_empty():
		return null

	return pick_weighted_random_successor(valid_successors)

var generator = RandomNumberGenerator.new()
func pick_weighted_random_successor(successors: Array[TrackPiece]):
	var random_nr = generator.randf();
	var threshold = 0;

	var weights = successors.map(get_piece_weight)
	var total_weight = weights.reduce(sum)
	weights = weights.map(divide_by(total_weight))

	for i in range(successors.size()):
		threshold += weights[i]
		if threshold > random_nr:
			return successors[i]

	return successors.pick_random()

func get_piece_weight(piece: TrackPiece) -> float:
	for key in piece_weights.keys():
		if piece.name.contains(key):
			return piece_weights[key]
	return 1.0

# Checks if piece can be placed on pos by checking
# if a path of the specified depth can be formed after that piece
func is_valid_piece_for_path(pos: Vector3i, piece: TrackPiece, depth: int):
	var next_pos = pos + piece.total_update()
	var next_below_pos = next_pos + Vector3i(0, -1, 0)
	var above_pos = pos + Vector3i(0, 1, 0)
	var below_pos = pos + Vector3i(0, -1, 0)

	var next_cell_item = grid_map.get_cell_item(next_pos)
	var next_below_cell_item = grid_map.get_cell_item(next_below_pos)
	var above_cell_item = grid_map.get_cell_item(above_pos)
	var below_cell_item = grid_map.get_cell_item(below_pos)

	# next position should be empty
	# have no ramp beneath
	# if a ramp, current position should have nothing above or below depending on direction
	# y should be between 0 and 2
	if (
		next_cell_item != GridMap.INVALID_CELL_ITEM
		or (
			next_below_cell_item != GridMap.INVALID_CELL_ITEM
			and grid_map.mesh_library.get_item_name(next_below_cell_item).contains("Ramp")
		)
		or (
			piece.total_update().y > 0
			and above_cell_item != GridMap.INVALID_CELL_ITEM
		)
		or (
			piece.total_update().y < 0
			and below_cell_item != GridMap.INVALID_CELL_ITEM
		)
		or next_pos.y < 0
		or next_pos.y > 1
	):
		return false

	# Have to check if there is a child with valid path
	if depth > 0:
		for successor in get_piece_successors(piece):
			if is_valid_piece_for_path(next_pos, successor, depth - 1):
				# We are empty and have a valid child so valid
				return true
		# No child has a valid path so we aren't valid
		return false

	# We don't need to check children and are empty so we are valid
	return true

func sum(a, b):
	return a + b

func divide_by(b):
	var f = func(a):
		return a / b
	return f
