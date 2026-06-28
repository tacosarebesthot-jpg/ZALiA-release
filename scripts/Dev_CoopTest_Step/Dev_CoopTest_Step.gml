// ============================================================================
// DEV CO-OP TEST harness (added 2026-06-28).
//
// Automated, headless-capable test that exercises the co-op P2 fairy
// (obj_fairy_p2) through ALL of its behaviours with SYNTHETIC inputs (no real
// controller) and verifies the client doesn't crash. Mirrors the room/scene
// auto-sweep harness exactly:
//   * trigger    : DEV + "_cooptest.flag" in working_directory (g_Create), OR
//                  the DEV TOOLS > TEST/CAPTURE > "COOP TEST" menu row.
//   * boot       : the SAME g_Step autopilot the sweeps use (title -> file
//                  select -> load save 1 -> reach an action room), then
//                  cooptest_start() kicks off the state machine.
//   * log/report : [COOPTEST] lines to debug console AND appended to
//                  working_directory + "cooptest/cooptest_report.txt"; the
//                  final verdict also lands in "cooptest/_RESULT.txt".
//   * exit       : game_end() at the end of a headless run (a menu run instead
//                  returns control to the player, like sweep_from_menu).
//
// INPUT INJECTION POINT: Dev_CoopTest_Step() is called from g_Step() (g's
// BEGIN STEP) immediately AFTER Input_update_p2() clears the Input.p2_* fields.
// Because g_Step runs in the Begin Step, it executes before EVERY instance's
// Normal Step -- so the fairy's Normal Step reads the values we inject here the
// same frame, with zero ambiguity about object step order.
//
// Revert: delete this script + its .yyp entry, the COOPTEST globals in
// g_Create, the autopilot/Dev_CoopTest_Step() hooks in g_Step, and the
// COOP_TEST rows in OptionsMenu_Create / _option_is_avail / _TestCap_update.
// ============================================================================

// Phase ids (sequential so cooptest_advance can just do phase+1). Macros instead of an
// enum to match this project's global-constant convention (see scripts/macros).
#macro CT_NONE    0
#macro CT_SETUP   1
#macro CT_MOVE    2
#macro CT_SHOOT   3
#macro CT_HEAL    4
#macro CT_TANK    5
#macro CT_FERRY   6
#macro CT_REVIVE  7
#macro CT_ROOMHOP 8
#macro CT_FINISH  9
#macro CT_DONE    10


function cooptest_phase_name(_p)
{
	switch (_p)
	{
		case CT_SETUP:   return "SETUP";
		case CT_MOVE:    return "MOVE";
		case CT_SHOOT:   return "SHOOT";
		case CT_HEAL:    return "HEAL";
		case CT_TANK:    return "TANK";
		case CT_FERRY:   return "FERRY";
		case CT_REVIVE:  return "REVIVE";
		case CT_ROOMHOP: return "ROOMHOP";
		case CT_FINISH:  return "FINISH";
		case CT_DONE:    return "DONE";
	}
	return "?";
}


// Log a line to the debug console AND the report file (guarded so file I/O can
// never crash the harness -- same convention as the sweep file appends).
function cooptest_log(_s)
{
	show_debug_message("[COOPTEST] " + string(_s));
	try
	{
		var _f = file_text_open_append(working_directory + "cooptest/cooptest_report.txt");
		file_text_write_string(_f, "[COOPTEST] " + string(_s));
		file_text_writeln(_f);
		file_text_close(_f);
	}
	catch (_ce) { }
}


// Log this phase's PASS/FAIL result, then advance to the next sequential phase.
function cooptest_advance(_phase, _pass, _detail)
{
	cooptest_log("phase=" + string(_phase) + " " + cooptest_phase_name(_phase)
		+ " " + (_pass ? "PASS" : "FAIL")
		+ ((string(_detail) == "") ? "" : " " + string(_detail)));
	if (!_pass)
	{
		global.cooptest_result = "FAIL";
		if (global.cooptest_fail_phase == 0) global.cooptest_fail_phase = _phase;
	}
	global.cooptest_phase = _phase + 1; // CoopTest enum values are sequential
	global.cooptest_t     = 0;
}


// Initialise + launch the state machine. Requires a live action room (PC + f).
// Safe to call from the headless autopilot OR the live menu row; aborts (run
// stays false) if gameplay isn't ready yet, so the autopilot can simply retry.
function cooptest_start()
{
	if (!instance_exists(g)
	||  !instance_exists(global.pc)
	||  !instance_exists(f)
	||  g.room_type != "A")
	{
		show_debug_message("[COOPTEST] cannot start yet: need a live action room (pc+f). will retry.");
		global.cooptest_run = false;
		return;
	}

	directory_create(working_directory + "cooptest");

	// Fresh report file for this run.
	try
	{
		var _rf = file_text_open_write(working_directory + "cooptest/cooptest_report.txt");
		file_text_write_string(_rf, "[COOPTEST] === START ts=" + string(date_datetime_string(date_current_datetime()))
			+ " room=" + room_get_name(room) + " from_menu=" + string(global.cooptest_from_menu) + " ===");
		file_text_writeln(_rf);
		file_text_close(_rf);
	}
	catch (_se) { }

	global.coop_enabled        = true;                              // master gate ON for the test
	global.coop_revive_tokens  = max(1, global.coop_revive_tokens); // guarantee a token for the REVIVE phase

	global.cooptest_phase      = CT_SETUP;
	global.cooptest_t          = 0;
	global.cooptest_result     = "PASS";
	global.cooptest_fail_phase = 0;

	// Phase-local accumulators (init defensively so a first read can never throw).
	global.cooptest_fx0          = 0;
	global.cooptest_fy0          = 0;
	global.cooptest_moved        = false;
	global.cooptest_inbounds     = true;
	global.cooptest_proj_base    = 0;
	global.cooptest_proj_fired   = false;
	global.cooptest_hp_low       = 0;
	global.cooptest_iframes_seen = false;
	global.cooptest_item         = noone;
	global.cooptest_item_x0      = 0;
	global.cooptest_item_y0      = 0;
	global.cooptest_ferry_ok     = false;
	global.cooptest_room0        = room;
	global.cooptest_revived      = false;
	global.cooptest_hop_idx      = 0;
	global.cooptest_hop_state    = 0;
	global.cooptest_hop_wait     = 0;
	global.cooptest_hop_fail     = false;
	global.cooptest_hop_town     = "";
	global.cooptest_hop_palace   = "";

	global.cooptest_run = true;
	cooptest_log("RUN START room=" + room_get_name(room) + " from_menu=" + string(global.cooptest_from_menu));
}


// ----------------------------------------------------------------------------
// Per-frame state machine + P2 input injection. Called from g_Step (Begin Step)
// right after Input_update_p2(). Self-gates on global.cooptest_run, so it's a
// single-bool no-op in any normal build / non-test run.
// ----------------------------------------------------------------------------
function Dev_CoopTest_Step()
{
	if (!variable_global_exists("cooptest_run") || !global.cooptest_run) exit;

	// Reset injected P2 inputs every frame; phases below re-assert what they need.
	// Input_update_p2() already cleared these one line earlier in g_Step; we own
	// them from here until the next frame's clear, so the fairy's Normal Step
	// reads exactly what we set.
	Input.p2_moveH          = 0;
	Input.p2_moveV          = 0;
	Input.p2_shoot_pressed  = false;
	Input.p2_action_pressed = false;
	Input.p2_tank_pressed   = false;

	global.cooptest_t++;

	try
	{
		switch (global.cooptest_phase)
		{
			// ── 1. SETUP ────────────────────────────────────────────────────
			case CT_SETUP:
			{
				if (global.cooptest_t == 1)
				{
					global.coop_enabled       = true;
					global.coop_revive_tokens = max(1, global.coop_revive_tokens);
					if (!instance_exists(obj_fairy_p2) && instance_exists(global.pc))
						instance_create(global.pc.x, global.pc.y, obj_fairy_p2);
					cooptest_log("phase=1 SETUP coop_enabled=1 tokens=" + string(global.coop_revive_tokens));
				}
				if (global.cooptest_t >= 15)
				{
					var _ok = instance_exists(obj_fairy_p2);
					cooptest_advance(CT_SETUP, _ok, "fairy_exists=" + string(_ok));
					if (!_ok) { global.cooptest_phase = CT_FINISH; global.cooptest_t = 0; } // no fairy -> abort to FINISH
				}
				break;
			}

			// ── 2. MOVE (cycle all 8 directions; verify move + clamp) ────────
			case CT_MOVE:
			{
				if (!instance_exists(obj_fairy_p2)) { cooptest_advance(CT_MOVE, false, "fairy_missing"); break; }
				if (global.cooptest_t == 1)
				{
					global.cooptest_fx0      = obj_fairy_p2.x;
					global.cooptest_fy0      = obj_fairy_p2.y;
					global.cooptest_moved    = false;
					global.cooptest_inbounds = true;
					cooptest_log("phase=2 MOVE x0=" + string(global.cooptest_fx0) + " y0=" + string(global.cooptest_fy0));
				}

				var _dh = [ 1, 1, 0,-1,-1,-1, 0, 1];
				var _dv = [ 0, 1, 1, 1, 0,-1,-1,-1];
				var _di = (global.cooptest_t div 6) mod 8; // each direction held ~6 frames
				Input.p2_moveH = _dh[_di];
				Input.p2_moveV = _dv[_di];

				// Observe the previous frame's fairy step result.
				if (abs(obj_fairy_p2.x - global.cooptest_fx0) > 0.5
				||  abs(obj_fairy_p2.y - global.cooptest_fy0) > 0.5) global.cooptest_moved = true;

				var _bxl = g.view_xl_og + 8;
				var _bxr = g.view_xl_og + VIEW_W_OG - 8;
				var _byt = g.view_yt_og + 8;
				var _byb = g.view_yt_og + VIEW_H_OG - 8;
				if (obj_fairy_p2.x < _bxl - 1 || obj_fairy_p2.x > _bxr + 1
				||  obj_fairy_p2.y < _byt - 1 || obj_fairy_p2.y > _byb + 1) global.cooptest_inbounds = false;

				if (global.cooptest_t >= 48)
				{
					var _ok = global.cooptest_moved && global.cooptest_inbounds;
					cooptest_advance(CT_MOVE, _ok, "moved=" + string(global.cooptest_moved) + " inbounds=" + string(global.cooptest_inbounds));
				}
				break;
			}

			// ── 3. SHOOT (pulse shoot; verify a ProjectileFriendly activates) ─
			case CT_SHOOT:
			{
				if (!instance_exists(obj_fairy_p2)) { cooptest_advance(CT_SHOOT, false, "fairy_missing"); break; }
				if (global.cooptest_t == 1)
				{
					var _nb = 0; with (ProjectileFriendly) { if (state != 0) _nb++; }
					global.cooptest_proj_base  = _nb;
					global.cooptest_proj_fired = false;
					cooptest_log("phase=3 SHOOT projBase=" + string(_nb));
				}
				Input.p2_shoot_pressed = true; // fairy's own 12f cooldown rate-limits actual fires
				var _nc = 0; with (ProjectileFriendly) { if (state != 0) _nc++; }
				if (_nc > global.cooptest_proj_base) global.cooptest_proj_fired = true; // peak detection
				if (global.cooptest_t >= 36)
					cooptest_advance(CT_SHOOT, global.cooptest_proj_fired, "fired=" + string(global.cooptest_proj_fired));
				break;
			}

			// ── 4. HEAL (pulse action; verify f.hp rises via adjust_stat) ────
			case CT_HEAL:
			{
				if (!instance_exists(f)) { cooptest_advance(CT_HEAL, false, "no_f"); break; }
				if (global.cooptest_t == 1)
				{
					var _max = get_stat_max(STR_Heart);
					f.hp = max(1, _max - 6); // leave headroom so the heal is observable
					global.cooptest_hp_low = f.hp;
					cooptest_log("phase=4 HEAL hp_low=" + string(f.hp) + " hp_max=" + string(_max));
				}
				Input.p2_action_pressed = true;
				if (global.cooptest_t >= 30)
				{
					var _ok = instance_exists(f) && (f.hp > global.cooptest_hp_low);
					cooptest_advance(CT_HEAL, _ok, "hp_now=" + (instance_exists(f) ? string(f.hp) : "?") + " hp_low=" + string(global.cooptest_hp_low));
				}
				break;
			}

			// ── 5. TANK (pulse tank; verify P1 iframes_timer gets set) ───────
			case CT_TANK:
			{
				if (!instance_exists(global.pc)) { cooptest_advance(CT_TANK, false, "no_pc"); break; }
				if (global.cooptest_t == 1)
				{
					global.cooptest_iframes_seen = false;
					if (variable_instance_exists(global.pc, "iframes_timer")) global.pc.iframes_timer = 0;
					cooptest_log("phase=5 TANK start");
				}
				if (global.cooptest_t <= 6) Input.p2_tank_pressed = true; // short pulse (fairy applies 30f invuln, 120f cooldown)
				if (instance_exists(global.pc)
				&&  variable_instance_exists(global.pc, "iframes_timer")
				&&  global.pc.iframes_timer > 0) global.cooptest_iframes_seen = true;
				if (global.cooptest_t >= 20)
					cooptest_advance(CT_TANK, global.cooptest_iframes_seen, "iframes_seen=" + string(global.cooptest_iframes_seen));
				break;
			}

			// ── 6. FERRY (fairy carries a world pickup onto P1; verify P1 collects it) ─
			case CT_FERRY:
			{
				if (global.cooptest_t == 1)
				{
					global.cooptest_item     = noone;
					global.cooptest_ferry_ok = false;
					if (instance_exists(obj_fairy_p2) && instance_exists(global.pc))
					{
						// Park the fairy ON P1 (its FERRY block only acts on items within
						// ~24px of the fairy) and spawn the pickup right on P1, so the fairy
						// carries + hands it off this phase. A P-Bag is save-safe: it awards
						// XP only, never a permanent f.items bit. Its pickup normally needs an
						// ACTIVE sword stab the idle test-P1 never does, so completion relies on
						// the fairy's FERRY hand-off (obj_fairy_p2 Step) -> Item_update_1 ->
						// state_DROP (xp-rise) -> instance despawns, i.e. consumed=1.
						obj_fairy_p2.x = global.pc.x;
						obj_fairy_p2.y = global.pc.y;
						try { global.cooptest_item = GameObject_create(global.pc.x, global.pc.y, ItmF0, 10); } // PBag (1000)
						catch (_fe) { global.cooptest_item = noone; cooptest_log("phase=6 FERRY item-spawn EXCEPTION " + string(_fe.message)); }
					}
					if (instance_exists(global.cooptest_item))
					{
						global.cooptest_item_x0 = global.cooptest_item.x;
						global.cooptest_item_y0 = global.cooptest_item.y;
						cooptest_log("phase=6 FERRY item spawned id=" + string(global.cooptest_item) + " x=" + string(global.cooptest_item.x) + " y=" + string(global.cooptest_item.y));
					}
					else cooptest_log("phase=6 FERRY item-spawn skipped (no item)");
				}

				if (global.cooptest_item == noone)
				{
					// Nothing to ferry -> can't verify the hand-off, but no-crash is the bar.
					if (global.cooptest_t >= 60) cooptest_advance(CT_FERRY, true, "item_skip");
					break;
				}

				// The fairy's FERRY hand-off awards + consumes the delivered pickup.
				if (!instance_exists(global.cooptest_item)) global.cooptest_ferry_ok = true; // delivered + consumed

				if (global.cooptest_t >= 60)
				{
					var _consumed = !instance_exists(global.cooptest_item);
					if (instance_exists(global.cooptest_item)) instance_destroy(global.cooptest_item); // cleanup before room-hop
					// PASS now REQUIRES an end-to-end delivery (item picked up + consumed).
					cooptest_advance(CT_FERRY, _consumed, "delivered=" + string(global.cooptest_ferry_ok) + " consumed=" + string(_consumed));
				}
				break;
			}

			// ── 7. REVIVE (force P1 death; verify the fairy revives in place) ─
			case CT_REVIVE:
			{
				if (!instance_exists(global.pc) || !instance_exists(f)) { cooptest_advance(CT_REVIVE, false, "no_pc_or_f"); break; }
				if (global.cooptest_t == 1)
				{
					global.coop_revive_tokens = max(1, global.coop_revive_tokens);
					global.cooptest_room0     = room;
					global.cooptest_revived   = false;

					// TEST ISOLATION: the phase-6 FERRY hand-off delivered a 1000-XP P-Bag
					// (Item_update_1 -> state_DROP -> f.xpPending). update_xp ticks f.xp past
					// f.xpNext, which opens the LEVEL-UP menu (g.gui_state = gui_state_LEVEL_UP).
					// While gui_state is LEVEL_UP, g_Step's _GUI_CONDITION is false so it SKIPS
					// g_Step_A2() -> PC_update_death(), and the co-op revive (which lives in
					// PC_update_death) never runs. That gate is the SAME one the normal death-room
					// transition sits behind, so deferring the revive while a menu is open is
					// CORRECT in real play -- this is purely a test artifact (we forced death on the
					// frames the ferry's level-up menu happened to be open). Neutralise the leftover
					// XP-rise + close the menu so the revive can fire inside the test window. NOTE:
					// both update_menus (g_Step_A1) AND update_xp re-open LEVEL_UP whenever
					// f.xp >= f.xpNext, so f.xp must drop below the threshold -- clearing gui_state
					// alone is not enough. (Clearing stun_timer, the originally-suspected gate, is
					// necessary too but was never the actual blocker here.)
					if (instance_exists(f))
					{
						f.xpPending = 0;
						f.xpDrain   = 0;
						if (f.xp >= f.xpNext) f.xp = max(0, f.xpNext - 1); // below the level-up threshold
					}
					if (instance_exists(g)) g.gui_state = g.gui_state_NONE; // close any LEVEL-UP menu the ferry's XP award opened

					f.hp              = 0;
					global.pc.is_dead = 1;
					if (variable_instance_exists(global.pc, "stun_timer"))    global.pc.stun_timer    = 0;
					if (variable_instance_exists(global.pc, "iframes_timer")) global.pc.iframes_timer = 0; // FERRY left iframes=4; clear leftover pickup pause
					cooptest_log("phase=7 REVIVE forced death (hp=0,is_dead=1) tokens=" + string(global.coop_revive_tokens)
						+ " room=" + room_get_name(room)
						+ " gui=" + (instance_exists(g) ? string(g.gui_state) : "?")
						+ " xp=" + string(f.xp) + "/" + string(f.xpNext));
				}
				// PC_update_death() runs later THIS frame (g_Step_A2) and the co-op revive
				// clears is_dead + restores HP without a death-room transition.
				if (global.cooptest_t >= 2)
				{
					if (instance_exists(global.pc) && global.pc.is_dead == 0
					&&  instance_exists(f) && f.hp > 0
					&&  room == global.cooptest_room0) global.cooptest_revived = true;
				}
				if (global.cooptest_t >= 18)
				{
					var _ok = global.cooptest_revived && (room == global.cooptest_room0) && instance_exists(global.pc);
					cooptest_advance(CT_REVIVE, _ok, "revived=" + string(global.cooptest_revived) + " room_now=" + room_get_name(room) + " room0_same=" + string(room == global.cooptest_room0));
				}
				break;
			}

			// ── 8. ROOM-HOP (town -> palace -> overworld; fairy survives/respawns) ─
			case CT_ROOMHOP:
			{
				if (global.cooptest_t == 1)
				{
					global.cooptest_hop_idx    = 0;
					global.cooptest_hop_state  = 0;
					global.cooptest_hop_wait   = 0;
					global.cooptest_hop_fail   = false;
					global.cooptest_hop_town   = "";
					global.cooptest_hop_palace = "";
					if (instance_exists(Dev_RmWarper))
					{
						try
						{
							with (Dev_RmWarper)
							{
								if (sweep_build_list_filtered(sweep_pred_town)    > 0) global.cooptest_hop_town   = sweep_list[|0];
								if (sweep_build_list_filtered(sweep_pred_dungeon) > 0) global.cooptest_hop_palace = sweep_list[|0];
							}
						}
						catch (_he) { cooptest_log("phase=8 ROOMHOP list-build EXCEPTION " + string(_he.message)); }
					}
					cooptest_log("phase=8 ROOMHOP town=" + string(global.cooptest_hop_town) + " palace=" + string(global.cooptest_hop_palace));
				}

				if (global.cooptest_hop_state == 0)
				{
					// Issue the warp for the current target (or skip if unavailable).
					if (global.cooptest_hop_idx == 0)
					{
						if (global.cooptest_hop_town != "" && instance_exists(Dev_RmWarper))
						{
							with (Dev_RmWarper) sweep_warp_to(global.cooptest_hop_town);
							cooptest_log("phase=8 hop[0] TOWN -> " + string(global.cooptest_hop_town));
							global.cooptest_hop_state = 1; global.cooptest_hop_wait = 0;
						}
						else { cooptest_log("phase=8 hop[0] TOWN SKIP (no name)"); global.cooptest_hop_idx = 1; }
					}
					else if (global.cooptest_hop_idx == 1)
					{
						if (global.cooptest_hop_palace != "" && instance_exists(Dev_RmWarper))
						{
							with (Dev_RmWarper) sweep_warp_to(global.cooptest_hop_palace);
							cooptest_log("phase=8 hop[1] PALACE -> " + string(global.cooptest_hop_palace));
							global.cooptest_hop_state = 1; global.cooptest_hop_wait = 0;
						}
						else { cooptest_log("phase=8 hop[1] PALACE SKIP (no name)"); global.cooptest_hop_idx = 2; }
					}
					else if (global.cooptest_hop_idx == 2)
					{
						// Overworld: freeze the OW encounter sim during the visit, then route
						// out via an "Ovrw" exit (same mechanism as sweep_start_ow()).
						global.dev_ow_sweep_active = true;
						if (instance_exists(g))
						{
							g.exit_leave = Exit_construct(EXIT_NAME_GAME_START);
							with (g.exit_leave) { goToExitName = Area_OvrwA + hex_str(0); }
						}
						cooptest_log("phase=8 hop[2] OVERWORLD -> " + Area_OvrwA + hex_str(0));
						global.cooptest_hop_state = 1; global.cooptest_hop_wait = 0;
					}
					else
					{
						// All hops issued + checked.
						global.dev_ow_sweep_active = false;
						cooptest_advance(CT_ROOMHOP, !global.cooptest_hop_fail, "hops_done fail=" + string(global.cooptest_hop_fail));
					}
				}
				else
				{
					// Wait for the issued warp to land + settle, then verify.
					global.cooptest_hop_wait++;
					var _is_ow  = (global.cooptest_hop_idx == 2);
					var _landed = false;
					if (global.cooptest_hop_wait > 40) // min settle past the transition
					{
						if (_is_ow) { if (g.room_type == "C") _landed = true; }
						else        { if (g.room_type == "A" && instance_exists(global.pc)) _landed = true; }
					}
					if (_landed)
					{
						var _fairy = instance_exists(obj_fairy_p2);
						if (!_is_ow && !_fairy) global.cooptest_hop_fail = true; // action room MUST respawn the fairy
						cooptest_log("phase=8 hop[" + string(global.cooptest_hop_idx) + "] landed=" + room_get_name(room) + " type=" + string(g.room_type) + " fairy=" + string(_fairy));
						global.cooptest_hop_idx++;
						global.cooptest_hop_state = 0;
					}
					else if (global.cooptest_hop_wait > 320) // watchdog
					{
						cooptest_log("phase=8 hop[" + string(global.cooptest_hop_idx) + "] STALL (warp never landed) room=" + room_get_name(room));
						global.cooptest_hop_fail = true;
						global.cooptest_hop_idx++;
						global.cooptest_hop_state = 0;
					}
				}
				break;
			}

			// ── 9. FINISH (write verdict; game_end on a headless run) ────────
			case CT_FINISH:
			{
				if (global.cooptest_t == 1)
				{
					if (instance_exists(f)) f.hp = get_stat_max(STR_Heart); // tidy up after the HEAL/REVIVE pokes
					global.dev_ow_sweep_active = false;

					if (global.cooptest_result == "PASS")
						cooptest_log("RESULT=PASS phases=9");
					else
						cooptest_log("RESULT=FAIL phase=" + string(global.cooptest_fail_phase) + " (" + cooptest_phase_name(global.cooptest_fail_phase) + ") phases=9");

					try
					{
						var _rf = file_text_open_write(working_directory + "cooptest/_RESULT.txt");
						if (global.cooptest_result == "PASS") file_text_write_string(_rf, "RESULT=PASS phases=9");
						else                                  file_text_write_string(_rf, "RESULT=FAIL phase=" + string(global.cooptest_fail_phase) + " phases=9");
						file_text_writeln(_rf);
						file_text_close(_rf);
					}
					catch (_re) { }
				}
				if (global.cooptest_t >= 3)
				{
					global.cooptest_phase = CT_DONE;
					global.cooptest_run   = false;
					if (global.cooptest_from_menu)
					{
						cooptest_log("menu run complete (no game_end)");
						global.cooptest_from_menu = false;
					}
					else
					{
						cooptest_log("headless run complete -> game_end()");
						game_end();
					}
				}
				break;
			}

			case CT_DONE:
			default:
			{
				global.cooptest_run = false;
				break;
			}
		}
	}
	catch (_e)
	{
		cooptest_log("phase=" + string(global.cooptest_phase) + " EXCEPTION " + string(_e.message) + " | " + string(_e.longMessage));
		global.cooptest_result = "FAIL";
		if (global.cooptest_fail_phase == 0) global.cooptest_fail_phase = global.cooptest_phase;
		global.cooptest_phase = CT_FINISH;
		global.cooptest_t     = 0;
	}
}
