extends CharacterBody3D

#dont set a shape for the springarm it will ignore collisions

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
var _camera_input_direction := Vector2.ZERO
@export var _target_zoom := 5.0
@export var _first_person := true

@export_group("Movement")
@export var move_speed := 10.0
@export var acceleration := 20.0
@export var rotation_speed := 15.0
@export var jump_strength := 6.0
@export var gravity := 9.8
var external_force := Vector3.ZERO

func apply_knockback(force: Vector3) -> void:
	external_force += force

@onready var _camera_pivot_tp: Node3D = %CameraPivot_TP
@onready var _camera_pivot_fp: Node3D = %CameraPivot_FP

@onready var _player_cam_tp: Camera3D = %PlayerCam_TP
@onready var _player_cam_fp: Camera3D = %PlayerCam_FP

var _camera_pivot: Node3D
var _player_cam: Camera3D

@onready var _player_skin:CSGCombiner3D = %PlayerSkin
@onready var _player_collision:CollisionShape3D  = %PlayerCollision
@onready var _spring_arm:SpringArm3D = %SpringArm
@onready var _detection_area:Area3D = %DetectionRange
@onready var dialogue_ui = get_tree().current_scene.get_node("GUIs/DialogueUI")

@export_group("UI")
@export var info_ui : PackedScene
var aim_timer := 0.0
@export var aim_delay := 0.15
var nearby_NPCs = []
var aimed_target = null
var closest_entity = null
var current_target = null
var current_ui = null
var in_dialogue = false
	
func _on_detection_area_body_entered(body):
	if body.is_in_group("NPC"):
		nearby_NPCs.append(body)
func _on_detection_area_body_exited(body):
	if body.is_in_group("NPC"):
		nearby_NPCs.erase(body)
		
func _on_dialogue_started():
	in_dialogue = true
	if current_target:
		current_target.start_interaction(self)
func _on_dialogue_ended():
	in_dialogue = false
	if current_target:
		current_target.stop_interaction()

func _ready() -> void:
	_player_skin.visible = false
	_camera_pivot = _camera_pivot_fp
	_player_cam = _player_cam_fp

	_player_cam_fp.current = true
	_player_cam_tp.current = false
	
	dialogue_ui.dialogue_start.connect(_on_dialogue_started)
	dialogue_ui.dialogue_ended.connect(_on_dialogue_ended)

func _input(event: InputEvent) -> void: #auto, runs after every input 
	if event.is_action_pressed("right_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED #cursor hidden + locked 
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE #normal 
		
	if event.is_action_pressed("x"):
		if current_target and current_ui:
			dialogue_ui.start_dialogue(current_target)
			current_target.start_interaction(self)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		
	if event.is_action_pressed("v"):
		_first_person = !_first_person
		if _first_person:
			_player_skin.visible = false
			_camera_pivot = _camera_pivot_fp
			_player_cam = _player_cam_fp
			
			_player_cam_fp.current = true
			_player_cam_tp.current = false
		else:
			_player_skin.visible = true
			_camera_pivot = _camera_pivot_tp
			_player_cam = _player_cam_tp
			
			_player_cam_fp.current = false
			_player_cam_tp.current = true
			
	

func _unhandled_input(event: InputEvent) -> void: #auto, process input after normal UI
	if in_dialogue == true:
		return
	var is_camera_motion := ( #ingame and mouse move
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	var is_zoom := (
		event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion: 
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		
	if is_zoom:
		if !_first_person:
			if event.is_action_pressed("middle_scroll_down"):
				_target_zoom -= 0.5
			elif event.is_action_pressed("middle_scroll_up"):
				_target_zoom += 0.5
		
func _physics_process(delta:float) -> void: #auto, every physics frame 
	#delta = 1/fps
	
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI/6.0, PI/2.0)
	
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	
	_camera_input_direction = Vector2.ZERO
	
	
	var raw_input := Input.get_vector("a", "d", "w", "s")
	var right := _player_cam.global_basis.z
	var forward := _player_cam.global_basis.x
	
	var move_direction := forward * raw_input.x + right *raw_input.y
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity - gravity * delta
	
	var start_jump := Input.is_action_just_pressed("space") and is_on_floor()
	if start_jump:
		velocity.y += jump_strength
		#_player_skin.jump()
	elif not is_on_floor and velocity.y < 0:
		pass
		#_player_skin.fall()
	
	move_and_slide()
	
	if move_direction.length() >= 0.2:
		var _last_direction = move_direction
		var target_angle := Vector3.RIGHT.signed_angle_to(_last_direction, Vector3.UP)
		_player_skin.global_rotation.y = lerp_angle(_player_skin.rotation.y, target_angle, rotation_speed * delta)
		_player_collision.global_rotation.y = lerp_angle(_player_collision.rotation.y, target_angle, rotation_speed * delta)
		
	var _current_speed := velocity.length()
	if _current_speed > 5.0 :
		_player_cam.fov = lerp(_player_cam.fov, 100.0, 5.0*delta)
		#_player_skin.move()
	elif _current_speed > 0.0 and _current_speed <= 5.0:
		_player_cam.fov = lerp(_player_cam.fov, 95.0, 5.0*delta)
		#_player_skin.move()
	else:
		_player_cam.fov = lerp(_player_cam.fov, 90.0, 5.0*delta)
		#_player_skin.idel()
		
	if !_first_person:
		_spring_arm.spring_length = lerp(
			_spring_arm.spring_length,
			_target_zoom,
			5.0 * delta
		)
		_spring_arm.spring_length = clamp(_spring_arm.spring_length, 1.0, 8.0)
	
	velocity += external_force
	external_force = external_force.move_toward(Vector3.ZERO, 1.0 * delta)

func _process(delta: float) -> void:
	var new_target = _get_crosshair_target()

	if new_target == current_target:
		aim_timer = 0.0
		return

	if new_target != current_target:
		aim_timer += delta

		if aim_timer < aim_delay:
			return

		aim_timer = 0.0
		current_target = new_target

		if current_ui:
			current_ui.queue_free()
			current_ui = null

		if current_target:
			current_ui = info_ui.instantiate()
			get_tree().current_scene.add_child(current_ui)
			current_ui.setup(current_target, _player_cam)

func _get_crosshair_target():
	var crosshair = get_viewport().get_visible_rect().size / 2
	
	#var best_npc = null
	#var best_score = 0.9  # aim tolerance (closer to 1 = stricter)

	#for npc in nearby_NPCs:
	#	if npc == null:
	#		continue

	#	var dir = (npc.global_position - _player_cam.global_position).normalized()
	#	var dot = (-_player_cam.global_basis.z).dot(dir)

		# only consider NPCs roughly in front of camera
	#	if dot > best_score:
	#		best_score = dot
	#		best_npc = npc

	#return best_npc
	var ray_origin = _player_cam.project_ray_origin(crosshair)
	var ray_direction = _player_cam.project_ray_normal(crosshair)
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction*20)
	query.exclude = [self]
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	
	if result.is_empty():
		return null
	var node = result.collider

	while node:
		if node.is_in_group("NPC"):
			return node
		node = node.get_parent()

	return null

func _get_closest_entity():
	var closest_entity = null
	var closest_dist = INF
	
	for NPC in nearby_NPCs:
		var dist = global_position.distance_squared_to(NPC.global_position)
		if dist< closest_dist:
			closest_entity = NPC
			closest_dist = dist 
	
	return closest_entity
	
