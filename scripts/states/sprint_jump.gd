extends PlayerMovementState


# =============================================================================
# STATE | SPRINT JUMP
# -----------------------------------------------------------------------------
# Pulo iniciado durante corrida. Mantém comportamento de sprint no ar.
# =============================================================================

func enter() -> void:
	if player.is_on_floor():
		player.velocity.y = player.jump_velocity


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.sprint_speed, delta)

	if player.velocity.y <= 0.0:
		state_machine.change_state(&"SprintFall")
