extends PlayerMovementState


# =============================================================================
# STATE | IDLE FALL
# -----------------------------------------------------------------------------
# Queda iniciada parada ou saída forçada de stealth no ar.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(0.0, delta)

	if not player.is_on_floor():
		return

	if player.is_aim_pressed:
		state_machine.change_state(&"AimIdle")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if player.has_movement_input():
		if player.is_sprint_pressed and player.can_sprint():
			state_machine.change_state(&"Sprint")
		else:
			state_machine.change_state(&"Walk")
	else:
		state_machine.change_state(&"Idle")
