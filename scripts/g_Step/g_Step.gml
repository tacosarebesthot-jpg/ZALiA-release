/// @description  g_Step()
function g_Step() {


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
	if (global.autosweep && !global.autosweep_started)
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
	        if (instance_exists(Dev_RmWarper))
	        {
	            with(Dev_RmWarper) sweep_start();
	            global.autosweep_started = true;
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


	// --------------------------------------------------------------------
	with(Input) Input_update1(); // Gamepad input checks. gp1,2,3,4, bumpers, triggers, fpb: frame pause buttons, keypressed_prev, keypressed_curr
	with(Input) Input_GameTesting();


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
	    if (Input.GP_Shoulder1R_pressed || keyboard_check_pressed(ord("Q")))                          _cycle =  1; // next
	    if (Input.GP_Shoulder1L_pressed || (keyboard_check_pressed(ord("Q")) && keyboard_check(vk_shift))) _cycle = -1; // prev

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







}
