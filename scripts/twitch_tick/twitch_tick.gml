/// @description  twitch_tick() -- age active timed effects, re-assert/revert them, count down the toast.
// ============================================================================
// TWITCH integration -- PHASE A effect ticker.
//
// Mirrors update_game_timers(): walk global.tw_active, decrement each .frames;
// while still active, re-assert reapply-type effects (the game recomputes the
// underlying value every frame, so we re-force it); on expiry run .restore()
// and drop the entry. Also counts the on-screen toast down.
//
// Effects drain even if the system is disabled mid-effect (so a toggle-off
// cleans up), but the whole call early-exits cheaply when idle+disabled.
// ============================================================================
function twitch_tick() {

	// toast countdown (independent of the effect list)
	if (variable_global_exists("tw_toast_timer") && global.tw_toast_timer > 0)
	{   global.tw_toast_timer--;  }

	if (!variable_global_exists("tw_active")) return;

	// cheap idle exit: disabled with nothing pending
	if ((!variable_global_exists("tw_enabled") || !global.tw_enabled)
	&&  array_length(global.tw_active) == 0)
	{   return;  }

	for (var _i = array_length(global.tw_active) - 1; _i >= 0; _i--)
	{
		var _e = global.tw_active[_i];
		_e.frames--;

		if (_e.frames > 0)
		{
			if (variable_struct_exists(_e, "reapply") && is_method(_e.reapply)) _e.reapply();
		}
		else
		{
			if (variable_struct_exists(_e, "restore") && is_method(_e.restore)) _e.restore();
			array_delete(global.tw_active, _i, 1);
		}
	}
}
