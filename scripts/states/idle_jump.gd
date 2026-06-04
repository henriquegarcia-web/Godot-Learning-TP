extends PlayerMovementState


# =============================================================================
# STATE | IDLE JUMP
# -----------------------------------------------------------------------------
# Pulo iniciado parado. Não muda para walk/sprint jump durante o ar.
# =============================================================================

func enter() -> void:
	if player.is_on_floor():
		player.velocity.y = player.jump_velocity


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(0.0, delta)

	if player.velocity.y <= 0.0:
		state_machine.change_state(&"IdleFall")
