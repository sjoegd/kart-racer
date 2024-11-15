extends Resource
class_name TrackCollection

@export var track_pieces: Array[TrackPiece] = []

func generate_track_one_hot_encoding(track: Array[PlacedTrackPiece]) -> Array:
	var track_encoding = []
	for placed_piece in track:
		track_encoding.append(_get_one_hot_encoding(placed_piece.track_piece))
	return track_encoding

func _get_one_hot_encoding(piece: TrackPiece) -> Array:
	return track_pieces.map(
		func (track_piece: TrackPiece):
			if track_piece.name == piece.name:
				return 1.0
			return 0.0
	)
