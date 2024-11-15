extends Resource
class_name PlacedTrackPiece

@export var track_piece: TrackPiece
@export var position: Vector3i
@export var rotation: float
@export var target_position: Vector3

func _init(_track_piece: TrackPiece, _position: Vector3, _rotation: float):
	track_piece = _track_piece
	position = TrackPiece.pos_vector3i(_position)
	rotation = _rotation

func calculate_target_position(grid_map: GridMap, road_y_offset: float):
	target_position = grid_map.map_to_local(position) + Vector3(0, road_y_offset, 0)
	target_position += grid_map.cell_size * (TrackPiece.rotate_update(track_piece.target_position_change, rotation))

# Updates the target_position so that it predicts its successor more
func predict_target_position_with_successor(grid_map: GridMap, successor: PlacedTrackPiece, weight: float = 0.0):
	target_position += (
		weight * 
		grid_map.cell_size *
		successor.track_piece.target_position_prediction_mult *
		(
			TrackPiece.rotate_update(
				successor.track_piece.target_position_change, 
				successor.rotation
			)
		)
	)

func _to_string() -> String:
	return str(track_piece, ' at ', position, ' with rot ', rotation)
