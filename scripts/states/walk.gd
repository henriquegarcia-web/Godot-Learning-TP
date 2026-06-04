extends PlayerMovementState


# =============================================================================
# STATE | WALK
# -----------------------------------------------------------------------------
# Estado de caminhada normal no chão.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.walk_speed, delta)

	if player.should_jump():
		state_machine.change_state(&"Jump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if not player.has_movement_input():
		state_machine.change_state(&"Idle")
		return

	if player.is_sprint_pressed:
		state_machine.change_state(&"Sprint")
