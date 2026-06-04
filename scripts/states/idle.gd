extends PlayerMovementState


# =============================================================================
# STATE | IDLE
# -----------------------------------------------------------------------------
# Estado parado no chão.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(0.0, delta)

	if player.should_jump():
		state_machine.change_state(&"Jump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if player.has_movement_input():
		if player.is_sprint_pressed:
			state_machine.change_state(&"Sprint")
		else:
			state_machine.change_state(&"Walk")
