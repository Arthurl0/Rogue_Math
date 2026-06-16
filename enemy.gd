extends Sprite2D
class_name Enemy
@onready var life_bar: TextureProgressBar = $LifeBar
@onready var text_bar: Label = $LifeBar/TextBar

signal selecionado(inimigo: Enemy)

var enemy_total_life:int = randi_range(5, 15)
var enemy_current_life:int = enemy_total_life

# Called when the node enters the scene tree for the first time.
func _ready():
	_atualiza_vida_inimigo()
	
	
func inicializar_inimigo(gm_valor: int) -> void:
	enemy_total_life = (gm_valor * randi_range(10, 15)) / 10
	enemy_current_life = enemy_total_life
	_atualiza_vida_inimigo()

func _atualiza_vida_inimigo():
	if life_bar:
		life_bar.max_value = enemy_total_life
		life_bar.value = enemy_current_life
		text_bar.text = str(enemy_current_life)
		
func tomar_dano(quantidade: int) -> void:
	enemy_current_life -= quantidade
	if enemy_current_life < 0:
		enemy_current_life = 0
		
	_atualiza_vida_inimigo()
	
	if enemy_current_life <= 0:
		derrotado()
		
func calcular_dano_para_o_jogador() -> int:
	if enemy_current_life <= 0:
		return 0
		
	var fracao = (enemy_current_life * 5) / enemy_total_life
	var porcentagem_dano = 5 + fracao
	
	return porcentagem_dano

func derrotado() -> void:
	print(name, " foi derrotado!")
	hide() 

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(get_local_mouse_position()):
			selecionado.emit(self)
			get_viewport().set_input_as_handled()
