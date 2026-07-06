extends Node2D

@onready var start_button: Button = $UI/StartButton
@onready var exit_button: Button = $UI/ExitButton
@export_file("*.tscn") var next_scene_path: String = "res://Combat.tscn"
@onready var como_jogar: Button = $UI/ComoJogar
@onready var sair_como_jogar: Button = $UI/JanelaInstrucoes/SairComoJogar
@onready var janela_instrucoes: TextureRect = $UI/JanelaInstrucoes


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	como_jogar.pressed.connect(_on_tutorial_button_pressed)
	sair_como_jogar.pressed.connect(_on_close_tutorial_pressed)
	janela_instrucoes.visible = false
	
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://Combat.tscn")
	
func _on_exit_button_pressed():
	get_tree().quit()

func _on_tutorial_button_pressed() -> void:
	janela_instrucoes.visible = true
	
	var scroll_container = janela_instrucoes.get_node("ScrollContainer") as ScrollContainer
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _on_close_tutorial_pressed() -> void:
	janela_instrucoes.visible = false
