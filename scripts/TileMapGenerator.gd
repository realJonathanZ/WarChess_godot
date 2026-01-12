## TileMapGenerator.gd

## Attached to the node TileMapLayer18x18
## '18' here means the Tileset Tab -> Setup -> the texture region got x=y=18px
## i.e. each texture region got 18x18px range

extends TileMapManager

class_name TileMapGenerator

@onready var turn_manager: TurnManager = $"../TurnManager"


@export var troop_container: Node2D

@export var hover_ui: Control

var hover_ui_normal: Color = Color("006f006e")
var hover_ui_attack: Color = Color("6f00006e")

@onready var move_and_attack_session: MoveAndAttackSession = $MoveAndAttackSession


##Quick reference to TileSet coordinates.
var terrain_dict = {
	"Plains": Vector2(1,6),
	"Road": Vector2(4,6),
	"Sea": Vector2(4,9)
}



@export var map_width: int = 0
@export var map_heigth: int = 0



func _ready():
	## Check the session is binding as a child of the node where this scirpt is bindig to
	if move_and_attack_session == null:
		move_and_attack_session = $MoveAndAttackSession
	## if it's still null after attempting to bind..
	if move_and_attack_session == null:
		push_error("MoveAndAttackSession not found! <- error from _ready() in TileMapGenerator.gd")
		
	## Connecting signals from the turn manager
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	
	## Godot does not support to call _init() in _ready(), it will crash
	## set the map on
	set_up_map(map_width, map_heigth) ## using set_up_map() declared inside super class(TileMapManager), instead...
	
	## The manager starts with default BLUE_TEAM to be the first faction in round#1
	turn_manager.start_game(TurnManager.Faction.BLUE_TEAM)
	
	#debug
	print("-----From TileMapLayer 18x18-----")
	
	for x in range(width):
		for y in range(height):
			#Adding 3 types of tiles just to test that the custom properties actually load for each tile
			if x > 3:
				#make the tilemap place a tile at the (1st arg). Use tile from Tileset (2nd arg) at coords (3rd arg)
				set_cell(Vector2(x,y), 0, terrain_dict["Sea"])
			elif x < 2:
				set_cell(Vector2(x,y), 0, terrain_dict["Road"])
			else:
				set_cell(Vector2(x,y), 0, terrain_dict["Plains"])
			
			#The tileset has custom properties (In the Tileset tab -> Paint -> Custom data)
			# debug
			print("Drawed tile at position:", Vector2(x,y), 
			" | Terraint type: ",get_cell_tile_data(Vector2i(x, y)).get_custom_data("terrain_type"),
			" | Block Mobility: ",get_cell_tile_data(Vector2i(x, y)).get_custom_data("block_mobility")
			)
	
	# spawn two troops
	spawn_test_troops()




func spawn_test_troops():	
	## Recap the parameters we need for creating a troop, in order! (the init and set data funcs are inside Troop.gd)
	##1 atroop_name: String
	##2 amax_hp: int
	##3 amobility: int
	##4 arange_lower_bound: int
	##5 arange_upper_bound: int
	##6 aarmor: int
	##7 agrid_position: Vector2i
	##8 atroop_type: String
	##9 ainitial_dmg_resist: Dictionary -> Key: string , Value: float  # NOT TESTED YET
	##
	
	
	var troop_scene: PackedScene = preload("res://scenes/Troop.tscn")
	
	var troop1: Troop = troop_scene.instantiate()
	troop1.set_data("Knight", 100, 6, 1, 1, 2, Vector2i(0,0), "Knight", {})
	var troop2: Troop = troop_scene.instantiate()
	troop2.set_data("Tank", 200, 6, 1, 1, 5, Vector2i(0,5), "Tank", {})
	var troop3: Troop = troop_scene.instantiate()
	troop3.set_data("Archer", 200, 6, 2, 3, 5, Vector2i(5,0), "Tank", {})
	var troop4: Troop = troop_scene.instantiate()
	troop4.set_data("Missile-Vehicle", 200, 6, 4, 7, 5, Vector2i(5,5), "Tank", {})
	
	troop1.faction = TurnManager.Faction.RED_TEAM
	troop2.faction = TurnManager.Faction.RED_TEAM
	troop3.faction = TurnManager.Faction.BLUE_TEAM
	troop4.faction = TurnManager.Faction.BLUE_TEAM
	
	
	# add nodes to the troop container
	troop_container.add_child(troop1)
	troop_container.add_child(troop2)
	troop_container.add_child(troop3)
	troop_container.add_child(troop4)
	## NOTE: have mannully set TroopContainer.zindex to be 5, so affecting all created troops appearing at the top.
	
	#change troop's position.
	troop1.position = map_to_local(troop1.grid_position)
	troop2.position = map_to_local(troop2.grid_position)
	troop3.position = map_to_local(troop3.grid_position)
	troop4.position = map_to_local(troop4.grid_position)
	
	connect_troop_signals(troop1)
	connect_troop_signals(troop2)
	connect_troop_signals(troop3)
	connect_troop_signals(troop4)


func connect_troop_signals(troop: Troop):
	#When the "troop_clicked" signal is emitted from the troop scene, run the troop_selected() function
	troop.troop_clicked.connect(_on_troop_selected)
	#troop.troop_hovered.connect(_on_troop_hovered)
	#troop.troop_unhovered.connect(_on_troop_unhovered)


## This function is called when a troop is clicked on.
## The signal is connected via troopx.connect("troop_clicked", _on_troop_selected) in _ready() (ancestor)
## Signal: omited by troop.gd + area2D node under the troop
func _on_troop_selected(origin: Troop):
	# origin is passed to start_session(), to be a "selected_troop" in the session
	
	## NEVER start a new session when the session is already active
	## To entry this part, for example, the user might click on the ally troop B when it is in troopA's session.
	## And we do not want start new session for troop B, while the remain logic is handled in session script
	if move_and_attack_session.active:
		print("ignoring the troop click since the move and attack session is already active. <- _on_troop_selected() in Generator script")
		return
		
	#print("clicked on troop at ", origin.grid_position)
	## If the faction of this troop does not match the faction from the turn manager... 
	if origin.faction != turn_manager.current_faction:
		print("It's currently ",
		turn_manager.faction_to_string(turn_manager.current_faction),
		"'s turn — cannot select enemy troop:",
		origin.troop_name)
		return
		

		
	# otherwise, the fraction matches the turn that told by turn manager
	# session starts
	move_and_attack_session.start_session(origin, self)
	return
	
## -----
## Turn Logic handles
## Signal received from TurnManager.gd, connected in self._ready()
## The signal received is with a TurnManager.Faction indicating the current turn faction
## -----

func _on_turn_started(afaction: TurnManager.Faction) -> void:
	print("Turn started for ", turn_manager.faction_to_string(afaction))
	## reset the "has-moved" attri to false at the beginning of each turn
	for troop in troop_container.get_children():
		if troop.faction == afaction:
			troop.unit_has_moved_this_turn = false
			
func _on_turn_ended(afaction: TurnManager.Faction) -> void:
	print("Turn ended for ", turn_manager.faction_to_string(afaction))
	## Since unit.has-moved is reset at the start of each turn
	## might not needed to set them again at the turn end
	
	## At the end of one turn, "kill" the session
	## not actually kill, just making it not active
	## I think it's ok, at this time, even without the following code
	## since session will always ended, and it's session scripts duty??
	## but in case..
	if move_and_attack_session.active:
		move_and_attack_session._cancel_session()
		
	








## NOTE: The functions below are no longer used in the latest version.

##Called everytime any input happens.
#func _input(event: InputEvent) -> void:
	##If the event is the mouse moving
	#if event is InputEventMouseMotion:
		#var hovered_tile = local_to_map(get_global_mouse_position())
		#
		##debug
		##print("Mouse is on ", hovered_tile)
		#
		##move the hover ui to where the mosue is and align it with tiles.
		#hover_ui.position = map_to_local(hovered_tile)
		#
		##NOTE: the event is not .consumed() or being set_input_as_handled()
		## Thus, the event continues travelling down the input chain.
		## Input chain, when input occurs:
		## 1. It’s sent first to focused UI elements.
		## 2. If not consumed, it’s passed to nodes with _input().
		## 3. Finally, if still unhandled, it goes to nodes with _unhandled_input().




#func _on_troop_hovered(origin: Troop):
	##If the player hovers over a troop while a movement sesssion is active then give it the option to attack that troop.
	#if session.active:
		#session.tile_occupied = true
		#session.target_troop = origin
		#
		##set hover ui to red
		#var hover_ui_c_rect = hover_ui.get_child(0)
		#if hover_ui_c_rect is ColorRect:
			#hover_ui_c_rect.color = hover_ui_attack
#
#
#func _on_troop_unhovered():
	#if session.active:
		#session.tile_occupied = false
		#session.target_troop = null
		#
	##set hover ui to green again.
	#var hover_ui_c_rect = hover_ui.get_child(0)
	#if hover_ui_c_rect is ColorRect:
		#hover_ui_c_rect.color = hover_ui_normal
