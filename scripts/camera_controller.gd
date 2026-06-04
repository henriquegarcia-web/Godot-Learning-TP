extends Node3D

# =============================================================================
# EXPORTS | CONFIGURAÇÕES DE ROTAÇÃO DA CÂMERA
# -----------------------------------------------------------------------------
# Controla sensibilidade do mouse e limites verticais da câmera.
# =============================================================================

@export_group("Camera Rotation")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = deg_to_rad(-45.0)
@export var max_pitch: float = deg_to_rad(65.0)

# =============================================================================
# EXPORTS | POSIÇÃO E COLISÃO DA CÂMERA
# -----------------------------------------------------------------------------
# Define distância, altura, raio de colisão e máscara física usada para impedir
# que a câmera atravesse paredes ou objetos do cenário.
# =============================================================================

@export_group("Camera Position")
@export var camera_distance: float = 4.0
@export var camera_height_offset: float = 0.0
@export var camera_min_distance: float = 0.45
@export var camera_collision_radius: float = 0.25
@export var camera_collision_margin: float = 0.08
@export var camera_collision_smooth_speed: float = 20.0
@export_flags_3d_physics var camera_collision_mask: int = 1

# =============================================================================
# EXPORTS | ZOOM DA CÂMERA
# -----------------------------------------------------------------------------
# Controla o zoom manual, com foco maior parado/stealth e menor ao andar.
# =============================================================================

@export_group("Camera Zoom")
@export var zoom_enabled: bool = true
@export var zoom_focus_distance: float = 3.25
@export var zoom_walk_distance: float = 3.75
@export var zoom_fov: float = 55.0
@export var normal_fov: float = 70.0
@export var zoom_speed: float = 12.0

# =============================================================================
# EXPORTS | DISTANCIAMENTO DA CÂMERA AO CORRER
# -----------------------------------------------------------------------------
# Ao correr, a câmera se afasta e aumenta o FOV para sensação de velocidade.
# =============================================================================

@export_group("Camera Sprint Distance")
@export var sprint_camera_enabled: bool = true
@export var sprint_camera_distance: float = 4
@export var sprint_camera_fov: float = 80.0
@export var sprint_camera_speed: float = 10.0

# Velocidade horizontal mínima para considerar que o player está realmente se movendo.
# Evita aplicar o efeito de corrida quando o botão sprint é pressionado parado.
@export var sprint_camera_min_movement_speed: float = 0.15

# =============================================================================
# EXPORTS | OMBRO DA CÂMERA
# -----------------------------------------------------------------------------
# Permite alternar a câmera entre o lado esquerdo e direito do personagem.
# =============================================================================

@export_group("Camera Shoulder")
@export var shoulder_offset: float = 0.6
@export var shoulder_change_speed: float = 8.0

# =============================================================================
# EXPORTS | VISIBILIDADE DO MODELO AO TOCAR A CÂMERA
# -----------------------------------------------------------------------------
# Oculta o ModelPivot quando a câmera encosta no volume aproximado do corpo.
# =============================================================================

@export_group("Player Visibility On Camera Touch")
@export var hide_model_when_camera_touches: bool = true

# Volume da câmera usado para detectar toque no corpo.
@export var camera_visibility_radius: float = 0.04

# Volume aproximado do corpo visual do player.
@export var model_touch_capsule_radius: float = 0.35
@export var model_touch_capsule_height: float = 1.7
@export var model_touch_capsule_offset: Vector3 = Vector3.ZERO

# 0.0 = só some quando realmente toca.
@export var model_touch_enter_margin: float = 0.0

# Evita flicker quando a câmera fica bem no limite.
@export var model_touch_exit_margin: float = 0.06

# =============================================================================
# REFERÊNCIAS DE NÓS
# -----------------------------------------------------------------------------
# Cache dos nós principais da hierarquia do player, câmera e StateMachine.
# =============================================================================

@onready var player_body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var model_pivot: Node3D = $"../ModelPivot"
@onready var movement_state_machine: PlayerMovementStateMachine = get_node_or_null("../StateMachine") as PlayerMovementStateMachine

@onready var camera_pitch: Node3D = $CameraPitch
@onready var camera_holder: Node3D = $CameraPitch/CameraHolder
@onready var camera: Camera3D = $CameraPitch/CameraHolder/Camera3D

# =============================================================================
# ESTADO INTERNO | INPUT E MOVIMENTO DA CÂMERA
# -----------------------------------------------------------------------------
# Guarda valores temporários usados para rotação, ombro, colisão e zoom.
# =============================================================================

var camera_input: Vector2 = Vector2.ZERO

var target_shoulder_offset: float = 0.0
var current_shoulder_offset: float = 0.0

var current_camera_local_position: Vector3 = Vector3.ZERO
var camera_collision_shape: SphereShape3D

var is_model_hidden_by_camera: bool = false
var is_zooming: bool = false
var current_camera_distance: float = 0.0

# =============================================================================
# CICLO DE VIDA | INICIALIZAÇÃO
# -----------------------------------------------------------------------------
# Configura mouse, câmera principal, colisão manual e valores iniciais.
# =============================================================================

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

	_setup_manual_camera_collision()

	target_shoulder_offset = shoulder_offset
	current_shoulder_offset = shoulder_offset

	current_camera_distance = camera_distance

	current_camera_local_position = Vector3(
		current_shoulder_offset,
		camera_height_offset,
		current_camera_distance
	)

	camera_holder.position = current_camera_local_position
	camera.fov = normal_fov

# =============================================================================
# SETUP | COLISÃO MANUAL DA CÂMERA
# -----------------------------------------------------------------------------
# Prepara o volume esférico usado no cast_motion para colisão da câmera.
# =============================================================================

func _setup_manual_camera_collision() -> void:
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	camera.near = 0.03

	camera_collision_shape = SphereShape3D.new()
	camera_collision_shape.radius = camera_collision_radius

# =============================================================================
# INPUT | EVENTOS DO MOUSE E AÇÕES DA CÂMERA
# -----------------------------------------------------------------------------
# Captura movimento do mouse, troca de ombro, zoom e toggle do mouse.
# =============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_input = event.relative

	if event.is_action_pressed("camera_left"):
		_set_camera_shoulder(-1.0)

	if event.is_action_pressed("camera_right"):
		_set_camera_shoulder(1.0)

	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()

# =============================================================================
# LOOP | ATUALIZAÇÃO DA CÂMERA
# -----------------------------------------------------------------------------
# Atualiza rotação, zoom/sprint, ombro, colisão e visibilidade do modelo.
# =============================================================================

func _process(delta: float) -> void:
	is_zooming = Input.is_action_pressed("aim")

	_update_camera_rotation(delta)
	_update_camera_distance_effects(delta)
	_update_camera_shoulder(delta)
	_update_camera_collision(delta)
	_update_model_visibility_from_camera_touch()

# =============================================================================
# CÂMERA | ROTAÇÃO
# -----------------------------------------------------------------------------
# Aplica rotação horizontal no rig e rotação vertical no CameraPitch.
# =============================================================================

func _update_camera_rotation(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		camera_input = Vector2.ZERO
		return

	rotate_y(-camera_input.x * mouse_sensitivity)

	camera_pitch.rotation.x -= camera_input.y * mouse_sensitivity
	camera_pitch.rotation.x = clamp(
		camera_pitch.rotation.x,
		min_pitch,
		max_pitch
	)

	camera_input = Vector2.ZERO

# =============================================================================
# CÂMERA | EFEITOS DE DISTÂNCIA E FOV
# -----------------------------------------------------------------------------
# Controla zoom manual e afastamento com FOV ao correr.
#
# Prioridade:
# 1. Sprint altera distância e FOV.
# 2. Zoom funciona em idle, walk e stealth.
# 3. Estado normal.
# =============================================================================

func _update_camera_distance_effects(delta: float) -> void:
	var target_distance: float = camera_distance
	var target_fov: float = normal_fov
	var target_speed: float = zoom_speed

	if sprint_camera_enabled and _is_player_actually_sprinting():
		target_distance = sprint_camera_distance
		target_fov = sprint_camera_fov
		target_speed = sprint_camera_speed
	elif zoom_enabled and is_zooming:
		target_distance = _get_zoom_target_distance()
		target_fov = zoom_fov
		target_speed = zoom_speed

	var weight: float = _get_smooth_weight(target_speed, delta)

	current_camera_distance = lerp(
		current_camera_distance,
		target_distance,
		weight
	)

	camera.fov = lerp(
		camera.fov,
		target_fov,
		weight
	)

# =============================================================================
# CÂMERA | DISTÂNCIA DO ZOOM POR ESTADO
# -----------------------------------------------------------------------------
# Define o nível de foco do zoom com base no estado atual do player.
# =============================================================================

func _get_zoom_target_distance() -> float:
	if movement_state_machine == null:
		return zoom_focus_distance

	if movement_state_machine.is_idle():
		return zoom_focus_distance

	if movement_state_machine.is_stealthing():
		return zoom_focus_distance

	if movement_state_machine.is_aim_idle():
		return zoom_focus_distance

	if movement_state_machine.is_aim_stealthing():
		return zoom_focus_distance

	if movement_state_machine.is_walking():
		return zoom_walk_distance

	if movement_state_machine.is_aim_walking():
		return zoom_walk_distance

	return zoom_focus_distance

# =============================================================================
# CÂMERA | DETECÇÃO DE CORRIDA REAL
# -----------------------------------------------------------------------------
# Consulta a StateMachine para bloquear zoom e aplicar afastamento de sprint.
# =============================================================================

func _is_player_actually_sprinting() -> bool:
	if movement_state_machine == null:
		return false

	return movement_state_machine.is_sprinting() \
		or movement_state_machine.is_sprint_jumping() \
		or movement_state_machine.is_sprint_falling()

# =============================================================================
# CÂMERA | OMBRO
# -----------------------------------------------------------------------------
# Suaviza a transição lateral da câmera entre esquerda e direita.
# =============================================================================

func _update_camera_shoulder(delta: float) -> void:
	var weight: float = _get_smooth_weight(shoulder_change_speed, delta)

	current_shoulder_offset = lerp(
		current_shoulder_offset,
		target_shoulder_offset,
		weight
	)

# =============================================================================
# CÂMERA | COLISÃO COM CENÁRIO
# -----------------------------------------------------------------------------
# Usa cast_motion com uma esfera para corrigir a posição da câmera antes que ela
# atravesse paredes, objetos ou geometrias físicas.
# =============================================================================

func _update_camera_collision(delta: float) -> void:
	var origin_global: Vector3 = camera_pitch.global_position

	var desired_local_position: Vector3 = Vector3(
		current_shoulder_offset,
		camera_height_offset,
		current_camera_distance
	)

	var desired_global_position: Vector3 = camera_pitch.global_transform * desired_local_position
	var camera_motion: Vector3 = desired_global_position - origin_global

	var corrected_local_position: Vector3 = desired_local_position

	if camera_motion.length() > 0.001:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = camera_collision_shape
		query.transform = Transform3D(Basis.IDENTITY, origin_global)
		query.motion = camera_motion
		query.collision_mask = camera_collision_mask
		query.collide_with_bodies = true
		query.collide_with_areas = false

		if player_body != null:
			query.exclude = [player_body.get_rid()]

		var space_state := get_world_3d().direct_space_state
		var result := space_state.cast_motion(query)

		var safe_fraction: float = 1.0

		if result.size() > 0:
			safe_fraction = result[0]

		var safe_distance: float = camera_motion.length() * safe_fraction
		safe_distance -= camera_collision_margin

		safe_distance = clamp(
			safe_distance,
			camera_min_distance,
			camera_motion.length()
		)

		var corrected_global_position: Vector3 = origin_global + camera_motion.normalized() * safe_distance
		corrected_local_position = camera_pitch.to_local(corrected_global_position)

	var weight: float = _get_smooth_weight(camera_collision_smooth_speed, delta)

	current_camera_local_position = current_camera_local_position.lerp(
		corrected_local_position,
		weight
	)

	camera_holder.position = current_camera_local_position

# =============================================================================
# VISIBILIDADE | MODELO DO PLAYER
# -----------------------------------------------------------------------------
# Oculta ou exibe o ModelPivot dependendo do toque entre câmera e corpo visual.
# =============================================================================

func _update_model_visibility_from_camera_touch() -> void:
	if not hide_model_when_camera_touches:
		_set_model_pivot_visible(true)
		is_model_hidden_by_camera = false
		return

	var camera_touches_model: bool = _is_camera_touching_model_pivot()

	if camera_touches_model and not is_model_hidden_by_camera:
		is_model_hidden_by_camera = true
		_set_model_pivot_visible(false)

	if not camera_touches_model and is_model_hidden_by_camera:
		is_model_hidden_by_camera = false
		_set_model_pivot_visible(true)

# =============================================================================
# VISIBILIDADE | TESTE DE TOQUE ENTRE CÂMERA E MODELO
# -----------------------------------------------------------------------------
# Aproxima o corpo visual como uma cápsula e testa se algum ponto da câmera
# entrou no volume de contato.
# =============================================================================

func _is_camera_touching_model_pivot() -> bool:
	var capsule_radius: float = maxf(model_touch_capsule_radius, 0.01)
	var capsule_height: float = maxf(model_touch_capsule_height, capsule_radius * 2.0)

	var bottom_local: Vector3 = model_touch_capsule_offset + Vector3(
		0.0,
		capsule_radius,
		0.0
	)

	var top_local: Vector3 = model_touch_capsule_offset + Vector3(
		0.0,
		capsule_height - capsule_radius,
		0.0
	)

	var bottom_global: Vector3 = model_pivot.global_transform * bottom_local
	var top_global: Vector3 = model_pivot.global_transform * top_local

	var threshold: float = capsule_radius + camera_visibility_radius + model_touch_enter_margin

	if is_model_hidden_by_camera:
		threshold += model_touch_exit_margin

	var camera_points: Array[Vector3] = _get_camera_touch_points()

	for point in camera_points:
		var closest_point: Vector3 = _closest_point_on_segment(
			point,
			bottom_global,
			top_global
		)

		var distance_to_capsule_axis: float = point.distance_to(closest_point)

		if distance_to_capsule_axis <= threshold:
			return true

	return false

# =============================================================================
# VISIBILIDADE | PONTOS DE CONTATO DA CÂMERA
# -----------------------------------------------------------------------------
# Retorna a posição da câmera e pontos frontais auxiliares para detectar contato
# mesmo quando o near clipping já está atravessando o modelo.
# =============================================================================

func _get_camera_touch_points() -> Array[Vector3]:
	var points: Array[Vector3] = []

	var camera_position: Vector3 = camera.global_position
	var camera_forward: Vector3 = -camera.global_transform.basis.z.normalized()

	points.append(camera_position)

	# Ponto logo à frente da câmera.
	# Ajuda quando o near clipping já está atravessando o modelo,
	# mas a origem da câmera ainda não entrou totalmente no corpo.
	points.append(camera_position + camera_forward * 0.12)

	# Ponto um pouco mais à frente.
	# Útil quando a câmera está muito próxima e olhando de cima/baixo.
	points.append(camera_position + camera_forward * 0.25)

	return points

# =============================================================================
# GEOMETRIA | PONTO MAIS PRÓXIMO EM SEGMENTO
# -----------------------------------------------------------------------------
# Calcula o ponto mais próximo dentro de um segmento 3D.
# Usado para medir distância entre câmera e eixo da cápsula do modelo.
# =============================================================================

func _closest_point_on_segment(
	point: Vector3,
	segment_start: Vector3,
	segment_end: Vector3
) -> Vector3:
	var segment: Vector3 = segment_end - segment_start
	var segment_length_squared: float = segment.length_squared()

	if segment_length_squared <= 0.00001:
		return segment_start

	var t: float = (point - segment_start).dot(segment) / segment_length_squared
	t = clampf(t, 0.0, 1.0)

	return segment_start + segment * t

# =============================================================================
# VISIBILIDADE | APLICAÇÃO NO MODELO
# -----------------------------------------------------------------------------
# Altera a visibilidade do ModelPivot e de seus filhos Node3D.
# =============================================================================

func _set_model_pivot_visible(value: bool) -> void:
	model_pivot.visible = value
	_set_node_3d_children_visible(model_pivot, value)

# =============================================================================
# VISIBILIDADE | RECURSÃO EM FILHOS
# -----------------------------------------------------------------------------
# Garante que todos os Node3D filhos sigam a mesma visibilidade do ModelPivot.
# =============================================================================

func _set_node_3d_children_visible(node: Node, value: bool) -> void:
	for child in node.get_children():
		if child is Node3D:
			child.visible = value

		_set_node_3d_children_visible(child, value)

# =============================================================================
# CÂMERA | TROCA DE OMBRO
# -----------------------------------------------------------------------------
# Define o lado alvo da câmera usando o offset lateral configurado.
# =============================================================================

func _set_camera_shoulder(side: float) -> void:
	target_shoulder_offset = shoulder_offset * side

# =============================================================================
# INPUT | CAPTURA DO MOUSE
# -----------------------------------------------------------------------------
# Alterna entre mouse capturado para gameplay e mouse visível para menus/debug.
# =============================================================================

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# =============================================================================
# UTILIDADE | PESO DE SUAVIZAÇÃO
# -----------------------------------------------------------------------------
# Converte velocidade e delta em um peso seguro para interpolações.
# =============================================================================

func _get_smooth_weight(speed: float, delta: float) -> float:
	return clampf(speed * delta, 0.0, 1.0)
