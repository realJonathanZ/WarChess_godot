## TileMapManager.gd

##NOTE: Changed this from extends Node2D to TileMapLayer so that we can use the built-in functions of TileMapLayer.
extends TileMapLayer

class_name TileMapManager

## the width and the height of the map
var width: int
var height: int

## The array that will be initialized with null-s in it.
## Each entry means nothing in the current implementation, just a placeholder for
## "there should be a tile here"
##
## We should find troop instances from troop_list (in subclass or this class)
## We should fins tile mobility via godot built in customed layer of tilemaplayer.
## (Through) TileSet -> Paint -> Paint properties -> scroll down to last
var tiles: Array = [] 


## When the construction for an instance is done..
## The self.tiles attr is..
## An W * H 2Darray
## The first indexing is along the horizental axis,
## and the second indexing is along the vertical axis(bottom to top)
func  set_up_map(awidth: int, aheight: int):
	self.width = awidth
	self.height = aheight
	self.tiles.resize(width) # Now we got index in (Array) tiles to be 0 to (width - 1)
	for x in range(width):
		self.tiles[x] = []
		for y in range(height):
			self.tiles[x].append(null)
			# debug
			print("set up the tile in the map at position: ", "(", x, ":", y, ")")
			
## set the tile object at the position (x, y)
##
#func set_tile(atile:Tile):
	#self.tiles[atile.position.x][atile.position.y] = atile
	
## get the tile object at postion(x, y)
##
#func get_tile(aposition: Vector2i) -> Tile:
	#return self.tiles[aposition.x][aposition.y]
