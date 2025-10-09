#Tile.gd

extends Node

class_name Tile

var terrain_type: String ##e.g. "Sea", "Mountain", "Road", "Forest", "Abyss", "Wall"...
var position: Vector2i ## the grid postiion
var troop: Troop = null ## Is a specified troop occuping the tile?

## The block-mobility factor.
## The lower this attr is, the better the mobility
## Currently thinking a away that deduct the mobility from Troop's max movement points
## The wall and the abyss can have the infinite block_mobility
var block_mobility: int = 1

func _init(terrain_type: String, position: Vector2i):
	self.terrain_type = terrain_type
	self.position = position
	
