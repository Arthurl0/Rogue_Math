extends Sprite2D
class_name Enemy

@onready var life_bar: TextureProgressBar = $LifeBar
@onready var text_bar: Label = $LifeBar/TextBar

signal selecionado(inimigo: Enemy)

var enemy_total_life: int = 10
var enemy_current_life: int = 10

func _ready():
	_atualiza_vida_inimigo()

func inicializar_inimigo(gm_valor: int) -> void:
	enemy_total_life = (gm_valor * randi_range(5, 15)) / 10
	enemy_current_life = enemy_total_life
	_atualiza_vida_inimigo()
	show() # Garante que reapareça no próximo nível

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
		# CRÍTICO: Colocamos o await aqui para que a morte segure a execução do código
		await derrotado()
	else:
		_animar_receber_dano()
		

# --- SISTEMA DE ANIMAÇÕES VIA TWEEN (GODOT 4) ---

func _animar_receber_dano() -> void:
	# Pisca a cor do Sprite para vermelho e volta ao normal
	var tween_cor = create_tween()
	modulate = Color(1, 0.2, 0.2) # Vermelho vivo
	tween_cor.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	
	# Treme horizontalmente (efeito de impacto)
	var tween_shake = create_tween()
	var pos_original = position
	tween_shake.tween_property(self, "position", pos_original + Vector2(10, 0), 0.05)
	tween_shake.tween_property(self, "position", pos_original - Vector2(10, 0), 0.05)
	tween_shake.tween_property(self, "position", pos_original, 0.05)

func animar_ataque() -> void:
	# 3. ANIMAÇÃO DE DANO RECEBIDO: Inimigo dá um "tranco" para frente e volta
	var tween = create_tween()
	var pos_original = position
	
	# Avança rápido para frente (simulando uma investida)
	tween.tween_property(self, "position", pos_original + Vector2(0, 30), 0.1)
	# Volta lentamente para a posição original
	tween.tween_property(self, "position", pos_original, 0.15)
	
	# Espera o movimento físico terminar antes de liberar o código do combate
	await tween.finished

func animar_derrota() -> void:
	# Reseta a cor para o flash branco iluminado que você configurou
	modulate = Color(1.353, 1.353, 1.353, 1.0)
	
	var tween = create_tween()
	# .set_parallel(true) faz com que o movimento e o sumiço aconteçam ao mesmo tempo!
	tween.set_parallel(true)
	
	var pos_original = position
	
	# 1. Movimento de queda: Dá uma subidinha rápida e depois desmorona para baixo
	tween.tween_property(self, "position", pos_original + Vector2(0, 60), 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	# 2. Desaparecimento: Vai diminuindo a opacidade (Alpha) até o zero (totalmente transparente)
	# Mantemos o brilho que você colocou (1.353), mas zeramos o último número (Alpha)
	tween.tween_property(self, "modulate", Color(1.353, 1.353, 1.353, 0.0), 0.5)
	
	# Espera o movimento físico e o sumiço terminarem
	await tween.finished

func derrotado() -> void:
	print(name, " foi derrotado!")
	await animar_derrota()
	hide() 

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(get_local_mouse_position()):
			selecionado.emit(self)
			get_viewport().set_input_as_handled()
