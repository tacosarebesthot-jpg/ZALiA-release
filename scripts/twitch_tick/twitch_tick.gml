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

/// @description  tw_track_pretty(asset_name) -- "mus_CV3_MadForest" -> "CV3 MAD FOREST".
/// Same first step as the jukebox list (drop "mus_", upper-case), plus underscores to
/// spaces, CamelCase split, and the ripper suffixes (_1a / _Body) dropped.
function tw_track_pretty(_name) {
	var _n = string(_name);
	if (string_copy(_n, 1, 4) == "mus_") _n = string_delete(_n, 1, 4);
	if (string_length(_n) > 3 && string_copy(_n, string_length(_n) - 2, 3) == "_1a")   _n = string_copy(_n, 1, string_length(_n) - 3);
	if (string_length(_n) > 5 && string_copy(_n, string_length(_n) - 4, 5) == "_Body") _n = string_copy(_n, 1, string_length(_n) - 5);
	var _out = "";
	var _prev = "";
	for (var _i = 1; _i <= string_length(_n); _i++)
	{
		var _c = string_char_at(_n, _i);
		if (_c == "_") { _out += " "; _prev = " "; continue; }
		// lower->Upper boundary or letter->digit boundary gets a space
		var _is_up  = (_c == string_upper(_c)) && (_c != string_lower(_c));
		var _is_dig = (string_digits(_c) == _c) && (_c != "");
		var _p_low  = (_prev != "") && (_prev == string_lower(_prev)) && (_prev != string_upper(_prev));
		var _p_dig  = (_prev != "") && (string_digits(_prev) == _prev);
		if (_out != "" && _prev != " " && ((_is_up && _p_low) || (_is_dig && !_p_dig && _prev != " ") || (!_is_dig && _p_dig && !_is_up && _prev != " ")))
			_out += " ";
		_out += _c;
		_prev = _c;
	}
	return string_upper(_out);
}

/// @description  tw_nowplaying_set(sound, is_intro) -- called from aud_play_sound for every
/// audiogroup_mus start. Records the current track and arms the NOW PLAYING toast once per
/// distinct body track. Layered-channel parts and utility assets (the jukebox's own
/// exclusion list) never announce. Lane's chat asks "what song is this" on every stream
/// (CHAT_IDEAS_2026-09-10, culture notes) -- this and !song answer it.
function tw_nowplaying_set(_snd, _is_intro) {
	if (is_string(_snd) || is_undefined(_snd) || _snd < 0) return;
	if (_is_intro) return;
	var _name = audio_get_name(_snd);
	if (_name == "mus_gain") return;
	if (string_pos("Square1_1a", _name) > 0 || string_pos("Triangle_Square", _name) > 0
	||  string_pos("Square1_only", _name) > 0 || string_pos("Square2_1a", _name) > 0) return;
	if (string_pos("_Intro", _name) > 0) return;
	global.tw_np_asset = _snd;
	global.tw_np_name  = tw_track_pretty(_name);
	if (!variable_global_exists("tw_np_enabled") || global.tw_np_enabled)
	{
		if (!variable_global_exists("tw_np_last") || global.tw_np_last != _name)
		{
			global.tw_np_timer = 300; // 5 s
		}
	}
	global.tw_np_last = _name;
}
