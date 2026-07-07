extends Control

@onready var NPCportrait : TextureRect = %NPCportrait
@onready var NPCname : Label = %NPCname
@onready var DialogueText : RichTextLabel = %DialogueText
@onready var ChoiceContainer : VBoxContainer = %ChoiceContainer
@onready var Audio_player : AudioStreamPlayer = %AudioStreamPlayer
@onready var AutoToggle : TextureButton = %Autoplay

signal dialogue_start
signal dialogue_ended

var current_npc
var dialogue_data
var current_dialogue
var choice_result
var typing_sound : AudioStream

var AutoMode := true
var IsTyping := false
var SkipTyping := false 
var WaitingForInput := false 
var BlinkTime := 0.0
var CursorVisible := true
var BlinkText := ""


func _on_auto_toggled(toggled_on: bool):
	AutoMode = toggled_on 
	print("AutoMode", AutoMode)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AutoToggle.toggle_mode = true
	AutoToggle.toggled.connect(_on_auto_toggled)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		if IsTyping:
			SkipTyping = true 
		elif WaitingForInput:
			WaitingForInput = false
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !IsTyping:
		BlinkTime += delta

		if BlinkTime >= 0.5:
			BlinkTime = 0.0
			CursorVisible = !CursorVisible
		DialogueText.text = BlinkText + ("▼" if CursorVisible else "")
	
func start_dialogue(npc):
	print("1 start_dialogue")
	dialogue_start.emit()
	DialogueText.clear()
	ChoiceContainer.hide()
	current_npc = npc 
	dialogue_data = npc.get_node("DialogueData")
	
	visible = true
	print("visible ", visible)
	NPCname.text = npc.NPC_name
	
	print("calling r")
	await dialogue_data.run(self)
	end_dialogue()
	
func speak(dialogue : String, portrait : Texture2D, wait_time := 0.0) -> void:
	IsTyping = true
	WaitingForInput = false
	BlinkText = ""
	NPCportrait.texture = portrait
	var DisplayedText := ""
	DialogueText.text = ""
	
	for i in dialogue:
		if SkipTyping:
			DialogueText.text = dialogue
			DisplayedText = dialogue
			IsTyping = false 
			SkipTyping = false
			break
			
		DisplayedText += i 
		DialogueText.text = DisplayedText + "▼"
			
		if typing_sound:
			play_sound(typing_sound)
		await get_tree().create_timer(0.05).timeout
	
	IsTyping = false
	BlinkText = DisplayedText
	DialogueText.text = BlinkText + "▼"
	CursorVisible = true
	BlinkTime = 0.0
	
	if AutoMode == true:
		if wait_time > 0:
			await get_tree().create_timer(wait_time).timeout
			
	else:
		WaitingForInput = true
		while WaitingForInput:
			await get_tree().process_frame
	
			

func show_choices(choice_array):
	choice_result = ""
	ChoiceContainer.show()
	
	for child in ChoiceContainer.get_children():
		child.queue_free()
	
	for option in choice_array:
		var button := Button.new()
		button.text = option
		button.pressed.connect(on_choice_pressed.bind(option))
		ChoiceContainer.add_child(button)

	while choice_result == "":
		await get_tree().process_frame

	ChoiceContainer.hide()

	return choice_result
	
func on_choice_pressed(choice:String):
	if choice_result != "":
		return
	choice_result = choice

func play_sound(sound:AudioStream):
	Audio_player.stop()
	Audio_player.stream = sound
	Audio_player.play()
	
func end_dialogue():
	DialogueText.clear()
	NPCportrait.texture = null
	for child in ChoiceContainer.get_children():
		child.queue_free()
	hide()
	dialogue_ended.emit()
