/// @description  Surface_Draw_GUI_End()
function Surface_Draw_GUI_End() {


	if (global.QuestTimer_can_draw)
	{
	    global.QuestTimer_can_draw = false;
	    draw_text_(global.QuestTimer_xl,global.QuestTimer_yt, global.QuestTimer_text);
	}


	// ------------------------------------------------------------------------------------
	// DEV PLAYTEST FLAG: press 3 during normal play to log the current spot for later review.
	// Writes a screenshot of the fully-composited frame (we're in Draw GUI End) plus the
	// scene / coords / game-time to <working_directory>problems\  (play_NNN.png + _playtest_log.txt).
	if (keyboard_check_pressed(ord("3"))) // ungated so key-3 marking still works in DEV=false play builds
	{
	    if (!variable_global_exists("dev_flag_count")) global.dev_flag_count = 0;
	    global.dev_flag_count++;
	    var _n  = global.dev_flag_count;
	    var _ns = string(_n);
	    if (_n<100) _ns = "0"+_ns;
	    if (_n<10)  _ns = "0"+_ns;

	    var _dir = working_directory + "problems/";
	    directory_create(_dir);

	    var _loc = "room=" + room_get_name(room);
	    if (instance_exists(g))
	    {
	        _loc += "  type=" + string(g.room_type) + "  scene=" + string(g.rm_name) + "  area=" + string(g.area_name);
	        if (g.room_type=="C" && instance_exists(global.OVERWORLD))
	            _loc += "  owrc=$" + hex_str(global.OVERWORLD.pcrc);
	        else if (instance_exists(global.pc))
	            _loc += "  pc_xy=(" + string(global.pc.x) + "," + string(global.pc.y) + ")";
	    }
	    var _gt = variable_global_exists("App_frame_count") ? ("frame="+string(global.App_frame_count)) : ("ms="+string(current_time));

	    screen_save(_dir + "play_" + _ns + ".png"); // captured before the FLAGGED overlay below, so the shot is clean

	    var _ff = file_text_open_append(_dir + "_playtest_log.txt");
	    file_text_write_string(_ff, "#"+_ns+"  |  "+_gt+"  |  "+_loc+"  |  play_"+_ns+".png");
	    file_text_writeln(_ff);
	    file_text_close(_ff);

	    // MARK -> REPRODUCIBLE REPLAY: dump the rolling input ring + the room-entry
	    // snapshot for THIS mark so it can be replayed via DEV TOOLS > TEST/CAPTURE >
	    // REPLAY LAST MARK (and tas_pb_load_start). Shares the dev_flag mark numbering.
	    mark_dump_replay(_n);

	    global.dev_flag_msg       = "FLAGGED #"+_ns;
	    global.dev_flag_msg_timer = 120;

	    // PLAYLOG: also drop a MARK line in the session log (no-op unless playlog is active).
	    if (variable_global_exists("playlog_active") && global.playlog_active)
	    {
	        var _playlog_pc_xy = "(?,?)";
	        if (instance_exists(global.pc)) _playlog_pc_xy = "(" + string(global.pc.x) + "," + string(global.pc.y) + ")";
	        var _playlog_room = "?";
	        if (instance_exists(g)) _playlog_room = string(g.rm_name);
	        playlog_write("MARK t=" + string(global.playlog_frame) + " room=" + _playlog_room + " pc=" + _playlog_pc_xy + " USER-FLAGGED");
	    }
	}
	if (variable_global_exists("dev_flag_msg_timer") && global.dev_flag_msg_timer>0)
	{
	    global.dev_flag_msg_timer--;
	    var _pf = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_left);
	    draw_set_colour(c_black); draw_text(9, 25, global.dev_flag_msg);
	    draw_set_colour(c_lime);  draw_text(8, 24, global.dev_flag_msg);
	    draw_set_colour(c_white);
	    draw_set_font(_pf);
	}


	// ------------------------------------------------------------------------------------
	// NOTE SYSTEM (4): PAUSE + TYPE a bug note + SAVE it next to the key-3 flag.
	// (revert: delete this whole NOTE SYSTEM block + the NOTE SYSTEM freeze guard at the
	//  top of g_Step.gml + the NOTE SYSTEM globals in g_Create.gml.)
	// While playing, press 4 -> the game FREEZES (g_Step's note_active guard) and the
	// user types a description of a bug. ENTER saves a NOTE line (+ a linked screenshot)
	// into the SAME working_directory + "problems/_playtest_log.txt" the key-3 flag writes,
	// reusing the key-3 mark counter (global.dev_flag_count) so notes share that numbering.
	// ESC cancels (discards). Play-safe: gated on its OWN state (global.note_active),
	// NEVER on DEV. All guarded; file write is try/caught; no ?: ternaries.
	//
	// NOTE: GMS2's built-in keyboard_string auto-appends printable chars AND handles
	// backspace for us (same idiom the DEV sweep-note overlay in Dev_RmWarper uses), so we
	// just read keyboard_string as the live note text. We clear it on enter/exit so it
	// never carries stale input between sessions.

	// --- 4: enter note mode (only when not already in it) ---
	if (keyboard_check_pressed(ord("4"))
	&&  variable_global_exists("note_active")
	&& !global.note_active)
	{
	    // reuse the key-3 mark counter so this note shares the flag numbering
	    if (!variable_global_exists("dev_flag_count")) global.dev_flag_count = 0;
	    global.dev_flag_count++;
	    var _nn  = global.dev_flag_count;
	    var _nns = string(_nn);
	    if (_nn<100) _nns = "0"+_nns;
	    if (_nn<10)  _nns = "0"+_nns;

	    // capture the SAME context fields the key-3 flag logs, at the moment key-4 is pressed
	    var _nloc = "room=" + room_get_name(room);
	    if (instance_exists(g))
	    {
	        _nloc += "  type=" + string(g.room_type) + "  scene=" + string(g.rm_name) + "  area=" + string(g.area_name);
	        if (g.room_type=="C" && instance_exists(global.OVERWORLD))
	            _nloc += "  owrc=$" + hex_str(global.OVERWORLD.pcrc);
	        else if (instance_exists(global.pc))
	            _nloc += "  pc_xy=(" + string(global.pc.x) + "," + string(global.pc.y) + ")";
	    }
	    var _ngt = "ms=" + string(current_time);
	    if (variable_global_exists("App_frame_count")) _ngt = "frame=" + string(global.App_frame_count);

	    // take the screenshot NOW (clean frame, before the overlay below) so note + image are linked
	    var _ndir = working_directory + "problems/";
	    var _nshot = "play_" + _nns + ".png";
	    try
	    {
	        directory_create(_ndir);
	        screen_save(_ndir + _nshot);
	    }
	    catch (_e)
	    {
	        _nshot = ""; // shot failed -> note still saves, just without a linked image
	    }

	    global.note_active = true;
	    global.note_num    = _nn;
	    global.note_ctx    = _ngt + "  |  " + _nloc;
	    global.note_shot   = _nshot;
	    global.note_text   = "";
	    keyboard_string    = ""; // clear so prior typing never carries into the note
	}

	// --- note mode: input handling + overlay draw (Draw GUI End runs even though g_Step is frozen) ---
	if (variable_global_exists("note_active") && global.note_active)
	{
	    // keyboard_string already holds the live, backspace-corrected text
	    global.note_text = string(keyboard_string);

	    // ENTER = save, ESC = cancel. (Checked here, in Draw GUI End, since g_Step is frozen.)
	    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_return))
	    {
	        var _nsv = string(global.note_num);
	        if (global.note_num<100) _nsv = "0"+_nsv;
	        if (global.note_num<10)  _nsv = "0"+_nsv;

	        var _nline = "NOTE #" + _nsv + "  |  " + string(global.note_ctx) + "  |  >> " + string(global.note_text);
	        if (string(global.note_shot) != "") _nline += "  |  " + string(global.note_shot);

	        try
	        {
	            var _ndir2 = working_directory + "problems/";
	            directory_create(_ndir2);
	            var _nf = file_text_open_append(_ndir2 + "_playtest_log.txt");
	            file_text_write_string(_nf, _nline);
	            file_text_writeln(_nf);
	            file_text_close(_nf);
	        }
	        catch (_e)
	        {
	            // never let a logging failure throw back into gameplay
	        }

	        global.note_msg       = "NOTE SAVED #" + _nsv;
	        global.note_msg_timer = 120;
	        global.note_active    = false; // resume gameplay
	        keyboard_string       = "";    // clear so the saved text doesn't leak into the game
	    }
	    else if (keyboard_check_pressed(vk_escape))
	    {
	        global.note_msg       = "NOTE CANCELLED";
	        global.note_msg_timer = 90;
	        global.note_active    = false; // resume gameplay (discard)
	        keyboard_string       = "";
	    }

	    // --- overlay: a readable centred box (ASCII-only, default-font style) ---
	    var _npf = draw_get_font();
	    draw_set_font(-1);

	    var _ngw = display_get_gui_width();
	    if (_ngw <= 0) _ngw = 320;
	    var _ngh = display_get_gui_height();
	    if (_ngh <= 0) _ngh = 240;

	    var _bw = _ngw - 24; // box width with an inset margin
	    if (_bw > 360) _bw = 360;
	    var _bh = 64;
	    var _bx = (_ngw - _bw) * 0.5;
	    var _by = (_ngh - _bh) * 0.5;

	    // dim panel behind the text for readability
	    draw_set_alpha(0.85);
	    draw_set_colour(c_black);
	    draw_rectangle(_bx, _by, _bx + _bw, _by + _bh, false);
	    draw_set_alpha(1);
	    draw_set_colour(c_yellow);
	    draw_rectangle(_bx, _by, _bx + _bw, _by + _bh, true);

	    draw_set_halign(fa_left);
	    var _tx = _bx + 6;
	    var _ty = _by + 5;

	    draw_set_colour(c_yellow);
	    draw_text(_tx, _ty, "FLAG NOTE (ENTER=save  ESC=cancel):");
	    _ty += 14;

	    // what they're annotating (so they see the context)
	    draw_set_colour(c_aqua);
	    draw_text(_tx, _ty, string(global.note_ctx));
	    _ty += 14;

	    // the typed line with a trailing cursor (keyboard_string is the live text)
	    draw_set_colour(c_white);
	    draw_text(_tx, _ty, "> " + string(global.note_text) + "_");

	    draw_set_colour(c_white);
	    draw_set_font(_npf);
	}

	// NOTE confirmation message (lives OUTSIDE the note_active block so it shows after save/cancel).
	if (variable_global_exists("note_msg_timer") && global.note_msg_timer > 0)
	{
	    global.note_msg_timer--;
	    var _nmpf = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_left);
	    var _nmsg = "";
	    if (variable_global_exists("note_msg")) _nmsg = string(global.note_msg);
	    draw_set_colour(c_black); draw_text(9, 41, _nmsg);
	    draw_set_colour(c_lime);  draw_text(8, 40, _nmsg);
	    draw_set_colour(c_white);
	    draw_set_font(_nmpf);
	}


	// ------------------------------------------------------------------------------------
	// DEPTH DEBUG: toggle via Dev Tools menu. Draws a readout of instance depth vs the
	// GMS2 managed-layer depth for the layering bug (Zelda/torches drawing over Link).
	// Source depths are PC=-33, Zelda=-17, TorchA=-12;
	// if the layer depths don't match those, GMS2's layer ordering is the culprit.
	if (variable_global_exists("dbg_depth_show") && global.dbg_depth_show)
	{
	    var _pf2 = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_left);
	    var _objs = [Lonk, Zelda, TorchA, Cutscene_FloorTrap_1];
	    var _nm   = ["Lonk/PC", "Zelda", "TorchA", "FloorTrap"];
	    var _dy   = 40;
	    var _line;
	    draw_set_colour(c_yellow); draw_text(8,_dy, "DEPTH DEBUG (Dev Tools menu)  [lower depth = front]"); _dy += 14;
	    for (var _o=0; _o<array_length(_objs); _o++)
	    {
	        var _any = false;
	        with(_objs[_o])
	        {
	            _any = true;
	            var _lyr = layer;
	            var _ln  = (is_real(_lyr) && layer_exists(_lyr)) ? layer_get_name(_lyr) : "none";
	            var _ld  = (is_real(_lyr) && layer_exists(_lyr)) ? string(layer_get_depth(_lyr)) : "?";
	            _line = _nm[_o] + ": depth=" + string(depth) + "  lyr=" + _ln + " lyrDepth=" + _ld;
	            draw_set_colour(c_black); draw_text(9,_dy+1, _line);
	            draw_set_colour(c_white); draw_text(8,_dy,   _line);
	            _dy += 12;
	        }
	        if (!_any)
	        {
	            _line = _nm[_o] + ": (no instance in room)";
	            draw_set_colour(c_black); draw_text(9,_dy+1, _line);
	            draw_set_colour(c_gray);  draw_text(8,_dy,   _line);
	            _dy += 12;
	        }
	    }
	    draw_set_colour(c_white);
	    draw_set_font(_pf2);
	}


	// ------------------------------------------------------------------------------------
	// MOVESPEED CHEAT (2): cycle Link's walk-speed multiplier 1 -> 2 -> 3 -> 4 -> 1.
	// Play-safe (NOT DEV-gated) so it works in DEV=false play builds.
	// Reversible: delete this block + the MOVESPEED CHEAT blocks in g_Create / updateX /
	// Overworld_Step. The multiplier itself is applied in updateX (action rooms) and
	// Overworld_Step (overworld); here we only own the hotkey + the on-screen readout.
	if (keyboard_check_pressed(ord("2")))
	{
	    if (!variable_global_exists("cheat_movespeed")) global.cheat_movespeed = 1;
	    global.cheat_movespeed++;
	    if (global.cheat_movespeed > 4) global.cheat_movespeed = 1;
	}
	// readout: only shown while engaged (>1). Bottom-LEFT, clear of the top-left timer/REC,
	// the top-right map label, and the bottom-right jukebox. Same shadow+colour style as the
	// depth HUD (default font, ASCII-only so font -1 glyph coverage is reliable).
	if (variable_global_exists("cheat_movespeed") && global.cheat_movespeed > 1)
	{
	    var _ms_pf = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_left);
	    var _ms_gh = display_get_gui_height();
	    if (_ms_gh <= 0) _ms_gh = 240;
	    var _ms_x = 8;
	    var _ms_y = _ms_gh - 14;
	    var _ms_line = "SPEED " + string(global.cheat_movespeed) + "x";
	    draw_set_colour(c_black);  draw_text(_ms_x+1, _ms_y+1, _ms_line);
	    draw_set_colour(c_yellow); draw_text(_ms_x,   _ms_y,   _ms_line);
	    draw_set_colour(c_white);
	    draw_set_font(_ms_pf);
	}


	// ------------------------------------------------------------------------------------
	// PLAYLOG: "watch-me-play" text session logger. Toggle via Dev Tools menu.
	// Default OFF; can also be pre-enabled by the presence of "_playlog.flag" (g_Create).
	if (variable_global_exists("playlog_active") && global.playlog_active)
	{
	    // Top-left anchored like the depth-debug HUD above -- avoids querying GUI/view
	    // width (untested in this codebase; Surface_Draw_GUI_Begin.gml even has the
	    // display_set_gui_size() call commented out), so this can't misplace itself.
	    var _pf3 = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_left);
	    var _playlog_hud = "* REC " + string(global.playlog_frame); // plain ASCII -- default font (-1) glyph coverage for "*" is reliable; matches the rest of this file's ASCII-only HUD text
	    draw_set_colour(c_black); draw_text(9, 9, _playlog_hud);
	    draw_set_colour(c_red);   draw_text(8, 8, _playlog_hud);
	    draw_set_colour(c_white);
	    draw_set_font(_pf3);
	}


	// TRACKER WINDOW toggle (Insert): open/close the Win32 companion tracker window on demand.
	// Ungated so it works in DEV=false play builds. Handles are defined by TrackerWin_extern()
	// in g_Create; TrackerWin_step keeps the window updated while TW_ENABLED is true.
	if (instance_exists(Input) && Input.Tracker_Toggle_pressed)
	{
	    if (!variable_global_exists("TW_ENABLED")) global.TW_ENABLED = false;
	    global.TW_ENABLED = !global.TW_ENABLED;
	    if (global.TW_ENABLED)
	    {
	        TrackerWin_init(); // (re)create the window
	    }
	    else if (variable_global_exists("TW_hwnd") && global.TW_hwnd
	         &&  variable_global_exists("TW_fn_DestroyWindow"))
	    {
	        external_call(global.TW_fn_DestroyWindow, global.TW_hwnd); // close it
	        global.TW_hwnd = 0;
	    }
	}


	// ------------------------------------------------------------------------------------
	// WALKTUNE: live overworld walk-feel tuning -- a MOUSE-DRAGGABLE SLIDER PANEL.
	// Toggle via Dev Tools menu. Play-safe (NOT DEV-gated).
	// Self-contained + reversible: delete this block + the walktune_* scripts
	// (+ their .yyp entries) + the WALKTUNE blocks in g_Create / Overworld_udp / Overworld_Step.
	//   F11 ... save current values to <working_directory>walktune.txt (inside walktune_panel)
	// IMPORTANT: this tool NO LONGER consumes "\" / "[" / "]" -- those are free for the
	// music jukebox (track skip). All slider interaction is MOUSE-only, so the user can
	// keep walking on the keyboard while dragging a slider and feel the change LIVE.
	// Draw + drive the panel (guarded internally; no-ops unless walktune_on is true).
	walktune_panel();


	// ------------------------------------------------------------------------------------
	// NES-MUSIC JUKEBOX (HOME toggle): a user-driven music player layered over the game.
	// Play-safe -- gated on its OWN state (global.jukebox_on), NEVER on DEV. Self-contained
	// + reversible: delete this whole block + the jukebox_* scripts + the jukebox_init()
	// call in g_Create. Controls:
	//
	// KEY MAP CORRECTED 2026-07-26 -- this block still documented the ORIGINAL hardcoded
	// F8 / ] / [ / F12 scheme long after the jukebox moved onto the remappable Input system
	// (Input_Create.gml:206-209). Following these stale keys meant pressing F12 and getting
	// nothing, because vk_f12 is bound to NOTHING anywhere in the project. The live bindings
	// are Input.Key_jukebox_* and are rebindable in OPTIONS > INPUT CONFIG; the defaults are:
	//   HOME ....... toggle jukebox MODE on/off (on -> overrides area music with the
	//                selected track; off -> stop our track, area music resumes on its own)
	//   PGDN/PGUP .. next / previous track (keyboard, = Key_jukebox_next / _prev)
	//   R-trig ..... next track   (gamepad gp_shoulderrb = Input.GP_other6)
	//   L-trig ..... prev track   (gamepad gp_shoulderlb = Input.GP_other5)
	//   END ........ assign current theme -> current track + append to jukebox_assignments.txt
	// Now-playing line drawn bottom-RIGHT (clear of the top-left timer/REC, the top-right
	// map label, and the bottom-left WALKTUNE overlay). Everything guarded.
	if (instance_exists(Input) && Input.Jukebox_Toggle_pressed)
	{
	    if (!variable_global_exists("jukebox_on")) global.jukebox_on = false;
	    global.jukebox_on = !global.jukebox_on;
	    if (global.jukebox_on)
	    {
	        jukebox_build_playlist(); // rebuild playlist from actual audiogroup_mus (fresh each toggle-on)

	        // TAKE THE CHANNEL (2026-07-26): toggling the jukebox ON while area music was
	        // already playing used to leave that music running -- the selected track either
	        // never took over or both played at once. It only behaved when you entered the
	        // area fresh, because that path re-inits the music state. Stop the music group
	        // outright and clear Audio's "currently playing" handle first, exactly the way
	        // the fall-scene trigger does it (update_change_room.gml: audio_group_stop_all +
	        // clear the can_play flags), so jukebox_play() starts from silence.
	        audio_group_stop_all(audiogroup_mus);
	        if (instance_exists(Audio))
	        {
	            Audio.mus_rm_inst = 0; // nothing believes room music is still live
	        }

	        jukebox_play(); // start the currently-selected track
	        global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps); // show HUD, then it fades
	    }
	    else
	    {
	        // turn jukebox OFF: stop our track. Audio_update_2 sees mus_rm_inst stop and
	        // re-plays the normal area music (mus_rm_body) on the next frame -- nothing else
	        // to do here, that restore path is the game's existing behaviour.
	        if (variable_global_exists("jukebox_inst")
	        &&  global.jukebox_inst
	        &&  audio_exists(global.jukebox_inst)
	        &&  audio_is_playing(global.jukebox_inst))
	        {
	            audio_stop_sound(global.jukebox_inst);
	        }
	        global.jukebox_inst = 0;
	        if (variable_global_exists("jukebox_msg"))
	        {
	            global.jukebox_msg       = "JUKEBOX OFF";
	            global.jukebox_msg_timer = 90;
	        }
	    }
	}

	if (variable_global_exists("jukebox_on") && global.jukebox_on)
	{
	    // --- AUTO-ADVANCE poll (2026-07-26) ---------------------------------------------
	    // Play one track, then the next, like a real player. jukebox_play() starts tracks
	    // NON-looping while global.jukebox_autoadvance is set, so "instance no longer
	    // playing" means "track finished" -> step to the next entry.
	    //
	    // Safe here: Audio_update_2's room-music (gml:84-88) and boss-music (gml:42-45)
	    // restarts are BOTH gated on !global.jukebox_on, which stays true throughout, so the
	    // brief gap between tracks can never let area music seize the channel.
	    //
	    // Deliberately requires jukebox_inst to be non-zero first: a 0 id means we have not
	    // started anything yet (or the jukebox was just toggled on), and advancing then would
	    // skip the very first track.
	    if (variable_global_exists("jukebox_autoadvance") && global.jukebox_autoadvance
	    &&  variable_global_exists("jukebox_inst")        && global.jukebox_inst)
	    {
	        var _jb_alive = audio_exists(global.jukebox_inst) && audio_is_playing(global.jukebox_inst);
	        if (!_jb_alive && variable_global_exists("jukebox_count") && global.jukebox_count > 0)
	        {
	            global.jukebox_idx = (global.jukebox_idx + 1) mod global.jukebox_count;
	            jukebox_play();
	            global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps); // show what changed
	        }
	    }

	    // --- skip inputs ---
	    var _jb_next = false;
	    var _jb_prev = false;

	    // keyboard ] / [  -- only when the WALKTUNE overlay is NOT capturing them
	    // (and NOT while a NOTE is being typed -- those chars belong to the note text).
	    var _jb_wt_open = (variable_global_exists("walktune_on") && global.walktune_on);
	    var _jb_note    = (variable_global_exists("note_active") && global.note_active); // NOTE SYSTEM guard
	    if (!_jb_wt_open && !_jb_note)
	    {
	        if (instance_exists(Input) && Input.Jukebox_Next_pressed) _jb_next = true;
	        if (instance_exists(Input) && Input.Jukebox_Prev_pressed) _jb_prev = true;
	    }

	    if (_jb_next || _jb_prev)
	    {
	        if (variable_global_exists("jukebox_idx") && variable_global_exists("jukebox_count"))
	        {
	            var _jb_n = global.jukebox_count;
	            if (_jb_n > 0)
	            {
	                if (_jb_next) global.jukebox_idx = (global.jukebox_idx + 1) mod _jb_n;
	                if (_jb_prev) global.jukebox_idx = (global.jukebox_idx - 1 + _jb_n) mod _jb_n;
	                jukebox_play(); // stops previous track + plays the new selection
	                global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps); // re-show HUD
	            }
	        }
	    }

	    // --- END (jukebox_assign): assign current theme -> current track, append to jukebox_assignments.txt ---
	    if (instance_exists(Input) && Input.Jukebox_Assign_pressed)
	    {
	        jukebox_assign();
	        global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps); // re-show HUD
	    }

	    // --- now-playing readout (bottom-RIGHT, GUI space, default font like the other HUDs) ---
	    // AUTO-FADE (2026-07-26): this used to draw for as long as the jukebox was ON, so it
	    // parked on screen permanently and cluttered the stream. It now shows for ~3s after
	    // any change (toggle on / track skip / assign) and fades over the last ~0.75s.
	    // jukebox_hud_timer is set at each of those three sites; nothing else touches it.
	    if (!variable_global_exists("jukebox_hud_timer")) global.jukebox_hud_timer = 0;
	    if (global.jukebox_hud_timer > 0)
	    {
	    global.jukebox_hud_timer--;
	    var _jb_fade = 0.75 * game_get_speed(gamespeed_fps);
	    var _jb_a    = min(1, global.jukebox_hud_timer / max(1, _jb_fade));

	    var _jb_pf = draw_get_font();
	    draw_set_font(-1);

	    var _jb_idx  = 0;
	    if (variable_global_exists("jukebox_idx"))   _jb_idx = global.jukebox_idx;
	    var _jb_cnt  = 56;
	    if (variable_global_exists("jukebox_count")) _jb_cnt = global.jukebox_count;

	    var _jb_name = "";
	    if (variable_global_exists("jukebox_names")
	    &&  is_array(global.jukebox_names)
	    &&  array_length(global.jukebox_names) > _jb_idx)
	    {
	        _jb_name = string(global.jukebox_names[_jb_idx]);
	    }

	    // "NNN/56  <friendly>"  (plain ASCII so default-font glyph coverage is reliable;
	    // a musical-note glyph isn't guaranteed in font -1, so we use a simple tag)
	    var _jb_num = string(_jb_idx + 1);
	    if (_jb_idx + 1 < 100) _jb_num = "0" + _jb_num;
	    if (_jb_idx + 1 < 10)  _jb_num = "0" + _jb_num;
	    var _jb_line = "JUKEBOX " + _jb_num + "/" + string(_jb_cnt) + "  " + _jb_name;
	    var _jb_help = "[Home on/off]  [PgUp/PgDn track]  [End assign]";

	    var _jb_gw = display_get_gui_width();
	    if (_jb_gw <= 0) _jb_gw = 320;
	    var _jb_gh = display_get_gui_height();
	    if (_jb_gh <= 0) _jb_gh = 240;

	    draw_set_halign(fa_right);
	    var _jb_x = _jb_gw - 8;
	    var _jb_y = _jb_gh - 26;

	    draw_set_alpha(_jb_a);
	    draw_set_colour(c_black);  draw_text(_jb_x+1, _jb_y+1,  _jb_line);
	    draw_set_colour(c_aqua);   draw_text(_jb_x,   _jb_y,    _jb_line);
	    draw_set_colour(c_black);  draw_text(_jb_x+1, _jb_y+13, _jb_help);
	    draw_set_colour(c_white);  draw_text(_jb_x,   _jb_y+12, _jb_help);
	    draw_set_alpha(1);

	    draw_set_halign(fa_left);
	    draw_set_colour(c_white);
	    draw_set_font(_jb_pf);
	    } // end jukebox_hud_timer > 0
	}

	// JUKEBOX confirmation message (also shown briefly when the jukebox is toggled OFF,
	// so this lives OUTSIDE the jukebox_on block above). Drawn bottom-right, guarded.
	if (variable_global_exists("jukebox_msg_timer") && global.jukebox_msg_timer > 0)
	{
	    global.jukebox_msg_timer--;
	    var _jbm_pf = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_right);
	    var _jbm_gw = display_get_gui_width();
	    if (_jbm_gw <= 0) _jbm_gw = 320;
	    var _jbm_gh = display_get_gui_height();
	    if (_jbm_gh <= 0) _jbm_gh = 240;
	    var _jbm_x = _jbm_gw - 8;
	    var _jbm_y = _jbm_gh - 40;
	    var _jbm_msg = "";
	    if (variable_global_exists("jukebox_msg")) _jbm_msg = string(global.jukebox_msg);
	    draw_set_colour(c_black); draw_text(_jbm_x+1, _jbm_y+1, _jbm_msg);
	    draw_set_colour(c_lime);  draw_text(_jbm_x,   _jbm_y,   _jbm_msg);
	    draw_set_halign(fa_left);
	    draw_set_colour(c_white);
	    draw_set_font(_jbm_pf);
	}


	// ------------------------------------------------------------------------------------
	// MAP NAME HUD: relocated into the top status bar (see HUD_Draw()), drawn there with
	// the bar's own sprite-font routine (draw_text_) so size/font/palette match natively.
	// (Was here as tiny top-right default-font corner text; moved 2026-06-23.)
	// To revert: delete the MAP-NAME block at the end of scripts/HUD_Draw/HUD_Draw.gml
	// and restore the top-right draw_text() block here.


	tas_draw_overlay();

	// CONTROLLER DIAGNOSTIC overlay (AUTOMATED TEST > CONTROLLER DIAG). Guarded internally on
	// global.gp_diag_on; no-op unless toggled on. Live gamepad button/trigger/axis + raw scan.
	gp_diag_overlay();

	// ── TWITCH toast (Phase A): bottom-centre feedback for the last applied chat verb ──
	// Mirrors the jukebox confirmation toast (black drop-shadow + c_lime). Timer is
	// counted down in twitch_tick(); this block only reads it. Fully guarded; saves and
	// restores font/halign/colour so it can't leak draw state into anything after it.
	// Revert: delete this block + the twitch_* scripts + their wiring/globals.
	if (variable_global_exists("tw_toast_timer") && global.tw_toast_timer > 0)
	{
		var _tw_pf = draw_get_font();
		var _tw_ph = draw_get_halign();
		var _tw_pc = draw_get_colour();
		draw_set_font(-1);
		draw_set_halign(fa_center);
		var _tw_gw = display_get_gui_width();  if (_tw_gw <= 0) _tw_gw = 320;
		var _tw_gh = display_get_gui_height(); if (_tw_gh <= 0) _tw_gh = 240;
		var _tw_x  = _tw_gw * 0.5;
		var _tw_y  = _tw_gh - 28;
		var _tw_msg = "";
		if (variable_global_exists("tw_toast")) _tw_msg = string(global.tw_toast);
		draw_set_colour(c_black); draw_text(_tw_x + 1, _tw_y + 1, _tw_msg);
		draw_set_colour(c_lime);  draw_text(_tw_x,     _tw_y,     _tw_msg);
		draw_set_halign(_tw_ph);
		draw_set_colour(_tw_pc);
		draw_set_font(_tw_pf);
	}

	// ── TWITCH IRC (no-bot mode) status line: top-left, only while the IRC client is
	// enabled. Reads global.tw_irc_status (idle/connecting/connected/error/no config)
	// so the user can see the live handshake state. Fully guarded; saves+restores
	// font/halign/colour. Revert: delete this block + the twitch_irc_* wiring. ───────
	// VISIBILITY RULE (user is streaming -- don't leave a label stuck on screen):
	//   "idle"                       -> never draw.
	//   "connecting"                 -> draw (handshake in progress).
	//   "connected"                  -> draw only while the auto-hide timer is still
	//                                   running (global.tw_irc_status_timer > 0); once
	//                                   it expires (<= 0) the label disappears so it's
	//                                   not on the stream permanently. The timer is
	//                                   armed to ~240 in twitch_irc_handle_line on the
	//                                   welcome 001 and counted down in twitch_irc_step.
	//   "error..." / "no config"     -> draw PERSISTENTLY (the user must see problems).
	if (variable_global_exists("tw_irc_enabled") && global.tw_irc_enabled)
	{
		var _ti_status = "";
		if (variable_global_exists("tw_irc_status")) _ti_status = string(global.tw_irc_status);

		var _ti_timer = 0;
		if (variable_global_exists("tw_irc_status_timer")) _ti_timer = global.tw_irc_status_timer;

		// decide visibility: hide "idle" always, and hide "connected" once its timer expires.
		var _ti_show = true;
		if (_ti_status == "idle") _ti_show = false;
		else if (_ti_status == "connected" && _ti_timer <= 0) _ti_show = false;

		if (_ti_show)
		{
			var _ti_pf = draw_get_font();
			var _ti_ph = draw_get_halign();
			var _ti_pc = draw_get_colour();
			draw_set_font(-1);
			draw_set_halign(fa_left);
			var _ti_msg = "TWITCH: " + _ti_status;
			draw_set_colour(c_black);  draw_text(9, 57, _ti_msg);
			draw_set_colour(c_aqua);   draw_text(8, 56, _ti_msg);
			draw_set_halign(_ti_ph);
			draw_set_colour(_ti_pc);
			draw_set_font(_ti_pf);
		}
	}

	// ── KONAMI toast (easter egg): bottom-centre celebratory feedback ───────────────
	// Mirrors the twitch toast above (black drop-shadow, default font, bottom-centre)
	// but in c_yellow and a touch higher so the two never overlap. konami_fire() sets
	// the text + timer; the timer is counted down HERE (Draw GUI End always runs, even
	// when g_Step exits early). Fully guarded; saves/restores font/halign/colour so it
	// can't leak draw state. Revert: delete this block + the konami_* globals in
	// g_Create + the konami_check script + the konami_check() call in g_Step.
	if (variable_global_exists("konami_toast_timer") && global.konami_toast_timer > 0)
	{
		global.konami_toast_timer--;
		var _km_pf = draw_get_font();
		var _km_ph = draw_get_halign();
		var _km_pc = draw_get_colour();
		draw_set_font(-1);
		draw_set_halign(fa_center);
		var _km_gw = display_get_gui_width();  if (_km_gw <= 0) _km_gw = 320;
		var _km_gh = display_get_gui_height(); if (_km_gh <= 0) _km_gh = 240;
		var _km_x  = _km_gw * 0.5;
		var _km_y  = _km_gh - 44;
		var _km_msg = "";
		if (variable_global_exists("konami_toast")) _km_msg = string(global.konami_toast);
		draw_set_colour(c_black);  draw_text(_km_x + 1, _km_y + 1, _km_msg);
		draw_set_colour(c_yellow); draw_text(_km_x,     _km_y,     _km_msg);
		draw_set_halign(_km_ph);
		draw_set_colour(_km_pc);
		draw_set_font(_km_pf);
	}

	// ── CO-OP P2 JOIN PROMPT ────────────────────────────────────────────────────────
	// While co-op is ON but no SEPARATE 2nd controller has joined the fairy (slot still
	// -1, or somehow collapsed onto P1's slot), prompt the user to press a button on the
	// 2nd pad. The fairy stays INERT until then (Input_update_p2 hard-returns while
	// unassigned), so one controller can never drive both players. Clears the instant a
	// distinct pad joins. Deliberately MINIMAL + unobtrusive: the built-in default font
	// (-1, the same HUD/dev font the rest of this file uses) scaled to half size via
	// draw_text_transformed, dimmed (alpha 0.55), tucked bottom-centre. Fully guarded;
	// saves+restores font/halign/valign/colour/alpha so it can't leak draw state.
	if (variable_global_exists("coop_enabled") && global.coop_enabled
	&&  instance_exists(Input)
	&&  (Input.gamepad_slot_p2 == -1 || Input.gamepad_slot_p2 == Input.gamepad_slot))
	{
		var _cp_pf = draw_get_font();
		var _cp_ph = draw_get_halign();
		var _cp_pv = draw_get_valign();
		var _cp_pc = draw_get_colour();
		var _cp_pa = draw_get_alpha();
		draw_set_font(-1);
		draw_set_halign(fa_center);
		draw_set_valign(fa_bottom);
		var _cp_gw = display_get_gui_width();  if (_cp_gw <= 0) _cp_gw = 320;
		var _cp_gh = display_get_gui_height(); if (_cp_gh <= 0) _cp_gh = 240;
		var _cp_x  = _cp_gw * 0.5;
		var _cp_y  = _cp_gh - 6;     // hugs the bottom edge, out of the way
		var _cp_sc = 0.5;            // half-size: smallest readable scale of the default HUD font
		var _cp_msg = "P2: press to join";
		draw_set_alpha(0.55);
		draw_set_colour(c_black); draw_text_transformed(_cp_x + 1, _cp_y + 1, _cp_msg, _cp_sc, _cp_sc, 0);
		draw_set_colour(c_aqua);  draw_text_transformed(_cp_x,     _cp_y,     _cp_msg, _cp_sc, _cp_sc, 0);
		draw_set_font(_cp_pf);
		draw_set_halign(_cp_ph);
		draw_set_valign(_cp_pv);
		draw_set_colour(_cp_pc);
		draw_set_alpha(_cp_pa);
	}

	/* This is here so it's the last thing that happens
	so `srf_app_paused_frame` can catch everything that
	drew this frame.
	*/
	update_app_pause();







}
