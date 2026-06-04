extends Node

class_name PlayerMovementState


# =============================================================================
# REFERÊNCIAS | PLAYER E STATE MACHINE
# -----------------------------------------------------------------------------
# Guarda acesso ao player e à máquina de estados.
# =============================================================================

var player: CharacterBody3D
var state_machine: PlayerMovementStateMachine


# =============================================================================
# SETUP | INICIALIZAÇÃO DO ESTADO
# -----------------------------------------------------------------------------
# Recebe as referências principais usadas pelos estados.
# =============================================================================

func setup(
	target_player: CharacterBody3D,
	target_state_machine: PlayerMovementStateMachine
) -> void:
	player = target_player
	state_machine = target_state_machine


# =============================================================================
# STATE | ENTRADA
# -----------------------------------------------------------------------------
# Executado uma vez ao entrar no estado.
# =============================================================================

func enter() -> void:
	pass


# =============================================================================
# STATE | SAÍDA
# -----------------------------------------------------------------------------
# Executado uma vez ao sair do estado.
# =============================================================================

func exit() -> void:
	pass


# =============================================================================
# STATE | LOOP FÍSICO
# -----------------------------------------------------------------------------
# Executado a cada physics frame enquanto o estado estiver ativo.
# =============================================================================

func physics_update(_delta: float) -> void:
	pass
