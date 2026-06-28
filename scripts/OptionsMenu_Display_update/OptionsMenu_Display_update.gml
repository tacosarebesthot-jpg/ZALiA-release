/// @description  OptionsMenu_Display_update()
function OptionsMenu_Display_update() {


	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter);

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	// -------------------------------------------------------------------------------
	// BACK out (b-button / esc), or CONFIRM on the BACK row -> return to MAIN.
	if(!timer)
	{
	    if (Backout_requested
	    ||  (Display_cursor==Display.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_MAIN;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	// -------------------------------------------------------------------------------
	// CONFIRM on a MODE row -> apply that mode and persist it.
	// FULLSCREEN + WINDOW SCALE are NOT part of this radio group: FULLSCREEN is a toggle and
	// WINDOW SCALE is a value, both handled in update_game_window_1a() (which keys off
	// menu_state_DISPLAY + Display_cursor). They are excluded here so a confirm on those rows
	// never hijacks global.DisplayMode.
	if(!timer)
	{
	    if (Display_cursor!=Display.BACK
	    &&  Display_cursor!=Display.FULLSCREEN
	    &&  Display_cursor!=Display.WINDOW_SCALE
	    &&  _InputConfirm_pressed2 )
	    {
	        // RADIO-SELECT commit: only NOW does the highlighted row become the active mode,
	        // and we persist EXACTLY ONCE -- and only if it actually changed (no-op otherwise).
	        // Mode rows SMOOTH..SCAN sit at enum offset Display.SMOOTH, so subtract it to map
	        // back onto the contiguous DISPLAY_* macros (DISPLAY_SMOOTH..DISPLAY_SCAN).
	        var _mode = Display_cursor - Display.SMOOTH;
	        if (global.DisplayMode != _mode)
	        {
	            global.DisplayMode = _mode;          // enum-mode row mapped onto DISPLAY_* macro
	            save_game_pref();                    // the ONLY save_game_pref() in this submenu
	            apply_display_mode();                // apply the newly-selected screen-scaling mode now
	        }
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	// -------------------------------------------------------------------------------
	// NAVIGATE: up/down OR left/right move the highlighted row only. This does NOT touch
	// global.DisplayMode and does NOT save -- the mode is committed on CONFIRM (block above).
	// (The old code set global.DisplayMode + save_game_pref() on every move, which hammered
	//  the disk -> the lag, and made the "ON" marker just follow the cursor.)
	var _VERTICAL   = bit_dir(gui_tmr_cursor_v()); // 0,1,-1
	var _HORIZONTAL = bit_dir(gui_tmr_cursor_h()); // 0,1,-1
	var _DIR = _VERTICAL;
	// LEFT/RIGHT navigates on the MODE rows (acts like up/down), but on the FULLSCREEN and
	// WINDOW SCALE rows LEFT/RIGHT is consumed by update_game_window_1a() (toggle fullscreen /
	// cycle window scale), so it must NOT move the cursor there.
	if (!_DIR
	&&  Display_cursor!=Display.FULLSCREEN
	&&  Display_cursor!=Display.WINDOW_SCALE )
	{
	    _DIR = _HORIZONTAL;
	}

	if(!timer2)
	{
	    if (_DIR)
	    {
	        for(_i=0; _i<Display.COUNT; _i++)
	        {
	            Display_cursor += _DIR;
	            Display_cursor += Display.COUNT;
	            Display_cursor  = Display_cursor mod Display.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_DISPLAY, Display_cursor))
	            {
	                break;//_i
	            }
	        }

	        // NOTE: cursor moved only. No global.DisplayMode write, no save_game_pref() here.

	        aud_play_sound(_SOUND1);
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}




}
