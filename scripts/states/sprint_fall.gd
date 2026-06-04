extends PlayerMovementState


# =============================================================================
# STATE | SPRINT FALL
# -----------------------------------------------------------------------------
# Queda iniciada durante corrida. Mantém comportamento de sprint até tocar o chão.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.sprint_speed, delta)

	if not player.is_on_floor():
		return

	if player.is_aim_pressed:
		if player.has_movement_input():
			state_machine.change_state(&"AimWalk")
		else:
			state_machine.change_state(&"AimIdle")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if not player.has_movement_input():
		state_machine.change_state(&"Idle")
		return

	if player.is_sprint_pressed and player.can_sprint():
		state_machine.change_state(&"Sprint")
	else:
		state_machine.change_state(&"Walk")
