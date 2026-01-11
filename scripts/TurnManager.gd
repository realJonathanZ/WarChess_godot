## TurnManager.gd

## For now, it tries to establish turn changing logic only between 2 players

extends Node

class_name TurnManager

## The signals denoting the start of end of one turn.
## The signals might be passed to TileMapLayer and the MoveAndAttackSession some time in process
signal turn_started(faction)
signal turn_ended(faction)

## NOTE: original testing enum in TileMapManager.gd is moved here
## We let this script determine the logic relevant to turns,
## and let the other scripts/nodes get notified about the turn change from a turn manager reference that is built in,
## theoretically

enum TurnFaction {
	RED_TEAM,
	BLUE_TEAM
}

# hard coded first turn to BLUE_TEAM
var current_faction: TurnFaction = TurnFaction.BLUE_TEAM
var turn_count: int = 1 # The first turn

func start_game(starting_faction: TurnFaction = TurnFaction.BLUE_TEAM):
	current_faction = starting_faction
	turn_count = 1
	emit_signal("turn_started", current_faction)
	
func end_turn():
	emit_signal("turn_ended", current_faction)
	_turn_plus_plus()
	
func _turn_plus_plus():
	if current_faction == TurnFaction.BLUE_TEAM:
		current_faction = TurnFaction.RED_TEAM
	elif current_faction == TurnFaction.RED_TEAM:
		current_faction = TurnFaction.BLUE_TEAM
	else:
		print("Error: something went wrong in TurnManager.gd -> _advance_turn()")
		
	turn_count += 1
	emit_signal("turn_started", current_faction)
