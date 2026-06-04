extends PlayerMovementState


# =============================================================================
# STATE | AIM STEALTH
# -----------------------------------------------------------------------------
# Estado furtivo mirando. Não permite pulo e, ao cair, vai para IdleFall.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.aim_stealth_speed, delta)

	if not player.is_on_floor():
		state_machine.change_state(&"IdleFall")
		return

	if not player.is_aim_pressed:
		state_machine.change_state(&"Stealth" if player.is_stealth_pressed else &"Idle")
		return

	if not player.is_stealth_pressed:
		state_machine.change_state(&"AimWalk" if player.has_movement_input() else &"AimIdle")
