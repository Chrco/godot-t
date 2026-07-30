extends CharacterBody3D

@export_group("movement")
@export var speed := 1.0
@export var tilt :=  0.0
@export var tilt_velocity := 0.0
@export var gravity := 50.0
@export var knockback := Vector3.ZERO
var movement_velocity := Vector3.ZERO
var knockback_velocity := Vector3.ZERO

@export_group("metadata")
@export var NPC_name := "Eldridge"
@export var maxHP := 130
@export var HP := 130
@export var InteractionNo = 0
@export var TaskNo = 0
@export var Location := "base"

@onready var dialogue = $DialogueData
@onready var UI_anchor = %UIanchor
@onready var Pickup_prompt = %PickupPrompt.get_node("Label3D")
@onready var navigation_agent: NavigationAgent3D = %NavigationAgent3D
@onready var Sprite: AnimatedSprite3D = %AnimatedSprite3D
@onready var Detection_area: Area3D = %DetectionRange

func _ready() -> void:
	# Connect the signal via code to a local function
	print(name, " NPC_name =", NPC_name)
	Detection_area.body_entered.connect(_on_detection_area_body_entered)
	Detection_area.body_exited.connect(_on_detection_area_body_exited)

var nearby_player = []
var nearby_NPCs = []
var player_in_range := false
var carried_by = null
var interaction_target = null

func _on_detection_area_body_entered(body):
	if body.is_in_group("NPC") and body != self:
		nearby_NPCs.append(body)
	elif body.is_in_group("Player"):
		nearby_player.append(body)
func _on_detection_area_body_exited(body):
	if body.is_in_group("NPC"):
		nearby_NPCs.erase(body)
	elif body.is_in_group("Player"):
		nearby_player.erase(body)



enum STATE {IDLE, WALKING, INTERACTION, SOCIALIZING, FALLEN, CARRIED}
var state = STATE.IDLE
var idle_timer = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("q"):
		if !nearby_player.is_empty() and state != STATE.CARRIED:
			start_carry(_get_closest_entity())
		elif state == STATE.CARRIED:
			stop_carry()

#func _unhandled_input(event: InputEvent) -> void:

func _physics_process(delta: float) -> void: #auto, every physics frame 
	#delta = 1/fps
	player_in_range = !nearby_player.is_empty()

	if Pickup_prompt:
		Pickup_prompt.visible = player_in_range and state != STATE.CARRIED
	
	match state:
		STATE.IDLE:
			animation()
			movement_velocity = Vector3.ZERO
			var closest_entity = _get_closest_entity()
			if closest_entity:
				face_target(closest_entity.global_position,delta)
			idle_timer -= delta
			if idle_timer <= 0:
				state = STATE.WALKING
				navigation_agent.target_position = get_random_target()
				
			
		STATE.WALKING:
			animation()
			if navigation_agent.is_navigation_finished():
				state = STATE.IDLE
				idle_timer = randf_range(2.0, 8.0)
				velocity = Vector3.ZERO
				return
				
			var next_position = navigation_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			
			if direction.length() > 0.1:
				var target_rotation = atan2(-direction.x, -direction.z)
				rotation.y = lerp_angle(rotation.y, target_rotation, delta*5.0)
			movement_velocity.x = direction.x * speed
			movement_velocity.z = direction.z * speed
			
			
		STATE.FALLEN:
			movement_velocity = Vector3.ZERO
			
		STATE.CARRIED:
			animation()
			movement_velocity = Vector3.ZERO
			velocity = Vector3.ZERO
			return
			
		STATE.INTERACTION:
			animation()

			movement_velocity = Vector3.ZERO
			velocity = Vector3.ZERO

			if interaction_target:
				face_target(interaction_target.global_position, delta)

			
	velocity = movement_velocity + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 1.0* delta)
	
	if state != STATE.CARRIED:
		if !is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
	else:
		velocity.y = 0.0

	#velocity.y = vertical_velocity
	
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		
		if state == STATE.CARRIED and collision.get_collider() == carried_by:
			continue
		if collision.get_collider() is CharacterBody3D:
			#add pushback physics
			var dir = (global_position - collision.get_collider().global_position).normalized()
			dir.y = 0.0
			
			knockback_velocity += dir * 2.0
			var collider = collision.get_collider()

			if collider.has_method("apply_knockback"):
				collider.apply_knockback(-dir * 0.5)
			
			var impact_speed = collision.get_collider().velocity.length()
			if impact_speed > 7.0 and state != STATE.FALLEN and state != STATE.CARRIED:
				fall()
	
			
func get_random_target():
	var points = get_tree().get_nodes_in_group("Base_pos")
	var target_point = points.pick_random()
	return target_point.global_position

func animation():
	var animation_name
	match state:
		STATE.IDLE:
			animation_name = NPC_name + " idle"
		STATE.WALKING:
			animation_name = NPC_name + " walk"
		STATE.CARRIED:
			animation_name = NPC_name + " fallen"
		STATE.FALLEN:
			animation_name = NPC_name + " fallen"
		STATE.INTERACTION:
			animation_name = NPC_name + " idle"
			
	Sprite.play(animation_name)
			
func fall():
	if state == STATE.FALLEN:
		return

	state = STATE.FALLEN
	velocity = Vector3.ZERO
	animation()
	if state != STATE.CARRIED:
		stand_up()

func _get_closest_entity(): #pioritize playere
	var closest_entity = null
	var closest_dist = INF
	
	if !nearby_player.is_empty():
		for player in nearby_player:
			var dist = global_position.distance_squared_to(player.global_position)
			if dist< closest_dist:
				closest_entity = player
				closest_dist = dist 
	else:
		for NPC in nearby_NPCs:
			var dist = global_position.distance_squared_to(NPC.global_position)
			if dist< closest_dist:
				closest_entity = NPC
				closest_dist = dist 
	
	print(closest_entity)
	return closest_entity
		
func stand_up():
	await get_tree().create_timer(2.5).timeout 
	var animation_name = NPC_name + " angry"
	Sprite.play(animation_name)
	await get_tree().create_timer(1.0).timeout 
	state = STATE.IDLE
	
func face_target(target_pos: Vector3, delta: float) -> void:
	var dir = target_pos - global_position
	dir.y = 0.0
	
	if dir.length() < 0.01:
		return
	
	var target_rot = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_rot - 90.0, 10.0 * delta)

func start_carry(player):
	state = STATE.CARRIED
	Detection_area.monitoring = false
	carried_by = player
	velocity = Vector3.ZERO
	movement_velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO

	navigation_agent.target_position = global_position

	# attach to player CarryPoint
	var carry_point = player.get_node("CarryPoint")

	reparent(carry_point)
	global_position = carry_point.global_position

	
	
func stop_carry():
	var world = get_tree().current_scene

	reparent(world, true)
	Detection_area.monitoring = true

	global_position = carried_by.global_position \
		- carried_by.global_basis.z * 1.0 \
		+ Vector3.UP * 1

	velocity = carried_by.velocity
	movement_velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO

	carried_by = null
	state = STATE.IDLE


func start_interaction(player):
	interaction_target = player
	state = STATE.INTERACTION

	velocity = Vector3.ZERO
	movement_velocity = Vector3.ZERO
	navigation_agent.target_position = global_position
	
func stop_interaction():
	interaction_target = null

	state = STATE.IDLE
	idle_timer = randf_range(2.0, 5.0)
