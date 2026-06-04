extends PlayerMovementState


# =============================================================================
# STATE | JUMP
# -----------------------------------------------------------------------------
# Estado de subida após o pulo.
# =============================================================================

func enter() -> void:
	if player.is_on_floor():
		player.velocity.y = player.jump_velocity


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.walk_speed, delta)

	if player.velocity.y <= 0.0:
		state_machine.change_state(&"Fall")
