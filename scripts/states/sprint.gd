extends PlayerMovementState


# =============================================================================
# STATE | SPRINT
# -----------------------------------------------------------------------------
# Estado de corrida. Consome stamina, bloqueia zoom e usa câmera de velocidade.
# =============================================================================

func physics_update(delta: float) -> void:
	if not player.consume_sprint_stamina(delta):
		state_machine.change_state(&"Walk")
		return

	player.apply_horizontal_movement(player.sprint_speed, delta)

	if player.should_jump():
		state_machine.change_state(&"SprintJump")
		return

	if not player.is_on_floor():
		state_machine.change_state(&"SprintFall")
		return

	if player.is_aim_pressed:
		state_machine.change_state(&"AimWalk")
		return

	if player.is_stealth_pressed:
		state_machine.change_state(&"Stealth")
		return

	if not player.has_movement_input():
		state_machine.change_state(&"Idle")
		return

	if not player.is_sprint_pressed:
		state_machine.change_state(&"Walk")
