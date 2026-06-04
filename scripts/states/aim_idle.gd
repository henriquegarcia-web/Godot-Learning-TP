extends PlayerMovementState


# =============================================================================
# STATE | AIM IDLE
# -----------------------------------------------------------------------------
# Estado parado mirando. Mantém zoom/foco máximo.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(0.0, delta)

	if player.should_jump():
		state_machine.change_state(&"IdleJump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"IdleFall")
		return

	if not player.is_aim_pressed:
		state_machine.change_state(&"Stealth" if player.is_stealth_pressed else &"Idle")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"AimStealth")
		return

	if player.has_movement_input():
		state_machine.change_state(&"AimWalk")
