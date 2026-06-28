/// @description  OptionsMenu_Sweeps_update()
function OptionsMenu_Sweeps_update() {

	// DEV TOOLS sub-folder: SWEEPS. Selecting a row starts that sweep LIVE and closes
	// the options menu -- the EXACT SAME close+launch sequence the old AUTOMATED TEST
	// submenu used: set global.sweep_from_menu=true so sweep_stop() returns to play
	// (NO game_end), force the options menu closed, then run the matching start method
	// on the persistent Dev_RmWarper instance. BACK -> DEV TOOLS launcher.

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	if(!timer)
	{
	    if (Backout_requested
	    ||  (Sweeps_cursor==Sweeps.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_DEV_TOOLS;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	if(!timer2)
	{
	    if (select_button_pressed
	    ||  Input.pressedV )
	    {
	        var _DIR = sign_(select_button_pressed || Input.Down_pressed);
	        for(_i=0; _i<Sweeps.COUNT; _i++)
	        {
	            Sweeps_cursor += _DIR;
	            Sweeps_cursor += Sweeps.COUNT;
	            Sweeps_cursor  = Sweeps_cursor mod Sweeps.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_SWEEPS,Sweeps_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(Sweeps_cursor)
	{
	    case Sweeps.SW_FULL:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start(); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_OVERWORLD:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_ow(); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_PALACES:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_dungeon); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_TOWNS:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_town); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_CAVES:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_cave); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_CAVES_WEST:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_cave_west); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_CAVES_EAST:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_cave_east); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_CAVES_DTHMT:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_cave_dthmt); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_CAVES_MAZIS:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_category(sweep_pred_cave_mazis); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.SW_OTHER:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.sweep_from_menu = true;
	        with (Dev_RmWarper) { sweep_start_other(); }
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    case Sweeps.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_DEV_TOOLS; }
	    break;}
	}

}
