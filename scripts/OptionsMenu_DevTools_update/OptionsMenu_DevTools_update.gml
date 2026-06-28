/// @description  OptionsMenu_DevTools_update()
function OptionsMenu_DevTools_update() {

	// DEV TOOLS is now a LAUNCHER: every row opens a sub-folder submenu. No toggles
	// live here anymore (they moved into OVERLAYS / CHEATS / COLOR / TEST·CAPTURE /
	// SWEEPS / MISC). BACK returns to the MAIN options menu; selecting a sub-folder
	// row sets the matching menu_state and lands the cursor on that folder's first
	// available row (mirrors how MainOption_* rows open their submenus).

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	// -------------------------------------------------------------------------------
	// BACK out -> MAIN options menu.
	if(!timer)
	{
	    if (Backout_requested
	    ||  (DevTools_cursor==DevTools.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_MAIN;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	// -------------------------------------------------------------------------------
	// Navigate the launcher rows.
	if(!timer2)
	{
	    if (select_button_pressed
	    ||  Input.pressedV )
	    {
	        var _DIR = sign_(select_button_pressed || Input.Down_pressed);
	        for(_i=0; _i<DevTools.COUNT; _i++)
	        {
	            DevTools_cursor += _DIR;
	            DevTools_cursor += DevTools.COUNT;
	            DevTools_cursor  = DevTools_cursor mod DevTools.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_DEV_TOOLS,DevTools_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }

	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	// -------------------------------------------------------------------------------
	// Open the highlighted sub-folder.
	switch(DevTools_cursor)
	{
	    // -------------------------------------------------
	    case DevTools.OVERLAYS:{
	    if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        for(Overlays_cursor=0; Overlays_cursor<Overlays.COUNT; Overlays_cursor++)
	            if (OptionsMenu_option_is_avail(menu_state_OVERLAYS,Overlays_cursor)) break;//Overlays_cursor
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_OVERLAYS;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // -------------------------------------------------
	    case DevTools.CHEATS:{
	    if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        for(Cheats_cursor=0; Cheats_cursor<Cheats.COUNT; Cheats_cursor++)
	            if (OptionsMenu_option_is_avail(menu_state_CHEATS,Cheats_cursor)) break;//Cheats_cursor
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_CHEATS;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // -------------------------------------------------
	    case DevTools.COLOR:{
	    if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        for(Color_cursor=0; Color_cursor<ClrTools.COUNT; Color_cursor++)
	            if (OptionsMenu_option_is_avail(menu_state_COLOR,Color_cursor)) break;//Color_cursor
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_COLOR;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // -------------------------------------------------
	    case DevTools.TEST_CAP:{
	    if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        for(TestCap_cursor=0; TestCap_cursor<TestCap.COUNT; TestCap_cursor++)
	            if (OptionsMenu_option_is_avail(menu_state_TEST_CAP,TestCap_cursor)) break;//TestCap_cursor
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_TEST_CAP;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // -------------------------------------------------
	    case DevTools.SWEEPS:{
	    if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        for(Sweeps_cursor=0; Sweeps_cursor<Sweeps.COUNT; Sweeps_cursor++)
	            if (OptionsMenu_option_is_avail(menu_state_SWEEPS,Sweeps_cursor)) break;//Sweeps_cursor
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_SWEEPS;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // -------------------------------------------------
	    case DevTools.MISC:{
	    if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        for(Misc_cursor=0; Misc_cursor<MiscTools.COUNT; Misc_cursor++)
	            if (OptionsMenu_option_is_avail(menu_state_MISC,Misc_cursor)) break;//Misc_cursor
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_MISC;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // -------------------------------------------------
	    case DevTools.BACK:{
	    if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_MAIN;
	    }
	    break;}
	}

}
