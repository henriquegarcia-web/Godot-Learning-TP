extends PlayerMovementState


# =============================================================================
# STATE | STEALTH
# -----------------------------------------------------------------------------
# Estado furtivo. Reduz velocidade e mantém foco maior no zoom.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.stealth_speed, delta)

	if player.should_jump():
		state_machine.change_state(&"Jump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return

	if not player.is_stealth_pressed:
		if not player.has_movement_input():
			state_machine.change_state(&"Idle")
		elif player.is_sprint_pressed:
			state_machine.change_state(&"Sprint")
		else:
			state_machine.change_state(&"Walk")
