extends PlayerMovementState


# =============================================================================
# STATE | AIM WALK
# -----------------------------------------------------------------------------
# Estado andando enquanto mira. Usa velocidade reduzida e zoom menos fechado.
# =============================================================================

func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(player.aim_walk_speed, delta)

	if player.should_jump():
		state_machine.change_state(&"WalkJump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"WalkFall")
		return

	if not player.is_aim_pressed:
		if not player.has_movement_input():
			state_machine.change_state(&"Idle")
		elif player.is_stealth_pressed:
			state_machine.change_state(&"Stealth")
		else:
			state_machine.change_state(&"Walk")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"AimStealth")
		return

	if not player.has_movement_input():
		state_machine.change_state(&"AimIdle")
