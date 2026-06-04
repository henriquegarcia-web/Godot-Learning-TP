extends Node

class_name PlayerStatusManager


# =============================================================================
# EXPORTS | STAMINA
# -----------------------------------------------------------------------------
# Controla o recurso usado para correr.
# =============================================================================

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var sprint_stamina_cost_per_second: float = 22.0
@export var stamina_regen_per_second: float = 18.0
@export var stamina_regen_delay: float = 5.0
@export var min_stamina_to_start_sprint: float = 5.0


# =============================================================================
# ESTADO INTERNO | STAMINA
# -----------------------------------------------------------------------------
# Guarda stamina atual e tempo desde o último gasto.
# =============================================================================

var current_stamina: float = 0.0
var time_since_last_stamina_spend: float = 0.0


# =============================================================================
# CICLO DE VIDA | INICIALIZAÇÃO
# -----------------------------------------------------------------------------
# Inicializa a stamina cheia.
# =============================================================================

func _ready() -> void:
	current_stamina = max_stamina
	time_since_last_stamina_spend = stamina_regen_delay


# =============================================================================
# LOOP | ATUALIZAÇÃO DE STATUS
# -----------------------------------------------------------------------------
# Recarrega stamina progressivamente após o delay configurado.
# =============================================================================

func update_status(delta: float) -> void:
	if current_stamina >= max_stamina:
		current_stamina = max_stamina
		return

	time_since_last_stamina_spend += delta

	if time_since_last_stamina_spend < stamina_regen_delay:
		return

	current_stamina += stamina_regen_per_second * delta
	current_stamina = clampf(current_stamina, 0.0, max_stamina)


# =============================================================================
# STAMINA | CONSUMO DE CORRIDA
# -----------------------------------------------------------------------------
# Consome stamina durante a corrida e reinicia o contador de recarga.
# =============================================================================

func consume_sprint_stamina(delta: float) -> bool:
	if current_stamina <= 0.0:
		current_stamina = 0.0
		return false

	current_stamina -= sprint_stamina_cost_per_second * delta
	current_stamina = clampf(current_stamina, 0.0, max_stamina)

	time_since_last_stamina_spend = 0.0

	return current_stamina > 0.0


# =============================================================================
# STAMINA | CONSULTORES
# -----------------------------------------------------------------------------
# Facilita a leitura da stamina por outros scripts.
# =============================================================================

func can_start_sprint() -> bool:
	return current_stamina >= min_stamina_to_start_sprint


func has_stamina() -> bool:
	return current_stamina > 0.0


func get_stamina_percent() -> float:
	if max_stamina <= 0.0:
		return 0.0

	return current_stamina / max_stamina
