## Troop.gd

extends Node2D

class_name Troop

## =======Properties===

## A signal for when the mouse clicks on this troop
signal troop_clicked(origin: Troop)
signal troop_hovered(origin: Troop)
signal troop_unhovered()

## Is it moved?
var moved: bool = false

##Note: suppose we have var current_turn_faction = Troop.factions.BLUE_TEAM
##this variable's datatype is int under the hood
enum factions {RED_TEAM, BLUE_TEAM} #List of factions, might change names later on.
var faction: factions #this troop's faction.

## The customized/generated name of this troop. It is different from self.troop_type
@export var troop_name: String
var hp: int
var max_hp: int
var mobility: int
var range_lower_bound : int
var range_upper_bound : int
var armor: int ## reduces dmg taken
## For each entry in this dict -> attacker_type: dmg_multiplier
var initial_dmg_resist: Dictionary = {}
var grid_position: Vector2i ##Grid coordinates, e.g., (x, y)
var troop_type: String ## e.g. "Tank" "Knight" "infantry" ...

## Optional but might needed.. who knows
## If needed, each entry -> {terrain_type, multiplier}
var terrian_resist: Dictionary = {}

func _ready():
	## When a troop is created..
	#print("a troop is spawn!")
	self._update_faction_color() # update the visual of the troop wrt to its faction
	
func _update_faction_color() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	match faction:
		factions.RED_TEAM:
			sprite.modulate = Color(1, 0.4, 0.4) # R big, G middle, B middle 
		factions.BLUE_TEAM:
			sprite.modulate = Color(0.4, 0.4, 1) # R middle, G middle, B big

## =======Mthods===
func _init(atroop_name: String = "", amax_hp: int = 0, amobility: int = 0, 
	arange_lower_bound: int = 0, arange_upper_bound: int = 0,
	aarmor: int = 0, agrid_position: Vector2i = Vector2.ZERO, 
	atroop_type: String = "", ainitial_dmg_resist: Dictionary = {}) -> void:
		
	self.troop_name = atroop_name
	self.max_hp = amax_hp
	self.mobility = amobility
	self.range_lower_bound = arange_lower_bound
	self.range_upper_bound = arange_upper_bound
	self.armor = aarmor
	self.grid_position = agrid_position
	self.troop_type = atroop_type
	self.initial_dmg_resist = ainitial_dmg_resist 



func set_data(atroop_name: String, amax_hp: int, amobility: int, 
	arange_lower_bound: int, arange_upper_bound: int, aarmor: int, 
	agrid_position: Vector2i, atroop_type: String, ainitial_dmg_resist: Dictionary) -> void:
		
	self.troop_name = atroop_name
	self.max_hp = amax_hp
	self.mobility = amobility
	self.range_lower_bound = arange_lower_bound
	self.range_upper_bound = arange_upper_bound
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
	#debug to show that damage happens
	rotation_degrees += 90
	
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
func _on_click_detection_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if self.moved:
			print("Hey, don't bother clicking on a troop that has already moved this turn!! Signal won't be emitted")
			return
		else:
			print("Signal emitted : _on_click_detection_input_event() for", troop_name)
			emit_signal("troop_clicked", self)


func _on_click_detection_mouse_entered() -> void:
	emit_signal("troop_hovered", self)


func _on_click_detection_mouse_exited() -> void:
	emit_signal("troop_unhovered")
