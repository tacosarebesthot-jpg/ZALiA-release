/// @description  OptionsMenu_Draw_Twitch(YT)
/// @param YT
function OptionsMenu_Draw_Twitch() {

	// PLAYER-FACING Twitch menu draw. Two on/off rows, two value rows shown in
	// SECONDS, one read-only reference row, and BACK.
	//
	// CONNECT TO CHAT deliberately shows the live connection STATUS rather than a plain
	// ON/OFF, because "on but not connected" is the state people actually get stuck in
	// (bad channel name, no token, network). global.tw_irc_status is maintained by
	// twitch_irc_load_config / _connect / _handle_line.
	//
	// The oauth token is never drawn here. This menu gets opened on stream.

	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $4;
	var _pi;
	var _text, _font, _font_w,_font_h;
	var _enum;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max, _vis_rows;

	var _dg_state_text = ds_grid_create(1,2);
	    _dg_state_text[#0,0] = "OFF";  _dg_state_text[#0,1] = "ON";

	_font   = Twitch_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt;
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	_vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;


	_vis_N = 0;
	var _vis_enum = array_create(Twitch.COUNT, 0);
	for (_i = 0; _i < Twitch.COUNT; _i++)
	{
	    if (OptionsMenu_option_is_avail(menu_state_TWITCH, _i)) { _vis_enum[_vis_N] = _i; _vis_N++; }
	}


	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++) { if (_vis_enum[_i] == Twitch_cursor) { _cursor_vis_pos = _i; break; } }

	_top_max   = max(0, _vis_N - _vis_rows);
	_top_index = _cursor_vis_pos - (_vis_rows >> 1);
	if (_top_index < 0)        _top_index = 0;
	if (_top_index > _top_max) _top_index = _top_max;


	_draw_end = _top_index + _vis_rows;
	if (_draw_end > _vis_N) _draw_end = _vis_N;

	var _fps = game_get_speed(gamespeed_fps);
	if (_fps <= 0) _fps = 60;

	for (_i = _top_index; _i < _draw_end; _i++)
	{
	    _yt1 = _ScrollArea_YT + (_i - _top_index) * _ROW_H;

	    _enum = _vis_enum[_i];
	    _text = Twitch_dg[#_enum,0];

	    if (_enum==Twitch_cursor) _pi = PI_MENU1;
	    else                      _pi = PI_MENU2;
	    _xl = TextArea1_xl;
	    draw_text_(_xl,_yt1, _text, _font, _pi);


	    // ---- right-hand state column ----
	    _text = 0;
	    switch(_enum){

	    case Twitch.REWARDS:
	        _text = _dg_state_text[#0, sign(variable_global_exists("tw_enabled") && global.tw_enabled)];
	    break;

	    case Twitch.CHAT:
	        // Live status beats ON/OFF here -- "on but never connected" is the real trap.
	        if (variable_global_exists("tw_irc_enabled") && global.tw_irc_enabled)
	        {
	            _text = variable_global_exists("tw_irc_status") ? string_upper(string(global.tw_irc_status)) : "ON";
	        }
	        else _text = _dg_state_text[#0,0];
	    break;

	    case Twitch.COOLDOWN:
	        // stored in frames, shown in seconds
	        var _cd_f = variable_global_exists("tw_irc_cooldown_frames") ? global.tw_irc_cooldown_frames : 600;
	        var _cd_s = round(_cd_f / _fps);
	        _text = (_cd_s <= 0) ? "NONE" : (string(_cd_s) + "S");
	    break;

	    case Twitch.DURATION:
	        var _du = variable_global_exists("tw_effect_secs") ? global.tw_effect_secs : 5;
	        _text = string(_du) + "S";
	    break;

	    case Twitch.JOKES:
	        _text = tw_jokes_mode_label();
	    break;

	    case Twitch.AUTOSAVE:
	        _text = _dg_state_text[#0, sign(variable_global_exists("tw_autosave") && global.tw_autosave)];
	    break;

	    }//switch(_enum)

	    if (_text != 0)
	    {
	        _xl  = TextArea2_xr;
	        _xl -= string_length(_text) * _font_w;
	        if (_enum == Twitch_cursor)
	        {
	            _pi = PI_MENU1;
	        }
	        else
	        {
	            // dim the "off"/"none" states so the eye finds what is live
	            if (_text==_dg_state_text[#0,0] || _text=="NONE") _pi = PI_DARK1;
	            else                                             _pi = PI_MENU2;
	        }
	        draw_text_(_xl,_yt1, _text, _font, _pi);
	    }


	    if (_enum == Twitch_cursor)
	    {
	        _x = Cursor_xl + (Cursor_W>>1);
	        _y = _yt1 + (_font_h>>1);
	        draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	    }
	}


	// OPTION INFO -----------------------------------------------------------
	_yt1 = Info_yt;
	if (_yt1+Info_FONT_H < MenuWindow_yb)
	{
	    _text = Twitch_dg[#Twitch_cursor,2];
	    if (is_string(_text))
	    {
	        _xl = TextArea1_xl;
	        _yt = _yt1;
	        pal_swap_set(global.palette_image, PI_MENU1);
	        draw_text_plus(_xl,Info_xr, _yt, _text, Info_FONT);
	        pal_swap_reset();
	    }
	}

	ds_grid_destroy(_dg_state_text); _dg_state_text=undefined;

}
