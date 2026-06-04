extends PlayerMovementState


# =============================================================================
# STATE | IDLE
# -----------------------------------------------------------------------------
# Estado parado no chão.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(0.0, delta)

	if player.should_jump():
		state_machine.change_state(&"IdleJump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"IdleFall")
		return

	if player.is_aim_pressed:
		state_machine.change_state(&"AimStealth" if player.is_stealth_pressed else &"AimIdle")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if player.has_movement_input():
		if player.is_sprint_pressed and player.can_sprint():
			state_machine.change_state(&"Sprint")
		else:
			state_machine.change_state(&"Walk")
