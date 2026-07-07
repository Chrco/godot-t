extends Node

var cycle := 1
var stage := 1
var world_time := 0.0

@export_group("Stages")
@export var stage1_duration := 10.0
@export var stage2_duration := 15.0
@export var stage3_duration := 20.0
var cycle_duration = stage1_duration + stage2_duration + stage3_duration

const MAPS = [
	preload("res://scenes/maps/map_1.tscn"),
	preload("res://scenes/maps/map_2.tscn")
   ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	world_time += delta
	
	if stage == 1 and world_time >= stage1_duration:
		stage = 2
	elif stage == 2 and world_time >= stage2_duration + stage1_duration:
		stage = 3
	elif stage == 3 and world_time >= stage3_duration + stage2_duration + stage1_duration:
		stage = 1
		world_time = 0.0
		cycle += 1 
		
