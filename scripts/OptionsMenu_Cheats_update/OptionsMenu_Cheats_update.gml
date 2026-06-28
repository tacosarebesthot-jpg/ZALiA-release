/// @description  OptionsMenu_Cheats_update()
function OptionsMenu_Cheats_update() {

	// DEV TOOLS sub-folder: CHEATS. Each toggle flips the EXACT SAME global it did
	// under the old flat DEV TOOLS menu. BACK -> DEV TOOLS launcher.

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	if(!timer)
	{
	    if (Backout_requested
	    ||  (Cheats_cursor==Cheats.BACK && _InputConfirm_pressed) )
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
	        for(_i=0; _i<Cheats.COUNT; _i++)
	        {
	            Cheats_cursor += _DIR;
	            Cheats_cursor += Cheats.COUNT;
	            Cheats_cursor  = Cheats_cursor mod Cheats.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_CHEATS,Cheats_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(Cheats_cursor)
	{
	    case Cheats.ADD_ITEMS:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.use_StabToCheat = !g.use_StabToCheat; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Cheats.PC_DASH:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.DevDash_state = !sign(g.DevDash_state); save_game_pref(); aud_play_sound(_SOUND2); timer = DURATION1; } // 0: Off, 1: On, 2: On and dash input held
	    break;}

	    case Cheats.INF_HP:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.cheat_inf_hp = !g.cheat_inf_hp; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Cheats.INF_MP:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.cheat_inf_mp = !g.cheat_inf_mp; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Cheats.INF_LIVES:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.cheat_inf_lives = !g.cheat_inf_lives; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Cheats.INVULN:{ if (timer) break;
	    if (_InputConfirm_pressed2){ g.cheat_invuln = !g.cheat_invuln; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case Cheats.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_DEV_TOOLS; }
	    break;}
	}

}
