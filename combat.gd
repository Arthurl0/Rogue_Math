extends Node2D

@export var card_scene: PackedScene
@onready var mao_jogador: HBoxContainer = $MaoJogador
@onready var player_bar: TextureProgressBar = $PlayerBar
@onready var label_player_bar: Label = $PlayerBar/LabelPlayerBar

@onready var plus_button: TextureButton = $PlusButton
@onready var times_button: TextureButton = $TimesButton
@onready var divide_button: TextureButton = $DivideButton
@onready var minus_button: TextureButton = $MinusButton
@onready var attack_button: TextureButton = $AttackButton
@onready var skip_button: TextureButton = $SkipButton

var vida_jogador: int = 100
var mao_atual: Array[Card] = []

enum Modo { NENHUM, ATAQUE, ADICAO, SUBTRACAO, MULTIPLICACAO, DIVISAO }
var modo_atual: Modo = Modo.NENHUM
var carta_selecionada: Card = null

func _ready() -> void:
	_conectar_botoes_ui() # CORREÇÃO 1: Ativa os botões logo no início
	_atualiza_vida()
	configurar_inimigos_do_combate(10)
	start_initial_combat()

func _conectar_botoes_ui() -> void:
	plus_button.pressed.connect(_on_plus_button_pressed)
	minus_button.pressed.connect(_on_minus_button_pressed)
	times_button.pressed.connect(_on_times_button_pressed)
	divide_button.pressed.connect(_on_divide_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)    

func _on_plus_button_pressed() -> void:
	modo_atual = Modo.ADICAO
	carta_selecionada = null
	print("Modo ativo: ADIÇÃO (+). Escolha duas cartas para somar.")

func _on_minus_button_pressed() -> void:
	modo_atual = Modo.SUBTRACAO
	carta_selecionada = null
	print("Modo ativo: SUBTRAÇÃO (-). Escolha duas cartas (Maior - Menor).")

func _on_times_button_pressed() -> void:
	modo_atual = Modo.MULTIPLICACAO
	carta_selecionada = null
	print("Modo ativo: MULTIPLICAÇÃO (×). Escolha duas cartas para multiplicar.")

func _on_divide_button_pressed() -> void:
	modo_atual = Modo.DIVISAO
	carta_selecionada = null
	print("Modo ativo: DIVISÃO (÷). Escolha duas cartas (Maior ÷ Menor Exato).")

func _on_attack_button_pressed() -> void:
	modo_atual = Modo.ATAQUE
	carta_selecionada = null
	print("Modo ativo: ATAQUE ⚔️. Escolha uma carta da mão e depois o inimigo alvo.")

func _on_skip_button_pressed() -> void:
	modo_atual = Modo.NENHUM
	carta_selecionada = null
	print("Jogador escolheu PULAR A RODADA 🛡️.")
	_executar_turno_do_inimigo() # Ativa o contra-ataque

func start_initial_combat() -> void:
	for i in range(5):
		draw_card()

func draw_card() -> void:
	if mao_atual.size() >= 5:
		return
		
	var nova_carta = card_scene.instantiate() as Card
	nova_carta.val = randi_range(1, 9)
	mao_jogador.add_child(nova_carta)
	mao_atual.append(nova_carta)
	
	# CORREÇÃO 2: Escuta o sinal 'clique' do seu card.gd
	nova_carta.clique.connect(_on_card_clicked)

func _atualiza_vida() -> void:
	if player_bar:
		player_bar.value = vida_jogador
		label_player_bar.text = str(vida_jogador) + "%"

func configurar_inimigos_do_combate(gm_atual: int) -> void:
	for inimigo in [$Enemy1, $Enemy2, $Enemy3]:
		if inimigo:
			inimigo.inicializar_inimigo(gm_atual)
			if not inimigo.selecionado.is_connected(_on_enemy_clicked):
				inimigo.selecionado.connect(_on_enemy_clicked)

func _on_card_clicked(carta: Card) -> void:
	if modo_atual == Modo.NENHUM:
		print("Por favor, selecione uma ação nos botões primeiro.")
		return
		
	if modo_atual == Modo.ATAQUE:
		carta_selecionada = carta
		print("Carta [", carta.val, "] selecionada para ataque! Clique no inimigo alvo.")
		
	elif modo_atual in [Modo.ADICAO, Modo.SUBTRACAO, Modo.MULTIPLICACAO, Modo.DIVISAO]:
		if carta_selecionada == null:
			carta_selecionada = carta
			print("Primeira carta selecionada: [", carta.val, "]. Escolha a segunda.")
		elif carta_selecionada != carta:
			match modo_atual:
				Modo.ADICAO:
					ExecuteAddition(carta_selecionada, carta)
				Modo.SUBTRACAO:
					ExecuteSubtraction(carta_selecionada, carta)
				Modo.MULTIPLICACAO:
					ExecuteMultiplication(carta_selecionada, carta)
				Modo.DIVISAO:
					ExecuteDivision(carta_selecionada, carta)
			
			carta_selecionada = null
			modo_atual = Modo.NENHUM
			
func _on_enemy_clicked(inimigo: Enemy) -> void:
	if modo_atual == Modo.ATAQUE and carta_selecionada != null:
		# CORREÇÃO 3: Mudado de .current_health para .enemy_current_life
		if carta_selecionada.val <= inimigo.enemy_current_life:
			print("Sucesso! Descarregando ", carta_selecionada.val, " de dano em ", inimigo.name)
			
			inimigo.tomar_dano(carta_selecionada.val)
			
			mao_atual.erase(carta_selecionada)
			carta_selecionada.queue_free()
			carta_selecionada = null
			modo_atual = Modo.NENHUM
			
			# O ataque bem-sucedido passa o turno para os monstros sobreviventes
			_executar_turno_do_inimigo()
		else:
			print("Ataque Bloqueado! O valor da carta é maior que a vida restante do inimigo.")
	else:
		print("Ação inválida. Garanta que clicou no botão de Ataque e escolheu uma carta antes.")

func ExecuteAddition(cardA: Card, cardB: Card) -> void:
	var result_value = cardA.val + cardB.val
	
	mao_atual.erase(cardA)
	mao_atual.erase(cardB)
	cardA.queue_free()
	cardB.queue_free()
	
	var result_card = card_scene.instantiate() as Card
	result_card.val = result_value
	
	mao_jogador.add_child(result_card)
	mao_atual.append(result_card)
	
	# CORREÇÃO 4: Atualizado de .clicada para .clique
	result_card.clique.connect(_on_card_clicked)
	print("Fusão concluída! Cartas geraram a carta [", result_value, "]")

func ExecuteSubtraction(cardA: Card, cardB: Card) -> void:
	if cardA.val == cardB.val:
		print("Operação inválida! É proibido gerar o número 0 no combate.")
		return
		
	var maior = max(cardA.val, cardB.val)
	var menor = min(cardA.val, cardB.val)
	var result_value = maior - menor
	
	_substituir_cartas_na_mao(cardA, cardB, result_value)
	
func ExecuteMultiplication(cardA: Card, cardB: Card) -> void:
	var result_value = cardA.val * cardB.val
	_substituir_cartas_na_mao(cardA, cardB, result_value)
	
func ExecuteDivision(cardA: Card, cardB: Card) -> void:
	var maior = max(cardA.val, cardB.val)
	var menor = min(cardA.val, cardB.val)
	
	if maior % menor == 0:
		var result_value = maior / menor
		_substituir_cartas_na_mao(cardA, cardB, result_value)
	else:
		print("Operação inválida! A divisão entre ", maior, " e ", menor, " não é exata.")
		
func _substituir_cartas_na_mao(cardA: Card, cardB: Card, novo_valor: int) -> void:
	mao_atual.erase(cardA)
	mao_atual.erase(cardB)
	cardA.queue_free()
	cardB.queue_free()
	
	var result_card = card_scene.instantiate() as Card
	result_card.val = novo_valor
	mao_jogador.add_child(result_card)
	mao_atual.append(result_card)
	
	# CORREÇÃO 4: Atualizado de .clicada para .clique
	result_card.clique.connect(_on_card_clicked)
	print("Fusão concluída! Nova carta gerada: [", novo_valor, "]")
	
func _executar_turno_do_inimigo() -> void:
	print("\n--- TURNO DO INIMIGO ---")
	
	var total_dano_recebido = 0
	
	# Passa por cada um dos 3 inimigos vivos para calcular o dano acumulado
	for inimigo in [$Enemy1, $Enemy2, $Enemy3]:
		if inimigo and inimigo.enemy_current_life > 0:
			var dano_causado = inimigo.calcular_dano_para_o_jogador()
			if dano_causado > 0:
				print(inimigo.name, " atacou e gerou ", dano_causado, "% de dano potencial!")
				total_dano_recebido += dano_causado
				
	# Aplica o dano total acumulado ao jogador de uma vez só
	if total_dano_recebido > 0:
		vida_jogador -= total_dano_recebido
		if vida_jogador < 0:
			vida_jogador = 0
		_atualiza_vida()
		print("Você recebeu um total de ", total_dano_recebido, "% de dano. Vida atual: ", vida_jogador, "%")
		
		if vida_jogador <= 0:
			print("Game Over! O jogador foi derrotado.")
			return # Aqui futuramente você chamará a tela de derrota
			
	print("--- SEU TURNO ---")
	# Compra até 3 cartas para a nova rodada respeitando o limite de 5 da mão
	for i in range(3):
		draw_card()
