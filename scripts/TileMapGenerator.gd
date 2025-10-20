#TileMapManager_testing4by4.gd

extends TileMapManager

class_name TileMapGenerator


@export var troop_container: Node2D

##Quick reference to TileSet coordinates.
var terrain_dict = {
	"Plains": Vector2(1,6),
	"Road": Vector2(4,6),
	"Sea": Vector2(4,9)
}

var troop_list: Array[Troop]

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
	
	# create tiles object for every potion in the map
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


func update_troop_list(troop: Troop):
	troop_list.append(troop)


func spawn_test_troops():
	var troop_scene: PackedScene = preload("res://scenes/Troop.tscn")
	
	#var troop1 = Troop.new("Knight", 100, 2, Vector2i(2,2), "Knight", {})
	#var troop2 = Troop.new("Tank", 200, 5, Vector2i(2,3), "Tank", {})
	var troop1: Troop = troop_scene.instantiate()
	troop1.set_data("Knight", 100, 2, Vector2i(2,2), "Knight", {})
	var troop2: Troop = troop_scene.instantiate()
	troop2.set_data("Tank", 200, 5, Vector2i(2,3), "Tank", {})
	
	# add nodes to the troop container
	troop_container.add_child(troop1)
	troop_container.add_child(troop2)
	
	## register troops on tiles.
	troop1.position = map_to_local(troop1.grid_position)
	troop2.position = map_to_local(troop2.grid_position)
	
	##Might not need to keep a list of troops instead just troop_container.get_children() if we need them.
	update_troop_list(troop1)
	update_troop_list(troop2)
	
	for i in troop_list:
		print(i.name, " ", i.grid_position)
