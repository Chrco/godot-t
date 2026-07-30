extends Node

const NPC_SCENES = {
	"Eldridge": preload("res://scenes/npc01.tscn"),
	"Atticus": preload("res://scenes/npc02.tscn"),
}
var npc_locations = {
	"Eldridge": "base",
	"Atticus": "map_1"
}
var base_npcs = [
	"Eld"
]
var dead_npcs = [
	
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_npcs_for_location(location):
	var npc_list = []
	for npc in npc_locations:
		if npc_locations[npc] == location:
			npc_list.append(NPC_SCENES[npc])
			
	return npc_list
