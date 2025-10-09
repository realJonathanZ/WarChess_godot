## Troop.gd

extends Node

class_name Troop

## =======Properties===

## The customized/generated name of this troop. It is different from self.troop_type
var troop_name: String
var hp: int
var max_hp: int
var armor: int ## reduces dmg taken
## For each entry in this dict -> attacker_type: dmg_multiplier
var initial_dmg_resist: Dictionary = {}
var grid_position: Vector2i ##Grid coordinates, e.g., (x, y)
var troop_type: String ## e.g. "Tank" "Knight" "infantry" ...

## Optional but might needed.. who knows
## If needed, each entry -> {terrain_type, multiplier}
var terrian_resist: Dictionary = {}

## =======Mthods===
func _init(troop_name: String, max_hp: int, armor: int, 
	grid_position: Vector2i, troop_type: String, initial_dmg_resist: Dictionary) -> void:
		
	self.troop_name = troop_name
	self.max_hp = max_hp
	self.armor = armor
	self.grid_position = grid_position
	self.troop_type = troop_type
	self.initial_dmg_resist = initial_dmg_resist 

## calculate effective dmg based on armor and resistance
##
## @para dmg: the incoming damage before calculation
## @para attacker_type: will be examined whether it is a type in (dict) self.initial_dmg_resist
## @post-condition: THIS troop's hp is reduced, ground to zero
## @return: the weighted-computed damage that this unit is supposed to take 
func take_dmg(dmg: int, attacker_type: String) -> int:
	## initial dmg-multiplier: 1.0
	## change in some situations..
	var mltp = 1.0 ## short-hand for damage-multiplier
	if self.initial_dmg_resist.has(attacker_type):
		mltp = initial_dmg_resist[attacker_type] ## value obtained from KVpair
	var final_dmg = int(dmg * mltp) - armor
	final_dmg = max(final_dmg, 0) ##Normally it cannot be <0
	self.hp = self.hp - final_dmg
	return final_dmg	
	
func is_alive() -> bool:
	var do_alive = hp > 0
	return do_alive
	
