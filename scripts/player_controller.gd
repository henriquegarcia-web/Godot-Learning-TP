extends CharacterBody3D

# =============================================================================
# EXPORTS | MOVIMENTAÇÃO
# -----------------------------------------------------------------------------
# Define velocidades, aceleração, desaceleração e rotação do corpo visual.
# =============================================================================

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
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
# Cache dos nós usados para girar o modelo e orientar movimento pela câmera.
# =============================================================================

@onready var model_pivot: Node3D = $ModelPivot
@onready var camera_rig: Node3D = $CameraPivot

# =============================================================================
# LOOP FÍSICO | CONTROLE PRINCIPAL DO PLAYER
# -----------------------------------------------------------------------------
# Atualiza gravidade, pulo, movimento e aplica move_and_slide.
# =============================================================================

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	move_and_slide()

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
# FÍSICA | PULO
# -----------------------------------------------------------------------------
# Aplica velocidade vertical quando a ação de pulo é pressionada no chão.
# =============================================================================

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# =============================================================================
# MOVIMENTO | DIREÇÃO, VELOCIDADE E ACELERAÇÃO
# -----------------------------------------------------------------------------
# Lê input, calcula direção baseada na câmera, aplica aceleração/desaceleração
# e gira o modelo visual na direção do movimento.
# =============================================================================

func _handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var direction := Vector3.ZERO

	if input_vector.length() > 0.0:
		var camera_basis := camera_rig.global_transform.basis

		var forward := -camera_basis.z
		var right := camera_basis.x

		forward.y = 0.0
		right.y = 0.0

		forward = forward.normalized()
		right = right.normalized()

		# Mantém a correção do W/S invertido.
		direction = ((right * input_vector.x) + (forward * -input_vector.y)).normalized()

	var target_speed := walk_speed

	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed

	var target_velocity := direction * target_speed
	var current_horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

	var smooth_factor := acceleration

	if direction == Vector3.ZERO:
		smooth_factor = deceleration

	current_horizontal_velocity = current_horizontal_velocity.move_toward(
		target_velocity,
		smooth_factor * delta
	)

	velocity.x = current_horizontal_velocity.x
	velocity.z = current_horizontal_velocity.z

	if direction != Vector3.ZERO:
		_rotate_model_towards(direction, delta)

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
