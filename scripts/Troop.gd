## Troop.gd

extends Node2D

class_name Troop

## =======Properties===

## A signal for when the mouse clicks on this troop
signal troop_clicked(origin: Troop)

## Is it moved?
var moved: bool = false


## The customized/generated name of this troop. It is different from self.troop_type
@export var troop_name: String
var hp: int
var max_hp: int
#NOTE: added mobility value
var mobility: int

var armor: int ## reduces dmg taken
## For each entry in this dict -> attacker_type: dmg_multiplier
var initial_dmg_resist: Dictionary = {}
var grid_position: Vector2i ##Grid coordinates, e.g., (x, y)
var troop_type: String ## e.g. "Tank" "Knight" "infantry" ...

## Optional but might needed.. who knows
## If needed, each entry -> {terrain_type, multiplier}
var terrian_resist: Dictionary = {}

## =======Mthods===
func _init(atroop_name: String = "", amax_hp: int = 0, amobility: int = 0, aarmor: int = 0, 
	agrid_position: Vector2i = Vector2.ZERO, atroop_type: String = "", ainitial_dmg_resist: Dictionary = {}) -> void:
		
	self.troop_name = atroop_name
	self.max_hp = amax_hp
	self.mobility = amobility
	self.armor = aarmor
	self.grid_position = agrid_position
	self.troop_type = atroop_type
	self.initial_dmg_resist = ainitial_dmg_resist 


func set_data(atroop_name: String, amax_hp: int, amobility: int, aarmor: int, 
	agrid_position: Vector2i, atroop_type: String, ainitial_dmg_resist: Dictionary) -> void:
		
	self.troop_name = atroop_name
	self.max_hp = amax_hp
	self.mobility = amobility
	self.armor = aarmor
	self.grid_position = agrid_position
	self.troop_type = atroop_type
	self.initial_dmg_resist = ainitial_dmg_resist 


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


#emitted when any input happens with the mouse clicking inside the troop's area2D
func _on_click_detection_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if self.moved:
		print("Hey, don't bother clicking on a troop that has already moved this turn!! Signal of clicking won't be emitted")
		return ## Nah, no signal is omitted, since it is a moved troop.
		## Moving the same unit twice in a round is cheating!!
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			print("Signal ommited : _on_click_detection_input_event()")
			#emit the "troop_clicked" signal with origin = self
			emit_signal("troop_clicked", self)
