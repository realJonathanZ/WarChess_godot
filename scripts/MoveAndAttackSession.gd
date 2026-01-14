extends Node2D

class_name MoveAndAttackSession

######################################################################################
##NOTE:changing parts
@onready var maas_view: MoveAndAttackSessionView = $MAAS_view
@onready var path_line: Line2D = $MAAS_view/PathLine

##NOTE: changing parts
var mass_model : MoveAndAttackSessionModel = MoveAndAttackSessionModel.new()
#######################################################################################


var selected_troop: Troop # The troop currently being selected in the session
var tilemap: TileMapManager # Reference to the TileMapGenerator
var move_stack: Array[Vector2i] = [] # stack of vector2i points that plotting the path

var troop_container: Node2D = null # This will be updated to the reference to TroopContainer node in start_session()

# list of grid positions (Vector2i) within this troop's attack range
var attackable_cells: Array[Vector2i] = [] 

## Is this session active? (will be set to ture everytime start_session() is run)
var active: bool = false

## This var is currently in use by function _confirm_attack() in this script. 
var target_troop: Troop #The troop being attacked.

# The cost of move for this moement session, should eventually become
# the sum of all block_mobilities for the tiles
var move_cost: int

# The flags indicating if the selected troop in this session has attacked/ has moved, respectively
var has_attacked_in_session:bool
var has_moved_in_session:bool


## Called to start the session
func start_session(troop: Troop, tilemap_ref: TileMapManager) -> void:
	################################################################################
	#NOTE: changing parts
	mass_model.move_path_changed.connect(maas_view.draw_move_path)
	mass_model.session_ended.connect(maas_view.clear)
	
	## Have to tell view class the tilemap ref cuz view cannot and wont search in tree
	maas_view.tilemap = tilemap_ref
	##################################################################################
	
	selected_troop = troop
	tilemap = tilemap_ref
	
	# Get the TroopContainer node in the scene tree.
	# Assumes the hierarchy: TestMapRoot/TroopContainer
	self.troop_container = get_tree().get_root().get_node("TestMapRoot/TroopContainer")
	
	# calculate the range, give it to atack_range_tiles
	attackable_cells = _calculate_attack_range()
	#print("Attackable tiles for", troop.troop_name, ":", attackable_cells)
	
	active = true
	visible = true
	
	# reset per-session state flags
	# these flags are used in move_and_attack cotrol flows, that this session controls
	self.has_attacked_in_session = false
	self.has_moved_in_session = false
	
	move_stack.clear()
	move_stack.append(troop.grid_position) ## the orginal starting tile-index of the troop
	print("Moving session started for ", troop.troop_name)
	print("appended first location ->", troop.grid_position)
	
	# Setup the line_style
	path_line.width = 3.0 ## change if not looking good
	path_line.default_color = Color(0,1,0) ## Green = OK, can do the move
	_update_path_visual()

# =====
# Mouse event propagation control flow
# =====


func _input(event: InputEvent) -> void:
	if active:
		if selected_troop == null or tilemap == null:
			print("The input event is received to MoveAndAttackSession.gd - (CanvasLayer)
			, but something wrong happens inside MoveAndAttckSession.gd -> _input()")
			return
			
		if event is InputEventMouseMotion:
			# if the flag shows the unit has done the move in this session...
			# Don't need to track the preview path! DOn't need to draw lines! Don't need to _update_stack() either
			if has_moved_in_session:
				return  # stop drawing the path after troop has moved
				
			var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
			var hovered_tile = tilemap.local_to_map(mouse_pos)
			_update_stack(hovered_tile)
			
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_handle_left_click()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
				_cancel_session()
				

func _handle_left_click() -> void:
	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var clicked_cell = tilemap.local_to_map(mouse_pos) # this var is a vector2i e.g. (4.3)
	
	if self.has_attacked_in_session:
		print("This troop already attacked. Cannot act further this turn.")
		return
	
	# Am I clicking on an empty cell, or a troop(of any fraction, any type)?
	var clicked_troop = null
	for troop in troop_container.get_children():
		if troop.grid_position == clicked_cell:
			clicked_troop = troop
			break
			
	# case #1: i clicked on enemy troop, try to attack it
	if clicked_troop != null and clicked_troop.faction != selected_troop.faction:
		if clicked_cell in attackable_cells:
			print("about to confirm_attack on enemy:", clicked_troop.troop_name, "at", clicked_cell)
			_confirm_attack(clicked_troop)
		else:
			print("Enemy out of range:", clicked_troop.troop_name, "at", clicked_cell)
		return
		
	# case #2: clciked on ally or self, try do nothing, ignore the event!
	if clicked_troop != null and clicked_troop.faction == selected_troop.faction:
		print("Clicked on an ally troop or self, ignoring this click event")
		return
		
	# case #3: clciked on empty cell
	# but is it really empty?
	if clicked_troop != null:
		print("Error: something is wrong inside _handle_left_click()")
		return
	
	if self.has_moved_in_session:
		print("Already moved — you can only attack now.")
	else:
		_confirm_move()


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
		#print("poped location:", popped)
	else: # if no pop form stack, it's time to append!
		if tile != last_tile:
			#print("appended location", tile)
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
	#var bool01 = _validate_destination()
	#var bool02 = _validate_no_enemy_blocking()
	#var bool03 = _validate_by_movement_type_and_terrains()
	
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
	selected_troop.unit_has_moved_this_turn = true   ## intended to make it to false gain when it's starting next turn.
	## TODO: handle the move-animation here??
	
	self.has_moved_in_session = true

	# This line is used for makeing area2D unreactive to input events for an amount of time(unused)
	#selected_troop.get_node("ClickDetection").input_pickable = false 
	# Recalculate attack range after movement
	attackable_cells = _calculate_attack_range()
	# print("Attack range recalculated after move:", attackable_cells)
	print("Troop moved to ", target_tile)
	print("Now in attack phase — you may click an enemy to attack.")
	
	## The move is done, whethwe we want to attack another troop, or to quit the session, we clear the path
	path_line.clear_points() # clean the path points after move!
	
	
# =====
# Attacking logic , and the helper funcitons
# =====	

func _calculate_attack_range() -> Array[Vector2i]:
	if selected_troop == null:
		#print("Something is wrong in _calculate_attack_range(), there is no selected troop")
		return []

	var results: Array[Vector2i] = []
	var origin: Vector2i = selected_troop.grid_position
	var lower : int = selected_troop.range_lower_bound
	var upper : int = selected_troop.range_upper_bound

	for dx in range(-upper, upper + 1):
		for dy in range(-upper, upper + 1):
			var distance : int= abs(dx) + abs(dy)
			# distance filter: inside [lower, upper], boundary included
			if distance >= lower and distance <= upper and distance != 0:
				var candidate = origin + Vector2i(dx, dy)
				# only append when it's valid cell on tilemap
				if tilemap.get_used_cells().has(candidate):
					results.append(candidate)
	return results
	
# =====
# Attack confirmation
# =====

## When this function is called, selected troop will deal dmg to target troop
## @para atarget_troop: the target troop instance "being attacked"
func _confirm_attack(atarget_troop: Troop) -> void:
	if selected_troop == null or atarget_troop == null:
		print("Attack error: missing references. in _confirm_attack()")
		return
		
	print(selected_troop.troop_name, "attacks", atarget_troop.troop_name)
	print("selected troop on grid:", selected_troop.grid_position)
	print("target troop on grid:", atarget_troop.grid_position)
	
	atarget_troop.take_dmg(10, selected_troop.troop_type) # temporary dmg #TODO: modify troop.gd to include the troop dmg attr
	
	## This troop is moved for this turn
	selected_troop.unit_has_moved_this_turn = true
	
	## This session, this flag, should be changed!
	self.has_attacked_in_session = true
	
	_cleanup_session() 
	

# ====
# Cancel and clean up
# ====


func _cancel_session() -> void:
	print("Move session cancelled.")
	_cleanup_session()


func _cleanup_session() -> void:
	self.active = false
	self.visible = false
	
	print("clean up for the session")
	#queue_free()
