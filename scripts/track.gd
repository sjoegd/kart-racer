extends Node3D
class_name Track

signal kart_finished(kart: Kart)

@export var track_pieces: Array[TrackPiece] = []
@export var track_length := 250
@export var road_y_offset := 0.5
@export var path_depth := 7
@export var with_border := true

@export var straight_weight := 1.0
@export var left_weight := 1.0
@export var right_weight := 1.0
@export var big_left_weight := 1.0
@export var big_right_weight := 1.0
@export var up_weight := 1.0
@export var down_weight := 1.0

@export var target_position_prediction_weight := 0.0

@onready var piece_weights = {
	'Straight': straight_weight,
	'Left': left_weight,
	'Right': right_weight,
	'Big Left': big_left_weight,
	'Big Right': big_right_weight,
	'Up': up_weight,
	'Down': down_weight
}

@onready var grid_map: GridMap = $GridMap
@onready var grid_map_border: GridMap = $"GridMap BORDER"
@onready var finish_area: Area3D = $GridMap/FinishArea
@onready var base_cell_area: Area3D = $GridMap/BaseCellArea
@onready var cell_areas: Node3D = $GridMap/CellAreas
@onready var spawns = $Spawns.get_children() as Array[Marker3D]

# Used to fill gridmap cells that are used by a big track piece
@onready var USED_CELL_ITEM = grid_map.mesh_library.find_item_by_name("UsedCell")

var current_track: Array[PlacedTrackPiece] = []
var kart_id_to_current_piece_index: Dictionary = {}
var kart_id_to_furthest_piece_index: Dictionary = {}

func create_basic_track():
	clear_current_track()

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
	for i in track_length:
		place_piece(c_piece, c_position, c_rotation)
		c_position += TrackPiece.rotate_update(c_piece.total_update(), c_rotation)
		c_rotation += c_piece.rotation_update

		if i >= track_length - 1:
			return place_finish(c_position, c_rotation)

		c_piece = get_valid_successor(get_piece_successors(c_piece), c_position, c_rotation)
		if not c_piece:
			print("NO VALID SUCCESSOR")
			return place_finish(c_position, c_rotation)

func clear_current_track():
	grid_map.clear()
	grid_map_border.clear()
	current_track.clear()
	kart_id_to_current_piece_index.clear()
	kart_id_to_furthest_piece_index.clear()
	for child in cell_areas.get_children():
		child.queue_free()

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
	if with_border:
		var item_border = grid_map.mesh_library.find_item_by_name(str(piece.mesh_name, " BORDER"))
		grid_map_border.set_cell_item(before_update_pos_i, item_border, grid_map.get_orthogonal_index_from_basis(item_basis))
	add_placed_piece(piece, pos, rot)

func add_placed_piece(piece: TrackPiece, pos: Vector3, rot: float):
	var placed_piece = PlacedTrackPiece.new(piece, pos, rot)
	placed_piece.calculate_target_position(grid_map, road_y_offset)
	add_cell_area(current_track.size(), placed_piece)
	if current_track.size() > 0:
		current_track[-1].predict_target_position_with_successor(grid_map, placed_piece, target_position_prediction_weight)
	current_track.append(placed_piece)

func add_cell_area(index: int, placed_piece: PlacedTrackPiece):
	var entered_cb = func(body):
		if body is Kart:
			var kart_id = body.controller.kart_id
			kart_id_to_current_piece_index[kart_id] = index
			var furthest_index = index
			if kart_id in kart_id_to_furthest_piece_index:
				furthest_index = max(index, kart_id_to_furthest_piece_index[kart_id])
			kart_id_to_furthest_piece_index[kart_id] = furthest_index

	var cell_area = base_cell_area.duplicate()
	cell_area.name = "CellArea " + str(index)
	cell_area.position = grid_map.map_to_local(placed_piece.position) + Vector3(0, grid_map.cell_size.y / 2, 0)
	cell_area.body_entered.connect(entered_cb)
	cell_areas.add_child(cell_area)

# Picks a (weighted) random valid successor if there is any
func get_valid_successor(successors: Array[TrackPiece], pos: Vector3, rot: float):
	var valid_filter = func(successor: TrackPiece):
		return is_valid_piece_for_path(successor, pos, rot, path_depth)

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
func pick_weighted_random_successor(successors: Array[TrackPiece]):
	for _i in range(5):
		var random_nr = randf()
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
	return piece_weights[piece.name] if piece.name in piece_weights else 1.0

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

# Returns the global position of the target position of the piece the kart is currently on
# from_furthest: if true, the position will be from the furthest piece the kart has reached, otherwise from the current piece
# index_add can be used to get the target position of a piece further ahead or behind
func get_kart_target_position(kart_id: int, from_furthest: bool, index_add: int = 0):
	var index = 0

	var kart_id_to_piece_index = kart_id_to_current_piece_index
	if from_furthest:
		kart_id_to_piece_index = kart_id_to_furthest_piece_index

	if kart_id in kart_id_to_piece_index:
		index = kart_id_to_piece_index[kart_id] + index_add
		index = clamp(index, 0, current_track.size() - 1)

	return grid_map.to_global(current_track[index].target_position)

func compare_kart_progression(kart_a: Kart, kart_b: Kart) -> bool:
	var kart_a_id = kart_a.controller.kart_id
	var kart_b_id = kart_b.controller.kart_id
	var kart_a_index = kart_id_to_current_piece_index[kart_a_id] if kart_a_id in kart_id_to_current_piece_index else 0
	var kart_b_index = kart_id_to_current_piece_index[kart_b_id] if kart_b_id in kart_id_to_current_piece_index else 0

	if kart_a_index < kart_b_index:
		return false

	if kart_a_index == kart_b_index:
		var kart_a_distance = (get_kart_target_position(kart_a_id, false, 0) - kart_a.global_position).length()
		var kart_b_distance = (get_kart_target_position(kart_b_id, false, 0) - kart_b.global_position).length()
	
		if kart_a_distance > kart_b_distance:
			return false
	
	return true
