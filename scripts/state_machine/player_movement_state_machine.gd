extends Node

class_name PlayerMovementStateMachine


# =============================================================================
# EXPORTS | ESTADO INICIAL
# -----------------------------------------------------------------------------
# Define o estado inicial usado quando o jogo começa.
# =============================================================================

@export var initial_state_name: StringName = &"Idle"


# =============================================================================
# SINAIS | MUDANÇA DE ESTADO
# -----------------------------------------------------------------------------
# Emitido sempre que o player troca de estado.
# =============================================================================

signal state_changed(previous_state_name: StringName, current_state_name: StringName)


# =============================================================================
# REFERÊNCIAS | PLAYER
# -----------------------------------------------------------------------------
# Guarda a referência do player dono da StateMachine.
# =============================================================================

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D


# =============================================================================
# ESTADO INTERNO | STATES
# -----------------------------------------------------------------------------
# Guarda os estados disponíveis e o estado atual.
# =============================================================================

var states: Dictionary = {}
var current_state: PlayerMovementState = null
var current_state_name: StringName = &""
var previous_state_name: StringName = &""


# =============================================================================
# CICLO DE VIDA | INICIALIZAÇÃO
# -----------------------------------------------------------------------------
# Registra os estados filhos e ativa o estado inicial.
# =============================================================================

func _ready() -> void:
	_register_states()
	change_state(initial_state_name)


# =============================================================================
# SETUP | REGISTRO DOS ESTADOS
# -----------------------------------------------------------------------------
# Busca todos os filhos que herdam de PlayerMovementState.
# =============================================================================

func _register_states() -> void:
	for child in get_children():
		if child is PlayerMovementState:
			states[child.name] = child
			child.setup(player, self)


# =============================================================================
# LOOP FÍSICO | ESTADO ATUAL
# -----------------------------------------------------------------------------
# Atualiza somente o estado ativo.
# =============================================================================

func physics_update(delta: float) -> void:
	if current_state == null:
		return

	current_state.physics_update(delta)


# =============================================================================
# STATE MACHINE | TROCA DE ESTADO
# -----------------------------------------------------------------------------
# Sai do estado atual e entra no próximo estado solicitado.
# =============================================================================

func change_state(next_state_name: StringName) -> void:
	if not states.has(next_state_name):
		push_warning("Estado não encontrado: " + str(next_state_name))
		return

	if current_state_name == next_state_name:
		return

	if current_state != null:
		current_state.exit()

	previous_state_name = current_state_name
	current_state_name = next_state_name
	current_state = states[next_state_name]

	current_state.enter()
	state_changed.emit(previous_state_name, current_state_name)


# =============================================================================
# CONSULTORES | ESTADO ATUAL
# -----------------------------------------------------------------------------
# Facilita a leitura do estado por câmera, animações e outros sistemas.
# =============================================================================

func is_current_state(state_name: StringName) -> bool:
	return current_state_name == state_name


func is_idle() -> bool:
	return is_current_state(&"Idle")


func is_walking() -> bool:
	return is_current_state(&"Walk")


func is_sprinting() -> bool:
	return is_current_state(&"Sprint")


func is_stealthing() -> bool:
	return is_current_state(&"Stealth")


func is_jumping() -> bool:
	return is_current_state(&"Jump")


func is_falling() -> bool:
	return is_current_state(&"Fall")


func get_state_name() -> StringName:
	return current_state_name
