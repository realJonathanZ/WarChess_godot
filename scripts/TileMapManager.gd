extends Node

class_name TileMapManager

## the width and the height of the map
var width: int
var height: int
var tiles: Array = [] ## 2D Array of Tile instances, initialized after construction

## When the construction for an instance is done..
## The self.tiles attr is..
## An W * H 2Darray
## The first indexing is along the horizental axis,
## and the second indexing is along the vertical axis(bottom to top)
func  _init(width: int, height: int):
	self.width = width
	self.height = height
	self.tiles.resize(width) # Now we got index in (Array) tiles to be 0 to (width - 1)
	for x in range(width):
		self.tiles[x] = []
		for y in range(height):
			self.tiles[x].append(null)
			
## add a tile at the position (x, y)
func set_tile(tile:Tile):
	self.tiles[tile.position.x][tile.position.y] = tile
	
## get the tile at postion(x, y)
func get_tile(position: Vector2) -> Tile:
	return self.tiles[position.x][position.y]
