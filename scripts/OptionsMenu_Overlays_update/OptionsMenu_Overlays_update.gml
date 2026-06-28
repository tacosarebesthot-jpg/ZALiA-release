/// @description  OptionsMenu_Overlays_update()
function OptionsMenu_Overlays_update() {

	// DEV TOOLS sub-folder: OVERLAYS. Each toggle flips the EXACT SAME global it did
	// under the old flat DEV TOOLS / AUTOMATED TEST menus. BACK returns to the DEV
	// TOOLS launcher (menu_state_DEV_TOOLS).

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	// BACK -> DEV TOOLS launcher.
	if(!timer)
	{
	    if (Backout_requested
	    ||  (Overlays_cursor==Overlays.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_DEV_TOOLS;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	// Navigate.
	if(!timer2)
	{
	    if (select_button_pressed
	    ||  Input.pressedV )
	    {
	        var _DIR = sign_(select_button_pressed || Input.Down_pressed);
	        for(_i=0; _i<Overlays.COUNT; _i++)
	        {
	            Overlays_cursor += _DIR;
	            Overlays_cursor += Overlays.COUNT;
	            Overlays_cursor  = Overlays_cursor mod Overlays.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_OVERLAYS,Overlays_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(Overlays_cursor)
	{
	    case Overlays.HITBOXES:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_draw_hb = !g.can_draw_hb; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.SCP:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_draw_cs = !g.can_draw_cs; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.XY:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.canDraw_ogXY = !g.canDraw_ogXY; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.OG_CAM:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_draw_og_cam_outline = !g.can_draw_og_cam_outline; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.HP:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_draw_hp = !g.can_draw_hp; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.SPRITE_OUTLINE:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        var _DIR = sign_(Input.Right_pressed || _InputConfirm_pressed);
	        var _COUNT=3; // Sequences 0, 1, 2
	        g.canDrawSprOutline += _DIR;
	        g.canDrawSprOutline += _COUNT;
	        g.canDrawSprOutline  = g.canDrawSprOutline mod _COUNT;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case Overlays.FRAME_COUNT:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        global.App_frame_count_can_draw          = !global.App_frame_count_can_draw;
	        global.App_frame_count_unpaused_can_draw = !global.App_frame_count_unpaused_can_draw;
	        global.Room_frame_count_can_draw         = !global.Room_frame_count_can_draw;
	        save_game_pref();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case Overlays.DEPTH_DEBUG:{ if (timer) break;
	    if (_InputConfirm_pressed2){ global.dbg_depth_show = !global.dbg_depth_show; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.DEATH_COUNTER:{ if (timer) break;
	    if (_InputConfirm_pressed2){ global.dbg_death_counter_show = !global.dbg_death_counter_show; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.EXITS:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_draw_Exit_hb = !g.can_draw_Exit_hb; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.SOLID_TILES:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_show_t_solid = !g.can_show_t_solid; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.UNIQUE_TILES:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.can_show_t_unique = !g.can_show_t_unique; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.DUNGEON_MAP:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        g.dev_DungeonMapShowAll = !g.dev_DungeonMapShowAll;
	        if (g.dungeon_num) DungeonMapVisible_refresh(g.dungeon_num);
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case Overlays.INPUT_DISPLAY:{ if (timer) break;
	    if (_InputConfirm_pressed2){ global.tas_overlay_on = !global.tas_overlay_on; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Overlays.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_DEV_TOOLS; }
	    break;}
	}

}
