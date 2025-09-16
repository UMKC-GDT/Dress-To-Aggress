extends Node
class_name ConsoleScenarioApp

@onready var generator := ScenarioGenerator.new()

@export var output_field_path: NodePath
@onready var output_field: RichTextLabel = get_node(output_field_path) as RichTextLabel

func _ready() -> void:
	add_child(generator)
	var message = ""
	message += "---------------------------------------------------"
	message += "\nDress to Aggress - Scenario Console"
	message += "\nPress SPACE to generate a scenario."
	message += "\nPress Q to quit."
	message += "\n---------------------------------------------------\n"
	output_field.text = message

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_print_new()
			KEY_Q:
				get_tree().quit()

func _print_new() -> void:
	var card := generator.generate()
	var message = ""
	message += "\n"
	message += "\n========== NEW SCENARIO ==========\n"
	message += card.summary()
	message += "\n=================================="
	output_field.text = message
