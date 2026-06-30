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

# --- REFERÊNCIAS DOS MENUS DE FIM DE JOGO ---
@onready var victory_menu: TextureRect = $VictoryMenu
@onready var defeat_menu: TextureRect = $DefeatMenu

@onready var victory_continue_btn: TextureButton = $VictoryMenu/ContinueButton
@onready var victory_exit_btn: TextureButton = $VictoryMenu/ExitButton

@onready var defeat_retry_btn: TextureButton = $DefeatMenu/RetryButton
@onready var defeat_exit_btn: TextureButton = $DefeatMenu/ExitButton

@onready var victory_pontos_label: Label = $VictoryMenu/Pontos
@onready var defeat_pontos_label: Label = $DefeatMenu/Pontos

@onready var sfx_ataque: AudioStreamPlayer2D = $SFXAtaque
@onready var sfx_dano: AudioStreamPlayer2D = $SFXDano
@onready var sfx_victory: AudioStreamPlayer2D = $SFXVictory
@onready var sfx_game_over: AudioStreamPlayer2D = $SFXGameOver
@onready var sfx_perfect: AudioStreamPlayer2D = $SFXPerfect


# --- SISTEMA DE PONTUAÇÃO ACUMULADA ---
var pontuacao_total: int = 0

# 1. ALTERAÇÃO: Vida inicial virou 10 (Nota máxima de avaliação)
var vida_jogador: int = 10
var nivel_atual: int = 1
var gm_atual: int = 10
var mao_atual: Array[Card] = []

enum Modo { NENHUM, ATAQUE, ADICAO, SUBTRACAO, MULTIPLICACAO, DIVISAO }
var modo_atual: Modo = Modo.NENHUM
var carta_selecionada: Card = null

func _ready() -> void:
	_conectar_botoes_ui()
	_conectar_botoes_menus() # Nova função de conexões
	
	# Garante que os menus começam invisíveis
	victory_menu.visible = false
	defeat_menu.visible = false
	
	_atualiza_vida()
	configurar_inimigos_do_combate(gm_atual)
	start_initial_combat()

func _conectar_botoes_ui() -> void:
	plus_button.pressed.connect(_on_plus_button_pressed)
	minus_button.pressed.connect(_on_minus_button_pressed)
	times_button.pressed.connect(_on_times_button_pressed)
	divide_button.pressed.connect(_on_divide_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)    
	
func _conectar_botoes_menus() -> void:
	victory_continue_btn.pressed.connect(_on_continue_button_pressed)
	victory_exit_btn.pressed.connect(_on_exit_button_pressed)
	defeat_retry_btn.pressed.connect(_on_retry_button_pressed)
	defeat_exit_btn.pressed.connect(_on_exit_button_pressed)

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
	_executar_turno_do_inimigo()

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
	nova_carta.clique.connect(_on_card_clicked)

func _atualiza_vida() -> void:
	if player_bar:
		player_bar.max_value = 10 # Teto máximo fixado em 10
		player_bar.value = vida_jogador
		label_player_bar.text = str(vida_jogador)

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
				Modo.ADICAO: ExecuteAddition(carta_selecionada, carta)
				Modo.SUBTRACAO: ExecuteSubtraction(carta_selecionada, carta)
				Modo.MULTIPLICACAO: ExecuteMultiplication(carta_selecionada, carta)
				Modo.DIVISAO: ExecuteDivision(carta_selecionada, carta)
			
			carta_selecionada = null
			modo_atual = Modo.NENHUM
			
func _on_enemy_clicked(inimigo: Enemy) -> void:
	if modo_atual == Modo.ATAQUE and carta_selecionada != null:
		var foi_perfect: bool = (carta_selecionada.val == inimigo.enemy_current_life)
		
		print("Sucesso! Descarregando ", carta_selecionada.val, " de dano em ", inimigo.name)
		
		if sfx_ataque:
			sfx_ataque.play()
		# --- MODIFICAÇÃO AQUI ---
		# Adicionamos 'await' para o combate congelar enquanto o monstro passa pela animação de dano ou morte
		await inimigo.tomar_dano(carta_selecionada.val)
		
		mao_atual.erase(carta_selecionada)
		carta_selecionada.queue_free()
		carta_selecionada = null
		modo_atual = Modo.NENHUM
		
		# Verifica se limpou a sala
		var sala_limpa = _checar_condicao_de_vitoria()
		if sala_limpa:
			return 
		
		if foi_perfect:
			print("✨ PERFECT! Inimigo eliminado no valor exato. Rodada do inimigo CANCELADA!")
			print("--- SEU TURNO ---")
			if sfx_perfect:
				sfx_perfect.play()
			for i in range(3):
				draw_card()
		else:
			await get_tree().create_timer(0.3).timeout
			_executar_turno_do_inimigo()
	else:
		print("Ação inválida. Garanta que clicou no botão de Ataque e escolheu uma carta antes.")

func _checar_condicao_de_vitoria() -> bool:
	if $Enemy1.enemy_current_life <= 0 and $Enemy2.enemy_current_life <= 0 and $Enemy3.enemy_current_life <= 0:
		print("\n🎉 VITÓRIA DO COMBATE!")
		if sfx_victory:
			sfx_victory.play()
		
		# 3. PONTUAÇÃO: Incrementa o valor da vida restante do jogador na pontuação total
		pontuacao_total += vida_jogador
		
		# Atualiza o texto da Label de pontos do menu de vitória e mostra o ecrã
		victory_pontos_label.text = "Pontos: " + str(pontuacao_total)
		victory_menu.visible = true
		
		return true
	return false


func ExecuteAddition(cardA: Card, cardB: Card) -> void:
	var result_value = cardA.val + cardB.val
	_substituir_cartas_na_mao(cardA, cardB, result_value)
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
		print("Operação inválida! A divisão não é exata.")
		
func _substituir_cartas_na_mao(cardA: Card, cardB: Card, novo_valor: int) -> void:
	mao_atual.erase(cardA)
	mao_atual.erase(cardB)
	cardA.queue_free()
	cardB.queue_free()
	
	var result_card = card_scene.instantiate() as Card
	result_card.val = novo_valor
	mao_jogador.add_child(result_card)
	mao_atual.append(result_card)
	result_card.clique.connect(_on_card_clicked)

# --- TURNO DO INIMIGO TOTALMENTE ASSEMBLEADO E SEQUENCIAL ---

func _executar_turno_do_inimigo() -> void:
	print("\n--- TURNO DO INIMIGO ---")
	var total_dano_recebido = 0
	
	# Passa por cada um dos 3 inimigos vivos para eles atacarem em fila
	for inimigo in [$Enemy1, $Enemy2, $Enemy3]:
		if inimigo and inimigo.enemy_current_life > 0:
			# 3. ANIMAÇÃO DE DANO RECEBIDO: Espera a investida física do monstro acabar por vez
			await inimigo.animar_ataque()
			
			# 1. ALTERAÇÃO: Cada sobrevivente causa exatamente 1 ponto estável de dano
			print(inimigo.name, " atacou e tirou 1 ponto da sua avaliação!")
			total_dano_recebido += 1
			if sfx_dano:
				sfx_dano.play()
				
	if total_dano_recebido > 0:
		vida_jogador -= total_dano_recebido
		if vida_jogador < 0:
			vida_jogador = 0
		_atualiza_vida()
		print("Dano recebido nesta rodada: ", total_dano_recebido, ". Avaliação Atual: ", vida_jogador, "/10")
		
		if vida_jogador <= 0:
			print("Game Over! Sua nota chegou a 0.")
			if sfx_game_over:
				sfx_game_over.play()
			# Exibe a pontuação final acumulada na Label do ecrã de derrota
			defeat_pontos_label.text = "Pontos: " + str(pontuacao_total)
			defeat_menu.visible = true
			return
			
	print("--- SEU TURNO ---")
	for i in range(3):
		draw_card()
		
		
# --- CALLBACKS DOS BOTÕES DOS MENUS (VITÓRIA / DERROTA) ---

func _on_continue_button_pressed() -> void:
	nivel_atual += 1
	
	# Validação do teto de níveis estabelecido no GDD
	if nivel_atual > 10:
		print("🏆 PARABÉNS! Completou o nível 10 e finalizou o Rogue Math!")
		get_tree().change_scene_to_file("res://PrimeiraCena.tscn")
		return
		
	victory_menu.visible = false
	
	# 1. ALTERAÇÃO: Novo combate com o valor de GM incrementado em 10% em relação ao anterior
	gm_atual = int(gm_atual * 1.20)
	print("Avançando para o Nível ", nivel_atual, ". Novo GM balanceado: ", gm_atual)
	
	# Limpa as cartas remanescentes da mão anterior
	_limpar_mao_jogador()
	
	# Reinicializa a sala de combate
	configurar_inimigos_do_combate(gm_atual)
	start_initial_combat()

func _on_retry_button_pressed() -> void:
	defeat_menu.visible = false
	
	# 2. ALTERAÇÃO: Reinicia o jogo com os valores iniciais padrão de fábrica
	nivel_atual = 1
	gm_atual = 10
	vida_jogador = 10
	pontuacao_total = 0 # Zera os pontos acumulados no Game Over
	
	_atualiza_vida()
	_limpar_mao_jogador()
	
	configurar_inimigos_do_combate(gm_atual)
	start_initial_combat()

func _on_exit_button_pressed() -> void:
	# Faz o jogador retornar ao menu principal (PrimeiraCena)
	get_tree().change_scene_to_file("res://PrimeiraCena.tscn")

# Função utilitária para limpar as cartas físicas e lógicas ao transicionar de estado
func _limpar_mao_jogador() -> void:
	for carta in mao_atual:
		if is_instance_valid(carta):
			carta.queue_free()
	mao_atual.clear()
