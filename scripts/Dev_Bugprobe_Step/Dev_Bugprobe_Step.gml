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


// -- DEV TWITCH-CHAT SELFTEST (v2.1.8: ISOLATED + ZONES) ------------------------
// "_tw_selftest.flag" in the save dir (%LOCALAPPDATA%\ZALiA). One-shot: g_Create deletes the
// flag the moment it is seen, so a crashed run can never hijack the owner's next launch.
//
// v2.1.7 fired a verb every 1/3 s, so effects stacked and hid each other (owner 09-27: "it
// triggers it all at the same time so even if something is broken you're unlikely to catch
// it"; proved by the shrink/grow shots being taken while !flip was still up). Now ONE verb at
// a time, per zone:
//   PREP   clear every effect, refill, wait for a live, settled screen, take a baseline
//   FIRE   the real IRC entry (twitch_irc_handle_line), grade the toast
//   DURING screenshot while the effect is up (SHOT rows)
//   EXPIRE wait until every timed effect has ended (timeout -> "OUTLIVED" FAIL)
//   AFTER  settle, check nothing leaked (flags, locks, scale, room), screenshot again
// ZONES (owner: "test in all the different types of zone ... some are fine some are not"):
// the load room runs the full matrix; then town / palace / boss / wide / cave / overworld
// each run the view- and spawn-sensitive set. Then a harness-forced DEATH checks that a new
// life starts clean (no chat verb -- !kill was removed 09-28).
// Link is dev-invulnerable (g.dev_invState 2) for the whole run except the death test.
// Log is appended line by line (_tw_selftest_result.log) so a crash keeps what ran.
// Watchdog: 60 s without progress -> "STUCK" line + game_end().

function tws_log(_line) {
	global.tw_selftest_log += "#" + _line;
	var _fh = file_text_open_append(working_directory + "_tw_selftest_result.log");
	if (_fh >= 0) { file_text_write_string(_fh, _line); file_text_writeln(_fh); file_text_close(_fh); }
	show_debug_message("[TWSELFTEST] " + _line);
}

function tws_zones() {
	static _z = [
		// [label, goto room ("" = stay, "OW" = overworld), case set]
		["start",     "",          "all"],
		["town",      "_TownA_01", "zone"],
		["palace",    "_PalcA_01", "zone"],
		["boss",      "_PalcA_0D", "zone"],   // Horsehead
		["wide",      "_DthMt_1F", "zone"],   // the owner's 09-16 wide-room viewport mark
		["cave",      "_WestA_0A", "zone"],
		["overworld", "OW",        "zone"]
	];
	return _z;
}

/// the verbs whose behaviour depends on WHERE you are: view/draw effects, spawns (battle-screen
/// guard), forms, locks, the MK splash, the help card. Parse/gate/points logic is zone-free and
/// only runs in the full "start" matrix.
function tws_zone_cases() {
	static _c = [
		["flip",       "toast", "SHOT"],
		["party",      "toast", "SHOT"],
		["disco",      "toast", ""],
		["dark",       "toast", "SHOT"],
		["shake",      "toast", ""],
		["shrink",     "toast", "SHOT feet on the floor?"],
		["grow 3",     "toast", "SHOT feet on the floor, not clipped?"],
		["moon",       "toast", ""],
		["ice",        "toast", ""],
		["slow",       "toast", ""],
		["speed",      "toast", ""],
		["confuse 3",  "toast", ""],
		["arise",      "arise", "SHOT"],
		["heckler",    "toast", "SHOT name tag"],
		["spawn goriya", "toast", ""],
		["swarm",      "toast", ""],
		["freeze",     "toast", ""],
		["root 3",     "toast", ""],
		["deny all",   "denyall",  ""],
		["stasis",     "toast", ""],
		["ghost",      "toast", ""],
		["crush",      "toast", ""],
		["challenge",  "toast", ""],
		["catslap",    "catslap", "TANGIA knocked around, no damage"],
		["flashbang",  "toast", "SHOT TANGIA white flash + smite"],
		["flawless",   "toast", "SHOT MK2 FLAWLESS VICTORY text"],
		["fatality",   "toast", "SHOT LATE MK2 fatality art, nothing drawn over it"],
		["friendship", "toast", "SHOT LATE MK2 friendship art"],
		["help",       "toast", "SHOT help card"]
	];
	return _c;
}

function tws_live() {
	return instance_exists(g) && instance_exists(f) && instance_exists(global.pc)
	    && (g.room_type == "A" || g.room_type == "C")
	    && g.ChangeRoom_timer <= 0 && !g.cutscene && !g.FallScene_timer
	    && g.gui_state == g.gui_state_NONE;
}

function tws_warp(_goto) {
	if (_goto == "OW")
	{
		g.exit_leave = Exit_construct(EXIT_NAME_GAME_START);
		with (g.exit_leave) { goToExitName = Area_OvrwA + hex_str($0000); }
		return true;
	}
	var _ex = -1;
	with (Dev_RmWarper) { Dev_RmWarper_update_1a(_goto); if (ds_list_size(dl_Rm_ExitIDs) > 0) _ex = dl_Rm_ExitIDs[|0]; }
	if (_ex < 0) return false;
	var _name = _goto + hex_str(_ex);
	g.exit_leave = Exit_construct(EXIT_NAME_GAME_START);
	with (g.exit_leave)
	{
		goToExitName = _name;
		goToExitNum  = str_hex(string_copy(goToExitName, RmName_LEN - 1, 2));
		goToRoom     = string_copy(goToExitName, 1, RmName_LEN);
	}
	return true;
}

/// every effect flag / lock / scale a timed verb may leave behind -- "" if clean
function tws_leaks(_b) {
	var _l = "";
	var _flags = ["tw_flip","tw_disco","tw_ice","tw_moon","tw_confuse","tw_confuse_v","tw_ghost","tw_stasis","tw_dark"];
	for (var _i = 0; _i < array_length(_flags); _i++)
	{   if (variable_global_exists(_flags[_i]) && variable_global_get(_flags[_i]) == true) _l += " " + _flags[_i];  }
	if (variable_global_exists("tw_dmg_mult") && global.tw_dmg_mult != 1) _l += " tw_dmg_mult=" + string(global.tw_dmg_mult);
	if (instance_exists(global.pc))
	{
		if (global.pc.tw_scale_mul != 1) _l += " scale=" + string(global.pc.tw_scale_mul);
		if (variable_instance_exists(global.pc, "tw_speed_mul") && global.pc.tw_speed_mul != 1) _l += " speed=" + string(global.pc.tw_speed_mul);
		if (pc_is_cucco() && !_b.cucco) _l += " still-chicken";
	}
	var _all7 = PC_LOCK_JUMP | PC_LOCK_ATK1 | PC_LOCK_ATK2 | PC_LOCK_ATK3 | PC_LOCK_ATK4 | PC_LOCK_SPEL | PC_LOCK_HSPD;
	if (instance_exists(g) && (g.pc_lock & _all7) != (_b.lock & _all7)) _l += " pc_lock=" + string(g.pc_lock) + "(was " + string(_b.lock) + ")";
	var _n = 0;
	for (var _i = 0; _i < array_length(global.tw_active); _i++)
	{   var _e = global.tw_active[_i]; if (!(variable_struct_exists(_e, "keep_on_death") && _e.keep_on_death)) _n++;  }
	if (_n > 0) _l += " active=" + string(_n);
	return _l;
}

function tws_shot(_tag) {
	var _fn = "_tw_selftest_" + string(global.tws_zone_label) + "_" + _tag + ".png";
	screen_save(working_directory + _fn);
	tws_log("   shot: " + _fn);
}

function tws_finish(_why) {
	var _nfail = string_count("FAIL", global.tw_selftest_log);
	tws_log("DONE (" + _why + "): " + string(_nfail) + " FAIL(s)");
	if (instance_exists(g)) { g.dev_invState = 0; g.DevTools_state = global.tws_devtools0; }
	game_end();
}

function tws_active_count() {
	var _n = 0;
	for (var _i = 0; _i < array_length(global.tw_active); _i++)
	{   var _e = global.tw_active[_i]; if (!(variable_struct_exists(_e, "keep_on_death") && _e.keep_on_death)) _n++;  }
	return _n;
}

function tws_go(_phase) {
	global.tws_phase = _phase;
	global.tws_prog  = 0;
	global.tws_t     = 0;
}

function tws_say(_line) {
	twitch_irc_handle_line(":tstchatter!tst@tmi.twitch.tv PRIVMSG #z :!" + _line);
}

/// one raw IRC line from `nick` (mod badge optional) through the real handler -> the toast it produced
function tws_line(_nick, _msg, _mod = false) {
	global.tw_toast = ""; global.tw_toast_timer = 0;
	twitch_irc_handle_line((_mod ? "@badges=moderator/1;mod=1 " : "") + ":" + _nick + "!" + _nick + "@tmi.twitch.tv PRIVMSG #z :" + _msg);
	return string(global.tw_toast);
}

function tws_feat(_name, _ok, _detail) {
	tws_log((_ok ? "PASS" : "FAIL") + "  [feat]  " + _name + "  ->  " + string(_detail));
}

/// read one key back from twitch_config.txt the way twitch_irc_load_config does ("" = absent)
function tws_cfg_read(_key) {
	var _p = working_directory + "twitch_config.txt";
	if (!file_exists(_p)) return "";
	var _fh = file_text_open_read(_p); var _out = "";
	while (!file_text_eof(_fh))
	{
		var _l = tw_trim(file_text_readln(_fh));
		var _eq = string_pos("=", _l);
		if (_eq > 1 && string_lower(tw_trim(string_copy(_l, 1, _eq - 1))) == _key) _out = tw_trim(string_copy(_l, _eq + 1, string_length(_l) - _eq));
	}
	file_text_close(_fh);
	return _out;
}

/// press confirm (A) on the CHAT EXTRAS page through the real update function
function tws_chatx_press_a(_om, _row) {
	with (_om) { ChatX_cursor = _row; timer = 0; timer2 = 0; a_button_pressed = true; Backout_requested = false; OptionsMenu_ChatX_update(); a_button_pressed = false; }
}
/// hold right (+1) or left (-1) one tick on the CHAT EXTRAS page through the real update function
function tws_chatx_press_h(_om, _row, _dir) {
	Input.heldH = (_dir > 0) ? Input.R : Input.L; Input.heldPrev = 0; g.gui_timer2 = 0;
	with (_om) { ChatX_cursor = _row; timer = 0; timer2 = 0; a_button_pressed = false; Backout_requested = false; OptionsMenu_ChatX_update(); }
	Input.heldH = 0;
}

/// 10-14: every CHAT EXTRAS row flips its global AND lands in twitch_config.txt, then is put back
function tws_chatx_tests(_om) {
	tws_log("---- CHAT EXTRAS rows (real update function, file read-back)");
	// the TWITCH page row opens the page, BACK returns to it
	with (_om) { menu_state = menu_state_TWITCH; Twitch_cursor = Twitch.EXTRAS; timer = 0; timer2 = 0; a_button_pressed = true; OptionsMenu_Twitch_update(); a_button_pressed = false; }
	tws_feat("CHAT EXTRAS row on TWITCH opens the page", _om.menu_state == _om.menu_state_CHAT_EXTRAS, "menu_state=" + string(_om.menu_state));
	tws_chatx_press_a(_om, ChatX.BACK);
	tws_feat("BACK on CHAT EXTRAS returns to TWITCH with the cursor on CHAT EXTRAS", _om.menu_state == _om.menu_state_TWITCH && _om.Twitch_cursor == Twitch.EXTRAS, "menu_state=" + string(_om.menu_state) + " cursor=" + string(_om.Twitch_cursor));
	with (_om) menu_state = menu_state_CHAT_EXTRAS;

	// on/off rows: [row, label, key, getter]
	var _tog = [
		[ChatX.HINT,      "FIRST-USE HINT", "first_use_hint", function() { return global.tw_first_use_hint; }],
		[ChatX.ANNOUNCER, "MK2 ANNOUNCER",  "announcer",      function() { return global.tw_announcer; }],
		[ChatX.BETS,      "CHAT BETS",      "bets",           function() { return global.tw_bets_on; }],
		[ChatX.BOUNTY,    "BOUNTIES",       "bounty",         function() { return global.tw_bounty_on; }],
		[ChatX.HELPCARD,  "HELP CARD",      "help_card",      function() { return global.tw_help_card; }],
		[ChatX.PRICES,    "COMMAND PRICES", "cmd_prices",     function() { return global.tw_cmd_prices; }]
	];
	for (var _i = 0; _i < array_length(_tog); _i++)
	{
		var _t = _tog[_i]; var _get = _t[3];
		var _v0 = _get();
		tws_chatx_press_a(_om, _t[0]);
		var _v1 = _get(); var _f1 = tws_cfg_read(_t[2]);
		tws_chatx_press_a(_om, _t[0]);
		var _v2 = _get(); var _f2 = tws_cfg_read(_t[2]);
		tws_feat(_t[1] + ": A flips it, the file follows, A again puts it back",
		         _v1 != _v0 && _v2 == _v0 && _f1 == (_v1 ? "1" : "0") && _f2 == (_v2 ? "1" : "0"),
		         string(_v0) + " -> " + string(_v1) + " (file " + _f1 + ") -> " + string(_v2) + " (file " + _f2 + ")");
	}

	// value rows: [row, label, key, getter, step]
	var _val = [
		[ChatX.ONEUP,     "1UP REMINDER", "oneup_nudge", function() { return global.tw_oneup_nudge_min; }, 1],
		[ChatX.SWARM_CAP, "SWARM CAP",    "swarm_cap",   function() { return global.tw_swarm_cap; },       2],
		[ChatX.TOASTY,    "TOASTY",       "toasty",      function() { return global.tw_toasty_pct; },      10],
		[ChatX.BABALITY,  "BABALITY",     "babality",    function() { return global.tw_babality_pct; },    5]
	];
	for (var _j = 0; _j < array_length(_val); _j++)
	{
		var _r = _val[_j]; var _g = _r[3];
		var _w0 = _g();
		// step away from a clamp edge first so one press in each direction is visible
		var _dir = (_w0 >= 100 || (_r[0] == ChatX.SWARM_CAP && _w0 >= 40) || (_r[0] == ChatX.ONEUP && _w0 >= 30)) ? -1 : 1;
		tws_chatx_press_h(_om, _r[0], _dir);
		var _w1 = _g(); var _h1 = tws_cfg_read(_r[2]);
		tws_chatx_press_h(_om, _r[0], -_dir);
		var _w2 = _g(); var _h2 = tws_cfg_read(_r[2]);
		tws_feat(_r[1] + ": one press moves it by " + string(_r[4]) + ", the file follows, the other way puts it back",
		         _w1 == _w0 + _dir * _r[4] && _w2 == _w0 && _h1 == string(_w1) && _h2 == string(_w2),
		         string(_w0) + " -> " + string(_w1) + " (file " + _h1 + ") -> " + string(_w2) + " (file " + _h2 + ")");
	}
	// clamps: TOASTY cannot pass 100 or drop below 0; SWARM CAP floor is 4
	var _tp0 = global.tw_toasty_pct; global.tw_toasty_pct = 100; tws_chatx_press_h(_om, ChatX.TOASTY, 1);
	var _tp_hi = global.tw_toasty_pct; global.tw_toasty_pct = 0; tws_chatx_press_h(_om, ChatX.TOASTY, -1);
	var _tp_lo = global.tw_toasty_pct; global.tw_toasty_pct = _tp0;
	var _sc0 = global.tw_swarm_cap; global.tw_swarm_cap = 4; tws_chatx_press_h(_om, ChatX.SWARM_CAP, -1);
	var _sc_lo = global.tw_swarm_cap; global.tw_swarm_cap = _sc0;
	tws_feat("value rows clamp (TOASTY 0..100, SWARM CAP floor 4)", _tp_hi == 100 && _tp_lo == 0 && _sc_lo == 4, "toasty hi=" + string(_tp_hi) + " lo=" + string(_tp_lo) + " swarm lo=" + string(_sc_lo));
	twitch_config_save(); // leave the file matching the restored globals
	with (_om) { ChatX_cursor = ChatX.BOUNTY; timer = 0; }
}

/// next stage of the "edge" / "erase" runs
function tws_stage(_n) {
	global.tws_es   = _n;
	global.tws_et   = 0;
	global.tws_prog = 0;
}

/// newest toast plate whose title contains `part` -> "TITLE / SUB", or "" when there is none
function tws_plate(_part) {
	if (!variable_global_exists("tw_toasts") || !is_array(global.tw_toasts)) return "";
	for (var _i = array_length(global.tw_toasts) - 1; _i >= 0; _i--)
	{
		var _p = global.tw_toasts[_i];
		if (string_pos(_part, _p.title) > 0) return _p.title + " / " + _p.sub;
	}
	return "";
}

/// harness-forced death, the same three lines the death test uses
function tws_kill() {
	g.dev_invState   = 0;
	g.DevTools_state = global.tws_devtools0;
	adjust_stat(-9999, 0);
	global.pc.is_dead = true;
}

/// first line of a file in the save folder ("" when it is not there)
function tws_file_text(_name) {
	if (!file_exists(_name)) return "";
	var _fh = file_text_open_read(working_directory + _name);
	if (_fh == -1) return "";
	var _s = file_text_read_string(_fh);
	file_text_close(_fh);
	return _s;
}

/// Flag text "erase" (~6 s): the ELIMINATION MODE confirm, worked on the file-select screen.
/// START once arms the slot ("ERASE? START" flashes), a second START inside 0.4 s is a pad
/// bounce and must do nothing, a later START erases. Slot 3's file NAME and file-name prefix
/// are aimed at "_tws_scratch*" files first, so the erase lands on a copy: the real slot,
/// its rando data and its spoiler are never opened. START goes in through the same
/// dev_inject_pause hook the boot autopilot uses; the autopilot itself is switched off the
/// moment the file-select screen is up, so nothing loads a save.
function tws_erase_step() {
	if (!variable_global_exists("tws_es")) { global.tws_es = 0; global.tws_et = 0; }
	if (room != rmB_FileSelect || !instance_exists(FileSelect)) exit; // the autopilot is still getting us off the title screen
	global.autosweep_started = true;
	global.tws_et++;
	var _slot = 3;
	var _scr  = "_tws_scratch_save.txt";
	switch (global.tws_es)
	{
	case 0:
		if (FileSelect.state != FileSelect.State_MAIN) { global.tws_et = 0; break; }
		if (global.tws_et < 60) break;
		tws_log("== ZALiA twitch selftest v" + ZALIA_VERSION + " (" + ZALIA_BUILD_DATE + ") -- erase confirm, file-select screen ==");
		global.tws_zone_label = "erase";
		var _txt = global.dm_save_file_data[? STR_Save + STR_File + hex_str(_slot) + STR_Encoded];
		if (!is_string(_txt) || !get_saved_value(_slot, f.SDNAME_saveCreated, 0))
		{
			tws_log("FAIL  [erase]  slot " + string(_slot) + " holds no save: there is nothing to arm");
			tws_finish("erase only");
			exit;
		}
		var _wh = file_text_open_write(working_directory + _scr);
		file_text_write_string(_wh, _txt);
		file_text_close(_wh);
		f.dl_file_names[| _slot - 1]       = _scr;
		f.dl_FILE_NAME_PREFIX[| _slot - 1] = "_tws_scratch";
		global.tws_er_len = string_length(_txt);
		with (FileSelect) Main_cursor = SAVE_FILE_MAX + 1; // ELIMINATION MODE
		global.dev_inject_pause = true;
		tws_stage(1);
		break;

	case 1:
		if (FileSelect.state == FileSelect.State_ELIMINATE) { tws_stage(10); break; }
		if (global.tws_et > 600) { tws_log("FAIL  [erase]  never reached ELIMINATION MODE (10 s)"); tws_finish("erase only"); exit; }
		break;

	case 10:
		if (global.tws_et < 40) break; // let the screen settle
		with (FileSelect) { Eliminate_cursor = _slot - 1; Eliminate_confirm = 0; }
		global.dev_inject_pause = true;                 // START no. 1
		tws_stage(2);
		break;

	case 2:
		if (global.tws_et == 4)
		{
			tws_feat("START on a slot with a save arms it and erases nothing", FileSelect.Eliminate_confirm == _slot && string_length(tws_file_text(_scr)) == global.tws_er_len,
			         "armed slot=" + string(FileSelect.Eliminate_confirm) + "  file " + string(global.tws_er_len) + " -> " + string(string_length(tws_file_text(_scr))) + " chars");
			global.dev_inject_pause = true;             // START no. 2, about 0.1 s after the first
		}
		if (global.tws_et == 10)
		{
			tws_feat("a second START 0.1 s later (a bouncing pad) does not erase", FileSelect.Eliminate_confirm == _slot && string_length(tws_file_text(_scr)) == global.tws_er_len,
			         "armed slot=" + string(FileSelect.Eliminate_confirm) + "  file still " + string(string_length(tws_file_text(_scr))) + " chars");
		}
		if (global.tws_et == 20 || global.tws_et == 28) tws_shot("armed_" + string(global.tws_et)); // the prompt flashes: one of the two shots has it
		if (global.tws_et == 70) global.dev_inject_pause = true; // START no. 3, a full second after arming
		if (global.tws_et == 78)
		{
			var _after = tws_file_text(_scr);
			tws_feat("START again after 0.4 s erases the slot", FileSelect.Eliminate_confirm == 0 && string_length(_after) < global.tws_er_len && !get_saved_value(_slot, f.SDNAME_saveCreated, 0),
			         "armed slot=" + string(FileSelect.Eliminate_confirm) + "  file " + string(global.tws_er_len) + " -> " + string(string_length(_after)) + " chars: " + string_copy(_after, 1, 60));
			tws_shot("erased");
			// leave nothing behind: the scratch slot the erase landed on, and the real names back
			var _px = f.dl_FILE_NAME_PREFIX[| _slot - 1];
			file_delete(working_directory + _scr);
			file_delete(working_directory + _px + dk_RandoDungeonTilesetData + ".txt");
			file_delete(working_directory + _px + STR_Rando + STR_Data + ".txt");
			file_delete(working_directory + _px + STR_Rando + "_Spoiler" + ".txt");
			f.dl_FILE_NAME_PREFIX[| _slot - 1] = "SaveFile_" + string(_slot);
			f.dl_file_names[| _slot - 1]       = f.dl_FILE_NAME_PREFIX[| _slot - 1] + ".txt";
			tws_finish("erase only");
			exit;
		}
		break;
	}
}

function Dev_TwSelftest_Step() {

	if (!variable_global_exists("tw_selftest") || !global.tw_selftest) return;
	if (!variable_global_exists("tws_phase"))
	{
		global.tws_phase = "boot";  global.tws_t = 0;  global.tws_zi = 0;  global.tws_ci = 0;
		global.tws_zone_label = "start";  global.tws_prog = 0;  global.tws_b = undefined;
		global.tws_cases = [];  global.tws_death_stage = 0;  global.tws_row = "";
		global.tws_devtools0 = instance_exists(g) ? g.DevTools_state : false;
		if (!variable_global_exists("tw_selftest_mode")) global.tw_selftest_mode = "";
		// No real chat during a selftest. tw_irc_enabled is forced off below, but the boot
		// auto-connect (frame 120) had already opened the socket by then: every run logged in
		// to the owner's channel and stayed there, and a live chat's commands would have landed
		// in the middle of the test (seen 2026-10-02: "TWITCH: connected" on the erase run).
		global.tw_irc_autoconnect_done = true;
		file_delete(working_directory + "_tw_selftest_result.log"); // fresh log (an empty open_write left a NUL byte)
	}
	global.tws_t++;
	global.tws_prog++;
	if (global.tws_prog > 3600)
	{
		tws_log("FAIL  STUCK 60s in phase=" + global.tws_phase + " zone=" + global.tws_zone_label + " case=" + string(global.tws_ci));
		tws_finish("watchdog");
		exit;
	}

	// Flag text "erase" never reaches gameplay: it runs on the file-select screen.
	if (global.tw_selftest_mode == "erase") { tws_erase_step(); exit; }

	// keep the harness in charge every frame
	global.tw_enabled             = true;
	global.tw_irc_enabled         = false;
	global.tw_irc_status          = "selftest";
	global.tw_rl                  = (variable_global_exists("tws_rl_on") && global.tws_rl_on); // off, except for the edge run's game-over callout
	global.tw_irc_cooldown_frames = 0;
	var _feat = (global.tws_phase == "feat" || global.tws_phase == "menus" || global.tws_phase == "edge"); // these set the per-chatter cooldown and the points gate themselves
	if (!_feat) global.tw_user_cooldown_frames = 0; // every row is typed by "tstchatter": the 30 s per-chatter cooldown would refuse all but the first
	if (variable_global_exists("tws_cs_x0") && variable_global_exists("tws_cs_maxd") && instance_exists(global.pc))
	{   // catslap: track the peak every frame
		global.tws_cs_maxd = max(global.tws_cs_maxd, abs(global.pc.x - global.tws_cs_x0));
		if (variable_global_exists("tws_cs_maxh") && variable_instance_exists(global.pc, "hspd")) global.tws_cs_maxh = max(global.tws_cs_maxh, global.pc.hspd);
	}
	global.tw_autosave            = false; // the harness mangles slot 1 (XP cap, forced death): no checkpoints of that, and no pruning the owner's real ones
	if (!_feat) global.tw_points_on = false; // "tstchatter" has 0 pts; with points on every paid verb is refused yet still grades PASS
	if (global.tws_death_stage == 0 || global.tws_death_stage == 3) // every stage but the death test itself
	{
		// PC_take_damage only honours dev_invState while g.DevTools_state is on. Run 1 had it
		// off: chat-spawned enemies killed Link over and over (4 lives -> game over -> STUCK).
		if (instance_exists(g)) { g.DevTools_state = true; g.dev_invState = 2; } // no damage, no knockback
		if (instance_exists(f) && f.hp < 16) adjust_stat(9999, 9999);   // !hurt/!poison bypass PC_take_damage
		// Run 2 stuck here: !smite killed 7 spawned enemies, the XP opened the LEVEL-UP menu, and
		// that menu waits for a button the harness cannot press. Same isolation the co-op test
		// uses (Dev_CoopTest_Step): hold XP under the threshold and close the menu.
		if (instance_exists(f))
		{
			f.xpPending = 0;
			f.xpDrain   = 0;
			if (f.xp >= f.xpNext) f.xp = max(0, f.xpNext - 1);
		}
		if (instance_exists(g) && g.gui_state == g.gui_state_LEVEL_UP)
		{
			g.gui_state = g.gui_state_NONE;
			tws_log("   (harness closed a LEVEL-UP menu)");
		}
	}

	switch (global.tws_phase)
	{
	case "boot":
		if (!tws_live()) { global.tws_t = 0; exit; }
		if (global.tws_t < 90) exit;
		global.tw_effect_secs = 2; // short effects: each verb expires quickly, one at a time
		tws_log("== ZALiA twitch selftest v" + ZALIA_VERSION + " (" + ZALIA_BUILD_DATE + ") -- ISOLATED, per zone ==");
		tws_log("tier: dev_avail=" + string(dev_avail()) + " tester=" + string(global.dev_unlock_tester) + " hotkeys=" + string(dev_hotkeys_avail()));
		if (global.tw_selftest_mode == "menus") tws_go("menus");
		else if (global.tw_selftest_mode == "edge")  { global.tws_es = 0; global.tws_et = 0; tws_go("edge"); }
		else if (global.tw_selftest_mode == "edge2") tws_go("edge2");
		else tws_go((global.tw_selftest_mode == "feat" || global.tw_selftest_mode == "") ? "feat" : "zone_start");
		break;

	case "menus":
		// Flag text "menus" (~10 s): screenshots of the options pages v2.1.8 added rows to, the
		// DEATH COUNTER on the HUD, and one real run of RESET ALL SETTINGS. The menu is opened
		// the way update_OptionsMenu opens it; nothing presses a key. RESET writes the prefs and
		// the Twitch config, so selftest_run.ps1 backs both up first and restores them after.
		if (global.tws_t < 30 && !tws_live()) { global.tws_t = 0; exit; }
		var _om = global.OPTIONS_MENU;
		if (global.tws_t == 30)
		{
			tws_log("---- options menu pages + RESET ALL SETTINGS");
			with (_om)
			{
				anim_frame = 0; MainOption = 0; draw_rows_count = 0;
				gui_state_backup = g.gui_state;
				g.gui_state      = g.gui_state_OPTIONS;
				menu_state        = menu_state_MAIN;
				InputConfigState  = InputConfigState_MAIN;
				InputConfigOption = InputConfigOption_RIGHT;
				timer = 0;
				sub_state = sub_state_OPENING1;
			}
		}
		if (global.tws_t == 110) { tws_shot("menu_main");               with (_om) { Other_state = Other_state_MAIN; menu_state = menu_state_OTHER; Other_cursor = Other_DEATH_COUNTER; timer = 0; } }
		if (global.tws_t == 140) { tws_shot("menu_other_deathcounter"); with (_om) Other_cursor = Other_RESET; }
		if (global.tws_t == 170) { tws_shot("menu_other_reset");        with (_om) Other_cursor = Other_BACK; }
		if (global.tws_t == 200) { tws_shot("menu_other_back");         with (_om) { menu_state = menu_state_TWITCH; Twitch_cursor = Twitch.EFFECTS_HUD; } }
		if (global.tws_t == 220) { tws_shot("menu_twitch_effecttimers");    with (_om) Twitch_cursor = Twitch.USER_COOLDOWN; }
		if (global.tws_t == 240) { tws_shot("menu_twitch_chattercooldown"); with (_om) Twitch_cursor = Twitch.MOD_BYPASS; }
		// 10-14: CHAT EXTRAS sub-page (the keys that used to be twitch_config.txt-only)
		if (global.tws_t == 260) { tws_shot("menu_twitch_modsskip");        with (_om) { menu_state = menu_state_CHAT_EXTRAS; ChatX_cursor = ChatX.TOASTY; } }
		if (global.tws_t == 275)
		{
			tws_shot("menu_chatextras_toasty");
			var _cx_ok = false; with (_om) _cx_ok = (menu_state == menu_state_CHAT_EXTRAS && ds_grid_width(ChatX_dg) == ChatX.COUNT);
			tws_feat("CHAT EXTRAS page is open with every row", _cx_ok, "ChatX.COUNT=" + string(ChatX.COUNT));
			tws_chatx_tests(_om);
		}
		if (global.tws_t == 290) { tws_shot("menu_chatextras_bounty");      with (_om) { menu_state = menu_state_MAIN; timer = 0; sub_state = sub_state_CLOSING1; } }
		if (global.tws_t == 380)
		{
			tws_feat("the options menu closed again", g.gui_state == g.gui_state_NONE, "gui_state=" + string(g.gui_state));
			global.dbg_death_counter_show = true;
		}
		if (global.tws_t == 420)
		{
			tws_shot("hud_deathcounter");
			// knock a few settings off their defaults, on three different objects, then reset
			g.all_bg_black_only            = true;
			g.ScreenShake_user_pref        = false;
			global.tw_effect_secs          = 33;
			global.tw_user_cooldown_frames = 77;
			global.tw_points_on            = false;
			if (instance_exists(Audio)) Audio.snd_vol = 1;
			var _tn0 = variable_global_exists("tw_toasts") ? array_length(global.tw_toasts) : 0;
			var _dm0 = global.DisplayMode; // the DISPLAY page is kept (owner 2026-10-01)
			options_reset_to_defaults();
			tws_feat("RESET ALL SETTINGS leaves the display scaling mode alone", global.DisplayMode == _dm0, "DisplayMode " + string(_dm0) + " -> " + string(global.DisplayMode));
			var _tn1 = variable_global_exists("tw_toasts") ? array_length(global.tw_toasts) : 0;
			var _rok = !g.all_bg_black_only && g.ScreenShake_user_pref && global.tw_effect_secs == 5 && global.tw_user_cooldown_frames == 1800
			        && global.tw_points_on && !global.dbg_death_counter_show && (!instance_exists(Audio) || Audio.snd_vol == Audio.Volume_DEFAULT);
			tws_feat("RESET ALL SETTINGS runs and puts every poked setting back", _rok,
			         "black_bgr=" + string(g.all_bg_black_only) + " shake=" + string(g.ScreenShake_user_pref) + " effect_secs=" + string(global.tw_effect_secs)
			         + " chatter_cd=" + string(global.tw_user_cooldown_frames) + " points=" + string(global.tw_points_on)
			         + " death_counter=" + string(global.dbg_death_counter_show) + " snd_vol=" + (instance_exists(Audio) ? string(Audio.snd_vol) : "-"));
			tws_feat("the SETTINGS RESET notice was queued (it used to be filed under a toast type that is OFF)", _tn1 > _tn0, "toast plates " + string(_tn0) + " -> " + string(_tn1));
		}
		if (global.tws_t == 470) tws_shot("reset_toast");
		if (global.tws_t >= 480) { tws_finish("menus only"); exit; }
		break;

	case "feat":
		// What the verb matrix cannot grade by "did a toast appear": billing, both cooldowns,
		// the ignore list, a vote from start to winner, the !hurt floor, real durations. Every
		// line goes in as a raw IRC line (tws_line), so the tag parser, the ignore gate, the
		// ballot reader and the points check all run exactly as they do for a live chat.
		// Flag text "feat" runs this alone (~15 s); the full run does it first.
		if (global.tws_t < 30 && !tws_live()) { global.tws_t = 0; exit; }
		if (variable_global_exists("tw_points_frame")) global.tw_points_saved = global.tw_points_frame; // no points.txt write while test chatters are in the map
		if (global.tws_t == 30)
		{
			tws_log("---- v2.1.8 feature checks in " + g.rm_name);
			global.tws_feat0 = {
				dirty    : (variable_global_exists("tw_points_dirty") && global.tw_points_dirty),
				ign_file : file_exists("ignored.txt"),
				mod_byp  : (!variable_global_exists("tw_mod_bypass") || global.tw_mod_bypass)
			};
			global.tw_points_on = false;
			global.tw_user_cooldown_frames = 0;
			var _t, _t2;

			_t = tws_line("tstchatter", "!ver");      tws_feat("!ver",   string_pos(ZALIA_VERSION, _t) > 0, _t);
			_t = tws_line("tstchatter", "!build");    tws_feat("!build", string_pos(ZALIA_VERSION, _t) > 0, _t);
			_t = tws_line("tstchatter", "!gorilla");  tws_feat("!gorilla spawns a goriya", string_pos("goriya", string_lower(_t)) > 0, _t);
			_t = tws_line("tstchatter", "!kills");    tws_feat("!kills answers", _t != "", _t);
			_t = tws_line("tstchatter", "!top");      tws_feat("!top answers",   _t != "", _t);

			// !hurt can never kill, and a refused command earns no kill credit
			f.hp = 2;
			_t = tws_line("tstchatter", "!hurt 8");
			tws_feat("!hurt 8 at 2 HP stops at 1 HP", f.hp == 1 && !global.pc.is_dead, "hp 2 -> " + string(f.hp));
			global.tw_last_hurter = "";
			_t = tws_line("tstchatter", "!hurt");
			tws_feat("a refused !hurt (already 1 HP) earns no kill credit", f.hp == 1 && global.tw_last_hurter == "", "hurter='" + string(global.tw_last_hurter) + "'   " + _t);
			adjust_stat(9999, 9999);

			// "!deny jump 10": the number is seconds
			_t = tws_line("tstchatter", "!deny jump 10");
			var _dn = array_length(global.tw_active);
			var _de = (_dn > 0) ? global.tw_active[_dn - 1] : undefined;
			var _dok = is_struct(_de) && variable_struct_exists(_de, "deny") && _de.bits == PC_LOCK_JUMP && _de.frames >= 590 && _de.frames <= 600;
			tws_feat("!deny jump 10 locks jump for 10 s", _dok, (is_struct(_de) && variable_struct_exists(_de, "frames") ? "frames=" + string(_de.frames) : "no entry") + "   " + _t);
			tws_line("tstchatter", "!undeny");

			// !invuln is in SECONDS (the timer only ticks once every timer_b period)
			global.pc.iframes_timer = 0;
			_t = tws_line("tstchatter", "!invuln 5");
			var _per = g.timer_b_DURATION1 + 1;
			tws_feat("!invuln 5 gives 5 s, not 105 s", global.pc.iframes_timer == ceil(300 / _per),
			         "iframes_timer=" + string(global.pc.iframes_timer) + " ticks x " + string(_per) + " frames = " + string(global.pc.iframes_timer * _per / 60) + " s");
			global.pc.iframes_timer = 0;

			// per-chatter cooldown, and mods skipping it
			global.tw_user_cooldown_frames = 1800;
			global.tw_mod_bypass = true;
			_t  = tws_line("tstcd", "!shake");
			_t2 = tws_line("tstcd", "!shake");
			tws_feat("per-chatter cooldown refuses a second command", string_pos("tstcd -> shake", _t) > 0 && string_pos("your cooldown", _t2) > 0, _t + "  /  " + _t2);
			tws_line("tstmod", "!shake", true);
			_t2 = tws_line("tstmod", "!shake", true);
			tws_feat("a mod skips the cooldown", _t2 != "" && string_pos("cooldown", _t2) == 0, _t2);
			global.tw_user_cooldown_frames = 0;
			global.tw_mod_bypass = global.tws_feat0.mod_byp;

			// ignore list: mods only, drops the chatter everywhere, reversible
			_t = tws_line("tstcd", "!ignore tstvic");
			tws_feat("!ignore from a non-mod is refused", string_pos("mods only", _t) > 0 && !tw_ignore_has("tstvic"), _t);
			_t  = tws_line("tstmod", "!ignore tstvic", true);
			_t2 = tws_line("tstvic", "!shake");
			tws_feat("an ignored chatter's command is dropped", tw_ignore_has("tstvic") && _t2 == "", _t + "  /  victim got '" + _t2 + "'");
			_t  = tws_line("tstmod", "!unignore tstvic", true);
			_t2 = tws_line("tstvic", "!shake");
			tws_feat("!unignore lets them back in", !tw_ignore_has("tstvic") && _t2 != "", _t + "  /  victim got '" + _t2 + "'");
			if (!global.tws_feat0.ign_file && tw_ignore_count() == 0 && file_exists("ignored.txt")) file_delete("ignored.txt"); // leave the save folder as it was

			// points: a broke viewer buys nothing directly. A vote is FREE to start and its
			// winner is free (owner's ruling 2026-10-01) -- checked so nobody "fixes" it again.
			global.tw_points_on = true;
			_t = tws_line("tstpoor", "!smite");
			tws_feat("a broke viewer cannot buy !smite", string_pos("needs", _t) > 0, _t);
			tw_points_add("tstrich", 100);
			_t = tws_line("tstrich", "!vote dark flip 10");
			var _bal = tw_points_get("tstrich");
			tws_feat("starting a vote is free", tw_vote_active() && _bal == 100 + 1, "100 pts +1 for the message -> " + string(_bal) + "   " + _t);
			tws_line("tstvic",  "2");
			tws_line("tstcd",   "flip");
			tws_line("tstpoor", "!dark");
			tws_feat("ballots  2 / flip / !dark  count 1-2", tw_vote_active() && global.tw_vote.na == 1 && global.tw_vote.nb == 2, tw_vote_line());

			// a swarm typed while the screen is busy is queued -- and paid for when it is queued
			var _cut0 = g.cutscene;
			var _bal0 = tw_points_get("tstrich");
			g.cutscene = true;
			_t = tws_line("tstrich", "!swarm 3");
			g.cutscene = _cut0;
			var _qn = (variable_global_exists("tw_swarm_queue") && is_array(global.tw_swarm_queue)) ? array_length(global.tw_swarm_queue) : -1;
			tws_feat("a queued !swarm is charged when queued (25)", _qn == 1 && tw_points_get("tstrich") == _bal0 + 1 - 25,
			         "queue=" + string(_qn) + "  balance " + string(_bal0) + " +1 for the message -> " + string(tw_points_get("tstrich")) + "   " + _t);
			global.tw_swarm_queue = [];
			global.tws_feat0.bal_after_swarm = tw_points_get("tstrich");
			global.tw_last_hurter = "";
		}
		if (global.tws_t == 100)
		{
			// 10-24: HELP CARD row (off by default since the card blocked Lane's screen). Off = a
			// toast and no card; on = the page as before.
			global.tw_help_card = false; global.tw_help_timer = 0;
			var _t0 = tws_line("tstchatter", "!help hurt");
			tws_feat("!help with HELP CARD off is a one-line toast, no card", global.tw_help_timer == 0 && string_pos("pinned", string(global.tw_toast)) > 0,
			         "help timer=" + string(global.tw_help_timer) + "  toast=" + string(global.tw_toast) + "   " + _t0);
			global.tw_help_card = true;
			tws_line("tstchatter", "!help hurt");
			tws_feat("!help hurt puts a page up (HELP CARD on)", global.tw_help_timer > 0, "help timer=" + string(global.tw_help_timer));
		}
		if (global.tws_t == 140) tws_shot("help_hurt");
		if (global.tws_t == 150) tws_line("tstchatter", "!help mods");
		if (global.tws_t == 190) tws_shot("help_mods");
		if (global.tws_t == 200) { global.tw_help_timer = 0; global.tw_help_card = false; }
		// 10-14 fun round: !bet / !bounty / !babality through the real chat entry (no boss on a town screen)
		if (global.tws_t == 300)
		{
			tw_points_add("tstgamb", 100); // its own chatter: the vote check at 720 reads the other balances
			var _b0 = tw_points_get("tstgamb");
			var _t = tws_line("tstgamb", "!bet win 20");
			tws_feat("!bet with no boss on screen is refused and costs nothing", string_pos("no boss", string(global.tw_toast)) > 0 && tw_points_get("tstgamb") == _b0 + 1,
			         "toast='" + string(global.tw_toast) + "'  balance " + string(_b0) + " -> " + string(tw_points_get("tstgamb")) + "   " + _t);
		}
		if (global.tws_t == 330)
		{
			var _t = tws_line("tstgamb", "!bounty moblin 20");
			tws_feat("!bounty is off by default", string_pos("bounties are off", string(global.tw_toast)) > 0, "toast='" + string(global.tw_toast) + "'   " + _t);
		}
		if (global.tws_t == 360)
		{
			global.tw_bounty_on = true;
			var _b0 = tw_points_get("tstgamb");
			var _t = tws_line("tstgamb", "!bounty moblin 20");
			var _nb = (ds_exists(global.tw_bounties, ds_type_map)) ? ds_map_size(global.tw_bounties) : -1;
			tws_feat("!bounty moblin 20 (bounty=1) opens one bounty and takes the 20", _nb == 1 && tw_points_get("tstgamb") == _b0 + 1 - 20,
			         "open=" + string(_nb) + "  balance " + string(_b0) + " -> " + string(tw_points_get("tstgamb")) + "   " + _t);
			if (ds_exists(global.tw_bounties, ds_type_map)) ds_map_clear(global.tw_bounties);
			global.tw_bounty_on = false;
		}
		if (global.tws_t == 390)
		{
			// 10-24: the Babality is a splash-queue step now (it used to fire over the FLAWLESS line).
			// At send time only the queue entry exists; the shrink lands once the FLAWLESS text
			// (100 frames) and the 20-frame gap have run -> checked at 520.
			var _t = tws_line("tstgamb", "!babality");
			var _queued = false;
			if (is_array(global.tw_splash_queue))
			{   for (var _qi = 0; _qi < array_length(global.tw_splash_queue); _qi++)
			    {   var _qe = global.tw_splash_queue[_qi]; if (is_struct(_qe) && variable_struct_exists(_qe, "fn") && is_method(_qe.fn)) _queued = true;  }
			}
			var _hit0 = false;
			for (var _bi = 0; _bi < array_length(global.tw_active); _bi++)
			{   var _be = global.tw_active[_bi]; if (is_struct(_be) && variable_struct_exists(_be, "verb") && _be.verb == "babality") _hit0 = true;  }
			tws_feat("!babality queues the Babality behind FLAWLESS instead of firing over it", _queued && !_hit0, "queued=" + string(_queued) + "  shrunk already=" + string(_hit0) + "   " + _t);
		}
		if (global.tws_t == 520)
		{
			var _hit = false;
			for (var _bi = 0; _bi < array_length(global.tw_active); _bi++)
			{   var _be = global.tw_active[_bi]; if (is_struct(_be) && variable_struct_exists(_be, "verb") && _be.verb == "babality") _hit = true;  }
			var _sc = instance_exists(global.pc) && variable_instance_exists(global.pc, "tw_scale_mul") ? global.pc.tw_scale_mul : -1;
			tws_feat("!babality shrinks Link to 0.45 on a timer once its queue step runs", _hit && _sc == 0.45, "entry=" + string(_hit) + "  scale=" + string(_sc));
		}
		if (global.tws_t == 420)
		{
			if (!ds_exists(global.tw_bets, ds_type_map)) global.tw_bets = ds_map_create();
			var _b0 = tw_points_get("tstgamb");
			global.tw_bets[? "tstgamb"] = "win,20";
			global.tw_bets[? "tstpoor"] = "death,10";
			tw_bets_resolve("flawless");
			tws_feat("a flawless pays the win bettor 2x and clears the book", tw_points_get("tstgamb") == _b0 + 40 && ds_map_size(global.tw_bets) == 0,
			         "balance " + string(_b0) + " -> " + string(tw_points_get("tstgamb")) + "  book=" + string(ds_map_size(global.tw_bets)));
		}
		if (global.tws_t >= 720)
		{
			var _lh = variable_global_exists("tw_last_hurter") ? string(global.tw_last_hurter) : "";
			tws_feat("the vote ended and FLIP fired in the starter's name, at no charge", !tw_vote_active() && _lh == "tstrich" && tw_points_get("tstrich") == global.tws_feat0.bal_after_swarm,
			         "vote running=" + string(tw_vote_active()) + "  last hurter='" + _lh + "'  balance " + string(tw_points_get("tstrich")));
			// leave nothing behind: test chatters out of the points maps, effects off, flags restored
			var _names = ["tstchatter", "tstcd", "tstmod", "tstvic", "tstpoor", "tstrich", "tstgamb"];
			for (var _ni = 0; _ni < array_length(_names); _ni++)
			{
				if (variable_global_exists("tw_points")      && ds_exists(global.tw_points,      ds_type_map)) ds_map_delete(global.tw_points,      _names[_ni]);
				if (variable_global_exists("tw_points_seen") && ds_exists(global.tw_points_seen, ds_type_map)) ds_map_delete(global.tw_points_seen, _names[_ni]);
				if (variable_global_exists("tw_points_rate") && ds_exists(global.tw_points_rate, ds_type_map)) ds_map_delete(global.tw_points_rate, _names[_ni]);
			}
			global.tw_points_dirty = global.tws_feat0.dirty;
			global.tw_points_on    = false;
			global.tw_last_hurter  = "";
			tw_effects_clear_all(false);
			if (global.tw_selftest_mode == "feat") { tws_finish("feat only"); exit; }
			tws_go("zone_start");
		}
		break;

	case "edge":
		// Flag text "edge" (~75 s): the rows the 2026-10-01 review left as "fixed, not exercised"
		// or "not tested". Stages, in order:
		//   0  a wiped queued !swarm is refunded; !spawn mid room-change; !ice 20 on the strip
		//   2  file_load on corrupt slot files; the writer and file_save against a locked file
		//  50  !challenge through a death in a palace, and off when the palace is left
		//   3  the DEATH COUNTER and CHATTER COOLDOWN rows worked with real key presses
		//   4  Alt+Enter and Escape in fullscreen, also real key presses
		//   6  last life: KILLED BY plate, then GG / EZ on the game-over screen (ends the run)
		// Keys go in through keyboard_key_press, so the game reads them exactly as it reads the
		// keyboard -- but only while the window has focus (selftest_edge.ps1 raises it). The file
		// checks never touch a real slot: the slot's file NAME is aimed at a scratch file for the
		// one call. selftest_edge.ps1 also holds "_tws_locked.txt" open for the locked-file
		// checks, backs up and restores every settings and save file, and boots a second time
		// with flag text "edge2" to see what survived the restart.
		if (variable_global_exists("tw_points_frame")) global.tw_points_saved = global.tw_points_frame; // no points.txt write while test chatters are in the map
		global.tws_et++;
		var _eom = global.OPTIONS_MENU;
		switch (global.tws_es)
		{
		case 0:
			if (!tws_live()) { global.tws_et = 0; break; }
			if (global.tws_et < 30) break;
			tws_log("---- edge checks in " + g.rm_name);
			global.tws_zone_label = "edge";
			global.tws_edge0 = {
				dirty : (variable_global_exists("tw_points_dirty") && global.tw_points_dirty),
				hud   : (!variable_global_exists("tw_effects_hud") || global.tw_effects_hud),
				game  : tw_toast_secs_get("game")
			};
			global.tw_user_cooldown_frames = 0;
			var _et;

			// a paid, queued !swarm that a death wipes before it lands is handed back
			global.tw_points_on = true;
			tw_points_add("tstrich", 100);
			var _ecut = g.cutscene;
			g.cutscene = true;
			_et = tws_line("tstrich", "!swarm 3");
			g.cutscene = _ecut;
			var _ebalq = tw_points_get("tstrich");
			var _eqn   = array_length(global.tw_swarm_queue);
			tw_effects_clear_all(true);
			tws_feat("a queued !swarm wiped by a death is refunded", _eqn == 1 && _ebalq < 100 && tw_points_get("tstrich") == _ebalq + 25 && array_length(global.tw_swarm_queue) == 0,
			         "queued=" + string(_eqn) + "  balance after paying " + string(_ebalq) + " -> after the wipe " + string(tw_points_get("tstrich")) + "   " + _et);

			// a spawn that arrives while the room is being changed
			var _een  = instance_number(Enemy);
			var _ecrt = g.ChangeRoom_timer;
			var _ebal = tw_points_get("tstrich");
			g.ChangeRoom_timer = 5;
			_et = tws_line("tstrich", "!spawn goriya");
			g.ChangeRoom_timer = _ecrt;
			tws_feat("!spawn during a room change fizzles, spawns nothing, costs nothing", string_pos("fizzled", _et) > 0 && instance_number(Enemy) == _een && tw_points_get("tstrich") >= _ebal,
			         "enemies " + string(_een) + " -> " + string(instance_number(Enemy)) + "  balance " + string(_ebal) + " -> " + string(tw_points_get("tstrich")) + "   " + _et);
			global.tw_points_on = false;

			// "!ice 20 shows ICE 20S top-right": the entry the strip reads, then a screenshot of it
			global.tw_effects_hud = true;
			_et = tws_line("tstchatter", "!ice 20");
			var _eie = undefined;
			for (var _ei = 0; _ei < array_length(global.tw_active); _ei++)
			{   var _eix = global.tw_active[_ei]; if (is_struct(_eix) && variable_struct_exists(_eix, "verb") && string_pos("ice", string(_eix.verb)) == 1) _eie = _eix;  }
			tws_feat("!ice 20 runs 20 s and carries the tag the EFFECT TIMERS strip prints", is_struct(_eie) && _eie.frames >= 1190 && _eie.frames <= 1200,
			         (is_struct(_eie) ? "strip row '" + string_upper(string(_eie.verb)) + " " + string(ceil(_eie.frames / 60)) + "S'" : "no tagged entry") + "   " + _et);
			tws_stage(1);
			break;

		case 1:
			if (global.tws_et < 40) break;
			tws_shot("ice20_strip");
			tw_effects_clear_all(false);
			global.tw_effects_hud = global.tws_edge0.hud;
			tws_stage(2);
			break;

		case 2:
			var _esl  = f.file_num;                      // the slot in play; its file NAME is re-aimed, the file is never opened
			var _enm0 = f.dl_file_names[| _esl - 1];
			var _epx0 = f.dl_FILE_NAME_PREFIX[| _esl - 1];
			var _escr = "_tws_scratch_save.txt";
			var _ebad = ["", " ", "garbage", "{\"a\":", "[1,2]", "{}"];
			var _esig0 = string(f.quest_num) + "/" + string(f.death_count) + "/" + string(g.rm_name);
			var _ecnt = 0, _ecd = "";
			for (var _ebi = 0; _ebi < array_length(_ebad); _ebi++)
			{
				var _ebh = file_text_open_write(working_directory + _escr);
				file_text_write_string(_ebh, _ebad[_ebi]);
				file_text_close(_ebh);
				global.tw_toasts = []; // the same plate twice within half a second is dropped as spam
				f.dl_file_names[| _esl - 1] = _escr;
				file_load(_esl);
				f.dl_file_names[| _esl - 1] = _enm0;
				var _ehit = (tws_plate("UNREADABLE") != "");
				if (_ehit) _ecnt++;
				_ecd += "  [" + _ebad[_ebi] + "]=" + (_ehit ? "refused" : "LOADED");
			}
			file_delete(working_directory + _escr);
			var _esig1 = string(f.quest_num) + "/" + string(f.death_count) + "/" + string(g.rm_name);
			tws_feat("file_load on six kinds of corrupt slot file: refused each time, the game in play untouched", _ecnt == array_length(_ebad) && _esig0 == _esig1,
			         tws_plate("UNREADABLE") + _ecd + "   state " + _esig0 + " -> " + _esig1);

			// an ordinary save, onto a scratch file nothing is holding: the writer reads its own
			// .tmp back before it swaps (file_text_holds), and a wrong "no" there would report
			// every save as failed. Real save text, real size.
			var _eok  = "_tws_scratch_save.txt";
			var _eoh  = file_text_open_write(working_directory + _eok);
			file_text_write_string(_eoh, "{\"save_name\":\"TWS\"}");
			file_text_close(_eoh);
			var _eokey = STR_Save + STR_File + hex_str(_esl) + STR_Encoded;
			var _eoenc = global.dm_save_file_data[? _eokey];
			var _eodm  = ds_map_create();
			ds_map_copy(_eodm, global.dm_save_file);
			global.tw_toasts = [];
			f.dl_file_names[| _esl - 1]       = _eok;
			f.dl_FILE_NAME_PREFIX[| _esl - 1] = "_tws_scratch";
			file_save(_esl, false);
			f.dl_file_names[| _esl - 1]       = _enm0;
			f.dl_FILE_NAME_PREFIX[| _esl - 1] = _epx0;
			var _eonew = global.dm_save_file_data[? _eokey];
			if (is_undefined(_eoenc)) ds_map_delete(global.dm_save_file_data, _eokey); else global.dm_save_file_data[? _eokey] = _eoenc;
			ds_map_copy(global.dm_save_file, _eodm);
			ds_map_destroy(_eodm);
			var _eolen = string_length(tws_file_text(_eok));
			tws_feat("an ordinary save writes the whole save, leaves no .tmp and raises no alarm", is_string(_eonew) && _eolen == string_length(_eonew) && _eolen > 500 && !file_exists(_eok + ".tmp") && tws_plate("NOT WRITTEN") == "",
			         "file " + string(_eolen) + " chars, save text " + (is_string(_eonew) ? string(string_length(_eonew)) : "-") + " chars, .tmp left=" + string(file_exists(_eok + ".tmp")) + ", plate '" + tws_plate("NOT WRITTEN") + "'");
			file_delete(working_directory + _eok);

			var _elk = "_tws_locked.txt";
			if (!file_exists(_elk)) tws_log("SKIP  [edge]  locked-file checks: selftest_edge.ps1 holds " + _elk + " open, and it is not there");
			else
			{
				// Another process holds the file open (others may read it, nobody may write or
				// delete it). First run of this, 2026-10-01: file_delete and file_rename both
				// returned false, file_text_open_write still handed back handle 1, the text did
				// not change, and the writer deleted its .tmp and reported success.
				var _ewr  = file_text_write_atomic(working_directory + _elk, "NEW TEXT");
				var _etmp = file_exists(_elk + ".tmp");
				tws_feat("a locked file: the writer says it failed and keeps the new text beside it", !_ewr && _etmp && tws_file_text(_elk + ".tmp") == "NEW TEXT",
				         "returned " + string(_ewr) + "  .tmp kept=" + string(_etmp) + "  .tmp holds '" + tws_file_text(_elk + ".tmp") + "'");
				if (_etmp) file_delete(working_directory + _elk + ".tmp");

				// file_save also refreshes its in-memory copies of the slot: put those back after
				var _ekey  = STR_Save + STR_File + hex_str(_esl) + STR_Encoded;
				var _eenc0 = global.dm_save_file_data[? _ekey];
				var _edm0  = ds_map_create();
				ds_map_copy(_edm0, global.dm_save_file);
				global.tw_toasts = [];
				f.dl_file_names[| _esl - 1]       = _elk;
				f.dl_FILE_NAME_PREFIX[| _esl - 1] = "_tws_scratch"; // keeps the slot's rando data / spoiler files out of it
				file_save(_esl, false);
				f.dl_file_names[| _esl - 1]       = _enm0;
				f.dl_FILE_NAME_PREFIX[| _esl - 1] = _epx0;
				if (is_undefined(_eenc0)) ds_map_delete(global.dm_save_file_data, _ekey); else global.dm_save_file_data[? _ekey] = _eenc0;
				ds_map_copy(global.dm_save_file, _edm0);
				ds_map_destroy(_edm0);
				tws_feat("file_save on a locked slot file puts up SAVE " + string(_esl) + " NOT WRITTEN", tws_plate("NOT WRITTEN") != "", tws_plate("NOT WRITTEN"));
				if (file_exists(_elk + ".tmp")) file_delete(working_directory + _elk + ".tmp");
			}
			global.tw_toasts = [];
			tws_stage(50);
			break;

		case 50:
			if (!tws_live()) { global.tws_et = 0; break; }
			tw_effects_clear_all(false);
			if (!tws_warp("_PalcA_01")) { tws_log("FAIL  [edge]  !challenge test: no exit found for _PalcA_01"); tws_stage(3); break; }
			tws_stage(51);
			break;

		case 51:
			if (!tws_live()) { global.tws_et = 0; break; }
			if (global.tws_et < 120) break;
			if (g.dungeon_num <= 0) { tws_log("FAIL  [edge]  !challenge test: the warp did not land in a palace (" + g.rm_name + ")"); tws_stage(3); break; }
			tws_log("---- !challenge through a death, in " + g.rm_name + " (palace " + string(g.dungeon_num) + ")");
			global.tw_toast = ""; global.tw_toast_timer = 0;
			tws_say("challenge");
			global.tws_chal_lost = "";
			tws_feat("!challenge switches on in a palace", global.tw_challenge && global.tw_flip, string(global.tw_toast));
			tws_stage(52);
			break;

		case 52:
			if (global.tws_et < 60) break;
			tws_feat("the challenge holds life at 4 containers", f.hp <= 4 * Container_AMT, "hp=" + string(f.hp) + "  (4 containers = " + string(4 * Container_AMT) + ")");
			global.tws_lives0 = max(global.pc_lives, 3);
			global.pc_lives   = global.tws_lives0;       // the death must land on NEXT LIFE, not GAME OVER
			global.tws_death_stage = 1;                  // harness invulnerability off
			global.tws_saw_death   = false;
			tws_kill();
			tws_stage(53);
			break;

		case 53:
			if (!global.tw_challenge && global.tws_chal_lost == "") global.tws_chal_lost = "switched off in " + room_get_name(room) + ", dungeon_num=" + string(g.dungeon_num);
			if (room == rmB_Death || !instance_exists(global.pc)) global.tws_saw_death = true;
			if (!global.tws_saw_death && global.tws_et < 600) break;
			if (!global.tws_saw_death) { tws_log("FAIL  [edge]  !challenge test: Link never died (10 s)"); global.tws_death_stage = 0; tws_stage(3); break; }
			tws_stage(54);
			break;

		case 54:
			if (!global.tw_challenge && global.tws_chal_lost == "") global.tws_chal_lost = "switched off in " + room_get_name(room) + ", dungeon_num=" + string(g.dungeon_num);
			if (!tws_live()) { global.tws_et = 0; break; }
			if (global.tws_et < 90) break;
			var _ekeep = 0;
			for (var _eki = 0; _eki < array_length(global.tw_active); _eki++)
			{   var _eke = global.tw_active[_eki]; if (is_struct(_eke) && variable_struct_exists(_eke, "keep_on_death") && _eke.keep_on_death) _ekeep++;  }
			tws_feat("!challenge is still on after the death", global.tw_challenge && global.tw_flip && _ekeep == 1 && f.hp <= 4 * Container_AMT,
			         "new life in " + g.rm_name + " (palace " + string(g.dungeon_num) + ")  lives " + string(global.tws_lives0) + " -> " + string(global.pc_lives)
			         + "  challenge=" + string(global.tw_challenge) + " flip=" + string(global.tw_flip) + " entries=" + string(_ekeep) + " hp=" + string(f.hp)
			         + ((global.tws_chal_lost == "") ? "" : "   " + global.tws_chal_lost));
			tws_shot("challenge_after_death");
			global.tws_death_stage = 0;                  // invulnerable again
			if (!tws_warp("_TownA_01")) { tws_log("FAIL  [edge]  !challenge test: no exit found for _TownA_01"); tws_stage(3); break; }
			tws_stage(55);
			break;

		case 55:
			if (!tws_live()) { global.tws_et = 0; break; }
			if (global.tws_et < 120) break;
			tws_feat("!challenge ends when the palace is left", g.dungeon_num <= 0 && !global.tw_challenge && !global.tw_flip && array_length(global.tw_active) == 0,
			         "now in " + g.rm_name + "  challenge=" + string(global.tw_challenge) + " flip=" + string(global.tw_flip) + " active=" + string(array_length(global.tw_active)));
			tw_effects_clear_all(false);
			tws_stage(3);
			break;

		case 3:
			// the two new option rows, worked the way a player works them
			if (global.tws_et < 10 && !tws_live()) { global.tws_et = 0; break; }
			var _ekJ = (Input.Key_jump  > 0) ? Input.Key_jump  : Input.Key_jump_alt;
			var _ekR = (Input.Key_right > 0) ? Input.Key_right : Input.Key_right_alt;
			if (global.tws_et == 10)
			{
				tws_log("---- option rows by key press, in " + g.rm_name + "  (window has focus: " + string(window_has_focus()) + ")");
				with (_eom)
				{
					anim_frame = 0; MainOption = 0; draw_rows_count = 0;
					gui_state_backup = g.gui_state;
					g.gui_state      = g.gui_state_OPTIONS;
					menu_state        = menu_state_MAIN;
					InputConfigState  = InputConfigState_MAIN;
					InputConfigOption = InputConfigOption_RIGHT;
					timer = 0;
					sub_state = sub_state_OPENING1;
				}
			}
			if (global.tws_et == 90)  { with (_eom) { Other_state = Other_state_MAIN; menu_state = menu_state_OTHER; Other_cursor = Other_DEATH_COUNTER; timer = 0; } }
			if (global.tws_et == 110) { global.tws_dc0 = global.dbg_death_counter_show; keyboard_key_press(_ekJ); }
			if (global.tws_et == 113) keyboard_key_release(_ekJ);
			if (global.tws_et == 135)
			{
				tws_feat("DEATH COUNTER row: the jump key flips it", global.dbg_death_counter_show != global.tws_dc0, string(global.tws_dc0) + " -> " + string(global.dbg_death_counter_show));
				with (_eom) { menu_state = menu_state_TWITCH; Twitch_cursor = Twitch.USER_COOLDOWN; timer = 0; }
				global.tw_user_cooldown_frames = 1800;
			}
			if (global.tws_et == 155) keyboard_key_press(_ekR);
			if (global.tws_et == 158) keyboard_key_release(_ekR);
			if (global.tws_et == 180)
			{
				tws_feat("CHATTER COOLDOWN row: one press right adds 5 s", global.tw_user_cooldown_frames == 2100, "1800 frames -> " + string(global.tw_user_cooldown_frames));
				tws_shot("menu_twitch_cooldown_35s");
				// what the second boot (flag text "edge2") must read back from the two files
				var _exh = file_text_open_write(working_directory + "_tws_edge_expect.txt");
				file_text_write_string(_exh, string(real(global.dbg_death_counter_show)) + "," + string(global.tw_user_cooldown_frames));
				file_text_close(_exh);
				with (_eom) { menu_state = menu_state_MAIN; timer = 0; sub_state = sub_state_CLOSING1; }
			}
			if (global.tws_et == 270)
			{
				tws_feat("the options menu closed again", g.gui_state == g.gui_state_NONE, "gui_state=" + string(g.gui_state));
				global.tw_user_cooldown_frames = 0;
				global.tws_fs0    = window_get_fullscreen();
				global.tws_fs_seq = global.tws_fs0 ? ["tog", "tog", "esc"] : ["tog", "esc", "tog"]; // the Escape check needs fullscreen; end as we started
				global.tws_fs_i   = 0;
				tws_log("---- fullscreen keys (started " + (global.tws_fs0 ? "fullscreen" : "windowed") + ")");
				tws_stage(4);
			}
			break;

		case 4:
			if (global.tws_fs_i >= array_length(global.tws_fs_seq))
			{
				tws_feat("the window is back the way it started", window_get_fullscreen() == global.tws_fs0, "fullscreen=" + string(window_get_fullscreen()));
				tws_stage(60);
				break;
			}
			if (global.tws_fs_seq[global.tws_fs_i] == "tog")
			{
				if (global.tws_et == 1)  { global.tws_fs_a = window_get_fullscreen(); keyboard_key_press(vk_alt); }
				if (global.tws_et == 3)  keyboard_key_press(vk_enter);
				if (global.tws_et == 6)  keyboard_key_release(vk_enter);
				if (global.tws_et == 8)  keyboard_key_release(vk_alt);
				if (global.tws_et == 60)
				{
					tws_feat("Alt+Enter: " + (global.tws_fs_a ? "fullscreen -> window" : "window -> fullscreen") + ", and no pause menu", window_get_fullscreen() != global.tws_fs_a && g.gui_state == g.gui_state_NONE,
					         "fullscreen " + string(global.tws_fs_a) + " -> " + string(window_get_fullscreen()) + "  gui_state=" + string(g.gui_state));
					global.tws_fs_i++;
					tws_stage(4);
				}
			}
			else
			{
				if (global.tws_et == 1)  keyboard_key_press(vk_escape);
				if (global.tws_et == 4)  keyboard_key_release(vk_escape);
				if (global.tws_et == 50)
				{
					tws_feat("Escape in fullscreen opens the quit menu and stays fullscreen", window_get_fullscreen() && g.gui_state == g.gui_state_QUIT_APP,
					         "fullscreen=" + string(window_get_fullscreen()) + "  gui_state=" + string(g.gui_state) + " (quit menu = " + string(g.gui_state_QUIT_APP) + ")");
					tws_shot("fullscreen_escape_quitmenu");
				}
				if (global.tws_et == 60) keyboard_key_press(vk_escape);
				if (global.tws_et == 63) keyboard_key_release(vk_escape);
				if (global.tws_et == 110)
				{
					tws_feat("Escape again closes the quit menu, still fullscreen", window_get_fullscreen() && g.gui_state == g.gui_state_NONE,
					         "fullscreen=" + string(window_get_fullscreen()) + "  gui_state=" + string(g.gui_state));
					global.tws_fs_i++;
					tws_stage(4);
				}
			}
			break;

		case 60:
			// back into the palace for the last death: the challenge has to END at a game over
			// (it only rides through the death and next-life screens), or the flip would follow
			// the player to the continue screen and the title
			if (!tws_live()) { global.tws_et = 0; break; }
			tw_effects_clear_all(false);
			if (!tws_warp("_PalcA_01")) tws_log("   (no exit found for _PalcA_01: the last-life test runs here, without the challenge)");
			tws_stage(6);
			break;

		case 6:
			// last life, with a chatter to blame: the KILLED BY plate, then chat's last word on
			// the game-over screen. Both are GAME TOASTS, OFF by default: switched on for this.
			if (global.tws_et <= 120 && !tws_live()) { global.tws_et = 0; break; } // settle in the palace first; after the kill nothing is "live"
			if (global.tws_et < 120) break;
			if (global.tws_et == 120)
			{
				tws_log("---- last life in " + g.rm_name + ": KILLED BY plate, then the game-over callout");
				variable_struct_set(global.tw_toast_secs, "game", 4);
				global.tws_rl_on = true;
				global.tw_rl     = true;
				tws_say("challenge");
				global.tws_chal_go = global.tw_challenge;
				global.tw_toasts = [];
				var _ekt = tws_line("tstkiller", "!swarm 3");
				tws_log("   " + _ekt + "   (last hurter '" + string(global.tw_last_hurter) + "')");
				global.pc_lives = 1;
				global.tws_death_stage = 1;
				global.tws_kplate = "";
				global.tws_gplate = "";
				global.tws_go_t   = -1;
				tws_kill();
			}
			if (global.tws_et > 120)
			{
				if (global.tws_kplate == "") global.tws_kplate = tws_plate("KILLED BY");
				for (var _egi = 0; _egi < array_length(global.tw_toasts); _egi++)
				{   var _egt = global.tw_toasts[_egi].title; if (_egt == "GG" || _egt == "EZ") global.tws_gplate = _egt;  }
				if (room == rmB_GameOver && global.tws_go_t < 0) global.tws_go_t = global.tws_et;
				if ((global.tws_go_t >= 0 && global.tws_et >= global.tws_go_t + 60) || global.tws_et > 1500)
				{
					var _ekills = tw_kills_top(5);
					tws_feat("the game went to GAME OVER on the last life", room == rmB_GameOver, "room " + room_get_name(room) + "  lives=" + string(global.pc_lives));
					tws_feat("death plate names the chatter, the verb and the tally", string_pos("TSTKILLER", global.tws_kplate) > 0 && string_pos("!SWARM  KILLS: 1", global.tws_kplate) > 0, (global.tws_kplate == "") ? "(no plate)" : global.tws_kplate);
					tws_feat("the kill is on the !kills board", string_pos("tstkiller x1", _ekills) > 0, (_ekills == "") ? "(nobody)" : _ekills);
					tws_feat("GG / EZ callout on the game-over screen", global.tws_gplate != "", (global.tws_gplate == "") ? "(no plate)" : global.tws_gplate);
					if (global.tws_chal_go) tws_feat("a game over ends the challenge (no mirrored continue screen or title)", !global.tw_challenge && !global.tw_flip,
					                                 "challenge=" + string(global.tw_challenge) + " flip=" + string(global.tw_flip));
					else tws_log("   (the challenge was not on for the last life: its game-over check did not run)");
					tws_shot("gameover_callout");
					// leave nothing behind
					var _enames = ["tstchatter", "tstrich", "tstkiller"];
					for (var _eni = 0; _eni < array_length(_enames); _eni++)
					{
						if (variable_global_exists("tw_points")      && ds_exists(global.tw_points,      ds_type_map)) ds_map_delete(global.tw_points,      _enames[_eni]);
						if (variable_global_exists("tw_points_seen") && ds_exists(global.tw_points_seen, ds_type_map)) ds_map_delete(global.tw_points_seen, _enames[_eni]);
						if (variable_global_exists("tw_points_rate") && ds_exists(global.tw_points_rate, ds_type_map)) ds_map_delete(global.tw_points_rate, _enames[_eni]);
					}
					global.tw_points_dirty = global.tws_edge0.dirty;
					variable_struct_set(global.tw_toast_secs, "game", global.tws_edge0.game);
					tws_finish("edge only");
					exit;
				}
			}
			break;
		}
		break;

	case "edge2":
		// Second boot of the edge run: what the first boot changed through the real menu rows
		// has to come back from UserPreferences.txt and twitch_config.txt.
		if (!tws_live()) { global.tws_t = 0; exit; }
		if (global.tws_t == 30)
		{
			var _xexp = "";
			if (file_exists("_tws_edge_expect.txt"))
			{
				var _xh = file_text_open_read(working_directory + "_tws_edge_expect.txt");
				_xexp = file_text_read_string(_xh);
				file_text_close(_xh);
				file_delete(working_directory + "_tws_edge_expect.txt");
			}
			var _xp = string_split(_xexp, ",");
			if (array_length(_xp) < 2) { tws_log("FAIL  [edge2]  no _tws_edge_expect.txt -- the edge run did not reach the option rows"); tws_finish("edge2 only"); exit; }
			tws_log("---- after a restart");
			twitch_irc_load_config(); // the harness zeroes the cooldown every frame: read the file again, now
			tws_feat("DEATH COUNTER setting survives a restart", real(global.dbg_death_counter_show) == real(_xp[0]), "saved " + _xp[0] + ", booted with " + string(real(global.dbg_death_counter_show)));
			tws_feat("CHATTER COOLDOWN setting survives a restart", global.tw_user_cooldown_frames == real(_xp[1]), "saved " + _xp[1] + " frames, booted with " + string(global.tw_user_cooldown_frames));
			global.dbg_death_counter_show = true; // for the screenshot
		}
		if (global.tws_t == 70) tws_shot("hud_deathcounter_after_restart");
		if (global.tws_t >= 80) { tws_finish("edge2 only"); exit; }
		break;

	case "zone_start":
		var _zs = tws_zones();
		if (global.tw_selftest_mode == "death") global.tws_zi = array_length(_zs);            // death test only
		// "pick:spawn goriya,swarm,catslap" = just those zone rows, in that order, town zone only.
		// For bisecting a row that passes alone and fails after other verbs.
		var _pick = (string_pos("pick:", global.tw_selftest_mode) == 1);
		if ((global.tw_selftest_mode == "zones" || global.tw_selftest_mode == "splash" || global.tw_selftest_mode == "tangia" || _pick) && global.tws_zi == 0) global.tws_zi = 1; // skip the full matrix
		if (global.tws_zi >= array_length(_zs))
		{
			if (global.tws_death_stage >= 3) { tws_finish("complete"); exit; }
			tws_go("death");
			break;
		}
		var _z = _zs[global.tws_zi];
		// The death test needs a side-scroll room, and the harness warp does not take from the
		// overworld (full run 2026-10-01: the test never started, STUCK 60s). So it runs just
		// BEFORE the overworld zone, from the cave zone's room, and the overworld goes last.
		if (_z[1] == "OW" && global.tws_death_stage == 0) { tws_go("death"); break; }
		global.tws_zone_label = _z[0];
		global.tws_cases      = (_z[2] == "all") ? tw_selftest_cases() : tws_zone_cases();
		if (global.tw_selftest_mode == "splash" || global.tw_selftest_mode == "tangia" || _pick)
		{   // quick look at one family only (MK2 splash / Tangia verbs): town zone, no death test
			if (global.tws_zi >= 2) { tws_finish((_pick ? "pick" : global.tw_selftest_mode) + " only"); exit; }
			var _tag = (global.tw_selftest_mode == "splash") ? "MK2" : "TANGIA";
			var _mk = [];
			if (_pick)
			{
				var _want = string_split(string_delete(global.tw_selftest_mode, 1, 5), ",");
				for (var _wi = 0; _wi < array_length(_want); _wi++)
				{
					var _wv = string_trim(_want[_wi]);
					for (var _mi = 0; _mi < array_length(global.tws_cases); _mi++)
					{   if (global.tws_cases[_mi][0] == _wv) { array_push(_mk, global.tws_cases[_mi]); break; }  }
				}
			}
			else
			{
				for (var _mi = 0; _mi < array_length(global.tws_cases); _mi++)
				{   if (string_pos(_tag, global.tws_cases[_mi][2]) > 0) array_push(_mk, global.tws_cases[_mi]);  }
			}
			global.tws_cases = _mk;
		}
		global.tws_ci         = 0;
		tw_effects_clear_all(false);
		if (_z[1] == "")
		{
			tws_log("---- zone " + _z[0] + " (" + g.rm_name + "), " + string(array_length(global.tws_cases)) + " verbs");
			tws_go("prep");
		}
		else if (tws_warp(_z[1]))
		{
			tws_log("---- zone " + _z[0] + " -> warp " + _z[1] + ", " + string(array_length(global.tws_cases)) + " verbs");
			tws_go("zone_wait");
		}
		else
		{
			tws_log("FAIL  zone " + _z[0] + ": no exit found for " + _z[1]);
			global.tws_zi++;
			tws_go("zone_start");
		}
		break;

	case "zone_wait":
		if (!tws_live()) { global.tws_t = 0; exit; }
		if (global.tws_t < 120) exit; // settle after the room change
		tws_log("   now in " + g.rm_name + " (type " + g.room_type + ")  view " + string(viewW()) + "x" + string(viewH())
		      + " at " + string(viewXL()) + "," + string(viewYT()));
		tws_shot("arrive");
		tws_go("prep");
		break;

	case "prep":
		if (global.tws_t == 1)
		{
			tw_effects_clear_all(false);
			global.tw_swarm_queue    = [];
			global.tw_help_timer     = 0;
			global.tw_toast          = "";
			global.tw_toast_timer    = 0;
			global.tw_irc_last_cmd   = -999999;
			global.tw_fz_toast_frame = -1000;
			if (instance_exists(f)) adjust_stat(9999, 9999);
		}
		var _splash_busy = (variable_global_exists("tw_splash_spr") && global.tw_splash_spr >= 0)
		                || (variable_global_exists("tw_splash_queue") && is_array(global.tw_splash_queue)
		                    && array_length(global.tw_splash_queue) > 0);
		if (!tws_live() || _splash_busy) { global.tws_t = 2; exit; }
		if (global.tws_t < 30) exit;
		if (global.tws_ci >= array_length(global.tws_cases))
		{
			global.tws_zi++;
			tws_go("zone_start");
			break;
		}
		global.tws_b = { lock : g.pc_lock, cucco : pc_is_cucco(), room : room, x : global.pc.x, y : global.pc.y };
		tws_go("fire");
		break;

	case "fire":
		var _c = global.tws_cases[global.tws_ci];
		global.tw_toast = ""; global.tw_toast_timer = 0; global.tw_apply_refused = false;
		if (_c[1] == "denyseq")
		{   // the chain depends on state carried between steps, so it runs within ONE frame
			var _A6 = PC_LOCK_JUMP | PC_LOCK_ATK1 | PC_LOCK_ATK2 | PC_LOCK_ATK3 | PC_LOCK_ATK4 | PC_LOCK_SPEL;
			var _steps = [["deny all", "all"], ["undeny jump", "nojump"], ["deny off", "none"], ["undeny", "noop"]];
			var _sok = true, _sd = "";
			for (var _si = 0; _si < array_length(_steps); _si++)
			{
				global.tw_toast = ""; global.tw_toast_timer = 0; global.tw_apply_ok = false;
				global.tw_irc_last_cmd = -999999;
				tws_say(_steps[_si][0]);
				var _h = 0;
				for (var _dj = 0; _dj < array_length(global.tw_active); _dj++)
				{   var _dd = global.tw_active[_dj]; if (variable_struct_exists(_dd, "deny")) _h |= _dd.bits;  }
				var _pass = false;
				switch (_steps[_si][1])
				{
					case "all":    _pass = (_h & _A6) == _A6; break;
					case "nojump": _pass = (_h & PC_LOCK_JUMP) == 0 && (_h & PC_LOCK_SPEL) != 0; break;
					case "none":   _pass = (_h == 0); break;
					case "noop":   _pass = (_h == 0) && !global.tw_apply_ok && string_pos("nothing is denied", string(global.tw_toast)) > 0; break;
				}
				if (!_pass) _sok = false;
				_sd += "  [" + _steps[_si][0] + ": " + (_pass ? "ok" : "BAD") + " held=" + string(_h) + "]";
			}
			global.tws_row = (_sok ? "PASS" : "FAIL") + "  [denyseq]" + _sd;
			tws_go("during");
			break;
		}
		tws_say(_c[0]);
		var _ok = false, _got = string(global.tw_toast), _expect = _c[1];
		var _held = 0;
		for (var _di = 0; _di < array_length(global.tw_active); _di++)
		{   var _de = global.tw_active[_di]; if (variable_struct_exists(_de, "deny")) _held |= _de.bits;  }
		var _all6 = PC_LOCK_JUMP | PC_LOCK_ATK1 | PC_LOCK_ATK2 | PC_LOCK_ATK3 | PC_LOCK_ATK4 | PC_LOCK_SPEL;
		var _tst  = (global.tw_toast_timer > 0 && string_pos("unknown:", _got) == 0);
		switch (_expect)
		{
			case "denyall":    _ok = _tst && (_held & _all6) == _all6; break;
			case "denynojump": _ok = _tst && (_held & PC_LOCK_JUMP) == 0 && (_held & PC_LOCK_SPEL) != 0; break;
			case "denynone":   _ok = _tst && _held == 0; break;
			case "denynoop":   _ok = _tst && _held == 0 && !global.tw_apply_ok && string_pos("nothing is denied", _got) > 0; break;
			case "arise":      _ok = _tst && (pc_is_cucco() || string_pos("OFF", _got) > 0)
			                        && (!pc_is_cucco() || !(g.CuccoSpell2_Acquired && g.CuccoSpell2_Option) || g.CuccoSpell2_Active); break;
			case "toast":      _ok = _tst; break;
			case "catslap":    _ok = _tst; global.tws_cs_x0 = global.pc.x; global.tws_cs_hp0 = f.hp; global.tws_cs_maxd = 0;
			                   global.tws_cs_cs0 = variable_instance_exists(global.pc, "cs") ? global.pc.cs : -1; global.tws_cs_maxh = 0; break; // graded in "after" on PEAK displacement
			case "silent":     _ok = (global.tw_toast_timer <= 0 || _got == ""); break;
			case "mean":       _ok = (string_pos("did you mean", _got) > 0); break;
			case "nomatch":    _ok = (string_pos("no match", _got) > 0); break;
		}
		global.tws_row = (_ok ? "PASS" : "FAIL") + "  [" + _expect + "]  " + _c[0] + "  ->  "
		               + ((_got == "") ? "(no toast)" : _got) + ((_c[2] == "") ? "" : "   (" + _c[2] + ")");
		tws_go("during");
		break;

	case "during":
		var _cd = global.tws_cases[global.tws_ci];
		// LATE rows: the finisher art starts ~1.3 s after the FLAWLESS VICTORY text, so shoot at 3.5 s
		if (global.tws_t < ((string_pos("LATE", _cd[2]) > 0) ? 210 : 40)) exit;
		tws_log(global.tws_row);
		if (string_pos("SHOT", _cd[2]) > 0) tws_shot(tw_slug(_cd[0]) + "_during");
		tws_go("expire");
		break;

	case "expire":
		// 2.1.10: !music plays the whole track by design (minutes, not the 5 s effect window). Stop
		// it here the way its own restore would, so the 35 s rule and the leak check grade the
		// verb's cleanup, not the length of the song.
		var _ce = global.tws_cases[global.tws_ci];
		if (string_pos("music", _ce[0]) == 1 && is_array(global.tw_active))
		{
			var _stopped = 0;
			for (var _mi = array_length(global.tw_active) - 1; _mi >= 0; _mi--)
			{
				var _me = global.tw_active[_mi];
				if (is_struct(_me) && variable_struct_exists(_me, "verb") && _me.verb == "music")
				{   if (variable_struct_exists(_me, "restore")) _me.restore(); array_delete(global.tw_active, _mi, 1); _stopped++;  }
			}
			if (_stopped > 0) tws_log("   (music plays the whole track by design -- stopped by the harness)");
		}
		var _n = tws_active_count();
		var _splash = (variable_global_exists("tw_splash_spr") && global.tw_splash_spr >= 0)
		           || (variable_global_exists("tw_flash_timer") && global.tw_flash_timer > 0);
		if ((_n > 0 || _splash) && global.tws_t < 2100) { global.tws_prog = 0; exit; } // up to 35 s (!confuse RNG is 10-30 s)
		if (_n > 0) tws_log("FAIL  OUTLIVED: " + string(_n) + " effect(s) still active 35 s later");
		tws_go("after");
		break;

	case "after":
		if (global.tws_t < 30) exit;
		var _ca   = global.tws_cases[global.tws_ci];
		var _leak = tws_leaks(global.tws_b);
		var _moved = (room != global.tws_b.room);
		if (_moved) _leak += " room-changed(now " + string(g.rm_name) + " hp=" + string(f.hp) + ")";
		// Nobody is holding the pad, so a verb that leaves Link at the same x but a different
		// height put him inside the floor or left him hanging: the chat chicken wore off 8 px
		// low and nothing here looked (found 2026-10-01 only because the NEXT verb, catslap,
		// could not move him).
		else if (instance_exists(global.pc) && abs(global.pc.x - global.tws_b.x) < 1 && abs(global.pc.y - global.tws_b.y) >= 2)
		{   _leak += " y-drift=" + string(global.pc.y - global.tws_b.y) + "(y " + string(global.tws_b.y) + " -> " + string(global.pc.y) + ")";  }
		if (_ca[0] == "challenge" && variable_global_exists("tw_challenge") && global.tw_challenge)
		{   // by design the challenge (flip + 4 hearts) lasts until the palace is left
			_leak = string_replace(_leak, " tw_flip", "");
			tws_log("   (challenge is ON and persistent by design -- cleared by the harness before the next verb)");
		}
		if (_ca[1] == "catslap" && string_pos("PASS", global.tws_row) == 1)
		{   // the slap must have MOVED Link (or fizzled with a reason off a battle screen) and cost no HP
			// peak, not net: the three slaps alternate sides, so the net move can be ~0 against a wall
			var _moved_px = max(abs(global.pc.x - global.tws_cs_x0), variable_global_exists("tws_cs_maxd") ? global.tws_cs_maxd : 0);
			var _fizz     = (string_pos("needs a battle screen", global.tws_row) > 0) || (string_pos("fizzled", global.tws_row) > 0);
			if (!_fizz && (_moved_px < 4 || f.hp < global.tws_cs_hp0))
			{   tws_log("FAIL  catslap: moved " + string(_moved_px) + " px, hp " + string(global.tws_cs_hp0) + " -> " + string(f.hp));  }
			else tws_log("   catslap: moved " + string(_moved_px) + " px, hp unchanged" + (_fizz ? " (fizzled by design here)" : ""));
			// what could hold him: lock bits, wall-contact bits (at the slap and now), the push he
			// was actually given (peak hspd byte), form, and who else is in the room
			if (!_fizz) tws_log("   catslap state: x " + string(global.tws_cs_x0) + " -> " + string(global.pc.x) + " y=" + string(global.pc.y)
			      + " cs " + string(global.tws_cs_cs0) + " -> " + string(global.pc.cs) + " peak_hspd=" + string(global.tws_cs_maxh)
			      + " pc_lock=" + string(g.pc_lock) + " cucco=" + string(pc_is_cucco())
			      + " enemies=" + string(instance_number(Enemy)) + " gui=" + string(g.gui_state) + " cutscene=" + string(g.cutscene));
		}
		if (variable_global_exists("tw_flash_timer") && global.tw_flash_timer > 0) _leak += " flash-still-on";
		if (_leak != "") tws_log("FAIL  LEAK after " + _ca[0] + ":" + _leak);
		if (string_pos("SHOT", _ca[2]) > 0) tws_shot(tw_slug(_ca[0]) + "_after");
		global.tws_ci++;
		if (_moved && global.tws_zone_label != "start")
		{   // bounced out of the zone (fall/exit) -- re-warp and carry on with the next verb
			tws_warp(tws_zones()[global.tws_zi][1]);
			tws_go("zone_wait");
			break;
		}
		tws_go("prep");
		break;

	case "death":
		// harness-forced death (no chat verb): arm a 60 s ice + chicken, die, and the new life
		// must start clean -- Lane 09-25: ice "stuck" after a death, chicken survived loads.
		if (global.tws_death_stage == 0)
		{   // run 3 ran this on the OVERWORLD, where is_dead does nothing: Link never died and
			// the check was meaningless. Go to a side-scroll room first.
			if (!tws_live()) exit;
			tw_effects_clear_all(false);
			global.tws_zone_label = "death";
			tws_warp("_WestA_0A");
			global.tws_death_stage = 10;
			tws_go("death");
			exit;
		}
		if (global.tws_death_stage == 10)
		{
			if (!tws_live() || g.room_type != "A") { global.tws_t = 0; exit; }
			if (global.tws_t < 120) exit;
			tws_log("---- death test in " + g.rm_name + " (type " + g.room_type + ")");
			tws_say("icefloor 60");
			tws_say("arise 60");
			global.tws_lives0 = global.pc_lives;
			tws_log("   armed: ice=" + string(global.tw_ice) + " cucco=" + string(pc_is_cucco())
			      + " active=" + string(array_length(global.tw_active)) + " lives=" + string(global.pc_lives));
			global.tws_death_stage = 1;
			global.tws_saw_death   = false;
			tws_go("death");
			g.dev_invState   = 0;
			g.DevTools_state = global.tws_devtools0;
			if (global.pc_lives < 2)
			{   // on a 1-life save the death landed on GAME OVER and the watchdog logged STUCK instead of a result
				global.pc_lives = 2;
				tws_log("   (harness topped lives up to 2 so the death lands on NEXT LIFE, not GAME OVER)");
			}
			adjust_stat(-9999, 0);
			global.pc.is_dead = true;
			exit;
		}
		if (global.tws_death_stage == 1)
		{   // the death must actually take us off the live screen (death room)
			if (room == rmB_Death || !instance_exists(global.pc)) global.tws_saw_death = true;
			if (!global.tws_saw_death && global.tws_t < 600) exit;
			if (!global.tws_saw_death)
			{
				tws_log("FAIL  [afterdeath]  Link never died (10 s) -- test invalid");
				tws_finish("death test invalid");
				exit;
			}
			global.tws_death_stage = 2;
			tws_go("death");
			exit;
		}
		if (global.tws_death_stage == 2)
		{   // respawned: settle, then check the new life
			if (!tws_live()) { global.tws_t = 0; exit; }
			if (global.tws_t < 90) exit;
			var _dl = tws_leaks({ lock : 0, cucco : false });
			var _clean = (_dl == "" && !global.tw_ice && !pc_is_cucco());
			tws_log((_clean ? "PASS" : "FAIL") + "  [afterdeath]  new life in " + g.rm_name + " starts clean   [lives "
			      + string(global.tws_lives0) + " -> " + string(global.pc_lives) + "  ice=" + string(global.tw_ice)
			      + " cucco=" + string(pc_is_cucco()) + " leaks:" + ((_dl == "") ? " none" : _dl) + "]");
			tws_shot("after_death");
			// death blame: the last hurt verb before the death was tstchatter's !icefloor, so the
			// kill is his ("KILLED BY ... / !ICEFLOOR  KILLS: 1" plate, !kills)
			var _kt = tw_kills_top(5);
			tws_log(((string_pos("tstchatter x1", _kt) > 0) ? "PASS" : "FAIL") + "  [afterdeath]  the death was credited to the chatter who armed the ice   [!kills -> " + ((_kt == "") ? "(nobody)" : _kt) + "]");
			global.tws_death_stage = 3;
			// zones left (the overworld) run after the death test; stage 3 puts the harness
			// invulnerability back on for them
			if (global.tws_zi < array_length(tws_zones())) tws_go("zone_start");
			else tws_finish("complete");
		}
		break;
	}
}

function tw_selftest_cases() {
	static _c = [
		// -- stat pokes / instant helpers ----------------------------------------
		["heal",       "toast", ""],
		["heal 5",     "toast", "quarter-boxes arg"],
		["hurt",       "toast", ""],
		["hurt 4",     "toast", ""],
		["mp",         "toast", ""],
		["drain",      "toast", ""],
		["1up",        "toast", ""],
		["invuln",     "toast", ""],
		["shake",      "toast", "SHOT screenshake placement"],
		// -- timed screen effects -------------------------------------------------
		["dark",       "toast", "SHOT may say no-dark-version -- still armed"],
		["flip",       "toast", "SHOT view while flipped"],
		["confuse",    "toast", "10-30s RNG"],
		["disco",      "toast", "SHOT"],
		["party",      "toast", "SHOT view during party"],
		["ice",        "toast", ""],
		["moon",       "toast", ""],
		["shrink",     "toast", "SHOT"],
		["grow 3",     "toast", "SHOT seconds arg"],
		["slow",       "toast", ""],
		["speed",      "toast", ""],
		["speed 5",    "toast", "seconds arg"],
		// -- music ----------------------------------------------------------------
		["music",      "toast", "random pick"],
		["music zzztop", "nomatch", "NEW no-match reason toast"],
		// -- spells ----------------------------------------------------------------
		["spell wibble", "toast", "SHOT = view AFTER flip/party/shrink/grow expired"],
		["spell",      "toast", "NEW which-one hint"],
		["fire",       "toast", "bare spell"],
		["thunder",    "toast", "bare spell"],
		["protect",    "toast", "bare spell"],
		["reflect",    "toast", "bare spell"],
		["jump",       "toast", "bare spell"],
		["life",       "toast", "bare spell"],
		["enigma",     "toast", "bare spell"],
		["summon",     "toast", "bare spell"],
		// -- hostile spawns -------------------------------------------------------
		["flame",      "toast", ""],
		["heckler",    "toast", "SHOT: name tag floats over the flame"],
		["spawn",      "toast", "default daira"],
		["spawn goriya", "toast", ""],
		["spawn wibble", "toast", "unknown-enemy list toast"],
		["swarm",      "toast", ""],
		// -- crowd control --------------------------------------------------------
		["freeze",     "toast", "counts enemies"],
		["stun",       "toast", "freeze alias"],
		["smite",      "toast", ""],
		["clearscreen", "toast", "smite alias"],
		["curse",      "toast", ""],
		["poison",     "toast", ""],
		["root",       "toast", "7-12s RNG"],
		["deny",       "toast", "help listing"],
		["deny jump",  "toast", ""],
		["(deny chain)", "denyseq", "deny all -> undeny jump -> deny off -> undeny, same frame, real lock bits"],
		["stasis",     "toast", ""],
		["disorient",  "toast", ""],
		// -- help / forms / misc --------------------------------------------------
		["refill",     "toast", ""],
		["fairy",      "toast", "refill alias since 09-12"],
		["arise",      "toast", "chicken or link-again"],
		["chicken",    "toast", ""],
		["cucco",      "toast", ""],
		["link",       "toast", ""],
		["unchicken",  "toast", ""],
		["tax",        "toast", ""],
		["dmgup",      "toast", ""],
		["attrition",  "toast", ""],
		["meth",       "toast", "combo"],
		["quantumentangle", "toast", ""],
		["help",       "toast", "help card"],
		["challenge",  "toast", "needs-a-palace outside palaces"],
		["track",      "toast", "song alias (!song itself is gone: Streamlabs owns it)"],
		["np",         "toast", "song alias"],
		["fatality",   "toast", "MK2 splash on demand"],
		["version",    "toast", ""],
		["points",     "toast", "balance or off"],
		["ghost",      "toast", ""],
		["crush",      "toast", "needs-a-palace outside palaces"],
		["reshuffle",  "toast", "ok or refused-with-reason"],
		["suggest test idea from selftest", "toast", "writes _tw_selftest_suggestions.txt (never the real inbox)"],
		// -- rocket league quick chat (plates OFF in the harness) -----------------
		["niceshot",   "toast", "rocket-league-is-off toast"],
		["gg",         "toast", ""],
		["thanks",     "toast", ""],
		// -- aliases (gate canonicalisation) --------------------------------------
		["tiny",       "toast", "alias -> shrink"],
		["statis",     "toast", "alias -> stasis"],
		["restore",    "toast", "alias -> refill"],
		["smith",      "toast", "alias -> smite"],
		// -- typos: NEAR miss -> NEW did-you-mean plate ----------------------------
		["stasus",     "mean",  "-> stasis"],
		["resuffle",   "mean",  "-> reshuffle"],
		["refil",      "mean",  "-> refill"],
		["smimte",     "mean",  "-> smite"],
		["ivuln",      "mean",  "-> invuln"],
		["chiken",     "mean",  "-> chicken"],
		// -- far-from-anything -> silence is CORRECT -------------------------------
		["zzz",        "silent", "no suggestion, no plate"],
		["papi",       "silent", ""],
		["butts",      "silent", ""],
		// -- (the death test is harness-driven, after the zones -- !kill was removed) --
		["refill",     "toast", "final"]
	];
	return _c;
}
