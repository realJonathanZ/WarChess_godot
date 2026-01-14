extends Node2D
class_name MoveAndAttackSessionView

@onready var path_line: Line2D = $PathLine

var tilemap: TileMapManager

func draw_move_path(path: Array[Vector2i]) -> void:
	path_line.clear_points()
	for cords in path:
		path_line.add_point(tilemap.map_to_local(cords))
		
func clear() -> void:
	path_line.clear_points()
