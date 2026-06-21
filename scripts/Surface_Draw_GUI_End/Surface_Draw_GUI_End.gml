/// @description  Surface_Draw_GUI_End()
function Surface_Draw_GUI_End() {


	if (global.QuestTimer_can_draw)
	{
	    global.QuestTimer_can_draw = false;
	    draw_text_(global.QuestTimer_xl,global.QuestTimer_yt, global.QuestTimer_text);
	}


	// ------------------------------------------------------------------------------------
	// DEV PLAYTEST FLAG: press F6 during normal play to log the current spot for later review.
	// Writes a screenshot of the fully-composited frame (we're in Draw GUI End) plus the
	// scene / coords / game-time to <working_directory>problems\  (play_NNN.png + _playtest_log.txt).
	if (DEV && keyboard_check_pressed(vk_f6))
	{
	    if (!variable_global_exists("dev_flag_count")) global.dev_flag_count = 0;
	    global.dev_flag_count++;
	    var _n  = global.dev_flag_count;
	    var _ns = string(_n);
	    if (_n<100) _ns = "0"+_ns;
	    if (_n<10)  _ns = "0"+_ns;

	    var _dir = working_directory + "problems/";
	    directory_create(_dir);

	    var _loc = "room=" + room_get_name(room);
	    if (instance_exists(g))
	    {
	        _loc += "  type=" + string(g.room_type) + "  scene=" + string(g.rm_name) + "  area=" + string(g.area_name);
	        if (g.room_type=="C" && instance_exists(global.OVERWORLD))
	            _loc += "  owrc=$" + hex_str(global.OVERWORLD.pcrc);
	        else if (instance_exists(global.pc))
	            _loc += "  pc_xy=(" + string(global.pc.x) + "," + string(global.pc.y) + ")";
	    }
	    var _gt = variable_global_exists("App_frame_count") ? ("frame="+string(global.App_frame_count)) : ("ms="+string(current_time));

	    screen_save(_dir + "play_" + _ns + ".png"); // captured before the FLAGGED overlay below, so the shot is clean

	    var _ff = file_text_open_append(_dir + "_playtest_log.txt");
	    file_text_write_string(_ff, "#"+_ns+"  |  "+_gt+"  |  "+_loc+"  |  play_"+_ns+".png");
	    file_text_writeln(_ff);
	    file_text_close(_ff);

	    global.dev_flag_msg       = "FLAGGED #"+_ns;
	    global.dev_flag_msg_timer = 120;
	}
	if (variable_global_exists("dev_flag_msg_timer") && global.dev_flag_msg_timer>0)
	{
	    global.dev_flag_msg_timer--;
	    var _pf = draw_get_font();
	    draw_set_font(-1);
	    draw_set_halign(fa_left);
	    draw_set_colour(c_black); draw_text(9, 25, global.dev_flag_msg);
	    draw_set_colour(c_lime);  draw_text(8, 24, global.dev_flag_msg);
	    draw_set_colour(c_white);
	    draw_set_font(_pf);
	}


	/* This is here so it's the last thing that happens
	so `srf_app_paused_frame` can catch everything that
	drew this frame.
	*/
	update_app_pause();







}
