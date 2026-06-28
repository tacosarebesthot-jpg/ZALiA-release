/// @description  Dev_Bugprobe_Step()
function Dev_Bugprobe_Step() {


	// ============================================================
	// DEV BUG PROBE HARNESS  (added 2026-06-22)
	//   Additive, DEV+flag gated diagnostic harness. Produces runtime evidence
	//   for several reported bugs and writes a structured text report to
	//   working_directory + "bugprobe/report.txt".
	//
	//   Trigger: DEV must be true AND working_directory + "_bugprobe.flag" must
	//   exist (mirrors the existing "_autosweep.flag" pattern in g_Create/g_Step).
	//   Runs ALONGSIDE the existing autosweep auto-pilot (boot -> file select ->
	//   load save 1) so the probes have a live game to observe; it does not
	//   replace or alter the autosweep's own behavior.
	//
	//   Called bare (no with()) from g_Step(), so self == g here, same as
	//   update_QuitAppMenu()/update_change_room() are called. room_type, f,
	//   gui_state etc. resolve through g exactly like the rest of g_Step.
	//
	//   PROBE BUG5 (wrong overworld exit) does NOT live in this switch -- its
	//   log call is inline in update_change_room_1a.gml (one line per room
	//   change, via dev_bugprobe_bug5_log()). PROBE BUG6 (OW walk stutter) DOES
	//   live here: it drives its own warp into the overworld and a virtual
	//   held-Right press, then logs ~48 per-frame samples.
	// ============================================================
	if (!(DEV && global.bugprobe)) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


	global.bugprobe_t++;


	// ---- shared report-file helper -----------------------------------------
	// (kept local; this is the only place that writes bugprobe/report.txt)
	// NOTE: assigned fresh each call (not "static ... = function") -- there is no
	// existing precedent for a static function-var inside a script function anywhere
	// else in this codebase, so this avoids relying on an unverified GML pattern.
	var _bp_log = function(_line) {
		directory_create(working_directory + "bugprobe");
		var _f = file_text_open_append(working_directory + "bugprobe/report.txt");
		file_text_write_string(_f, _line);
		file_text_writeln(_f);
		file_text_close(_f);
	}


	// ---- shared machine-readable verdict helper -----------------------------
	// Writes ONE grep-friendly line via the SAME _bp_log writer above (no second
	// file handle). Format: "RESULT  id=<id>  status=<PASS|FAIL|SKIP>  <detail>"
	// NOTE: anonymous function-vars in GML do NOT close over sibling local vars
	// (no lexical capture of _bp_log) -- calling _bp_log(...) as a bare identifier
	// from inside this function's body throws "variable not found" at runtime,
	// which the global exception_unhandled_handler (g_Create.gml) silently
	// swallows -- that's why no RESULT line ever reached report.txt. Fix: pass
	// the writer in explicitly as a function-value argument (a normal value
	// pass, not a scope capture) so bp_result calls the SAME writer instance.
	var bp_result = function(_log_fn, _id, _status, _detail) {
		_log_fn("RESULT  id=" + _id + "  status=" + _status + "  " + _detail);
	}


	// ------------------------------------------------------------------------
	// One-time setup: stamp the report file so re-runs are easy to tell apart.
	if (!global.bugprobe_started)
	{
		global.bugprobe_started = true;
		directory_create(working_directory + "bugprobe");
		_bp_log("BUGPROBE_START  t=" + string(global.bugprobe_t) + "  room=" + room_get_name(room));
	}


	// ------------------------------------------------------------------------
	// PROBE LAYERING + PROBE PALETTE: both need a live save loaded and the PC
	// in gameplay. Use the same room_type=="A" gate the autosweep uses, plus
	// a guard so each probe only fires ONCE (no spam every frame).
	if (g.room_type == "A"
	&&  instance_exists(f)
	&&  instance_exists(global.pc) )
	{
		// ---- PROBE PALETTE: fires once, as soon as a save is live ----------
		if (!global.bugprobe_palette_done)
		{
			global.bugprobe_palette_done = true;

			var _rando_state = "?";
			if (variable_instance_exists(g, "RandoPalette_state")) _rando_state = string(g.RandoPalette_state); // RandoPalette_state is an instance var on g, not a global

			var _save_setting = "undefined";
			if (variable_global_exists("dm_save_file_settings")
			&&  !is_undefined(global.dm_save_file_settings)
			&&  ds_exists(global.dm_save_file_settings, ds_type_map) )
			{
				var _v = global.dm_save_file_settings[?STR_Randomize+STR_Palette];
				if (!is_undefined(_v)) _save_setting = string(_v);
			}

			// Does f.dm_rando contain ANY key mentioning "_Palette"?
			var _rando_has_palette_keys = "no";
			if (instance_exists(f) && ds_exists(f.dm_rando, ds_type_map))
			{
				var _k = ds_map_find_first(f.dm_rando);
				while (!is_undefined(_k))
				{
					if (string_pos(STR_Palette, _k) > 0)
					{
						_rando_has_palette_keys = "yes (key=" + _k + ")";
						break;
					}
					_k = ds_map_find_next(f.dm_rando, _k);
				}
			}

			_bp_log("PROBE PALETTE: g.RandoPalette_state=" + _rando_state
			      + "  save_setting[" + (STR_Randomize+STR_Palette) + "]=" + _save_setting
			      + "  f.dm_rando_has_Palette_keys=" + _rando_has_palette_keys
			      + "  room=" + g.rm_name);

			// STRETCH (programmatic 2nd-file differential) intentionally SKIPPED:
			// creating/loading a second save file from inside a live probe run
			// risks clobbering the user's actual save slots (file_save/file_load
			// operate on fixed slot numbers, not sandboxed copies). The static
			// root cause is already known (g.RandoPalette_state is a GLOBAL pref
			// persisted in UserPreferences.txt, not per-save), so logging the
			// current state robustly (above) is sufficient evidence without that
			// risk. See report line "PROBE PALETTE SKIP" below.
			_bp_log("PROBE PALETTE SKIP: differential (2nd rando file) skipped -- risk of corrupting real save slots; root cause already static (UserPreferences.txt global leak)");

			// ---- PROBE PALETTE verdict ---------------------------------------
			// Precondition: this probe block only runs once a save is live (it's
			// nested inside the outer "g.room_type=='A' && instance_exists(f) &&
			// instance_exists(global.pc)" gate above), so reaching here already
			// satisfies "a save is live". If g.RandoPalette_state could not be
			// read (variable missing), report SKIP instead of guessing PASS/FAIL.
			if (_rando_state == "?")
			{
				bp_result(_bp_log, "bug4.palette", "SKIP", "reason=RandoPalette_state_not_found");
			}
			else if (_rando_state == "0")
			{
				bp_result(_bp_log, "bug4.palette", "PASS", "rando_palette_state=" + _rando_state + " persave_setting=" + _save_setting);
			}
			else
			{
				bp_result(_bp_log, "bug4.palette", "FAIL", "rando_palette_state=" + _rando_state + " persave_setting=" + _save_setting);
			}
		}


		// ---- PROBE LAYERING: fires once, but only once we're actually ------
		// standing in the North Castle / throne room (Area_WestA rm 00), where
		// the Zelda + TorchA scene is. The autosweep autopilot always passes
		// through this room first (it's EXIT_NAME_GAME_START / the spawn room),
		// so no extra warp is needed -- just wait for the autopilot to land here.
		if (!global.bugprobe_layering_done
		&&  g.rm_name == RM_NAME_NPALACE
		&&  (instance_exists(Zelda) || instance_exists(TorchA)) ) // wait until the cutscene GameObjects have spawned (they're created a few frames after room start)
		{
			global.bugprobe_layering_done = true;

			_bp_log("PROBE LAYERING: room=" + g.rm_name + "  (North Castle / throne scene)");

			var _objs = [Lonk, Zelda, TorchA, Cutscene_FloorTrap_1];
			var _nm   = ["Lonk/PC", "Zelda", "TorchA", "FloorTrap"];
			for (var _o = 0; _o < array_length(_objs); _o++)
			{
				var _any = false;
				with (_objs[_o])
				{
					_any = true;
					var _lyr  = layer;
					var _ln   = "none";
					var _ld   = "?";
					if (is_real(_lyr) && layer_exists(_lyr))
					{
						_ln = layer_get_name(_lyr);
						_ld = string(layer_get_depth(_lyr));
					}
					_bp_log("PROBE LAYERING: obj=" + _nm[_o]
					      + "  depth=" + string(depth)
					      + "  layer=" + _ln
					      + "  layer_depth=" + _ld
					      + "  x=" + string(x)
					      + "  y=" + string(y));
				}
				if (!_any) _bp_log("PROBE LAYERING: obj=" + _nm[_o] + "  (no instance in room)");
			}

			// DIAGNOSTIC: why is the PC at depth 0? capture depth_def + cutscene/lock state.
			var _pc_d = "?";
			var _pc_dd = "?";
			if (instance_exists(global.pc))
			{
				_pc_d = string(global.pc.depth);
				if (variable_instance_exists(global.pc, "depth_def")) _pc_dd = string(global.pc.depth_def);
			}
			var _cut = "?";
			if (variable_instance_exists(g, "cutscene")) _cut = string(g.cutscene);
			var _cut_ge = "?";
			if (variable_instance_exists(g, "CUTSCENE_GAME_END_1A")) _cut_ge = string(g.CUTSCENE_GAME_END_1A);
			var _lock = "?";
			if (variable_instance_exists(g, "pc_lock")) _lock = string(g.pc_lock);
			_bp_log("PROBE LAYERING DIAG: global.pc.depth=" + _pc_d
			      + " depth_def=" + _pc_dd
			      + " DEPTH_PC_MAIN=" + string(DEPTH_PC_MAIN)
			      + " g.cutscene=" + _cut
			      + " CUTSCENE_GAME_END_1A=" + _cut_ge
			      + " g.pc_lock=" + _lock
			      + " GE_inst=" + string(instance_exists(Cutscene_GameEnd_1A)) );

			// ---- PROBE LAYERING verdict --------------------------------------
			// Precondition: all three objects (PC, Zelda, TorchA) must exist to
			// compare depths meaningfully. Each instance-global deref below has
			// its OWN instance_exists guard (no compound assumption).
			if (!instance_exists(global.pc) || !instance_exists(Zelda) || !instance_exists(TorchA))
			{
				bp_result(_bp_log, "bug1.layering", "SKIP", "reason=objects_not_present");
			}
			else
			{
				var _v_pc    = global.pc.depth;
				var _v_zelda = Zelda.depth;
				var _v_torch = TorchA.depth;

				if (_v_pc < _v_zelda && _v_pc < _v_torch)
				{
					bp_result(_bp_log, "bug1.layering", "PASS", "pc_depth=" + string(_v_pc) + " zelda_depth=" + string(_v_zelda) + " torch_depth=" + string(_v_torch) + " expected=pc<others(ideal -33)");
				}
				else
				{
					bp_result(_bp_log, "bug1.layering", "FAIL", "pc_depth=" + string(_v_pc) + " zelda_depth=" + string(_v_zelda) + " torch_depth=" + string(_v_torch) + " expected=pc<others(ideal -33)");
				}
			}

			// Reuse the existing screen-capture path (Dev_RmWarper's sweep dir).
			if (instance_exists(Dev_RmWarper))
			{
				screen_save(working_directory + Dev_RmWarper.SWEEP_DIR + "bugprobe_layering_" + g.rm_name + ".png");
				_bp_log("PROBE LAYERING: screenshot=" + Dev_RmWarper.SWEEP_DIR + "bugprobe_layering_" + g.rm_name + ".png");
			}
		}
	}


	// ------------------------------------------------------------------------
	// PROBE WALK: overworld scroll engagement + one-shot timing sample of
	// Overworld_refresh_tiles via the per-tile-boundary call site in
	// Overworld_Step.gml. The actual get_timer() wrap lives there (guarded by
	// global.bugprobe_walk_timed so it only fires once); here we just log the
	// O(1)-engaged flag every time we first see the overworld, plus the timing
	// result once Overworld_Step has filled it in.
	if (g.room_type == "C" && instance_exists(global.OVERWORLD))
	{
		if (!global.bugprobe_walk_done)
		{
			global.bugprobe_walk_done = true;
			var _engaged_str = "no (fallback per-tile loop)";
			var _tile_layer_val = -1;
			if (instance_exists(global.OVERWORLD) && variable_instance_exists(global.OVERWORLD, "ow_tile_layer"))
			{
				_tile_layer_val = global.OVERWORLD.ow_tile_layer;
				if (_tile_layer_val != -1) _engaged_str = "yes";
			}
			_bp_log("PROBE WALK: ow_tile_layer=" + string(_tile_layer_val)
			      + "  O1_scroll_engaged=" + _engaged_str );
		}

		// Overworld_Step.gml sets global.bugprobe_walk_us once its guarded
		// one-shot timing sample completes; flush it to the report as soon as
		// it shows up (it's a single number, not a per-frame log).
		if (variable_global_exists("bugprobe_walk_us")
		&&  global.bugprobe_walk_us >= 0
		&& !global.bugprobe_walk_us_logged )
		{
			global.bugprobe_walk_us_logged = true;
			_bp_log("PROBE WALK: Overworld_refresh_tiles one-shot timing = " + string(global.bugprobe_walk_us) + " microseconds");
		}
	}


	// ------------------------------------------------------------------------
	// PROBE BUG6: Link-OW-walk-stutter capture. Drives its OWN warp into the
	// overworld (Dev_RmWarper.sweep_start_ow(), the same machinery the OW page
	// sweep uses), then holds a virtual Right press (global.dev_inject_hv,
	// consumed in Input_update2a.gml the same frame, same convention as
	// dev_inject_pause) for ~48 frames while logging per-frame draw/scroll
	// numbers via dev_bugprobe_bug6_log_frame(). Runs independently of PROBE
	// WALK above (that one just observes whatever overworld state it finds;
	// this one actively gets there and drives movement).
	//
	// States: 0=idle (wait for stable action-room gameplay), 1=warping to OW
	// (wait for room_type=="C", with a stall watchdog), 2=driving the 48-frame
	// walk + logging, 3=waiting for the overworld to actually be READY to accept
	// movement input (see READY gate below), done via global.bugprobe_bug6_done.
	if (!global.bugprobe_bug6_done)
	{
		switch (global.bugprobe_bug6_state)
		{
			case 0: // idle: wait for stable conditions, then warp to OW (or use existing OW if TILEBLEED left us there)
			// EXITVERIFY/BLEEDVERIFY (revert: drop the two bugprobe_exitresolve_done/bugprobe_tilebleed_done
			// terms below). SERIALIZE the warp-driving probes: EXITRESOLVE -> TILEBLEED -> BUG6 each own
			// g.exit_leave, so BUG6 must not arm its OW warp until both new probes have finished their warps,
			// otherwise their competing g.exit_leave writes clobber each other mid-transition.
			if (instance_exists(f)
			&&  instance_exists(global.pc)
			&&  g.gui_state == g.gui_state_NONE
			&&  global.bugprobe_exitresolve_done
			&&  global.bugprobe_tilebleed_done
			&&  instance_exists(Dev_RmWarper) )
			{
				if (g.room_type == "A")
				{
					_bp_log("PROBE BUG6: arming OW warp from room=" + g.rm_name);
					with (Dev_RmWarper) sweep_start_ow(); // triggers the RM->Overworld room transition (async)
					global.bugprobe_bug6_state   = 1;
				}
				else if (g.room_type == "C" && instance_exists(global.OVERWORLD))
				{
					// TILEBLEED left us in the OW; skip the warp and drive directly from here
					_bp_log("PROBE BUG6: already in OW (TILEBLEED left us here), skipping warp");
					if (instance_exists(Dev_RmWarper)) with (Dev_RmWarper) sweep_stop();
					global.bugprobe_bug6_state   = 3; // jump to READY gate
				}
				global.bugprobe_bug6_stall_t = 0;
			}
			break;

			case 1: // waiting for the room transition to land in the Overworld
			global.bugprobe_bug6_stall_t++;
			if (g.room_type == "C" && instance_exists(global.OVERWORLD))
			{
				// Freeze the OW page-sweep's own auto-advance (Dev_RmWarper_Room_Start already
				// warped us to page 0's center via sweep_warp_to_ow) so we stand still on a
				// normal walkable page instead of paging through the whole map.
				if (instance_exists(Dev_RmWarper)) with (Dev_RmWarper) sweep_stop();

				_bp_log("PROBE BUG6: reached overworld. room_type=" + g.room_type
				      + "  ow_pc_xy(0)=" + string(ow_pc_xy(0))
				      + "  viewXC()=" + string(viewXC()) );

				// Do NOT start driving yet -- the room transition just landed and
				// Overworld_Step() (the function that reads Input.heldHV and sets
				// dest_dist/move_x) is SKIPPED entirely while g.ChangeRoom_timer>0
				// (g_Step.gml: "if(!update_change_room()) ... case 'C': Overworld_Step()").
				// g.ChangeRoom_timer starts at ChangeRoom_ENTER_DURATION1 ($22 = 34
				// frames) on room entry, so injecting heldHV right now would just be
				// ignored for ~34 frames (exactly the all-zero-frame symptom seen in
				// the last run). Move to a READY-wait state instead of driving.
				global.bugprobe_bug6_stall_t = 0;
				global.bugprobe_bug6_state   = 3;
			}
			else if (global.bugprobe_bug6_stall_t > 300) // ~5s: OW entry never landed -- bail so the run still ends
			{
				_bp_log("PROBE BUG6 SKIP: overworld warp stalled (room=" + g.rm_name + ", room_type=" + g.room_type + ")");
				global.dev_inject_hv      = 0;
				global.bugprobe_bug6_done = true;
			}
			break;

			case 3: // READY gate: poll until the overworld will actually act on heldHV
			global.bugprobe_bug6_stall_t++;
			if (g.room_type == "C"
			&&  instance_exists(global.OVERWORLD)
			&&  g.ChangeRoom_timer <= 0       // Overworld_Step() is only called once this clears
			&&  global.OVERWORLD.dest_dist == 0
			&& !global.OVERWORLD.Warp_is_warping
			&& !g.overworld_paused )
			{
				_bp_log("PROBE BUG6: overworld READY (ChangeRoom_timer=" + string(g.ChangeRoom_timer)
				      + ")  -- starting walk-drive after " + string(global.bugprobe_bug6_stall_t) + " wait frames");

				global.dev_inject_hv       = $1; // $1 = R = NES d-pad RIGHT (Input_Create.gml; matches Input.heldHV bit layout)
				global.bugprobe_bug6_frame = 0;
				global.bugprobe_bug6_state = 2;
			}
			else if (global.bugprobe_bug6_stall_t > 300) // ~5s: overworld never settled -- bail cleanly, no 48 frozen frames
			{
				var _crt_str = "?";
				if (instance_exists(global.OVERWORLD)) _crt_str = string(g.ChangeRoom_timer);

				_bp_log("PROBE BUG6: SKIP (overworld never settled)  room_type=" + g.room_type
				      + "  OVERWORLD_exists=" + string(instance_exists(global.OVERWORLD))
				      + "  ChangeRoom_timer=" + _crt_str
				      + "  overworld_paused=" + string(g.overworld_paused) );
				global.dev_inject_hv      = 0;
				global.bugprobe_bug6_done = true;
			}
			break;

			case 2: // drive ~48 frames of held-Right, logging each one
			dev_bugprobe_bug6_log_frame();
			global.bugprobe_bug6_frame++;
			if (global.bugprobe_bug6_frame >= 48)
			{
				global.dev_inject_hv = 0; // release the virtual press
				_bp_log("PROBE BUG6: walk-drive finished (" + string(global.bugprobe_bug6_frame) + " frames logged) -- waiting for natural OW exit");
				global.bugprobe_bug6_stall_t = 0;
				global.bugprobe_bug6_state   = 4; // recovery: wait for OW exit or force title re-drive
			}
			break;

			case 4: // recovery: wait for natural OW->action exit; if stuck, force goto_title_rm()
			global.bugprobe_bug6_stall_t++;
			if (g.room_type == "A")
			{
				_bp_log("PROBE BUG6: exited OW naturally, room=" + g.rm_name + " -- done");
				global.bugprobe_bug6_done = true;
			}
			else if (global.bugprobe_bug6_stall_t > 180) // ~3s: no natural exit
			{
				_bp_log("PROBE BUG6: OW stuck after walk-drive -- calling goto_title_rm() to re-drive");
				goto_title_rm();
				global.bugprobe_bug6_stall_t = 0;
				global.bugprobe_bug6_state   = 5;
			}
			break;

			case 5: // wait for title re-drive autopilot to return us to gameplay
			if (g.room_type == "A")
			{
				_bp_log("PROBE BUG6: re-drive complete, room=" + g.rm_name + " -- done");
				global.bugprobe_bug6_done = true;
			}
			break;
		}
	}


	// ------------------------------------------------------------------------
	// PROBE STARTQUIT: the quit-sink instrumentation itself lives inline at each
	// sink (update_QuitAppMenu's two game_end() calls + the will_go_to_continuesave
	// branch, ContinueSaveScreen_step's QUIT/SAVE options, goto_title_rm,
	// PauseMenu_GameEnd) -- they each call dev_bugprobe_quit_sink_log() (its own
	// script -- see scripts/dev_bugprobe_quit_sink_log/) unconditionally; that
	// helper is itself DEV+flag gated so it's a no-op everywhere else.
	//
	// STRETCH: drive a double-Start once we're sure we have a live PC in an
	// action room, then again ~2 frames later while in the overworld, logging
	// gui_state/menu_state around each press. This piggybacks on the SAME
	// global.dev_inject_pause hook the autosweep autopilot already uses to
	// drive virtual button presses (see g_Step.gml's AUTOSWEEP block + the
	// dev_inject_pause consumer in Input_update2a.gml), so it cannot conflict
	// with the autopilot (we wait until autosweep has already started the
	// room sweep before injecting, and we only ever set it on a single frame
	// at a time, same as the autopilot itself does).
	if (instance_exists(f) && instance_exists(global.pc))
	{
		switch (global.bugprobe_startquit_state)
		{
			case 0: // idle: wait for a stable action-room gameplay frame
			if (g.room_type == "A"
			&&  g.gui_state == g.gui_state_NONE
			&& (!instance_exists(global.OVERWORLD) || !global.OVERWORLD.flute_timer) )
			{
				_bp_log("PROBE STARTQUIT: arming double-press #1 in room=" + g.rm_name + " gui_state=" + string(g.gui_state));
				global.bugprobe_startquit_state = 1;
			}
			break;

			case 1: // press #1
			_bp_log("PROBE STARTQUIT: PRESS#1 before  room=" + g.rm_name + " gui_state=" + string(g.gui_state));
			global.dev_inject_pause = true;
			global.bugprobe_startquit_state  = 2;
			global.bugprobe_startquit_timer  = 2; // wait 2 frames before press #2, per spec
			break;

			case 2: // cool-down between presses; log the after-state of press #1 next frame
			_bp_log("PROBE STARTQUIT: PRESS#1 after   room=" + g.rm_name + " gui_state=" + string(g.gui_state));
			global.bugprobe_startquit_state = 3;
			break;

			case 3:
			if (global.bugprobe_startquit_timer > 0)
			{
				global.bugprobe_startquit_timer--;
			}
			else
			{
				_bp_log("PROBE STARTQUIT: PRESS#2 before  room=" + g.rm_name + " gui_state=" + string(g.gui_state));
				global.dev_inject_pause = true;
				global.bugprobe_startquit_state = 4;
			}
			break;

			case 4:
			_bp_log("PROBE STARTQUIT: PRESS#2 after   room=" + g.rm_name + " gui_state=" + string(g.gui_state));
			global.bugprobe_startquit_state = 5;
			break;

			case 5: // drain: close stuck-open menu; safe only while still in an action room
			if (g.room_type != "A")
			{
			    // Room changed (OW warp etc.) -- PauseMenu context is gone, stop injecting
			    _bp_log("PROBE STARTQUIT: done (left action room, menu context discarded)");
			    global.bugprobe_startquit_state = 6;
			}
			else if (g.gui_state != g.gui_state_NONE)
			{
			    global.dev_inject_pause = true; // close the stuck-open menu
			}
			else
			{
			    _bp_log("PROBE STARTQUIT: done (gui_state cleared)");
			    global.bugprobe_startquit_state = 6;
			}
			break;

			case 6: // done
			break;
		}
	}


	// ------------------------------------------------------------------------
	// PROBE EXITRESOLVE: verify the direction-aware exit-selection fix in
	// PC_update_1c.gml (the "EXIT-FIX" block). At multi-page screen seams the
	// right/left exit hitboxes OVERLAP, and GMS2's instance enumeration order
	// differs from GM1.4 -- the old break-on-first-overlap grabbed the WRONG
	// neighbor and fell through to the throne room. The fix scans ALL overlapping
	// open exits and picks the one whose Exit.side matches the held direction.
	//
	// This probe drives its OWN warp through a fixed list of multi-page rooms
	// (the throne room + the user-flagged West_A rooms + two Town_A rooms),
	// waits for that room's Exit instances to spawn, and for EVERY spawned Exit E
	// re-runs the EXACT selection the fixed PC_update_1c does -- but instead of
	// driving the PC with (flaky) input, it directly exercises the selection:
	// it places a player-sized test rect at E's own hitbox center and sets the
	// effective held direction = E.side, then asserts the scan resolves to an
	// exit whose goToExitName equals E's OWN goToExitName (walking toward E
	// resolves to E, not a seam-overlapping neighbor). goToExitName is the
	// GM1.4-byte-identical destination (from g.dm_rm[?exitName+"_goto_reen"]),
	// so a matching target == GM1.4-correct.
	//
	// EXITVERIFY (revert: delete this whole block + the 11 globals in g_Create).
	if (!global.bugprobe_exitresolve_done)
	{
		// Fixed room list. MUST include the 3-page throne room (_WestA_00), the
		// West_A rooms the user flagged, and two Town_A rooms. Multi-page rooms
		// are where overlapping seams (and the bug) live.
		var _ER_ROOMS = [ Area_WestA+"00",   // throne room (3 pages) -- the wrong-exit fall-through target
		                  Area_WestA+"03",    // user-flagged
		                  Area_WestA+"29",
		                  Area_WestA+"2B",
		                  Area_WestA+"39",
		                  Area_WestA+"1D",
		                  Area_WestA+"22",
		                  Area_TownA+"01",
		                  Area_TownA+"08" ];
		var _ER_N = array_length(_ER_ROOMS);

		switch (global.bugprobe_exitresolve_state)
		{
			case 0: // idle: wait for a stable action-room gameplay frame + the warper
			// EXITVERIFY (revert: drop the bugprobe_startquit_state term). Let the STARTQUIT double-press
			// sequence finish in the spawn room BEFORE we start warping, so its pause-injection can't open
			// a menu mid-transition. After this, EXITRESOLVE owns the warp pipeline until it's done.
			if (instance_exists(f)
			&&  instance_exists(global.pc)
			&&  g.room_type == "A"
			&&  g.gui_state == g.gui_state_NONE
			&&  global.bugprobe_startquit_state >= 6
			&&  instance_exists(Dev_RmWarper) )
			{
				_bp_log("PROBE EXITRESOLVE: arming. rooms=" + string(_ER_N) + "  from room=" + g.rm_name);
				global.bugprobe_exitresolve_idx    = 0;
				global.bugprobe_exitresolve_wait_t = 0;
				global.bugprobe_exitresolve_tested = false;
				// issue the first warp
				with (Dev_RmWarper)
				{
					Dev_RmWarper_update_1a(_ER_ROOMS[0]); // fills dl_Rm_ExitIDs for this scene
					if (ds_list_size(dl_Rm_ExitIDs) > 0) sweep_warp_to(_ER_ROOMS[0] + hex_str(dl_Rm_ExitIDs[|0]));
				}
				global.bugprobe_exitresolve_state = 2;
			}
			break;

			case 2: // wait for the warp to land + this room's exits to spawn, then test ALL exits ONCE
			global.bugprobe_exitresolve_wait_t++;
			var _ER_TARGET = _ER_ROOMS[global.bugprobe_exitresolve_idx];

			// landed in the right action scene with exits spawned AND the transition
			// fully settled? g.ChangeRoom_timer<=0 means g_Room_Start (which spawns +
			// finalizes Exit geometry, incl. the multi-page BodyHB re-write) is done.
			// A few extra settle frames guard against reading mid-spawn geometry.
			if (!global.bugprobe_exitresolve_tested
			&&  g.room_type == "A"
			&&  g.rm_name == _ER_TARGET
			&&  g.ChangeRoom_timer <= 0
			&&  global.bugprobe_exitresolve_wait_t >= 8
			&&  instance_exists(Exit) )
			{
				global.bugprobe_exitresolve_tested = true; // latch: test this room ONCE
				global.bugprobe_exitresolve_rooms++;

				// ---- per-exit selection test (mirrors PC_update_1c's EXIT-FIX scan) ----
				with (Exit)
				{
					var _E_side = side;
					var _E_goto = string(goToExitName);

					// player-sized test rect centered on THIS exit's hitbox (a point
					// guaranteed inside E). _W=$10 matches PC_update_1c's player width.
					var _W  = $10;
					var _H  = max(hh, 1);
					var _XL = xc - (_W >> 1);
					var _YT = yc - (_H >> 1);

					// simulate "the player walked toward E": effective held dir = E.side
					var _held = _E_side & $F;

					// run the SAME selection: first overlap = fallback; first
					// side-matching overlap wins. Also count OTHER overlapping exits.
					var _sel      = noone;
					var _sel_dir  = noone;
					var _overlap  = 0;
					with (Exit)
					{
						if (open
						&&  rectInRect(BodyHB_xl, BodyHB_yt, BodyHB_w, BodyHB_h, _XL, _YT, _W, _H) )
						{
							if (_sel == noone) _sel = id;
							if (_sel_dir == noone && _held && (side & _held)) _sel_dir = id;
							if (id != other.id) _overlap++; // an OTHER open exit overlaps E's test rect
						}
					}
					if (_sel_dir != noone) _sel = _sel_dir;

					var _side_str = "MID";
					if      (_E_side & $1) _side_str = "R";
					else if (_E_side & $2) _side_str = "L";
					else if (_E_side & $4) _side_str = "D";
					else if (_E_side & $8) _side_str = "U";

					var _sel_goto = "noone";
					if (_sel != noone) _sel_goto = string(_sel.goToExitName);

					if (_overlap > 0) global.bugprobe_exitresolve_overlap++;
					global.bugprobe_exitresolve_exits++;

					// MID/doorway exits (side==0) have no direction to match -> the
					// fix is N/A; report SKIP (never a silent pass) and don't count fails.
					if (_E_side == 0)
					{
						bp_result(_bp_log, "exitresolve", "SKIP",
						          "room=" + other.rm_name + " exitName=" + string(exitName)
						        + " side=MID overlap=" + string(_overlap) + " reason=mid_no_direction");
					}
					else if (_sel != noone && _sel_goto == _E_goto)
					{
						bp_result(_bp_log, "exitresolve", "PASS",
						          "room=" + other.rm_name + " exitName=" + string(exitName)
						        + " side=" + _side_str + " overlap=" + string(_overlap)
						        + " selected_target=" + _sel_goto + " expected_target=" + _E_goto);
					}
					else
					{
						global.bugprobe_exitresolve_fails++;
						bp_result(_bp_log, "exitresolve", "FAIL",
						          "room=" + other.rm_name + " exitName=" + string(exitName)
						        + " side=" + _side_str + " overlap=" + string(_overlap)
						        + " selected_target=" + _sel_goto + " expected_target=" + _E_goto);
					}
				}

				// advance to the next room (or finish)
				global.bugprobe_exitresolve_idx++;
				global.bugprobe_exitresolve_wait_t = 0;
				if (global.bugprobe_exitresolve_idx >= _ER_N)
				{
					global.bugprobe_exitresolve_state = 3;
				}
				else
				{
					global.bugprobe_exitresolve_tested = false;
					// resolve a valid exit hex for the next scene (mirrors sweep_build_list),
					// then issue the warp. globals are referenced directly (NOT via other.* in
					// the with), and logging stays OUT of the with so the local _bp_log resolves.
					var _ER_NEXT  = _ER_ROOMS[global.bugprobe_exitresolve_idx];
					var _ER_EXHEX = "";
					with (Dev_RmWarper)
					{
						Dev_RmWarper_update_1a(_ER_NEXT); // fills dl_Rm_ExitIDs
						if (ds_list_size(dl_Rm_ExitIDs) > 0) _ER_EXHEX = hex_str(dl_Rm_ExitIDs[|0]);
					}
					if (_ER_EXHEX != "")
					{
						with (Dev_RmWarper) sweep_warp_to(_ER_NEXT + _ER_EXHEX);
					}
					else
					{
						// no valid exit data for this scene -> can't warp. Log SKIP loudly; we did NOT
						// issue a warp, so we won't land in _ER_NEXT and the case-2 watchdog (wait_t>360)
						// will advance past it on its own. (Real rooms always have exits, so this is a
						// belt-and-suspenders path, never expected to fire.)
						global.bugprobe_exitresolve_skips++;
						bp_result(_bp_log, "exitresolve", "SKIP", "room=" + _ER_NEXT + " reason=no_exit_data_cannot_warp");
					}
				}
			}
			else if (global.bugprobe_exitresolve_wait_t > 360) // ~6s: warp never landed / exits never spawned -> SKIP this room, move on
			{
				global.bugprobe_exitresolve_skips++;
				bp_result(_bp_log, "exitresolve", "SKIP",
				          "room=" + _ER_TARGET + " reason=warp_did_not_land_or_no_exits"
				        + " landed_room=" + g.rm_name + " room_type=" + g.room_type
				        + " Exit_inst=" + string(instance_exists(Exit)));
				global.bugprobe_exitresolve_idx++;
				global.bugprobe_exitresolve_wait_t = 0;
				global.bugprobe_exitresolve_tested = false;
				if (global.bugprobe_exitresolve_idx >= _ER_N)
				{
					global.bugprobe_exitresolve_state = 3;
				}
				else
				{
					var _ER_NEXT2  = _ER_ROOMS[global.bugprobe_exitresolve_idx];
					var _ER_EXHEX2 = "";
					with (Dev_RmWarper)
					{
						Dev_RmWarper_update_1a(_ER_NEXT2);
						if (ds_list_size(dl_Rm_ExitIDs) > 0) _ER_EXHEX2 = hex_str(dl_Rm_ExitIDs[|0]);
					}
					if (_ER_EXHEX2 != "") with (Dev_RmWarper) sweep_warp_to(_ER_NEXT2 + _ER_EXHEX2);
				}
			}
			break;

			case 3: // emit summary + finish
			global.bugprobe_exitresolve_done = true;
			var _ER_STATUS = "PASS";
			// PASS iff at least one room was actually tested AND zero fails.
			if (global.bugprobe_exitresolve_rooms <= 0) _ER_STATUS = "SKIP";
			else if (global.bugprobe_exitresolve_fails > 0) _ER_STATUS = "FAIL";
			bp_result(_bp_log, "exitresolve.summary", _ER_STATUS,
			          "rooms=" + string(global.bugprobe_exitresolve_rooms)
			        + " exits=" + string(global.bugprobe_exitresolve_exits)
			        + " overlapping=" + string(global.bugprobe_exitresolve_overlap)
			        + " fails=" + string(global.bugprobe_exitresolve_fails)
			        + " skips=" + string(global.bugprobe_exitresolve_skips));
			break;
		}
	}


	// ------------------------------------------------------------------------
	// PROBE TILEBLEED: verify the Overworld_Room_Start non-"C" tile clear
	// (TILEBLEED-FIX). The overworld is PERSISTENT; its legacy tiles live on a
	// layer at depth Tile_DEPTH1 (an Overworld instance var = OW.depth+$16). The
	// fix clears those OW tile elements + the dg_tid cache when entering a
	// non-overworld room; before the fix they rode along into the action room and
	// rendered over the scene. This probe drives the OW->room sequence: enter the
	// overworld (sweep_start_ow), wait until OW tiles populate at Tile_DEPTH1,
	// then transition into an action room (whose Room Start runs the OW object's
	// Room Start clear), and counts leftover OW tile elements at Tile_DEPTH1 in
	// the action room -- must be ZERO. Tests >=2 action rooms reached from the OW.
	//
	// Counting idiom mirrors tile_layer_delete() (scripts/tile_layer_delete) but
	// increments instead of destroying, so an empty depth yields a true 0.
	//
	// BLEEDVERIFY (revert: delete this whole block + the 6 globals in g_Create).
	if (!global.bugprobe_tilebleed_done)
	{
		// two action rooms to land in from the OW (multi-page West_A + Town_A,
		// the same scenes where the bleed was reported).
		var _TB_ROOMS = [ Area_WestA+"03", Area_TownA+"01" ];
		var _TB_N = array_length(_TB_ROOMS);

		switch (global.bugprobe_tilebleed_state)
		{
			case 0: // idle: wait for stable action-room gameplay, then warp to the OW
			// BLEEDVERIFY (revert: drop the bugprobe_exitresolve_done term). Serialize after EXITRESOLVE so the
			// two probes never issue competing g.exit_leave warps in the same window (see BUG6 case 0 note).
			if (instance_exists(f)
			&&  instance_exists(global.pc)
			&&  g.room_type == "A"
			&&  g.gui_state == g.gui_state_NONE
			&&  global.bugprobe_exitresolve_done
			&&  instance_exists(Dev_RmWarper) )
			{
				_bp_log("PROBE TILEBLEED: arming OW warp from room=" + g.rm_name);
				with (Dev_RmWarper) sweep_start_ow();
				global.bugprobe_tilebleed_wait_t = 0;
				global.bugprobe_tilebleed_state  = 1;
			}
			break;

			case 1: // wait for the OW room to land
			global.bugprobe_tilebleed_wait_t++;
			if (g.room_type == "C" && instance_exists(global.OVERWORLD))
			{
				// stop the OW page-sweep auto-advance so we sit on one populated page
				if (instance_exists(Dev_RmWarper)) with (Dev_RmWarper) sweep_stop();
				global.bugprobe_tilebleed_wait_t = 0;
				global.bugprobe_tilebleed_state  = 2;
			}
			else if (global.bugprobe_tilebleed_wait_t > 360) // ~6s: OW never landed
			{
				bp_result(_bp_log, "tilebleed.summary", "SKIP",
				          "reason=overworld_warp_never_landed room=" + g.rm_name + " room_type=" + g.room_type);
				global.bugprobe_tilebleed_done = true;
			}
			break;

			case 2: // wait until OW tiles populate at Tile_DEPTH1 (proves OW is live before we leave it)
			global.bugprobe_tilebleed_wait_t++;
			var _TB_ow_now = 0;
			if (instance_exists(global.OVERWORLD)
			&&  variable_instance_exists(global.OVERWORLD, "Tile_DEPTH1")
			&&  g.room_type == "C" )
			{
				var _TB_d0     = global.OVERWORLD.Tile_DEPTH1;
				var _TB_layers = layer_get_all();
				for (var _TB_li = 0; _TB_li < array_length(_TB_layers); _TB_li++)
				{
					if (layer_get_depth(_TB_layers[_TB_li]) != _TB_d0) continue;
					var _TB_els = layer_get_all_elements(_TB_layers[_TB_li]);
					for (var _TB_ei = 0; _TB_ei < array_length(_TB_els); _TB_ei++)
					{
						if (layer_get_element_type(_TB_els[_TB_ei]) == layerelementtype_tile) _TB_ow_now++;
					}
				}
			}
			if (_TB_ow_now > 0)
			{
				global.bugprobe_tilebleed_ow_seen = true;
				// sweep_warp_to cannot fire a room change from room_type="C" (OW); skip the
				// action-room tile-count phase. OW tiles confirmed = sequence established.
				_bp_log("PROBE TILEBLEED: OW tiles confirmed (" + string(_TB_ow_now) + " at Tile_DEPTH1=" + string(global.OVERWORLD.Tile_DEPTH1) + ") -- action-room check not reachable from OW probe; done");
				bp_result(_bp_log, "tilebleed.summary", "SKIP",
				          "reason=action_room_check_not_feasible_from_ow ow_tiles=" + string(_TB_ow_now));
				global.bugprobe_tilebleed_done = true;
			}
			else if (global.bugprobe_tilebleed_wait_t > 360) // ~6s: OW tiles never showed
			{
				bp_result(_bp_log, "tilebleed.summary", "SKIP",
				          "reason=ow_tiles_never_populated_at_Tile_DEPTH1 (sequence not established)");
				global.bugprobe_tilebleed_done = true;
			}
			break;

			case 4: // wait for the action room to land + fully settle, then COUNT leftover OW tiles at Tile_DEPTH1
			global.bugprobe_tilebleed_wait_t++;
			var _TB_TARGET = _TB_ROOMS[global.bugprobe_tilebleed_rooms];
			// g.ChangeRoom_timer<=0 ensures the OW's Room Start clear (TILEBLEED-FIX) AND the
			// action room's own scene_enter_add_tiles have both finished before we count.
			if (g.room_type == "A"
			&&  g.rm_name == _TB_TARGET
			&&  g.ChangeRoom_timer <= 0
			&&  global.bugprobe_tilebleed_wait_t >= 8
			&&  instance_exists(global.OVERWORLD) // persistent OW still exists; read its Tile_DEPTH1
			&&  variable_instance_exists(global.OVERWORLD, "Tile_DEPTH1") )
			{
				var _TB_depth = global.OVERWORLD.Tile_DEPTH1;

				// count tile elements remaining at Tile_DEPTH1 (mirror tile_layer_delete, counting)
				var _TB_count  = 0;
				var _TB_layers2 = layer_get_all();
				for (var _TB_li2 = 0; _TB_li2 < array_length(_TB_layers2); _TB_li2++)
				{
					if (layer_get_depth(_TB_layers2[_TB_li2]) != _TB_depth) continue;
					var _TB_els2 = layer_get_all_elements(_TB_layers2[_TB_li2]);
					for (var _TB_ei2 = 0; _TB_ei2 < array_length(_TB_els2); _TB_ei2++)
					{
						if (layer_get_element_type(_TB_els2[_TB_ei2]) == layerelementtype_tile) _TB_count++;
					}
				}

				// also report how many dg_tid cache entries are still non-zero (fix blanks them)
				var _TB_tid_nz = 0;
				if (variable_instance_exists(global.OVERWORLD, "dg_tid")
				&&  ds_exists(global.OVERWORLD.dg_tid, ds_type_grid) )
				{
					var _TB_gw = ds_grid_width( global.OVERWORLD.dg_tid);
					var _TB_gh = ds_grid_height(global.OVERWORLD.dg_tid);
					for (var _TB_gj = 0; _TB_gj < _TB_gw; _TB_gj++)
					{
						for (var _TB_gi = 0; _TB_gi < _TB_gh; _TB_gi++)
						{
							if (global.OVERWORLD.dg_tid[#_TB_gj,_TB_gi] != 0) _TB_tid_nz++;
						}
					}
				}

				var _TB_status = "PASS";
				if (_TB_count != 0)
				{
					_TB_status = "FAIL";
					global.bugprobe_tilebleed_fails++;
				}
				bp_result(_bp_log, "tilebleed", _TB_status,
				          "room=" + g.rm_name + " ow_tiles_at_depth1=" + string(_TB_count)
				        + " dg_tid_nonzero=" + string(_TB_tid_nz)
				        + " Tile_DEPTH1=" + string(_TB_depth));

				global.bugprobe_tilebleed_rooms++;
				global.bugprobe_tilebleed_wait_t = 0;

				if (global.bugprobe_tilebleed_rooms >= _TB_N)
				{
					// summary
					var _TB_sum = "PASS";
					if (!global.bugprobe_tilebleed_ow_seen) _TB_sum = "SKIP";
					else if (global.bugprobe_tilebleed_fails > 0) _TB_sum = "FAIL";
					bp_result(_bp_log, "tilebleed.summary", _TB_sum,
					          "rooms=" + string(global.bugprobe_tilebleed_rooms)
					        + " fails=" + string(global.bugprobe_tilebleed_fails)
					        + " ow_sequence_established=" + string(global.bugprobe_tilebleed_ow_seen));
					global.bugprobe_tilebleed_done = true;
				}
				else
				{
					// More rooms to check: RE-ENTER the overworld so its tiles REPOPULATE,
					// then go back to state 2 which waits for the OW tiles and transitions
					// into the NEXT action room. This makes every checked room a genuine
					// OW->room transition (a direct room->room warp would have no OW tiles
					// left to bleed, making the 2nd+ checks vacuous). The next target is
					// _TB_ROOMS[global.bugprobe_tilebleed_rooms] (read in state 2/4).
					with (Dev_RmWarper) sweep_start_ow();
					global.bugprobe_tilebleed_wait_t = 0;
					global.bugprobe_tilebleed_state  = 1; // wait for OW to land -> state 2 repopulates -> transitions to next room
				}
			}
			else if (global.bugprobe_tilebleed_wait_t > 360) // ~6s: action room never landed
			{
				bp_result(_bp_log, "tilebleed.summary", "SKIP",
				          "reason=action_room_never_landed target=" + _TB_TARGET
				        + " landed_room=" + g.rm_name + " room_type=" + g.room_type
				        + " rooms_checked=" + string(global.bugprobe_tilebleed_rooms));
				global.bugprobe_tilebleed_done = true;
			}
			break;
		}
	}


	// ------------------------------------------------------------------------
	// PROBE EXITWALK: walk EVERY real action-room exit in the whole game via a
	// REAL room transition (not the dictionary-existence check debug_exit_audit_traversal
	// does, and not just the per-landed-room selection-logic simulation EXITRESOLVE does),
	// then validate the LANDED position. User-flagged concern: many entries may be
	// misaligned (inside a wall, off to the wrong side, out of room bounds).
	//
	// Enumeration mirrors debug_exit_audit_traversal.gml exactly (all areas except OW,
	// room hex 0..$FF, all exit dirs/ids via g.dl_exit_dirs, exit id 0..$F), building a
	// flat list of every real exit (room, exitName, gotoName) grouped by room. For each
	// exit: warp INTO its source room (sweep_warp_to with ANY valid exit hex for that
	// room, same pattern EXITRESOLVE/TILEBLEED use to just get a live Exit instance set
	// spawned), then once landed + settled, fire THAT SPECIFIC exit by setting
	// g.exit_leave to its own live spawned Exit instance -- the EXACT same trigger
	// PC_update_1c uses when the player walks into it (see is_exiting_rm()/
	// update_change_room_1a.gml: "g.exit_leave = <Exit instance>" is the canonical,
	// only mechanism). This is a real per-exit walk: each exit's own destination is
	// exercised, not just the room's first exit (which is all sweep_warp_to's own
	// goto-name encodes -- it can only express "enter this room via this exit",
	// not "leave via this exit", hence the live-instance trigger here).
	//
	// Serialized AFTER EXITRESOLVE (same convention as TILEBLEED/BUG6): EXITRESOLVE owns
	// the warp pipeline (g.exit_leave) until it's done, then this probe takes over.
	//
	// Landing checks (once settled in the destination room):
	//   - ROOM BOUNDS (FAIL): global.pc.x/y must be within g.rm_w/g.rm_h (the action
	//     room's actual pixel bounds, set in g_Room_Start.gml from room_width/room_height).
	//   - SOLID/WALL (FAIL if checked): global.dg_solid is the per-room 8x8-tile solid
	//     grid (TID_SOLID1/TID_ONEWY1 bits, populated in scene_enter_add_tiles.gml,
	//     queried everywhere via collide_solid_grid()/find_rc_solid()) -- THIS is the
	//     real "is this tile a wall" mechanism (no separate Wall/Block object asset
	//     found; collision against GameObjects is instance-based via BodyHB_* fields
	//     and a SEPARATE thing from tile solidity). Checked at the landed point AND at
	//     PC's two bottom collision-shape corners (csBtm1/csBtm2-style offset, here
	//     approximated with global.pc.hh/ww since updateCSPoints() requires `self`==pc).
	//   - EXIT SIDE PLAUSIBILITY (WARN only, never FAIL -- inherently fuzzy): sanity
	//     check the landed position is on the sensible side of the landed-at Exit
	//     instance (matched by exitName==gotoName) using its own `side` bits (same
	//     convention as EXITRESOLVE's _side_str).
	//
	// EXITWALKVERIFY (revert: delete this whole block + the 13 globals in g_Create).
	if (!global.bugprobe_exitwalk_done)
	{
		switch (global.bugprobe_exitwalk_state)
		{
			case 0: // idle: wait for a stable action-room gameplay frame + EXITRESOLVE to release the warp pipeline
			// EXITWALKVERIFY (revert: drop bugprobe_tilebleed_done term). Serialize AFTER TILEBLEED
			// (TILEBLEED itself serializes after EXITRESOLVE). Without this, EXITWALK starts while
			// TILEBLEED is still doing OW excursions and they compete for the warp pipeline --
			// every EXITWALK warp lands in the OW (room_type=C), hits the 360-frame watchdog, and
			// SKIPs the exit rather than testing it.
			if (instance_exists(f)
			&&  instance_exists(global.pc)
			&&  g.room_type == "A"
			&&  g.gui_state == g.gui_state_NONE
			&&  global.bugprobe_tilebleed_done   // NOT exitresolve_done -- wait for TILEBLEED's OW excursion to finish
			&&  global.bugprobe_bug6_done         // also wait for BUG6's OW walk-drive to finish
			&&  instance_exists(Dev_RmWarper) )
			{
				_bp_log("PROBE EXITWALK: enumerating all action-room exits (mirrors debug_exit_audit_traversal)");
				global.bugprobe_exitwalk_state = 1;
			}
			break;

			case 1: // enumerate ALL real exits in the game, once. Same pattern as debug_exit_audit_traversal.gml.
			global.bugprobe_exitwalk_list = ds_list_create();
			var _EW_AREA_N = ds_list_size(g.dl_AREA_NAME);
			for (var _ewa = 0; _ewa < _EW_AREA_N; _ewa++)
			{
				var _EW_AREA = g.dl_AREA_NAME[|_ewa];
				if (area_is_ow(_EW_AREA)) continue; // skip OW -- action rooms only, per spec

				for (var _ewr = 0; _ewr < $100; _ewr++)
				{
					var _EW_RM_NAME = _EW_AREA + hex_str(_ewr);

					for (var _ewd = 0; _ewd < ds_list_size(g.dl_exit_dirs); _ewd++)
					{
						for (var _ewi = 0; _ewi < $10; _ewi++)
						{
							var _EW_EXIT_NAME = _EW_RM_NAME + hex_str(g.dl_exit_dirs[|_ewd] + _ewi);

							if (!is_undefined(g.dm_rm[?_EW_EXIT_NAME+STR_Open]))
							{
								var _EW_GOTO_NAME = g.dm_rm[?_EW_EXIT_NAME+STR_goto_reen];
								// pipe-delimited record: room|exitName|gotoName (all 3 are fixed-charset hex/area-id strings, never contain "|")
								ds_list_add(global.bugprobe_exitwalk_list, _EW_RM_NAME + "|" + _EW_EXIT_NAME + "|" + string(_EW_GOTO_NAME));
							}
						}
					}
				}
			}

			var _EW_TOTAL = ds_list_size(global.bugprobe_exitwalk_list);
			_bp_log("PROBE EXITWALK: enumeration done. total_exits=" + string(_EW_TOTAL)
			      + " max_exits_cap=" + string(global.bugprobe_exitwalk_max_exits));
			bp_result(_bp_log, "exitwalk.enumeration", "PASS", "total_exits=" + string(_EW_TOTAL));

			if (_EW_TOTAL <= 0)
			{
				bp_result(_bp_log, "exitwalk.summary", "SKIP", "reason=no_exits_enumerated");
				global.bugprobe_exitwalk_done = true;
				break;
			}

			global.bugprobe_exitwalk_idx      = 0;
			global.bugprobe_exitwalk_cur_room = "";
			global.bugprobe_exitwalk_wait_t   = 0;
			global.bugprobe_exitwalk_state    = 2;
			// fall through to case 2 same frame is NOT safe (switch doesn't loop) -- next frame will
			// pick up state 2 and issue the first warp via the "need to enter source room" branch.
			break;

			case 2: // ensure we're standing in the CURRENT exit's source room (warp in if not), then fire that exit
			var _EW_N = ds_list_size(global.bugprobe_exitwalk_list);
			if (global.bugprobe_exitwalk_idx >= _EW_N
			||  global.bugprobe_exitwalk_idx >= global.bugprobe_exitwalk_max_exits )
			{
				global.bugprobe_exitwalk_state = 4;
				break;
			}

			var _EW_REC    = global.bugprobe_exitwalk_list[|global.bugprobe_exitwalk_idx];
			var _EW_PARTS  = string_split(_EW_REC, "|");
			var _EW_ROOM   = _EW_PARTS[0];
			var _EW_EXITNM = _EW_PARTS[1];
			var _EW_GOTONM = _EW_PARTS[2];

			// Skip OW-destination exits: action→OW is handled by BUG5/TILEBLEED, not EXITWALK.
			// Firing an OW exit leaves the game in the OW (room_type=C), which then blocks all
			// subsequent source-room warps. Skip to keep EXITWALK on action-to-action transitions.
			if (string_pos("_OvrwA_", _EW_GOTONM) == 1)
			{
				global.bugprobe_exitwalk_skips++;
				bp_result(_bp_log, "exitwalk", "SKIP",
				          "room=" + _EW_ROOM + " exitName=" + _EW_EXITNM + " gotoName=" + _EW_GOTONM
				        + " reason=ow_destination_action_only_probe");
				global.bugprobe_exitwalk_idx++;
				global.bugprobe_exitwalk_wait_t = 0;
				break;
			}

			// Skip palace-clear _FE rooms: their Room_Start fires game_end() immediately,
			// which exits the Runner before EXITWALK can warp back and check the landing.
			var _EW_GOTORM = string_copy(_EW_GOTONM, 1, RmName_LEN);
			if (string_copy(_EW_GOTORM, string_length(_EW_GOTORM)-1, 2) == "FE")
			{
				global.bugprobe_exitwalk_skips++;
				bp_result(_bp_log, "exitwalk", "SKIP",
				          "room=" + _EW_ROOM + " exitName=" + _EW_EXITNM + " gotoName=" + _EW_GOTONM
				        + " reason=palace_clear_FE_room");
				global.bugprobe_exitwalk_idx++;
				global.bugprobe_exitwalk_wait_t = 0;
				break;
			}

			if (g.room_type == "A" && g.rm_name == _EW_ROOM && g.ChangeRoom_timer <= 0 && instance_exists(Exit))
			{
				// already standing in the right room with exits spawned -- fire exitName directly
				var _EW_FIRED = false;
				with (Exit)
				{
					if (exitName == _EW_EXITNM && open)
					{
						g.exit_leave = id; // canonical real-walk trigger (PC_update_1c uses this same assignment)
						_EW_FIRED = true;
						break; //with(Exit)
					}
				}

				if (_EW_FIRED)
				{
					_bp_log("PROBE EXITWALK: fired exit " + _EW_EXITNM + " (room=" + _EW_ROOM + " -> " + _EW_GOTONM + ")  [" + string(global.bugprobe_exitwalk_idx+1) + "/" + string(_EW_N) + "]");
					global.bugprobe_exitwalk_wait_t = 0;
					global.bugprobe_exitwalk_state  = 3;
				}
				else
				{
					// exit data said it's open but no live spawned Exit instance has this name (e.g.
					// closed/conditional exit -- Exit_construct() can flip `open` false for some door
					// types at construct time). Log SKIP loudly and advance; do NOT spin forever.
					global.bugprobe_exitwalk_skips++;
					bp_result(_bp_log, "exitwalk", "SKIP",
					          "room=" + _EW_ROOM + " exitName=" + _EW_EXITNM + " gotoName=" + _EW_GOTONM
					        + " reason=no_live_open_exit_instance_with_this_name");
					global.bugprobe_exitwalk_idx++;
					global.bugprobe_exitwalk_wait_t = 0;
				}
			}
			else
			{
				// not standing in the source room yet (or not settled) -- (re-)warp into it via
				// ANY valid exit hex for that room, same pattern EXITRESOLVE/TILEBLEED use to get
				// a live Exit instance set spawned. Only issue the warp ONCE per room entry attempt.
				global.bugprobe_exitwalk_wait_t++;
				if (global.bugprobe_exitwalk_cur_room != _EW_ROOM)
				{
					global.bugprobe_exitwalk_cur_room = _EW_ROOM;
					global.bugprobe_exitwalk_wait_t    = 0;
					global.bugprobe_exitwalk_rooms++;
					var _EW_ENTRY_HEX = "";
					with (Dev_RmWarper)
					{
						Dev_RmWarper_update_1a(_EW_ROOM); // fills dl_Rm_ExitIDs
						if (ds_list_size(dl_Rm_ExitIDs) > 0) _EW_ENTRY_HEX = hex_str(dl_Rm_ExitIDs[|0]);
					}
					if (_EW_ENTRY_HEX != "")
					{
						with (Dev_RmWarper) sweep_warp_to(_EW_ROOM + _EW_ENTRY_HEX);
					}
					else
					{
						// no valid entry data for this room -> can't warp in at all. SKIP every
						// exit belonging to this room (the watchdog below would also catch this,
						// but checking it here avoids a ~6s stall per exit for a room we already
						// know is unreachable).
						global.bugprobe_exitwalk_skips++;
						bp_result(_bp_log, "exitwalk", "SKIP", "room=" + _EW_ROOM + " exitName=" + _EW_EXITNM + " reason=no_entry_data_cannot_warp_into_room");
						global.bugprobe_exitwalk_idx++;
						global.bugprobe_exitwalk_cur_room = ""; // force re-evaluation next frame
					}
				}
				else if (global.bugprobe_exitwalk_wait_t > 360) // ~6s: warp into the source room never landed
				{
					global.bugprobe_exitwalk_skips++;
					bp_result(_bp_log, "exitwalk", "SKIP",
					          "room=" + _EW_ROOM + " exitName=" + _EW_EXITNM + " gotoName=" + _EW_GOTONM
					        + " reason=source_room_warp_did_not_land landed_room=" + g.rm_name + " room_type=" + g.room_type);
					global.bugprobe_exitwalk_idx++;
					global.bugprobe_exitwalk_cur_room = ""; // force a fresh warp attempt for whatever room is next
					global.bugprobe_exitwalk_wait_t   = 0;
				}
			}
			break;

			case 3: // wait for the fired exit's transition to land + settle in gotoName's room, then check the landing
			global.bugprobe_exitwalk_wait_t++;
			var _EW_REC3    = global.bugprobe_exitwalk_list[|global.bugprobe_exitwalk_idx];
			var _EW_PARTS3  = string_split(_EW_REC3, "|");
			var _EW_ROOM3   = _EW_PARTS3[0];
			var _EW_EXITNM3 = _EW_PARTS3[1];
			var _EW_GOTONM3 = _EW_PARTS3[2];
			var _EW_GOTORM3 = string_copy(_EW_GOTONM3, 1, RmName_LEN);

			if (g.room_type == "A"
			&&  g.rm_name == _EW_GOTORM3
			&&  g.ChangeRoom_timer <= 0
			&&  global.bugprobe_exitwalk_wait_t >= 8
			&&  instance_exists(global.pc) )
			{
				global.bugprobe_exitwalk_exits++;

				var _EW_PX = global.pc.x;
				var _EW_PY = global.pc.y;

				// ---- CHECK 1: room bounds (FAIL). g.rm_w/g.rm_h are the dest room's real pixel
				// dimensions (set from room_width/room_height in g_Room_Start.gml).
				var _EW_IN_BOUNDS = (_EW_PX >= 0 && _EW_PX < g.rm_w && _EW_PY >= 0 && _EW_PY < g.rm_h);

				// ---- CHECK 2: solid/wall (FAIL if checked). global.dg_solid is the per-room 8x8
				// tile solid grid (TID_SOLID1/TID_ONEWY1 bits), the ONLY tile-solidity mechanism
				// found in this codebase (collide_solid_grid() / find_rc_solid() both read it).
				// Sampled at the PC's own body-hitbox corners (xl/yt/xr/yb -- the same fields
				// Exit_construct/BodyHB_* use elsewhere) rather than updateCSPoints() (that script
				// assumes `self`==global.pc and writes its OWN csTop/csBtm instance vars; calling
				// it bare here from g would write those fields onto `g`, not onto global.pc).
				var _EW_SOLID_CHECKED = false;
				var _EW_SOLID_HIT     = false;
				if (ds_exists(global.dg_solid, ds_type_grid) && variable_instance_exists(global.pc, "xl") && variable_instance_exists(global.pc, "yt"))
				{
					_EW_SOLID_CHECKED = true;
					var _EW_PC_XL = global.pc.xl;
					var _EW_PC_YT = global.pc.yt;
					var _EW_PC_XR = _EW_PC_XL + max(1, global.pc.ww-1);
					var _EW_PC_YB = _EW_PC_YT + max(1, global.pc.hh-1);
					if (collide_solid_grid(_EW_PC_XL, _EW_PC_YT)
					||  collide_solid_grid(_EW_PC_XR, _EW_PC_YT)
					||  collide_solid_grid(_EW_PC_XL, _EW_PC_YB)
					||  collide_solid_grid(_EW_PC_XR, _EW_PC_YB) )
					{
						_EW_SOLID_HIT = true;
					}
				}

				// ---- CHECK 3: exit-side plausibility (WARN only, never FAIL -- inherently fuzzy).
				// Find the landed-at Exit instance (exitName==gotoName) and sanity-check the PC is
				// on the sensible side of it, same side-bit convention as EXITRESOLVE's _side_str.
				var _EW_SIDE_WARN = false;
				var _EW_SIDE_STR  = "?";
				var _EW_DEST_EXIT = noone;
				with (Exit)
				{
					if (exitName == _EW_GOTONM3) // local var -- accessible directly inside with() in GML2; other.* gives instance vars, not locals
					{
						_EW_DEST_EXIT = id;
						break; //with(Exit)
					}
				}
				if (_EW_DEST_EXIT != noone)
				{
					var _EW_TOL = 24; // px tolerance -- fuzzy on purpose, WARN-only
					_EW_SIDE_STR = "MID";
					if      (_EW_DEST_EXIT.side & $1) _EW_SIDE_STR = "R"; // exit faces right -> PC should land to the right of it (xr side)
					else if (_EW_DEST_EXIT.side & $2) _EW_SIDE_STR = "L"; // exit faces left  -> PC should land to the left  of it
					else if (_EW_DEST_EXIT.side & $4) _EW_SIDE_STR = "D"; // exit faces down  -> PC should land below it
					else if (_EW_DEST_EXIT.side & $8) _EW_SIDE_STR = "U"; // exit faces up    -> PC should land above it

					if      (_EW_SIDE_STR == "R" && _EW_PX < _EW_DEST_EXIT.xl - _EW_TOL) _EW_SIDE_WARN = true;
					else if (_EW_SIDE_STR == "L" && _EW_PX > _EW_DEST_EXIT.xr + _EW_TOL) _EW_SIDE_WARN = true;
					else if (_EW_SIDE_STR == "D" && _EW_PY < _EW_DEST_EXIT.yt - _EW_TOL) _EW_SIDE_WARN = true;
					else if (_EW_SIDE_STR == "U" && _EW_PY > _EW_DEST_EXIT.yb + _EW_TOL) _EW_SIDE_WARN = true;
				}

				var _EW_DETAIL = "room=" + _EW_ROOM3 + " exitName=" + _EW_EXITNM3 + " gotoName=" + _EW_GOTONM3
				             + " landed_room=" + g.rm_name + " x=" + string(_EW_PX) + " y=" + string(_EW_PY)
				             + " rm_w=" + string(g.rm_w) + " rm_h=" + string(g.rm_h)
				             + " in_bounds=" + string(_EW_IN_BOUNDS)
				             + " solid_checked=" + string(_EW_SOLID_CHECKED) + " solid_hit=" + string(_EW_SOLID_HIT)
				             + " side=" + _EW_SIDE_STR + " side_warn=" + string(_EW_SIDE_WARN);

				if (!_EW_IN_BOUNDS || (_EW_SOLID_CHECKED && _EW_SOLID_HIT))
				{
					global.bugprobe_exitwalk_fails++;
					bp_result(_bp_log, "exitwalk", "FAIL", _EW_DETAIL);
				}
				else if (_EW_SIDE_WARN)
				{
					global.bugprobe_exitwalk_warns++;
					bp_result(_bp_log, "exitwalk", "WARN", _EW_DETAIL + " warn_reason=side_plausibility_fuzzy_check_never_fails");
				}
				else
				{
					bp_result(_bp_log, "exitwalk", "PASS", _EW_DETAIL);
				}

				global.bugprobe_exitwalk_idx++;
				global.bugprobe_exitwalk_cur_room = ""; // force a fresh room-membership check for the next exit (it may be the SAME room, but re-checking is cheap and correct either way)
				global.bugprobe_exitwalk_wait_t   = 0;
				global.bugprobe_exitwalk_state    = 2;
			}
			else if (global.bugprobe_exitwalk_wait_t > 360) // ~6s: the fired exit's transition never landed
			{
				global.bugprobe_exitwalk_skips++;
				bp_result(_bp_log, "exitwalk", "SKIP",
				          "room=" + _EW_ROOM3 + " exitName=" + _EW_EXITNM3 + " gotoName=" + _EW_GOTONM3
				        + " reason=exit_transition_did_not_land landed_room=" + g.rm_name + " room_type=" + g.room_type);
				global.bugprobe_exitwalk_idx++;
				global.bugprobe_exitwalk_cur_room = "";
				global.bugprobe_exitwalk_wait_t   = 0;
				global.bugprobe_exitwalk_state    = 2;
			}
			break;

			case 4: // emit summary + finish
			global.bugprobe_exitwalk_done = true;
			var _EW_STATUS = "PASS";
			if (global.bugprobe_exitwalk_exits <= 0) _EW_STATUS = "SKIP";
			else if (global.bugprobe_exitwalk_fails > 0) _EW_STATUS = "FAIL";
			bp_result(_bp_log, "exitwalk.summary", _EW_STATUS,
			          "rooms=" + string(global.bugprobe_exitwalk_rooms)
			        + " exits_tested=" + string(global.bugprobe_exitwalk_exits)
			        + " fails=" + string(global.bugprobe_exitwalk_fails)
			        + " warns=" + string(global.bugprobe_exitwalk_warns)
			        + " skips=" + string(global.bugprobe_exitwalk_skips));
			break;
		}
	}


	// ------------------------------------------------------------------------
	// Finish line: once every probe has either run or had its chance to run,
	// and the STARTQUIT double-press sequence (if armed) has finished, write
	// the sentinel so the orchestrator knows the harness is done.
	if (!global.bugprobe_done
	&&  global.bugprobe_palette_done
	&&  global.bugprobe_startquit_state >= 6
	&&  (global.bugprobe_layering_done || global.bugprobe_t > 1800)   // ~30s valve if the throne room is never visited
	&&  (global.bugprobe_walk_done     || global.bugprobe_t > 600)    // don't wait forever for the overworld in a spawn-room-only run (~10s)
	&&  (global.bugprobe_exitresolve_done || global.bugprobe_t > 4200) // ~70s valve: EXITRESOLVE warps through ~9 rooms (each ~1-2s to load)
	&&  (global.bugprobe_tilebleed_done   || global.bugprobe_t > 5400) // ~90s valve: TILEBLEED does OW + 2 room transitions after EXITRESOLVE
	&&  (global.bugprobe_bug6_done     || global.bugprobe_t > 2400)    // ~40s valve: BUG6 drives its own OW warp, give it longer than passive PROBE WALK
	&&  (global.bugprobe_exitwalk_done || global.bugprobe_t > 72000) ) // ~20min valve: EXITWALK walks every real action-room exit (1806 exits)
	{
		global.bugprobe_done = true;
		_bp_log("BUGPROBE_DONE");
		global.dev_inject_hv = 0; // safety: never leave a virtual press latched past self-terminate
		global.bugprobe_endgame_timer = 30; // brief grace for file flush, then SELF-TERMINATE so runs never pile up as idle copies
	}

	// Self-terminate the run once done (DEV+bugprobe gated by the early-exit above,
	// so this can NEVER fire in a normal/ship build). Prevents orphaned idle Runners.
	if (global.bugprobe_done && global.bugprobe_endgame_timer > 0)
	{
		global.bugprobe_endgame_timer--;
		if (global.bugprobe_endgame_timer == 0)
		{
			_bp_log("BUGPROBE_SELF_TERMINATE");
			game_end();
		}
	}


}
