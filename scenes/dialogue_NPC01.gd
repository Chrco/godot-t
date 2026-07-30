extends Node

@export var InteractionNo := 1
@export var playerchoice := ""

@export var portrait_expressionless : Texture2D
@export var portrait_hello : Texture2D
@export var portrait_disappointed : Texture2D
@export var portrait_happy : Texture2D

@export var audio_typing : AudioStream
@export var audio_load_gun : AudioStream
@export var audio_gunshot : AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func run(dialogue_manager):
	match InteractionNo:
		1:
			await dialogue_manager.speak(
			"Hello.", portrait_hello, 2
			)
			await dialogue_manager.speak(
				"Do you have a problem?", portrait_expressionless, 1
			)

			playerchoice = await dialogue_manager.show_choices([
				"Knock knock",
				"You are the youngest NPC EVER! again"
			])
			
			if playerchoice == "Knock knock":
				await dialogue_manager.speak(
					"No solicitors.", portrait_expressionless, 2
				)
			elif playerchoice == "You are the youngest NPC EVER! again":
				await dialogue_manager.speak(
					"hm", portrait_expressionless, 1
				)
				await dialogue_manager.speak(
					"They really should tax you for existing.", portrait_expressionless, 2
				)
				
			InteractionNo += 1
			
		2:
			await dialogue_manager.speak(
				"Yes?", portrait_expressionless, 1
			)
			dialogue_manager.play_sound(audio_load_gun)
			playerchoice = await dialogue_manager.show_choices([
				"i havent coded your gun yet"
			])
			if playerchoice == "i havent coded your gun yet":
				await dialogue_manager.speak(
					"what a shame.", portrait_disappointed, 2
				)
			playerchoice = await dialogue_manager.show_choices([
				"were you looking foward to shooting me??!",
				"tsk.. i'll do it later"
			])
			if playerchoice == "were you looking foward to shooting me??!":
				await dialogue_manager.speak(
					"...", portrait_expressionless, 2
				)
				await dialogue_manager.speak(
					"if not apparent enough.", portrait_happy, 2
				)
			elif playerchoice == "tsk.. i'll do it later":
				await dialogue_manager.speak(
					"please do.", portrait_expressionless, 1
				)
				
			InteractionNo += 1
			
			
		3:
			await dialogue_manager.speak(
				"where did the other guy go?", portrait_expressionless, 1
			)
			playerchoice = await dialogue_manager.show_choices([
				"eh i havent coded him yet",
				"just mitisos yourself",
				"publicly executed"
			])
			if playerchoice == "eh i havent coded him yet":
				await dialogue_manager.speak(
					"...", portrait_expressionless, 2
				)
				await dialogue_manager.speak(
					"really do wish there's someone other than you here", portrait_disappointed, 3
				)
			elif playerchoice == "just mitisos yourself":
				await dialogue_manager.speak(
					"the gun would be really useful now.", portrait_expressionless, 1
				)
			elif playerchoice == "publicly executed":
				await dialogue_manager.speak(
					"...", portrait_expressionless, 2
				)
				await dialogue_manager.speak(
					"okay", portrait_expressionless, 1
				)
			InteractionNo += 1
		
		4:
			await dialogue_manager.speak(
				"...", portrait_expressionless, 2
			)

			
		
