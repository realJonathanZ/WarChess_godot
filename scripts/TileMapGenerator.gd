## TileMapGenerator.gd

## Attached to the node TileMapLayer18x18
## '18' here means the Tileset Tab -> Setup -> the texture region got x=y=18px
## i.e. each texture region got 18x18px range

extends TileMapManager

class_name TileMapGenerator


@export var troop_container: Node2D

@export var hover_ui: Control

var troop_list: Array [Troop]

##Quick reference to TileSet coordinates.
var terrain_dict = {
	"Plains": Vector2(1,6),
	"Road": Vector2(4,6),
	"Sea": Vector2(4,9)
}

##Exporting makes it so you can edit it in the editor (on the right side of screen)
##This makes it so we can reuse this script for any size as long as we set the two vars below.
@export_category("Dimensions")

@export var map_width: int = 0
@export var map_heigth: int = 0




func _ready():
	## Godot does not support to call _init() in _ready(), it will crash
	set_up_map(map_width, map_heigth) ## using set_up_map() declared inside super class, instead...
	
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


#Called everytime any input happens.
func _input(event: InputEvent) -> void:
	#If the event is the mouse moving
	if event is InputEventMouseMotion:
		var hovered_tile = local_to_map(get_global_mouse_position())
		
		#debug
		#print("Mouse is on ", hovered_tile)
		
		#move the hover ui to where the mosue is and align it with tiles.
		hover_ui.position = map_to_local(hovered_tile)
		
		#NOTE: the event is not .consumed() or being set_input_as_handled()
		# Thus, the event continues travelling down the input chain.
		# Input chain, when input occurs:
		# 1. It’s sent first to focused UI elements.
		# 2. If not consumed, it’s passed to nodes with _input().
		# 3. Finally, if still unhandled, it goes to nodes with _unhandled_input().


func spawn_test_troops():	
	var troop_scene: PackedScene = preload("res://scenes/Troop.tscn")
	
	var troop1: Troop = troop_scene.instantiate()
	troop1.set_data("Knight", 100, 4, 2, Vector2i(0,0), "Knight", {})
	var troop2: Troop = troop_scene.instantiate()
	troop2.set_data("Tank", 200, 4, 5, Vector2i(2,3), "Tank", {})
	
	# add nodes to the troop container
	troop_container.add_child(troop1)
	troop_container.add_child(troop2)
	## NOTE: have mannully set TroopContainer.zindex to be 5, so affecting all created troops appearing at the top.
	
	#change troop's position.
	troop1.position = map_to_local(troop1.grid_position)
	troop2.position = map_to_local(troop2.grid_position)
	
	#When the "troop_clicked" signal is emitted from the troop scene, run the troop_selected() function
	troop1.connect("troop_clicked", _on_troop_selected)
	troop2.connect("troop_clicked", _on_troop_selected)
	
	
	troop_list.append(troop1)
	troop_list.append(troop2)


## This function is called when a troop is clicked on.
## The signal is connected via troopx.connect("troop_clicked", _on_troop_selected) in _ready() (ancestor)
## Signal: omited by troop.gd + area2D node under the troop
func _on_troop_selected(origin: Troop):
	# origin can be used to set the selected troop for future UI/pathfinding implementations.
	
	#debug
	print("clicked on troop at ", origin.grid_position)
	#print("hovered on (self.hover_ui(control)) at -- (global position)", self.hover_ui.position)
	var session_scene = preload("res://scenes/move_and_attack_session.tscn")
	var session = session_scene.instantiate()
	get_parent().add_child(session)
	# Wait one frame to ensure the input event doesn’t immediately propagate
	session.start_session(origin, self)
	
