extends Area3D


@export var go_to_outside := true
var player_inside := false

func _on_body_entered(body):
	print("in teleporter")
	if body.is_in_group("Player"):
		player_inside = true
		

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_inside = false
		print("out of teleporter")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !player_inside:
		return
		
	if !Input.is_action_just_pressed("e"):
		return
		
	if go_to_outside:
		if WorldManager.stage != 2:
			return
		get_tree().current_scene.load_random_map()

	else:
		get_tree().current_scene.return_to_base()
