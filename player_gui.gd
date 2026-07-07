extends CanvasLayer

@onready var StageTimer = %StageTimer
@onready var CycleLabel = %CycleLabel

var StageTimer_fill

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	StageTimer_fill = StageTimer.get_theme_stylebox("fill").duplicate()

	print(StageTimer_fill)
	print(StageTimer_fill.get_class())
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(WorldManager.stage)
	StageTimer.max_value = WorldManager.cycle_duration
	StageTimer.value = WorldManager.world_time

	CycleLabel.text = "Cycle %d" % WorldManager.cycle
	
	match WorldManager.stage:
		1:
			StageTimer_fill.bg_color = Color("318000")
		2:
			StageTimer_fill.bg_color = Color("4d8be7")
		3:
			StageTimer_fill.bg_color = Color("cf502b")
			
	StageTimer.add_theme_stylebox_override("fill", StageTimer_fill)
