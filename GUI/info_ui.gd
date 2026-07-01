extends Control

@onready var name_label : Label = %Name
@onready var hp_bar : ProgressBar = %HP

var NPC 
var cam : Camera3D

func setup(target_npc, camera):
	NPC = target_npc
	cam = camera
	print("setup")
	print(NPC)
	print(NPC.NPC_name)
	print(name_label)
	
	name_label.text = NPC.NPC_name
	hp_bar.max_value = NPC.maxHP

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if NPC == null:
		queue_free()
		return
	
	var world_pos = NPC.UI_anchor.global_position
	var screen_pos = cam.unproject_position(world_pos)
	
	visible = (cam.global_position.distance_squared_to(world_pos) <= 10 and !cam.is_position_behind(world_pos))
	position = screen_pos
	
	hp_bar.value = NPC.HP
	
