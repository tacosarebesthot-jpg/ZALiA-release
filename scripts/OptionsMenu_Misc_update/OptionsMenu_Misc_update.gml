/// @description  OptionsMenu_Misc_update()
function OptionsMenu_Misc_update() {

	// DEV TOOLS sub-folder: MISC. SET ALL TO DEFAULT, APP PERFORMANCE overlay, and the
	// DEV TOOLS master switch -- each does the EXACT SAME thing it did under the old
	// flat DEV TOOLS menu. BACK -> DEV TOOLS launcher.

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	if(!timer)
	{
	    if (Backout_requested
	    ||  (Misc_cursor==MiscTools.BACK && _InputConfirm_pressed) )
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
	        for(_i=0; _i<MiscTools.COUNT; _i++)
	        {
	            Misc_cursor += _DIR;
	            Misc_cursor += MiscTools.COUNT;
	            Misc_cursor  = Misc_cursor mod MiscTools.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_MISC,Misc_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(Misc_cursor)
	{
	    // -------------------------------------------------
	    case MiscTools.SET_DEFAULT:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        g.DevTools_state          = false;

	        g.can_show_debug_overlay  = false;
	        show_debug_overlay(g.can_show_debug_overlay);

	        g.can_draw_hb             = false;
	        g.can_draw_cs             = false;
	        g.canDraw_ogXY            = false;
	        g.can_draw_ocs            = false;
	        g.can_draw_og_cam_outline = false;
	        g.can_draw_hp             = false;
	        g.canDrawSprOutline       = 0;

	        global.App_frame_count_can_draw          = false;
	        global.App_frame_count_unpaused_can_draw = false;
	        global.Room_frame_count_can_draw         = false;

	        g.all_bg_black_only = false;

	        g.can_draw_Exit_hb  = false;
	        g.can_show_t_solid  = false;
	        g.can_show_t_unique = false;

	        g.dev_DungeonMapShowAll = false;
	        if (g.dungeon_num) DungeonMapVisible_refresh(g.dungeon_num);

	        g.use_StabToCheat  = false;
	        g.DevDash_state    = 0; // 0: Off, 1: On, 2: On and dash input held
	        g.dev_invState     = 0;

	        save_game_pref();
	        aud_play_sound(_SOUND2);
	        aud_play_sound(get_audio_theme_track(dk_BlockBreak));
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case MiscTools.APP_PERFORMANCE:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        g.can_show_debug_overlay = !g.can_show_debug_overlay;
	        save_game_pref();
	        show_debug_overlay(g.can_show_debug_overlay);
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case MiscTools.DEV_TOOLS_STATE:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        g.DevTools_state = !g.DevTools_state;
	        save_game_pref();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    // (MiscTools.CO_OP removed 2026-06-28 -- CO-OP toggle promoted to the MAIN options
	    //  list; the master gate now flips global.coop_enabled from MainOption_CO_OP.)

	    // -------------------------------------------------
	    case MiscTools.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_DEV_TOOLS; }
	    break;}
	}

}
