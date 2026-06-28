/// @description  OptionsMenu_Color_update()
function OptionsMenu_Color_update() {

	// DEV TOOLS sub-folder: COLOR. Opens the same palette editors the old flat DEV
	// TOOLS menu did (PaletteEditor bgr / pal edit modes). BACK -> DEV TOOLS launcher.

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	if(!timer)
	{
	    if (Backout_requested
	    ||  (Color_cursor==ClrTools.BACK && _InputConfirm_pressed) )
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
	        for(_i=0; _i<ClrTools.COUNT; _i++)
	        {
	            Color_cursor += _DIR;
	            Color_cursor += ClrTools.COUNT;
	            Color_cursor  = Color_cursor mod ClrTools.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_COLOR,Color_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(Color_cursor)
	{
	    // ---------------------------------------------------------
	    case ClrTools.BGR_COLOR:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame      = 0;
	        draw_rows_count = 0;
	        g.gui_state     = g.gui_state_NONE;
	        with(PaletteEditor) PaletteEditor_initiate_bgr_edit_mode();

	        aud_play_sound(get_audio_theme_track(dk_OpenGUI));
	        timer = 0;
	        sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}//case ClrTools.BGR_COLOR

	    // ---------------------------------------------------------
	    case ClrTools.ROOM_COLOR:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame      = 0;
	        draw_rows_count = 0;
	        g.gui_state     = g.gui_state_NONE;
	        with(PaletteEditor) PaletteEditor_initiate_pal_edit_mode();

	        aud_play_sound(get_audio_theme_track(dk_OpenGUI));
	        timer = 0;
	        sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}//case ClrTools.ROOM_COLOR

	    // ---------------------------------------------------------
	    case ClrTools.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_DEV_TOOLS; }
	    break;}
	}

}
