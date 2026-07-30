extends Node

@onready var base_map = %base
@onready var map_container = %CurrentMap
@onready var player = %Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_random_map():
	unload_map()
		
	var scene = WorldManager.current_map_scene
	var map = scene.instantiate()
	var map_name = ""

	map_container.add_child(map)

	WorldManager.current_map = map
	map_name = str(map.name)
	for npc in NPCManager.get_npcs_for_location(map_name):
		map.add_child(npc)
	
	player.global_position = map.get_node("SpawnPoint").global_position
	
func return_to_base():
	player.global_position = base_map.get_node("SpawnPoint").global_position
	unload_map()
	
func unload_map():
	for child in map_container.get_children():
		child.queue_free()
