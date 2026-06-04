extends PlayerMovementState


# =============================================================================
# STATE | FALL
# -----------------------------------------------------------------------------
# Estado de queda até tocar o chão.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.walk_speed, delta)

	if not player.is_on_floor():
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if not player.has_movement_input():
		state_machine.change_state(&"Idle")
		return

	if player.is_sprint_pressed:
		state_machine.change_state(&"Sprint")
	else:
		state_machine.change_state(&"Walk")
