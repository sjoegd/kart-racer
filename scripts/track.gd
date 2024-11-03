extends Node3D
class_name Track

signal kart_finished(kart: Kart)

@export var track_pieces: Array[TrackPiece] = []
@export var track_length := 250

@export var straight_weight := 1.0
@export var right_weight := 1.0
@export var left_weight := 1.0
@export var up_weight := 1.0
@export var down_weight := 1.0

@onready var piece_weights = {
	'Straight': straight_weight,
	'Left': left_weight,
	'Right': right_weight,
	'Up': up_weight,
	'Down': down_weight
}

@onready var grid_map: GridMap = $GridMap
@onready var finish_area: Area3D = $GridMap/FinishArea
@onready var spawns = $Spawns.get_children() as Array[Marker3D]

# Used to fill gridmap cells that are used by a big track piece
@onready var USED_CELL_ITEM = grid_map.mesh_library.find_item_by_name("UsedCell")

func create_basic_track():
	grid_map.clear()

	var c_position := Vector3.ZERO
	var c_piece: TrackPiece = find_piece_by_name("Start", track_pieces)
	var c_rotation := 0.0
	
	# Place start
	place_piece(c_piece, c_position, c_rotation)
	c_position += TrackPiece.rotate_update(c_piece.total_update(), c_rotation)
	c_rotation += c_piece.rotation_update
	
	# Get valid successor for c_piece based on c_position and c_rotation
	c_piece = get_valid_successor(get_piece_successors(c_piece), c_position, c_rotation)
	
	# Create track	
	for i in range(track_length):
		place_piece(c_piece, c_position, c_rotation)
		c_position += TrackPiece.rotate_update(c_piece.total_update(), c_rotation)
		c_rotation += c_piece.rotation_update
		
		if i >= track_length - 1:
			return place_finish(c_position, c_rotation)
		
		c_piece = get_valid_successor(get_piece_successors(c_piece), c_position, c_rotation)
		if not c_piece:
			print("NO VALID SUCCESSOR")
			return false

func place_finish(pos: Vector3, rot: float) -> bool:
	var finish_piece = find_piece_by_name("Finish", track_pieces)
	place_piece(finish_piece, pos, rot)
	
	var pos_i = TrackPiece.pos_vector3i(pos)
	var grid_pos = grid_map.map_to_local(pos_i)
	finish_area.rotation.y = deg_to_rad(rot)
	finish_area.position = Vector3(grid_pos.x, grid_pos.y + grid_map.cell_size.y / 4, grid_pos.z)
	
	return true

func _on_finish_area_body_entered(body: Node3D) -> void:
	if body is Kart:
		kart_finished.emit(body)

func get_piece_successors(piece: TrackPiece):
	var successors: Array[TrackPiece] = []

	for other_piece in track_pieces:
		if other_piece.name in piece.follow_up_pieces && get_piece_weight(other_piece) > 0.0:
			successors.append(other_piece)
	
	return successors

func find_piece_by_name(piece_name: String, pieces: Array[TrackPiece]):
	for piece in pieces:
		if piece.name == piece_name:
			return piece
	return null

func place_piece(piece: TrackPiece, pos: Vector3, rot: float):
	var pos_i = TrackPiece.pos_vector3i(pos + TrackPiece.rotate_update(piece.mesh_before_update, rot))
	var mesh_pos_i = TrackPiece.pos_vector3i(pos + TrackPiece.rotate_update(piece.mesh_update, rot))
	
	# Set all positions in range pos -> mesh_pos to USED_CELL_ITEM
	for x in (range(pos_i.x, mesh_pos_i.x, get_range_step(pos_i.x, mesh_pos_i.x)) + [pos_i.x]):
		for y in (range(pos_i.y, mesh_pos_i.y, get_range_step(pos_i.y, mesh_pos_i.y)) + [pos_i.y]):
			for z in (range(pos_i.z, mesh_pos_i.z, get_range_step(pos_i.z, mesh_pos_i.z)) + [pos_i.z]):
				grid_map.set_cell_item(Vector3i(x, y, z), USED_CELL_ITEM)

	var item = grid_map.mesh_library.find_item_by_name(piece.mesh_name)
	var item_basis = Basis.IDENTITY.rotated(Vector3.UP, deg_to_rad(rot + piece.mesh_rotation))
	
	var before_update_pos = pos + (TrackPiece.rotate_update(piece.before_update, rot))
	var before_update_pos_i = TrackPiece.pos_vector3i(before_update_pos)
	
	grid_map.set_cell_item(before_update_pos_i, item, grid_map.get_orthogonal_index_from_basis(item_basis))

# Picks a (weighted) random valid successor if there is any
func get_valid_successor(successors: Array[TrackPiece], pos: Vector3, rot: float):
	var valid_filter = func(successor: TrackPiece):
		return is_valid_piece_for_path(successor, pos, rot, 5)

	var valid_successors = successors.filter(valid_filter)

	if valid_successors.is_empty():
		return null

	return pick_weighted_random_successor(valid_successors)

# Checks if piece can be placed on pos by checking
# if a path of the specified depth can be formed after that piece
func is_valid_piece_for_path(piece: TrackPiece, pos: Vector3, rot: float, depth: int):
	var mesh_pos = pos + (TrackPiece.rotate_update(piece.mesh_update, rot))
	var pos_i = TrackPiece.pos_vector3i(pos)
	var mesh_pos_i = TrackPiece.pos_vector3i(mesh_pos)

	# Checks for all positions from position till mesh position
	for x in (range(pos_i.x, mesh_pos_i.x, get_range_step(pos_i.x, mesh_pos_i.x)) + [pos_i.x]):
		for y in (range(pos_i.y, mesh_pos_i.y, get_range_step(pos_i.y, mesh_pos_i.y)) + [pos_i.y]):
			for z in (range(pos_i.z, mesh_pos_i.z, get_range_step(pos_i.z, mesh_pos_i.z)) + [pos_i.z]):
				var current_cell_item = grid_map.get_cell_item(Vector3i(x, y, z))
				if current_cell_item != GridMap.INVALID_CELL_ITEM:
					return false

	# Checks for next position
	var next_pos = pos + TrackPiece.rotate_update(piece.total_update(), rot)
	var next_rot = rot + piece.rotation_update
	var next_cell_item = grid_map.get_cell_item(next_pos)
	if (
		next_cell_item != GridMap.INVALID_CELL_ITEM
		or next_pos.y < 0
		or next_pos.y > 1
	):
		return false

	# Have to check if there is a child with valid path
	if depth > 0:
		for successor in get_piece_successors(piece):
			if is_valid_piece_for_path(successor, next_pos, next_rot, depth - 1):
				# We passed the check and we have a child that is valid so we are valid
				return true
		# No child has a valid path so we aren't valid
		return false

	# We don't need to check children and passed the check so we are valid
	return true

# Picks a random successor based on the specified weights of pieces
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

func get_range_step(a: int, b: int) -> int:
	if (a > b):
		return -1
	return 1

func sum(a, b):
	return a + b

func divide_by(b):
	var f = func(a):
		return a / b
	return f
