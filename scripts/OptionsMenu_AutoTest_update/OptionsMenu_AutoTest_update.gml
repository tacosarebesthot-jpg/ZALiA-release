/// @description  OptionsMenu_AutoTest_update()
function OptionsMenu_AutoTest_update() {


	var _i, _val;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // GP_Face1_pressed: xbox A
	var _InputConfirm_pressed2 = _InputConfirm_pressed || Input.pressedH;

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	// -------------------------------------------------------------------------------
	if(!timer)
	{
	    if (Backout_requested
	    ||  (AutoTest_cursor==AutoTest.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_MAIN;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}




	// -------------------------------------------------------------------------------
	if(!timer2)
	{
	    if (select_button_pressed
	    ||  Input.pressedV )
	    {
	        var _DIR = sign_(select_button_pressed || Input.Down_pressed);
	        for(_i=0; _i<AutoTest.COUNT; _i++)
	        {
	            AutoTest_cursor += _DIR;
	            AutoTest_cursor += AutoTest.COUNT;
	            AutoTest_cursor  = AutoTest_cursor mod AutoTest.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST,AutoTest_cursor))
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
	// SWEEP STARTERS: selecting a row starts that sweep LIVE and closes the options menu.
	// The shared close+launch sequence (mirrors the DEV TOOLS palette-editor open path):
	//   set global.sweep_from_menu=true so sweep_stop() returns to play instead of game_end(),
	//   force the options menu closed (gui_state_NONE + sub_state_IDLE_CLOSED), then run the
	//   matching start method on the persistent Dev_RmWarper instance.
	// -------------------------------------------------------------------------------
	switch(AutoTest_cursor)
	{
	    // ------------------------------------------------- SWEEP STARTERS
	    case AutoTest.SW_FULL:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_OVERWORLD:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_PALACES:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_TOWNS:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_CAVES:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_CAVES_WEST:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_CAVES_EAST:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_CAVES_DTHMT:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_CAVES_MAZIS:{
	    if (timer) break;
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

	    // -------------------------------------------------
	    case AutoTest.SW_OTHER:{
	    if (timer) break;
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


	    // ------------------------------------------------- MOVED TOGGLES (behavior unchanged)
	    case AutoTest.BUGPROBE:{
	    if (timer) break;

	    if (_InputConfirm_pressed2)
	    {
	        global.bugprobe = !global.bugprobe;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case AutoTest.TAS_RECORD:{
	    if (timer) break;

	    if (_InputConfirm_pressed2)
	    {
	        if (global.tas_rec_state)
	        {
	            tas_rec_stop();
	        }
	        else
	        {
	            tas_rec_start();
	        }
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case AutoTest.TAS_PLAYBACK:{
	    if (timer) break;

	    if (_InputConfirm_pressed2)
	    {
	        if (global.tas_pb_state)
	        {
	            global.tas_pb_state = 0;
	        }
	        else
	        {
	            tas_pb_load_start();
	        }
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case AutoTest.INPUT_DISPLAY:{
	    if (timer) break;

	    if (_InputConfirm_pressed2)
	    {
	        global.tas_overlay_on = !global.tas_overlay_on;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case AutoTest.PLAYLOG:{
	    if (timer) break;

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

	    // -------------------------------------------------
	    case AutoTest.WALKTUNE:{
	    if (timer) break;

	    if (_InputConfirm_pressed2)
	    {
	        global.walktune_on = !global.walktune_on;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case AutoTest.GP_DIAG:{
	    if (timer) break;

	    if (_InputConfirm_pressed2)
	    {
	        if (!variable_global_exists("gp_diag_on")) global.gp_diag_on = 0;
	        global.gp_diag_on = !global.gp_diag_on;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // -------------------------------------------------
	    case AutoTest.BACK:{
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
