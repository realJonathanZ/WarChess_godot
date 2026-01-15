class_name MoveAndAttackSessionModel

## ==
## States
## ==

var selected_troop:Troop # selected troop in the session
var tilemap: TileMapManager # reference to the (only) tile map in THIS level
var troop_container: Node2D # troop container contains troop objects

var move_path: Array[Vector2i] = [] # A set of adjacent-continuous vector2i gird-points that will soon instructing view class to draw preview path
var attackable_cells: Array[Vector2i] = [] # A set of vector2i gird-points that includes all attackable cells in range, of the current selected troop.
# NOTE: attackable cells should be work whether the troop has or has not moved after a single session started

var move_cost: int = 0 # The move cost. Should be the sum of all terrains at grids specified by move_path
var active: bool = false # Is this session active?
# NOTE: an inactive session will be rejected to be opened in main maas script

## ==
## Signals
## All signals are intended to be wired in main session script
## ==

signal move_path_changed(path) #changed so tell view to update path
signal attackables_changed(cells) #changed to tell view to update (possible highlight range)
signal session_started(troop) #changed to tell view: session started for A troop, start inserting plotting points in
signal session_ended(troop) #changed to tell view: sesssion ended for A troop, clean the evidence(drawing)

# changed to tell view: A troop has confirmed the moving logic and about to move, 
# move TO a Vector2i destination
signal move_confirmed(troop: Troop, destination: Vector2i)

# changed to tell view: A troop has confirmed the attacking logic and about to attack,
# attack to a Vector2i destination
signal attack_confirmed(troop: Troop, destination: Vector2i)

## ====
## move and attack session --- life cycle
## ====

## Start a move_and_attack session with several state determination/state change after it.
## NOTE that: the session should be only existing one. More than one session existing may imply bugs inside.
## @para troop: the troop instance that will be assigned to selected troop within this session.
## @para tilemap_ref: the reference of the tile map layer of this level
## @para troop_container_ref: the reference of the troop container of this level
func start_session(atroop: Troop, tilemap_ref: TileMapManager, troop_container_ref: Node2D):
	print("I'm first code line in maas model script -> start_session()")
	
	selected_troop = atroop
	tilemap = tilemap_ref
	troop_container = troop_container_ref
	
	move_path.clear() # turn logic's call back funcs are also clearing the drawing lines!
	move_path.append(selected_troop.gird_position)
	
	move_cost = 0
	active = true
	
	attackable_cells = _calculate_attack_range()
	
	## emit these signals hoping that view can receive and then execute its call back funca
	emit_signal("session_started", selected_troop)
	emit_signal("move_path_changed", move_path)
	emit_signal("attackables_changed", attackable_cells)

## end the session, and, clear all states of maas_model class to intial	
func end_session() -> void:
	if not active:
		return
		
	active = false
	emit_signal("session_ended", selected_troop)
	
	selected_troop = null
	move_path.clear()
	attackable_cells.clear()
	
## ===
## 'preview path' logic. 
## Player can preview path visual after session starts and before move is confirmed
## ===

## given a tile grid recently 'catched' from an input nouse motion event, then determine:
## do we add it to coords stack(move_path)? or delete it? or do nothing?
## based on different scenarios
func preview_tile(tile: Vector2i) -> void:
	if not active:
		return
	if selected_troop.unit_has_moved_this_turn:
		return
	if not tilemap.get_used_cells().has(tile):
		return
	if move_path.is_empty():
		return
		
	## else, if not returning by the guards above, 
	var last: Vector2i = move_path.back()
	
	## must be adjacent in '4-connectivity' rule
	if abs(tile.x - last.x) + abs(tile.y - last.y) != 1:
		return
		
	## hover-back scenario:
	if move_path.size() >=2 and tile == move_path[ move_path.size() - 2 ]:
		move_path.pop_back()
	else:
		## nah not hover back
		## but if it is the same tile? we do not append the same tile
		if tile != last:
			move_path.append(tile)
			
	move_cost = _calculate_path_cost(move_path)
	emit_signal("move_path_changed", move_path)
	
## =====
## Move confirmation
## =====

## The move in the session is confirmed, so,
## move the troop, and recalculate relevant session states as well as this troop's node position and stats attributes
func confirm_move() -> void:
	if move_path.size() <= 1:
		end_session()
		return
	
	if move_cost > selected_troop.mobility:
		end_session()
		return
		
	if not self._validate_path():
		end_session()
		return
		
	## TODO TODO TODO TODO
	## unfinished part. 
	## updating stats for this selected troop
	## got different attack range and attackable cells after move
	## optional? get the move path stack cleared after move
	## emit signal so view can receive! The connection of signal should be left to main session script
		
		
		
## =====
## Attack Confirmation
## =====
## When this function is called, selected troop will deal dmg to target troop
## @para atarget_troop: the target troop instance "being attacked"
func confirm_attack(target: Troop) -> void:
	if not active or target == null:
		return
	
	##TODO: change the hard coded 10 dmg to attackew's real dmg
	## Need modifying troop class then come back for it
	target.take_dmg(10, selected_troop.troop_type)
	selected_troop.unit_has_moved_this_turn = true
	
	emit_signal("attack_confirmed", selected_troop, target)
	end_session()
	
## ===
## Validation logic
## A path stack is valid if and only if the consitions below are met:
## Condition #1: if final destination is free of any troop
## COndition #2: if either tile on the path is not occupied by an enemy
## Condition #3: if this moving troop's movement type supports all the terrains along the path(including destination)
## ===
	
## This function returns a combination of few validation funcs' returns that must be met prior, and before
## the unit is confirmed to move. (otherwise we are in the sea of bugs)
func _validate_path() -> bool:
	return(
		_validate_destination()
		and _validate_no_enemy_blocking_in_way()
		and _validate_by_movement_type_and_terrains()
	)	
	
## Validate the destination is not occupied by any troop.
## i.e. to return true, there must be no troop on destination
func _validate_destination() -> bool:
	var dest: Vector2i = move_path.back()
	for troop in troop_container.get_children():
		if troop == selected_troop:
			continue
		if troop.grid_position == dest:
			return false
	return true

## Validate either tile on the path is not blocked by enemy troop
## i.e. to return true, there is no enemy faction troop between starting tile and destination tile
## It can return true if ally unit is in between.	
func _validate_no_enemy_blocking_in_way() -> bool:
	for cords in move_path:
		for troop in troop_container.get_children():
			if troop == selected_troop:
				continue
			if troop.grid_position == cords and troop.faction != selected_troop.faction:
				return false
	return true
	
## NOTE TODO just a stub, filling it with right logic
## intended to return false if the troop's movement type does not support the move of this troop
func _validate_by_movement_type_and_terrains() -> bool:
	return true
	
## =====
## Calculations
## Have some calculation funcs here.
## They are mainly calculating the math, in order to be used in other funcs that need determination on numbers
## =====
	
	###TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
	### below are stubs
	
	
	
	
	
	
	
	


# stub
func _calculate_path_cost(a_move_path:Array[Vector2i]) -> int:
	return 12345
	
	
	
# stub
func _calculate_attack_range() -> Array[Vector2i]:
	var exampleVector01: Vector2i = Vector2i(1,1)
	var exampleVector02: Vector2i = Vector2i(2,2)
	return [exampleVector01, exampleVector02]
	
	











 
