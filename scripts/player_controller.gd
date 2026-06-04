extends CharacterBody3D


# =============================================================================
# EXPORTS | MOVIMENTAÇÃO
# -----------------------------------------------------------------------------
# Define velocidades, aceleração, desaceleração e rotação do corpo visual.
# =============================================================================

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var stealth_speed: float = 2.5
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var rotation_speed: float = 12.0


# =============================================================================
# EXPORTS | PULO E GRAVIDADE
# -----------------------------------------------------------------------------
# Controla força do pulo e intensidade da gravidade aplicada ao player.
# =============================================================================

@export_group("Jump & Gravity")
@export var jump_velocity: float = 5.5
@export var gravity: float = 20.0


# =============================================================================
# REFERÊNCIAS DE NÓS
# -----------------------------------------------------------------------------
# Cache dos nós usados para modelo, câmera e StateMachine.
# =============================================================================

@onready var model_pivot: Node3D = $ModelPivot
@onready var camera_rig: Node3D = $CameraPivot
@onready var movement_state_machine: PlayerMovementStateMachine = $StateMachine


# =============================================================================
# ESTADO INTERNO | INPUT
# -----------------------------------------------------------------------------
# Guarda o input atual usado pelos estados de movimento.
# =============================================================================

var movement_input: Vector2 = Vector2.ZERO
var movement_direction: Vector3 = Vector3.ZERO

var is_jump_requested: bool = false
var is_sprint_pressed: bool = false
var is_stealth_pressed: bool = false


# =============================================================================
# LOOP FÍSICO | CONTROLE PRINCIPAL DO PLAYER
# -----------------------------------------------------------------------------
# Atualiza input, gravidade, estado atual e movimento final.
# =============================================================================

func _physics_process(delta: float) -> void:
	_update_movement_input()
	_apply_gravity(delta)
	movement_state_machine.physics_update(delta)
	move_and_slide()


# =============================================================================
# INPUT | LEITURA DO MOVIMENTO
# -----------------------------------------------------------------------------
# Lê movimento, sprint, stealth e calcula direção baseada na câmera.
# =============================================================================

func _update_movement_input() -> void:
	movement_input = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	is_jump_requested = Input.is_action_just_pressed("jump")
	is_sprint_pressed = Input.is_action_pressed("sprint")
	is_stealth_pressed = Input.is_action_pressed("stealth")

	movement_direction = Vector3.ZERO

	if movement_input.length() <= 0.0:
		return

	var camera_basis := camera_rig.global_transform.basis

	var forward := -camera_basis.z
	var right := camera_basis.x

	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	# Mantém a correção do W/S invertido.
	movement_direction = ((right * movement_input.x) + (forward * -movement_input.y)).normalized()


# =============================================================================
# FÍSICA | GRAVIDADE
# -----------------------------------------------------------------------------
# Aplica gravidade quando está no ar e estabiliza velocidade vertical no chão.
# =============================================================================

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1


# =============================================================================
# MOVIMENTO | APLICAÇÃO HORIZONTAL
# -----------------------------------------------------------------------------
# Aplica aceleração/desaceleração usando a direção e velocidade do estado atual.
# =============================================================================

func apply_horizontal_movement(target_speed: float, delta: float) -> void:
	var target_velocity := movement_direction * target_speed
	var current_horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

	var smooth_factor := acceleration

	if movement_direction == Vector3.ZERO:
		smooth_factor = deceleration

	current_horizontal_velocity = current_horizontal_velocity.move_toward(
		target_velocity,
		smooth_factor * delta
	)

	velocity.x = current_horizontal_velocity.x
	velocity.z = current_horizontal_velocity.z

	if movement_direction != Vector3.ZERO:
		_rotate_model_towards(movement_direction, delta)


# =============================================================================
# CONSULTORES | INPUT
# -----------------------------------------------------------------------------
# Facilita a leitura dos estados sem repetir regras.
# =============================================================================

func has_movement_input() -> bool:
	return movement_direction != Vector3.ZERO


func should_jump() -> bool:
	return is_jump_requested and is_on_floor()


# =============================================================================
# MODELO | ROTAÇÃO VISUAL DO PERSONAGEM
# -----------------------------------------------------------------------------
# Gira apenas o ModelPivot para alinhar o corpo visual à direção de movimento.
# =============================================================================

func _rotate_model_towards(direction: Vector3, delta: float) -> void:
	# Mantém a correção do corpo visual invertido.
	var target_angle := atan2(-direction.x, -direction.z)

	model_pivot.rotation.y = lerp_angle(
		model_pivot.rotation.y,
		target_angle,
		rotation_speed * delta
	)
