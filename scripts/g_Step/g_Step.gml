/// @description  g_Step()
function g_Step() {


	// ── 2nd-window companion tracker: serialize state every 4 frames ────────────
	// File-IPC writer for the separate "ZALiA Tracker" process. Runs FIRST/uncondi-
	// tionally so the state file stays live even in menus/pauses/note-freeze.
	// tracker_state_write() self-guards on instance_exists(f) (writes {"live":false}
	// when no save is loaded), so this is safe on title/file-select too.
	// global.TW_tick is initialized in g_Create(); the dead Win32 TrackerWin_step()
	// early-exits (TW_ENABLED=false) and never touches TW_tick, so this is its sole
	// incrementer — fires on counts 0,4,8,... (every 4th frame).
	if ((global.TW_tick++ mod 4) == 0) tracker_state_write();


	// ── TWITCH integration (Phase A): drain the chat drop-queue + age timed effects ─
	// Runs every frame, here (unconditionally, like the tracker write above) so timed
	// effects revert on schedule even in menus/pauses. Both calls early-return cheaply
	// while global.tw_enabled is false (set in g_Create). Revert: delete these 2 lines
	// + the globals in g_Create + the toast block in Surface_Draw_GUI_End + the scripts.
	twitch_poll();
	twitch_tick();
	// In-game Twitch IRC (no-bot mode): cheap per-frame tick (advances the cooldown
	// frame counter). Early-returns instantly while global.tw_irc_enabled is false.
	twitch_irc_step();


	// ── NOTE SYSTEM freeze guard (revert: delete this block + the NOTE SYSTEM blocks
	// in Surface_Draw_GUI_End.gml and the globals in g_Create.gml). ──────────────
	// While the user is typing a bug note (F7), FREEZE all gameplay so the typed
	// characters can't move Link or fire actions. The note's input + draw live in
	// Surface_Draw_GUI_End (Draw GUI End runs regardless of this Step exit), so we
	// only need to short-circuit Step here. Play-safe: gated on its OWN state
	// (global.note_active), NEVER on DEV; guarded so it can never throw. Sits ABOVE
	// every existing gameplay/pause path (scheduler, delta, App_frame_count, the
	// move-speed cheat, can_update_frame, the overworld softlock exit) so nothing
	// gameplay-affecting runs while a note is open.
	if (variable_global_exists("note_active") && global.note_active)
	{
		exit; // !!! freeze gameplay; note input/draw handled in Surface_Draw_GUI_End
	}


	// An Extension so that Windows Sleep Margin in
	// Global Game Settings doesn't need to be maxed at 15 
	// to get smooth performance and avoid stuttering/jittering.
	if (scheduler_resolution_get()!=1)
	{   scheduler_resolution_set(1);  }


	// Added this to help decrease large room loading times.
	global.delta_target     = 1 / game_get_speed(gamespeed_fps);
	global.delta_actual     = delta_time / 1000000;
	global.delta_multiplier = global.delta_actual / global.delta_target;
	//show_debug_message('delta_time: '+string(delta_time)+', delta_target: '+string(delta_target)+', delta_actual: '+string(delta_actual)+', delta_multiplier: '+string(delta_multiplier));


	global.App_frame_count++;


	// ── DEV AUTOSWEEP auto-pilot: boot -> file select -> load save 1 -> start sweep ──
	// Sets dev_inject_pause BEFORE Input_update2() (line below) so the virtual press
	// lands the same frame the menus read it.
	// Also drives the SAME boot->fileselect->load-save-1 steps for the bugprobe harness
	// (global.bugprobe) when it's running without autosweep, so PROBE LAYERING/PALETTE/
	// WALK/STARTQUIT have a live save to observe. Only autosweep itself triggers the
	// room sweep (Dev_RmWarper.sweep_start()) below; a bugprobe-only run instead just
	// idles in gameplay once loaded, watched by Dev_Bugprobe_Step().

	// Bugprobe re-drive: STARTQUIT probe deliberately selects "Game End" from the pause
	// menu, which calls goto_title_rm() and lands back at rmB_Title. By that point,
	// autosweep_started=true so the block below is skipped. Reset it so the autopilot
	// drives the boot sequence again — EXITRESOLVE/TILEBLEED/EXITWALK need a live gameplay
	// session and won't run until autosweep_started becomes true a second time.
	// NOT applied to autosweep (autosweep self-terminates via game_end() before this).
	if (global.bugprobe && global.autosweep_started && room == rmB_Title)
	{
	    global.autosweep_started = false;
	    global.autosweep_t       = 0;
	    global.autosweep_boot    = 0;
	    global.autosweep_room    = -1; // force timer reset on the next frame
	}

	if ((global.autosweep || global.bugprobe || global.sweep_single || global.cooptest) && !global.autosweep_started)
	{
	    if (room != global.autosweep_room) { global.autosweep_room = room; global.autosweep_t = 0; }
	    global.autosweep_t++;
	    global.autosweep_boot++;

	    if (global.autosweep_boot > 1800) // ~60s with no gameplay reached: bail so the run returns
	    {
	        directory_create(working_directory + "screen_check");
	        var _sf = file_text_open_append(working_directory + "screen_check/crashes.txt");
	        file_text_write_string(_sf, "AUTOPILOT_STALL room=" + string(room_get_name(room)));
	        file_text_writeln(_sf); file_text_close(_sf);
	        game_end();
	    }
	    else if (room_type == "A")
	    {
	        if (instance_exists(Dev_RmWarper) && (global.autosweep || global.sweep_single))
	        {
	            // Pick the sweep by flag. Region sub-flags (cave_west/east/dthmt/mazis) are
	            // checked BEFORE the generic cave flag so a region wins if both are set.
	            // Single-category sweeps self-finalize (sweep_stop -> _DONE.txt + game_end);
	            // the bare autosweep falls through to the full RM->OW sweep_start().
	            with (Dev_RmWarper)
	            {
	                if      (global.sweep_ow)         sweep_start_ow();
	                else if (global.sweep_pal)        sweep_start_category(sweep_pred_dungeon);
	                else if (global.sweep_town)       sweep_start_category(sweep_pred_town);
	                else if (global.sweep_cave_west)  sweep_start_category(sweep_pred_cave_west);
	                else if (global.sweep_cave_east)  sweep_start_category(sweep_pred_cave_east);
	                else if (global.sweep_cave_dthmt) sweep_start_category(sweep_pred_cave_dthmt);
	                else if (global.sweep_cave_mazis) sweep_start_category(sweep_pred_cave_mazis);
	                else if (global.sweep_cave)       sweep_start_category(sweep_pred_cave);
	                else if (global.sweep_other)      sweep_start_other();
	                else                              sweep_start(); // full RM->OW (autosweep)
	            }
	            global.autosweep_started = true;
	        }
	        else if (global.bugprobe) // bugprobe-only: we've reached gameplay, nothing more for the autopilot to do
	        {
	            global.autosweep_started = true;
	        }
	        else if (global.cooptest) // co-op test: kick off the fairy state machine once gameplay (pc+f) is live
	        {
	            cooptest_start();
	            if (global.cooptest_run) global.autosweep_started = true; // only stop the autopilot once the test actually began
	        }
	    }
	    else if (room == rmB_Title)
	    {
	        if (global.autosweep_t == 40) global.dev_inject_pause = true; // -> File Select
	    }
	    else if (room == rmB_FileSelect)
	    {
	        with(FileSelect) Main_cursor = 0;                            // force cursor onto save file 1
	        if (global.autosweep_t == 90) global.dev_inject_pause = true; // confirm -> load + enter game
	    }
	}


	// ── DEV BUGPROBE harness: diagnostic probes (LAYERING/PALETTE/WALK/STARTQUIT). ──
	// Self-gated on DEV+global.bugprobe internally, so this call is a no-op (single
	// boolean check, immediate exit) in any normal/ship build or autosweep-only run.
	Dev_Bugprobe_Step();


	// --------------------------------------------------------------------
	with(Input) Input_update1(); // Gamepad input checks. gp1,2,3,4, bumpers, triggers, fpb: frame pause buttons, keypressed_prev, keypressed_curr
	with(Input) Input_update_p2(); // CO-OP P2 (fairy) gamepad read. No-op unless global.coop_enabled && a 2nd pad exists.
	Dev_CoopTest_Step(); // CO-OP TEST harness: injects synthetic Input.p2_* AFTER the clear above so the fairy's Step reads them this frame. Self-gates on global.cooptest_run.
	if (DEV) with(Input) Input_GameTesting(); // DEV-only: dev hotkeys (U=debug overlay, Z/E/V, file-clean combos). Gated so they can't fire in a play build.

	// CHEATS (toggled in Options > Dev Tools). Applied every step while in gameplay.
	if (instance_exists(f) && instance_exists(global.pc))
	{
	    if (cheat_inf_hp) f.hp = get_stat_max(STR_Heart);
	    if (cheat_inf_mp) f.mp = get_stat_max(STR_Magic);
	}
	if (cheat_inf_lives && global.pc_lives < 9) global.pc_lives = 9;


	update_game_window_1a(); // app window scale and positioning


	update_QuestTimer();


	if(!can_update_frame()) // for pausing during dev
	{
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}



	global.App_frame_count_unpaused++;
	global.Room_frame_count++;

	counter0 = (counter0+1)&$FF;


	// --------------------------------------------------------------------
	spell_cast_this_frame = 0;
	dialogue_started_this_frame = false;




	// --------------------------------------------------------------------
	// --------------------------------------------------------------------
	// --------------------------------------------------------------------
	// --------------------------------------------------------------------
	// --------------------------------------------------------------------
	// --------------------------------------------------------------------


	// C12F: JSR C1C1,   C1C6
	Audio_update();

	// C132  - Input
	with(Input) Input_update2(); // determine inputs for this frame

	// ── KONAMI CODE easter egg: detect UP UP DOWN DOWN LEFT RIGHT LEFT RIGHT B A on P1 ──
	// Runs AFTER Input_update2() so the per-frame PRESSED edges are ready. Self-guards
	// on its globals + the Input instance; fires a harmless, runtime-only egg (full heal
	// + a few lives + toast + SFX). Reversible: delete this call + the konami_check script
	// + the konami_* globals in g_Create + the KONAMI toast block in Surface_Draw_GUI_End.
	konami_check();




	if (room_type=="C" 
	&&  overworld_paused )
	{
	    if ((Input.GP_Other5_held && Input.GP_Other6_held && Input.GP_Other1_held)  // Other5: LT, Other6: RT, Other1: Xbox B
	    ||  (keyboard_check(vk_control) && keyboard_check(vk_backspace)) )
	    {
	        if(!global.OverworldSoftlock_timer)
	        {
	            global.OverworldSoftlock_timer = global.OverworldSoftlock_DURATION0;
	        }
	        else
	        {
	            global.OverworldSoftlock_timer--;
	            if(!global.OverworldSoftlock_timer)
	            {
	                room_goto_(rmB_ContinueSave);
	            }
	        }
	    }
	    else
	    {
	        global.OverworldSoftlock_timer = 0;
	    }
    
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}








	// --------------------------------------------------------------------
	// --------------------------------------------------------------------
	if(!update_QuitAppMenu() 
	&& !update_OptionsMenu() )
	{
	    if(!update_change_room()) // if not changing rm
	    {
	        // --------------------------------------------------------------------
	        switch(room_type){
	        case "A":{g_Step_A1(); break;} // menus, out of bounds fail safe
	        case "B":{g_Step_B1(); break;} // Title Screen, File Select, Next Life, Game Over, etc..
	        case "C":{with(global.OVERWORLD) Overworld_Step(); break;} // Overworld
	        }
        
	        d_l0__oo__0l_b();
        
        
	        // --------------------------------------------------------------------
	        // C14E
	        var _GUI_CONDITION =  gui_state==gui_state_NONE 
	                          ||  gui_state==gui_state_DIALOGUE1 
	                          ||  gui_state==gui_state_DIALOGUE2 
	                          ||  gui_state==gui_state_DIALOGUE3;
	        //
	        if (_GUI_CONDITION  // g.gui_state is 0 or dialogue
	        && !global.OVERWORLD.flute_timer )
	        {   // C169  - Timers
	            update_game_timers();
	            // C185  - Random numbers
	            update_og_rand();
	        }
        
        
	        // --------------------------------------------------------------------
	        if (    EnterRoom_SpawnGO_timer)
	        {
	                EnterRoom_SpawnGO_timer--;
	            if(!EnterRoom_SpawnGO_timer)
	            {
	                go_spawn_enter_room();
	            }
	        }
        
        
	        // --------------------------------------------------------------------
	        // Main update
	        if (room_type=="A" 
	        && !EnterRoom_SpawnGO_timer 
	        &&  _GUI_CONDITION ) // g.gui_state is 0 or dialogue
	        {
	            g_Step_A2();
	        }
	    }
    
    
    
    
	    // --------------------------------------------------------------------
	    // --------------------------  CUTSCENES  -----------------------------
	    cutscene_update();
	}


	// ── Quick spell cycle: L/R shoulder buttons or Q/Shift+Q key ─────────────
	// Cycles owned spells without opening the pause menu.
	if (instance_exists(f)
	&&  f.spells > 0
	&&  gui_state == gui_state_NONE
	&& !pc_lock
	&&  (room_type=="A" || room_type=="C"))
	{
	    var _cycle = 0;
	    if (Input.Spell_Next_pressed) _cycle =  1; // next
	    if (Input.Spell_Prev_pressed) _cycle = -1; // prev

	    if (_cycle != 0)
	    {
	        var _idx  = bitNum(g.spell_selected) - 1;
	        var _loop;
	        for (_loop=0; _loop<g.SPELL_COUNT; _loop++) {
	            _idx = ((_idx + _cycle) + g.SPELL_COUNT) mod g.SPELL_COUNT;
	            if (f.spells & (1<<_idx)) {
	                g.spell_selected = 1<<_idx;
	                g.spell_ready    = g.spell_selected;
	                break;
	            }
	        }
	    }
	}

	// ── Tracker window redraw ──────────────────────────────────────────────────
	TrackerWin_step();


	// ── PLAYLOG "watch-me-play" session logger: frame counter + periodic PC snapshot ──
	// Near-zero cost when off (single bool check). Frame counter only advances while
	// active (matches the F3 HUD's "REC <frame>" readout and the t=<frame> field used
	// by every other playlog log line). The snapshot itself is gated to every 30th
	// frame so file I/O stays cheap during a long session.
	if (variable_global_exists("playlog_active") && global.playlog_active)
	{
	    global.playlog_frame++;

	    if (global.playlog_frame mod 30 == 0
	    &&  instance_exists(global.pc)
	    &&  instance_exists(f) )
	    {
	        var _playlog_room  = "?";
	        if (instance_exists(g)) _playlog_room = string(g.rm_name);
	        var _playlog_lives = "?";
	        if (variable_global_exists("pc_lives")) _playlog_lives = string(global.pc_lives);
	        var _playlog_spell = "?";
	        if (instance_exists(g) && variable_instance_exists(g, "spell_selected")) _playlog_spell = string(g.spell_selected);

	        playlog_write("PC t=" + string(global.playlog_frame)
	              + " room=" + _playlog_room
	              + " x=" + string(global.pc.x)
	              + " y=" + string(global.pc.y)
	              + " hp=" + string(f.hp)
	              + " mp=" + string(f.mp)
	              + " lives=" + _playlog_lives
	              + " spell=" + _playlog_spell);
	    }

	    // ── MUSIC-STATE diag: one-shot AUDIO boot line ──────────────────────────────
	    // Fires once, as soon as Audio instance exists, to capture the initial state of
	    // the audio groups (are they loaded? what set/vol is configured?).
	    if (!global.playlog_audio_logged
	    &&  instance_exists(Audio) )
	    {
	        global.playlog_audio_logged = true;
	        playlog_write("AUDIO boot mus_vol=" + string(Audio.mus_vol)
	              + " snd_vol=" + string(Audio.snd_vol)
	              + " mus_grp_loaded=" + string(audio_group_is_loaded(audiogroup_mus))
	              + " snd_grp_loaded=" + string(audio_group_is_loaded(audiogroup_snd))
	              + " set=" + string(Audio.audio_set));
	    }

	    // ── MUSIC-STATE diag: periodic music state line (once per second at 60 fps) ──
	    // Logs whether the music group is loaded, what track is set, and whether it's
	    // actually playing — to diagnose silent-music issues in play builds.
	    if (global.playlog_frame mod 60 == 0
	    &&  instance_exists(Audio) )
	    {
	        var _playing = -1;
	        if (Audio.mus_rm_body != 0)
	        {
	            _playing = audio_is_playing(Audio.mus_rm_body);
	        }
	        playlog_write("MUSIC t=" + string(global.playlog_frame)
	              + " set=" + string(Audio.audio_set)
	              + " theme=" + string(Audio.rm_music_theme)
	              + " body=" + string(Audio.mus_rm_body)
	              + " grp_loaded=" + string(audio_group_is_loaded(audiogroup_mus))
	              + " playing=" + string(_playing));
	    }
	}

	if (global.tas_pb_state == 2)
	{
	    global.tas_pb_state = 0;
	}







}
