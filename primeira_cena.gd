extends Node2D

@onready var start_button: Button = $UI/StartButton
@onready var exit_button: Button = $UI/ExitButton
@export_file("*.tscn") var next_scene_path: String = "res://Combat.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://Combat.tscn")
	
func _on_exit_button_pressed():
	get_tree().quit()
