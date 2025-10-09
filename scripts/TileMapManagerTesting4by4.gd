#TileMapManager_testing4by4.gd

extends TileMapManager

class_name TileMapManagerTesting4by4

func _ready():
	## Godot does not support to call _init() in _ready(), it will crash
	set_up_map(4, 4) ## using set_up_map() declared inside super class, instead...
	
	# create tiles object for every potion in the map
	for x in range(width):
		for y in range(height):
			var tile = Tile.new("Plain", Vector2i(x,y))
			set_tile(tile)
			draw_tile_visual(tile)
			# debug
			print("Drawed tile at position:", tile.position)
	
	# spawn two troops
	spawn_test_troops()

## Draw the visuual of one specific tile
##
## @para tile: a Tile instance, where to draw on
func draw_tile_visual(tile: Tile):
	var node = ColorRect.new()
	node.color = Color(0.7,0.7,0.7)
	node.size = Vector2(16,16)
	node.position = Vector2(tile.position.x, tile.position.y) * 16 ## Using 16 for default size of a single box in TileMapLayer setting
	add_child(node)

func spawn_test_troops():
	var troop1 = Troop.new("Knight", 100, 2, Vector2i(2,2), "Knight", {})
	var troop2 = Troop.new("Tank", 200, 5, Vector2i(2,3), "Tank", {})
	
	# add nodes to the troop container
	add_child(troop1)
	add_child(troop2)
	
	## register troops on tile objects
	get_tile(Vector2i(0,0)).troop = troop1
	get_tile(Vector2i(3,3)).troop = troop2
