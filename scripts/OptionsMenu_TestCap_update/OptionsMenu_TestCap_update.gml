/// @description  OptionsMenu_TestCap_update()
function OptionsMenu_TestCap_update() {

	// DEV TOOLS sub-folder: TEST / CAPTURE. Each toggle fires the EXACT SAME action
	// it did under the old AUTOMATED TEST submenu (bugprobe, TAS rec/playback, playlog,
	// walktune, controller diag). BACK -> DEV TOOLS launcher.

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	if(!timer)
	{
	    if (Backout_requested
	    ||  (TestCap_cursor==TestCap.BACK && _InputConfirm_pressed) )
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
	        for(_i=0; _i<TestCap.COUNT; _i++)
	        {
	            TestCap_cursor += _DIR;
	            TestCap_cursor += TestCap.COUNT;
	            TestCap_cursor  = TestCap_cursor mod TestCap.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_TEST_CAP,TestCap_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(TestCap_cursor)
	{
	    case TestCap.BUGPROBE:{ if (timer) break;
	    if (_InputConfirm_pressed2){ global.bugprobe = !global.bugprobe; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case TestCap.TAS_RECORD:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        if (global.tas_rec_state) tas_rec_stop();
	        else                      tas_rec_start();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case TestCap.TAS_PLAYBACK:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        if (global.tas_pb_state) global.tas_pb_state = 0;
	        else                     tas_pb_load_start();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case TestCap.PLAYLOG:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        if (!variable_global_exists("playlog_active")) global.playlog_active = false;
	        if (!variable_global_exists("playlog_frame"))  global.playlog_frame  = 0;
	        if (global.playlog_active)
	        {
	            // Write STOP before clearing the flag (gate in playlog_write requires active==true)
	            playlog_write("=== PLAYLOG STOP ===");
	            global.playlog_active = false;
	        }
	        else
	        {
	            global.playlog_active = true;
	            playlog_write("=== PLAYLOG START t=" + string(global.playlog_frame) + " ts=" + string(date_datetime_string(date_current_datetime())) + " ===");
	        }
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case TestCap.WALKTUNE:{ if (timer) break;
	    if (_InputConfirm_pressed2){ global.walktune_on = !global.walktune_on; aud_play_sound(_SOUND2); timer = DURATION1; }
	    break;}

	    case TestCap.GP_DIAG:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        if (!variable_global_exists("gp_diag_on")) global.gp_diag_on = 0;
	        global.gp_diag_on = !global.gp_diag_on;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // CO-OP TEST: launch the SAME automated fairy test LIVE. Mirrors the SWEEPS rows'
	    // close+launch sequence -- set global.cooptest_from_menu=true so the test returns to
	    // play (NO game_end) at FINISH, force the options menu closed, then cooptest_start().
	    case TestCap.COOP_TEST:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        global.cooptest_from_menu = true;
	        cooptest_start();
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // REPLAY LAST MARK: restore the last MARK (key 3) room-entry snapshot and arm
	    // TAS playback of its dumped input ring. Mirrors the COOP TEST close sequence
	    // (force the options menu closed, then launch) so the replay runs in live play.
	    case TestCap.REPLAY_MARK:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        mark_replay_load();
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // SPAWN AT LAST MARK: same snapshot restore as REPLAY LAST MARK, but WITHOUT arming
	    // TAS playback -- the tester keeps the controls. Added so a bug that takes a long walk
	    // to reach can be re-tested from its exact state as many times as needed.
	    case TestCap.SPAWN_MARK:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        anim_frame = 0; draw_rows_count = 0; g.gui_state = g.gui_state_NONE;
	        mark_replay_load(false); // false = restore state, do NOT replay inputs
	        aud_play_sound(_SOUND2);
	        timer = 0; sub_state = sub_state_IDLE_CLOSED;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    break;}

	    // TWITCH (master gate): standalone ON/OFF for the file-drop poll (twitch_poll)
	    // + verb dispatcher (twitch_apply), both gated on global.tw_enabled. Lets you test
	    // the channel-point / donation file-drop path WITHOUT the in-game IRC connecting
	    // (which is the only OTHER thing that flips tw_enabled, as a side effect).
	    // TWITCH + TWITCH IRC moved to the player-facing TWITCH menu (2026-07-26).

	    case TestCap.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_DEV_TOOLS; }
	    break;}
	}

}
