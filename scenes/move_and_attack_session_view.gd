extends Node2D
class_name MoveAndAttackSessionView

@onready var path_line: Line2D = $PathLine

@export var tilemap: TileMapManager

## giving dots to the Line2D child and draw it.
func draw_move_path(path: Array[Vector2i]) -> void:
	if tilemap == null:
		print("Error: no tilemap reference found when executing move_and_attack_session_view.gd -- draw_move_path")
	path_line.clear_points()
	for cords in path:
		path_line.add_point(tilemap.map_to_local(cords))

## clear all points on the Line2D child
func clear() -> void:
	path_line.clear_points()

## make self and the line2D child visible again	
func _on_session_started(troop: Troop) -> void:
	visible = true

## make self and the line2D child invisible again, and, clear the point components of line2D child	 	
func _on_session_ended(troop: Troop) -> void:
	clear()
	visible = false
	
