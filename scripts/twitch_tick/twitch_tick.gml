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

	// ── FLAWLESS BOSS CALLOUT (B65) ─────────────────────────────────────────────
	// Copy supplied by chat itself (asm0deus, 09-04: "Flawless victory, fatility,
	// babality, humaliation, FRIENDSHIP, TOASTY"). Track per room: a live Boss sets
	// tw_boss_seen; any PC hit while one is alive dirties the fight (PC_take_damage);
	// when the boss count drops to zero in the SAME room (no transition), a clean
	// fight that lasted >5s earns a random finisher toast. tw_boss_room_loading
	// swallows the no-boss frames inside a room transition so walking OUT of a boss
	// room alive never counts as a kill.
	if (variable_global_exists("tw_boss_seen"))
	{
		if (g.ChangeRoom_timer > 0)
		{   global.tw_boss_room_loading = true;  }
		else if (global.tw_boss_room_loading)
		{   // new room is live -- fresh fight
			global.tw_boss_room_loading = false;
			global.tw_boss_seen         = false;
			global.tw_boss_damaged      = false;
			global.tw_boss_frames       = 0;
		}

		if (instance_exists(Boss))
		{
			global.tw_boss_seen = true;
			global.tw_boss_frames++;
		}
		else if (global.tw_boss_seen && !global.tw_boss_room_loading)
		{
			global.tw_boss_seen = false;
			if (!global.tw_boss_damaged && global.tw_boss_frames > 300)
			{
				global.tw_toast       = global.tw_mk_strings[irandom(array_length(global.tw_mk_strings) - 1)];
				global.tw_toast_timer = 240;
			}
			global.tw_boss_damaged = false;
			global.tw_boss_frames  = 0;
		}
	}

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
