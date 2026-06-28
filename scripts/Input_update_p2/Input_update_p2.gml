/// @description  Input_update_p2()
function Input_update_p2() {

	// Co-op Player 2 (fairy) gamepad read.
	// Runs via `with(Input)` so these are Input instance vars (init'd in Input_Create()).
	// No-op (cleared values) unless co-op is enabled AND a SEPARATE 2nd pad has JOINED.
	p2_moveH          = 0;
	p2_moveV          = 0;
	p2_shoot_pressed  = false;
	p2_action_pressed = false;
	p2_tank_pressed   = false;

	if (!global.coop_enabled)  return; // !!!!! OFF by default -- nothing changes for solo play

	// ── EXPLICIT P2 JOIN ──────────────────────────────────────────────────────────
	// The fairy stays INERT until the user DELIBERATELY presses a button/stick on a
	// SEPARATE 2nd controller. We NEVER auto-bind on connect anymore (the old auto-
	// capture in Input_System made ONE physical pad that enumerates as TWO gamepad
	// slots drive BOTH players). Each frame we're unassigned, scan every connected slot
	// that is NOT P1's slot and accept the first one whose input is DISTINCT from P1's
	// same-frame input.
	//   DUPLICATE-PAD GUARD: a PS4 pad through DS4Windows shows as native DS4 + emulated
	//   XInput -- one physical pad on TWO slots, so every press lands on BOTH. We only
	//   accept a candidate that has a button/stick the SAME-FRAME P1 slot does NOT --
	//   i.e. a real, independently-pressed 2nd controller. A mirrored duplicate is
	//   rejected (its inputs always match P1's), so it can never auto-join the fairy.
	if (gamepad_slot_p2 == -1)
	{
		var _btns = [gp_face1, gp_face2, gp_face3, gp_face4,
		             gp_start, gp_select,
		             gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb,
		             gp_padl, gp_padr, gp_padu, gp_padd];
		var _max = gamepad_get_device_count();
		for (var _i = 0; _i < _max; _i++)
		{
			if (_i == gamepad_slot)        continue; // never adopt P1's own slot
			if (!gamepad_is_connected(_i)) continue;

			// A button HELD on this candidate but NOT on P1's slot => genuinely distinct.
			var _distinct = false;
			for (var _b = 0; _b < array_length(_btns); _b++)
			{
				if ( gamepad_button_check(_i,           _btns[_b])
				&&  !gamepad_button_check(gamepad_slot, _btns[_b]) )
				{ _distinct = true; break; }
			}
			// Stick fallback: a left-stick push on the candidate not matched on P1.
			if (!_distinct)
			{
				var _ch = clamp(round(gamepad_axis_value(_i,           gp_axislh)), -1, 1);
				var _cv = clamp(round(gamepad_axis_value(_i,           gp_axislv)), -1, 1);
				var _ph = clamp(round(gamepad_axis_value(gamepad_slot, gp_axislh)), -1, 1);
				var _pv = clamp(round(gamepad_axis_value(gamepad_slot, gp_axislv)), -1, 1);
				if (_ch != 0 && _ch != _ph) _distinct = true;
				if (_cv != 0 && _cv != _pv) _distinct = true;
			}

			if (_distinct)
			{
				gamepad_slot_p2 = _i; // this separate pad now drives the fairy
				break;
			}
		}
		return; // still unassigned, or just joined this frame -> no fairy input yet
	}

	// ── HARD GATE ── P2 must be a VALID slot DISTINCT from P1's. If it ever collapses
	// onto P1's slot, refuse all input so the fairy can NEVER echo P1's controller.
	if (gamepad_slot_p2 == gamepad_slot) return;

	var _s = gamepad_slot_p2;

	// Movement reuses Link's OWN rebindable bindings (GP_right/left/down/up), just polled
	// on the P2 slot, so the fairy honours the player's d-pad remaps. Defaults = the d-pad.
	p2_moveH = gamepad_button_check(_s, GP_right) - gamepad_button_check(_s, GP_left);
	p2_moveV = gamepad_button_check(_s, GP_down)  - gamepad_button_check(_s, GP_up);

	// Left-stick fallback (snapped to -1/0/1) when the d-pad isn't pushed.
	if (p2_moveH == 0) p2_moveH = clamp(round(gamepad_axis_value(_s, gp_axislh)), -1, 1);
	if (p2_moveV == 0) p2_moveV = clamp(round(gamepad_axis_value(_s, gp_axislv)), -1, 1);

	// Actions reuse Link's OWN rebindable button bindings (read on the P2 slot) so the
	// fairy's buttons sit on the SAME physical buttons as Link's -- no more "attack feels
	// swapped" -- and they follow the player's rebinds:
	//   SHOOT = Link's ATTACK button (GP_attack)
	//   HEAL  = Link's JUMP   button (GP_jump)
	//   TANK  = Link's B / OTHER1 button (GP_other1)
	p2_shoot_pressed  = gamepad_button_check_pressed(_s, GP_attack); // fairy shoots
	p2_action_pressed = gamepad_button_check_pressed(_s, GP_jump);   // heal P1
	p2_tank_pressed   = gamepad_button_check_pressed(_s, GP_other1); // shield P1 (iframes)




}
