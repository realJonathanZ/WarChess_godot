extends Node2D

## The path line is supposed to instruct how the animation is done on the troop, and
## how the plan-lines within a session can be
@onready var path_line: Line2D = $PathLine

var selected_troop: Troop # The troop currently moving in the session
var tilemap: TileMapGenerator # Reference to the TileMapGenerator
var move_stack: Array[Vector2i] = [] # stack of vector2i points that plotting the path

## The cost of move for this moement session, should eventually become
## the sum of all block_mobilities for the tiles
var move_cost: int = 0

## Called to start the session
func start_session(troop: Troop, tilemap_ref: TileMapGenerator) -> void:
	selected_troop = troop
	tilemap = tilemap_ref
	move_stack.clear()
	move_stack.append(troop.grid_position) ## the orginal starting tile-index of the troop
	print("Moving session started for ", troop.troop_name)
	print("appended first location ->", troop.grid_position)
	
	# Setup the line_style
	path_line.width = 3.0 ## change if not looking good
	path_line.default_color = Color(0,1,0) ## Green = OK, can do the move
	
	
func _input(event: InputEvent) -> void:
	if selected_troop == null or tilemap == null:
		print("The input event is received to MoveAndAttackSession.gd - (CanvasLayer)
		, but something wrong happens inside _unhandled_input()")
		return
		
	if event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		var hovered_tile = tilemap.local_to_map(mouse_pos)
		_update_stack(hovered_tile)
				
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			_confirm_move()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_cancel_session()

## update the path and cost based on hovered tile
func _update_stack(tile: Vector2i) -> void:
	#print("About to update on move stack", move_stack)
	if move_stack.size() == 0:
		return
	
	var last_tile: Vector2i = move_stack[move_stack.size() - 1]
	
	if abs(tile.x - last_tile.x) + abs(tile.y - last_tile.y) != 1:
		return
	
	if move_stack.size() >= 2 and tile == move_stack[move_stack.size() - 2]:
		var popped = move_stack.pop_back()
		print("poped location:", popped)
	else:
		if tile != last_tile:
			print("appended location", tile)
			move_stack.append(tile)
	
	# Calculate new move cost
	move_cost = _calculate_path_cost(move_stack)
	print("new move_cost is ", move_cost)
	
	# Update color depending on troop mobility
	if move_cost > selected_troop.mobility:
		path_line.default_color = Color(1, 0, 0)  # red = over limit
	else:
		path_line.default_color = Color(0, 1, 0)  # green = within range
	
	# Update line drawing positions
	_update_path_visual()

# Calculate the total mobility cost along the path
func _calculate_path_cost(path: Array[Vector2i]) -> int:
	var cost_sum = 0
	# The starting tile do not cost mobility points
	for i in range(1, path.size()):
		var tile_pos = path[i]
		var tile_data = tilemap.get_cell_tile_data(tile_pos)
		if tile_data == null:
			continue
		cost_sum += tile_data.get_custom_data("block_mobility")
	return cost_sum

# Convert stack -> Line2D points
func _update_path_visual() -> void:
	path_line.clear_points()
	for tile_pos in move_stack:
		var world_pos = tilemap.map_to_local(tile_pos) + tilemap.position
		path_line.add_point(world_pos)

func _confirm_move() -> void:
	if selected_troop == null or move_stack.size() < 2:
		_cancel_session()
		return
	
	if move_cost > selected_troop.mobility:
		print("Path too long. Cancelled.")
		_cancel_session()
		return
	
	# Move troop immediately to target (animation comes later)
	var target_tile = move_stack.back()
	selected_troop.grid_position = target_tile
	selected_troop.position = tilemap.map_to_local(target_tile)
	selected_troop.moved = true   ## intended to make it to false gain when it's starting next turn.
	print("Troop moved to ", target_tile)
	
	_cleanup_session()

func _cancel_session() -> void:
	#print("Move session cancelled.")
	_cleanup_session()

func _cleanup_session() -> void:
	#print("clean up")
	queue_free()
	
	
