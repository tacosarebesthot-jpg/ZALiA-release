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

	tw_splash_step(); // MK2 splash queue (runs even with the twitch mod off: boss callouts are for everyone)
	// toast countdown (independent of the effect list)
	if (variable_global_exists("tw_toast_timer") && global.tw_toast_timer > 0)
	{   global.tw_toast_timer--;  }

	if (variable_global_exists("tw_flash_timer") && global.tw_flash_timer > 0) global.tw_flash_timer--; // !flashbang fade

	tw_checkpoint_tick();   // rolling checkpoints (round 10d) -- independent of the twitch mod
	tw_points_tick();       // points stipend + throttled save (round 10h)
	tw_vote_tick();         // !vote clock; fires the winner through twitch_apply (twitch_vote.gml)
	tw_oneup_nudge_tick();  // "!1up" reminder after N minutes on the last life (10-09 VOD round)

	if (!variable_global_exists("tw_active")) return;

	// !challenge ends the moment the palace is left (round 10c). g_Room_Start zeroes dungeon_num
	// for every room that is not a scene, the death and next-life screens included, so the bare
	// test ended the challenge at the first death -- the one thing keep_on_death exists to
	// prevent (selftest "edge" 2026-10-01: "switched off in rmB_Death, dungeon_num=0"). Those two
	// screens are the only exception: a game over, the continue screen and the title all end it,
	// or the flip would follow the player out and mirror the menus.
	if (variable_global_exists("tw_challenge") && global.tw_challenge && instance_exists(g) && g.dungeon_num <= 0
	&&  room != rmB_Death && room != rmB_NextLife)
	{   global.tw_challenge = false;  }

	// queued swarms land on the next live battle screen, 60 frames after it settles
	if (variable_global_exists("tw_swarm_queue") && array_length(global.tw_swarm_queue) > 0 && instance_exists(g))
	{
		if (!variable_global_exists("tw_room_live_frames")) global.tw_room_live_frames = 0;
		if (g.room_type == "A" && g.gui_state == g.gui_state_NONE && !g.cutscene && !g.FallScene_timer && g.ChangeRoom_timer <= 0 && instance_exists(global.pc))
		{
			global.tw_room_live_frames++;
			if (global.tw_room_live_frames >= 60 && global.tw_enabled)
			{
				var _sq = global.tw_swarm_queue[0];
				array_delete(global.tw_swarm_queue, 0, 1);
				global.tw_room_live_frames = 0;
				twitch_apply("swarm", string(_sq.n), _sq.who, "");
			}
		}
		else global.tw_room_live_frames = 0;
	}

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
			global.tw_boss_pc_died      = false;
			global.tw_boss_frames       = 0;
		}

		// Lane 09-18 (3:58:23): dying to a boss awarded the BOSS a FLAWLESS VICTORY. Death
		// has paths that never touch PC_take_damage (barrier/backwall/pit set is_dead
		// directly), and the death-room exit isn't a ChangeRoom_timer transition -- so a
		// dead or missing PC dirties the fight here, where the finisher is decided.
		if (global.tw_boss_seen
		&& (!instance_exists(global.pc) || global.pc.is_dead || f.hp <= 0))
		{   global.tw_boss_damaged = true;  global.tw_boss_pc_died = true;  }

		if (instance_exists(Boss))
		{
			global.tw_boss_seen = true;
			global.tw_boss_frames++;
			if (global.tw_boss_frames == 1 || (global.tw_boss_frames mod 30) == 0) // CHAT JOKES {boss}: remember who this was
			{   with (Boss) { global.tw_last_boss = object_get_name(object_index); break; }  }
		}
		else if (global.tw_boss_seen && !global.tw_boss_room_loading)
		{
			global.tw_boss_seen = false;
			if (!global.tw_boss_damaged && global.tw_boss_frames > 300)
			{
				// Lane 09-11 (3:45:24): "all I did was get some green text at the bottom there ...
				// we want a little cutscene where the screen goes dark." Owner: the real MK2 splash.
				tw_flawless_event("");
			}
			// ROCKET LEAGUE (round 11): the consolation prize. A boss that died after landing a
			// hit isn't flawless, so it gets the RL plate instead of the MK2 splash -- the two
			// branches are exclusive, no kill ever throws both.
			else if (variable_global_exists("tw_rl") && global.tw_rl && global.tw_boss_damaged
			     &&  !global.tw_boss_pc_died) // a death gets no finisher of any kind
			{   tw_toast_push("CALCULATED.", "", "win");  }
			global.tw_boss_damaged = false;
			global.tw_boss_pc_died = false;
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
	// NO SFX/JINGLE TOASTS (owner 2026-09-16, from the p1 VOD: "remove sound effects from
	// toast ... the whole point of the toast is to tell what music's playing"). Short cues
	// (get-spell, level-up, item-get, fanfares, chimes) live in audiogroup_mus so they funnel
	// through here and were being announced like tracks. Suppress them by their name markers;
	// real tracks are named after their game/stage and never carry these.
	if (string_pos("GetSpell", _name) > 0 || string_pos("LevelUp", _name) > 0
	||  string_pos("Fanfare", _name) > 0  || string_pos("ItemGet", _name) > 0
	||  string_pos("Get_Item", _name) > 0 || string_pos("Jingle", _name) > 0
	||  string_pos("Container", _name) > 0 || string_pos("Rescued", _name) > 0
	||  string_pos("Victory", _name) > 0) return;
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

/// @description  tw_splash_enqueue(sprite, sound, wait_frames, toast) -- queue one splash step.
/// sprite/sound may be -1 (sound-only step, or silent sprite). wait = frames to hold before
/// this step starts (after the previous one ends). toast = "" or a line for the small toast.
function tw_splash_enqueue(_spr, _snd, _wait, _toast, _dur = 0, _y = -1, _corner = false) {
	if (!variable_global_exists("tw_splash_queue") || !is_array(global.tw_splash_queue)) global.tw_splash_queue = [];
	array_push(global.tw_splash_queue, { spr : _spr, snd : _snd, wait : _wait, toast : _toast, dur : _dur, y : _y, corner : _corner });
}

/// @description  tw_oneup_nudge_tick() -- 10-09 VOD 2:22:55, Lane: "I want my lives back, I've been
/// playing with one life for like an hour." !1up exists; nobody in chat used it. After
/// tw_oneup_nudge_min minutes on the last life a toast reminds chat, then the clock restarts.
/// Off when the mod is off, in VS / !challenge mode (1up is refused there anyway), on the
/// overworld / menus (no PC instance), or with oneup_nudge=0.
function tw_oneup_nudge_tick() {
	if (!variable_global_exists("tw_oneup_nudge_min") || global.tw_oneup_nudge_min <= 0) return;
	if (!variable_global_exists("tw_enabled") || !global.tw_enabled) return;
	if (!variable_global_exists("pc_lives")) return;
	var _blocked = (variable_global_exists("tw_vs_mode") && global.tw_vs_mode)
	            || (variable_global_exists("tw_challenge") && global.tw_challenge);
	if (_blocked || global.pc_lives > 1 || !instance_exists(global.pc)) { global.tw_oneup_nudge_frames = 0; return; }
	global.tw_oneup_nudge_frames++;
	var _fps = game_get_speed(gamespeed_fps); if (_fps <= 0) _fps = 60;
	if (global.tw_oneup_nudge_frames < global.tw_oneup_nudge_min * 60 * _fps) return;
	global.tw_oneup_nudge_frames = 0;
	tw_toast_push("LAST LIFE FOR " + string(global.tw_oneup_nudge_min) + " MIN", "CHAT: !1UP GIVES LINK A LIFE", "info", "chat");
}

/// @description  tw_splash_step() -- per-frame driver: advances the playing splash at the
/// arcade's frame rate, then starts the next queued step once the wait elapses.
function tw_splash_step() {
	if (!variable_global_exists("tw_splash_spr")) return;
	if (global.tw_splash_spr >= 0)
	{
		var _fps = game_get_speed(gamespeed_fps); if (_fps <= 0) _fps = 60;
		global.tw_splash_frame += 54.70684 / _fps;             // MK2 arcade = 54.706840 Hz
		if (global.tw_splash_dur > 0)
		{
			// looping mode (the flashing FLAWLESS VICTORY line): cycle for dur frames
			global.tw_splash_dur--;
			// selftest "splash" mode: one screenshot of the Toasty pop mid-hold (see Dev_Bugprobe_Step)
			if (variable_global_exists("tw_splash_corner") && global.tw_splash_corner
			&&  global.tw_splash_dur == global.tw_splash_dur_total - 20
			&&  variable_global_exists("tw_selftest_mode") && global.tw_selftest_mode == "splash") tws_shot("toasty");
			if (global.tw_splash_frame >= sprite_get_number(global.tw_splash_spr)) global.tw_splash_frame -= sprite_get_number(global.tw_splash_spr);
			if (global.tw_splash_dur <= 0) { global.tw_splash_spr = -1; global.tw_splash_frame = 0; }
		}
		else if (global.tw_splash_frame >= sprite_get_number(global.tw_splash_spr))
		{
			global.tw_splash_spr   = -1;
			global.tw_splash_frame = 0;
		}
		return;
	}
	if (global.tw_splash_wait > 0) { global.tw_splash_wait--; return; }
	if (!is_array(global.tw_splash_queue) || array_length(global.tw_splash_queue) == 0) return;
	var _e = global.tw_splash_queue[0];
	array_delete(global.tw_splash_queue, 0, 1);
	if (_e.wait > 0)
	{
		// hold first, then start: re-queue at the front with wait cleared
		global.tw_splash_wait = _e.wait;
		array_insert(global.tw_splash_queue, 0, { spr : _e.spr, snd : _e.snd, wait : 0, toast : _e.toast, dur : _e.dur, y : _e.y,
		                                          corner : (variable_struct_exists(_e, "corner") && _e.corner) });
		return;
	}
	if (is_string(_e.toast) && _e.toast != "")
	{
		global.tw_toast       = _e.toast;
		global.tw_toast_timer = 240;
	}
	// Toasty (10-09 VOD): a corner pop instead of a centre banner. The draw block slides it in
	// from the right edge and back out, no screen dim; dur_total is what the slide is timed from.
	global.tw_splash_corner    = (variable_struct_exists(_e, "corner") && _e.corner);
	global.tw_splash_dur_total = _e.dur;
	if (_e.snd >= 0 && audio_exists(_e.snd)) aud_play_sound(_e.snd);
	if (_e.spr >= 0 && sprite_exists(_e.spr))
	{
		global.tw_splash_spr   = _e.spr;
		global.tw_splash_frame = 0;
		global.tw_splash_dur   = _e.dur;
		global.tw_splash_cur_y = (_e.y >= 0) ? _e.y : global.tw_splash_y;
	}
}

/// @description  tw_flawless_event(which) -- the flawless-boss celebration. "" = random
/// finisher, "fatality" / "friendship" force one, "flawless" = announcer + text only.
/// Sequence (mirrors the arcade): FLAWLESS VICTORY announcer + text, ~1.3 s, then the
/// finisher splash with its own announcer sample. Assets by name so a missing import
/// degrades to the old text toast instead of crashing.
function tw_flawless_event(_which) {
	if (variable_global_exists("tw_splash_enabled") && !global.tw_splash_enabled)
	{
		global.tw_toast       = global.tw_mk_strings[irandom(array_length(global.tw_mk_strings) - 1)];
		global.tw_toast_timer = 240;
		return;
	}
	var _s_flaw = asset_get_index("snd_mk2_flawless");
	var _s_fat  = asset_get_index("snd_mk2_fatality");
	var _s_frd  = asset_get_index("snd_mk2_friendship");
	var _p_fat  = asset_get_index("spr_mk2_fatality");
	var _p_frd  = asset_get_index("spr_mk2_friendship");
	var _p_fvt  = asset_get_index("spr_mk2_flawless_text");
	// The arcade's own FLAWLESS VICTORY line (8-frame white/red flash, ripped), looped for
	// ~1.8 s under the announcer, mid-screen like the arcade (row 112 of 254 -> GUI y 106).
	if (_p_fvt >= 0) tw_splash_enqueue(_p_fvt, _s_flaw, 0, "", 100, 106);
	else             tw_splash_enqueue(-1,     _s_flaw, 0, "FLAWLESS VICTORY!");
	if (_which == "flawless") return;
	if (_which == "") _which = (irandom(1) == 0) ? "fatality" : "friendship";
	if (_which == "friendship" && _p_frd >= 0) tw_splash_enqueue(_p_frd, _s_frd, 20, "");
	else if (_p_fat >= 0)                       tw_splash_enqueue(_p_fat, _s_fat, 20, "");
	else { global.tw_toast = "FATALITY."; global.tw_toast_timer = 240; }
	tw_toasty_enqueue();
}

/// @description  tw_toasty_enqueue() -- 10-09 VOD 2:53:59, Lane: "We need to get Claude to put Toasty
/// in there for us, popping out of the corner of the screen." MK2's Dan Forden head pops in at the
/// bottom-right with the "Toasty!" yell. Rides the splash queue after the finisher, as a corner
/// pop (no dim, slides in from the right edge and back out over ~1.3 s). Assets by name, like the
/// rest of the MK2 set: spr_mk2_toasty (origin TOP-LEFT, arcade pixels) + snd_mk2_toasty. Until
/// they are imported this is a no-op. toasty= in twitch_config.txt is the percent chance (100).
function tw_toasty_enqueue() {
	if (variable_global_exists("tw_splash_enabled") && !global.tw_splash_enabled) return;
	var _p = asset_get_index("spr_mk2_toasty");
	if (_p < 0 || !sprite_exists(_p)) return;
	var _pct = variable_global_exists("tw_toasty_pct") ? global.tw_toasty_pct : 100;
	if (irandom(99) >= _pct) return;
	var _s = asset_get_index("snd_mk2_toasty");
	// wait 30 frames after the finisher ends, show for 60 frames (7 in / 35 hold / 18 out, see the
	// draw block); looping mode on a 1-frame sprite. The sound plays as the head starts sliding in.
	tw_splash_enqueue(_p, _s, 30, "", 60, -1, true);
}
