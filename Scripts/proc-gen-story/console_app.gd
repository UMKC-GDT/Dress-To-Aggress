extends Node
class_name ConsoleScenarioApp

@onready var generator := ScenarioGenerator.new()

func _ready() -> void:
	add_child(generator)
	print("-----------------------------------------")
	print("Dress to Aggress — Scenario Console")
	print("Press SPACE to generate a scenario.")
	print("Press Q to quit.")
	print("-----------------------------------------")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_print_new()
			KEY_Q:
				get_tree().quit()

func _print_new() -> void:
	var card := generator.generate()
	print("")
	print("=== NEW SCENARIO ===")
	print(card.summary())
	print("====================")
