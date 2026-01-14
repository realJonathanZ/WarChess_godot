class_name MoveAndAttackSessionModel

var selected_troop:Troop
var move_path: Array[Vector2i] = []
var attackable_cells: Array[Vector2i] = []
var active: bool = false

signal move_path_changed(path) #changed so tell view to update path
signal attackables_changed(cells) #changed to tell view to update (possible highlight range)
signal session_started(troop) #changed to tell view: session started for A troop, start inserting plotting points in
signal session_ended(troop) #changed to tell view: sesssion ended for A troop, clean the evidence(drawing)

 
