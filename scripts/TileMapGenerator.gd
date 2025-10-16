#TileMapManager_testing4by4.gd

extends TileMapManager

class_name TileMapGenerator


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
	
	# create tiles object for every potion in the map
	for x in range(width):
		for y in range(height):
			#make the tilemap place a tile at the (1st arg). Use tile from Tileset (2nd arg) at coords (3rd arg)
			set_cell(Vector2(x,y), 0, terrain_dict["Plains"])
			# debug
			print("Drawed tile at position:", Vector2(x,y))
	
	# spawn two troops
	spawn_test_troops()


func update_troop_list(troop: Troop):
	troop_list.append(troop)

func spawn_test_troops():
	var troop1 = Troop.new("Knight", 100, 2, Vector2i(2,2), "Knight", {})
	var troop2 = Troop.new("Tank", 200, 5, Vector2i(2,3), "Tank", {})
	
	# add nodes to the troop container
	add_child(troop1)
	add_child(troop2)
	
	## register troops on tile objects
	##get_tile(Vector2i(0,0)).troop = troop1
	##get_tile(Vector2i(3,3)).troop = troop2
	
	update_troop_list(troop1)
	update_troop_list(troop2)
