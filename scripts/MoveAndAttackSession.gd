extends Node2D

class_name MoveAndAttackSession

## The path line is supposed to instruct how the animation is done on the troop, and
## how the plan-lines within a session can be
@onready var path_line: Line2D = $PathLine

var selected_troop: Troop # The troop currently moving in the session
var tilemap: TileMapManager # Reference to the TileMapGenerator
var move_stack: Array[Vector2i] = [] # stack of vector2i points that plotting the path

var troop_container: Node2D = null # This will be updated to the reference to TroopContainer node in start_session()

var active: bool = false

#Both of these are set by TileMapGenerator
var tile_occupied: bool = false #If the mouse is blocked by a troop (used for attacks and making sure that a space is occupied).
var target_troop: Troop #The troop being attacked.

# The cost of move for this moement session, should eventually become
# the sum of all block_mobilities for the tiles
var move_cost: int = 0


## Called to start the session
func start_session(troop: Troop, tilemap_ref: TileMapManager) -> void:
	selected_troop = troop
	tilemap = tilemap_ref
	
	# Get the TroopContainer node in the scene tree.
	# Assumes the hierarchy: TestMapRoot/TroopContainer
	self.troop_container = get_tree().get_root().get_node("TestMapRoot/TroopContainer")
	
	active = true
	visible = true
	
	move_stack.clear()
	move_stack.append(troop.grid_position) ## the orginal starting tile-index of the troop
	print("Moving session started for ", troop.troop_name)
	print("appended first location ->", troop.grid_position)
	
	# Setup the line_style
	path_line.width = 3.0 ## change if not looking good
	path_line.default_color = Color(0,1,0) ## Green = OK, can do the move
	_update_path_visual()


func _input(event: InputEvent) -> void:
	if active:
		if selected_troop == null or tilemap == null:
			print("The input event is received to MoveAndAttackSession.gd - (CanvasLayer)
			, but something wrong happens inside _unhandled_input()")
			return
			
		if event is InputEventMouseMotion:
			var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
			var hovered_tile = tilemap.local_to_map(mouse_pos)
			_update_stack(hovered_tile)
			if tile_occupied:
				pass
			
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_confirm_move()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
				_cancel_session()
				
# =====
# Move Path Logic
# =====

## update the path and cost based on hovered tile
func _update_stack(tile: Vector2i) -> void:
	## If the tile cell does not exist in the tile map, return
	if !(tile in tilemap.get_used_cells()):
		return
	
	#print("About to update on move stack", move_stack)
	
	if move_stack.size() == 0:
		print("Error in _update_stack: move stack length 0")
		return
	
	var last_tile: Vector2i = move_stack[move_stack.size() - 1]
	
	# When updating stack, this tile must have d = 1 far from last tile
	if abs(tile.x - last_tile.x) + abs(tile.y - last_tile.y) != 1:
		return
		
	# Handle the "mouse--hover-back" scenario
	if move_stack.size() >= 2 and tile == move_stack[move_stack.size() - 2]:
		var popped = move_stack.pop_back()
		print("poped location:", popped)
	else: # if no pop form stack, it's time to append!
		if tile != last_tile:
			print("appended location", tile)
			move_stack.append(tile)
	
	# calculate new move cost based on path-cords stack
	move_cost = _calculate_path_cost(move_stack)
	print("new move_cost is ", move_cost)
	
	# Update color depending on troop mobility
	if move_cost > selected_troop.mobility:
		path_line.default_color = Color(1, 0, 0)  # red = over limit
	else:
		path_line.default_color = Color(0, 1, 0)  # green = within range
	# update line drawing positions
	_update_path_visual()

## calculate the total mobility cost along the path stack
## returning an int, which indicated the sum of block-mobility of different terrains along the path
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


## Preapring line2D points, to draw the path out in game
## Line2D node is supposed to be a child of the session
func _update_path_visual() -> void:
	path_line.clear_points()
	for tile_pos in move_stack:
		var world_pos = tilemap.map_to_local(tile_pos) + tilemap.position
		path_line.add_point(world_pos)




# =====
# Validate function s for path validation
#
# A path stack is valid if and only if the consitions below are met:
# Condition #1: if final destination is free of any troop
# COndition #2: if either tile on the path is not occupied by an enemy
# Condition #3: if this moving troop's movement type supports all the terrains along the path(including destination)
# =====

## Validate the path in different dimentions(, at least 3).
## Returns a bool value true is path is validated, otherwise false
func _validate_path() -> bool:
	var bool01 = _validate_destination()
	var bool02 = _validate_no_enemy_blocking()
	var bool03 = _validate_by_movement_type_and_terrains()
	
	#print("_validate_destination() returns:", bool01)
	#print("_validate_no_enemy_blocking() returns:", bool02)
	#print("_validate_by_movement_type_and_terrains() returns:", bool03)
	#
	#print("Selected troop:", selected_troop.troop_name, "at", selected_troop.grid_position)
	#print("Move stack:", move_stack)
	#print("All troop positions:")
	#for troop in troop_container.get_children():
		#print("  ", troop.troop_name, "at", troop.grid_position)
	
	return _validate_destination() and _validate_no_enemy_blocking() and _validate_by_movement_type_and_terrains()
	
## Validate the destination is not blocked by any troop
## Returns a bool value true if the path is not blocked by any troop, otherwise false.
func _validate_destination() -> bool:
	var destination = move_stack.back()
	
	# safety check: There must be wrong if no troop is inside the container
	if troop_container == null:
		push_warning("troop_container is null in _validate_destination() inside session script")
		return false
	
	## Is there any troop at the destination? (enemy or ally), since troop DOES NOT stack
	for troop in troop_container.get_children():
		if troop == selected_troop:
			continue  # skip self
		if troop.grid_position == destination:
			print("Destination blocked by", troop.troop_name)
			return false
	return true

## Validating that no enemy troop blocking the path, at any position in path_stack
func _validate_no_enemy_blocking() -> bool:
	# safety check: There must be wrong if no troop is inside the container
	if troop_container == null:
		push_warning("troop_container is null in _validate_no_enemy_blocking() inside session script")
		return false
	
	for pos in move_stack:
		for troop in troop_container.get_children():
			if troop == selected_troop:
				continue # skip self
			## Only enemy unit can block the path. This selected unit can go through ally unit
			if troop.grid_position == pos and troop.faction != selected_troop.faction:
				print("Enemy blocking path at ", pos, " : (troopname -> ", troop.troop_name, ")")
				return false
	return true

## Validating that each tile on the path is suppotable, based on troop's movement type
## It is just a stub funciton for now
func _validate_by_movement_type_and_terrains() -> bool:
	## TODO: switch case determination on troop of different movement type?
	return true
	
# =====
# Move confirmation
# =====

## Confirm the move step, updating seleted troop position.
## If stack sice <= 1, cancel session since selected troop did not move
## The move is confirmed when several conditions are met.
## Condition #1: move_cost is <= selected_troop.mobility .
## Condition #2: the path is validated by validation function(s?).
func _confirm_move() -> void:
	if selected_troop == null or move_stack.size() <= 1:
		print("Error: inside _confirm_move(), session about to cancel")
		_cancel_session()
		return
	
	if move_cost > selected_troop.mobility:
		print("Path too long. Cancelled.")
		_cancel_session()
		return
		
	if not _validate_path():
		print("Invalid path through _validate_path(), check it out in MoveAndAttackSession.gd !(triggered at _confirm_move())")
		_cancel_session()
		return
	
	var target_tile = move_stack.back()
	selected_troop.grid_position = target_tile
	selected_troop.position = tilemap.map_to_local(target_tile)
	selected_troop.moved = true   ## intended to make it to false gain when it's starting next turn.
	## TODO: handle the move-animation here??

	# This line is used for makeing area2D unreactive to input events for an amount of time(unused)
	#selected_troop.get_node("ClickDetection").input_pickable = false 
	print("Troop moved to ", target_tile)
	
	_cleanup_session()
	
	
##Attack target_troop using selected_troop's stats
func _confirm_attack():
	pass
	##Make sure it's not attacking itself or an ally.
	#if target_troop != selected_troop and target_troop.faction != selected_troop.faction:
		#target_troop.take_dmg(1, selected_troop.troop_type)


func _cancel_session() -> void:
	print("Move session cancelled.")
	_cleanup_session()


func _cleanup_session() -> void:
	active = false
	visible = false
	
	print("clean up for the session")
	#queue_free()
