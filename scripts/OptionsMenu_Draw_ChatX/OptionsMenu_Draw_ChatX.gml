/// @description  OptionsMenu_Draw_ChatX(YT)
/// @param YT
function OptionsMenu_Draw_ChatX() {

	// CHAT EXTRAS (TWITCH sub-page). Same scrolling list as OptionsMenu_Draw_Twitch:
	// name on the left, state on the right, help text in the info area below.
	// Every row here mirrors a twitch_config.txt key; the right-hand column is the live value.

	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $4;
	var _pi;
	var _text, _font, _font_w, _font_h;
	var _enum;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max, _vis_rows;

	var _OFF = "OFF", _ON = "ON";

	_font   = ChatX_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt;
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	_vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;

	_vis_N = 0;
	var _vis_enum = array_create(ChatX.COUNT, 0);
	for (_i = 0; _i < ChatX.COUNT; _i++)
	{
	    if (OptionsMenu_option_is_avail(menu_state_CHAT_EXTRAS, _i)) { _vis_enum[_vis_N] = _i; _vis_N++; }
	}

	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++) { if (_vis_enum[_i] == ChatX_cursor) { _cursor_vis_pos = _i; break; } }

	_top_max   = max(0, _vis_N - _vis_rows);
	_top_index = _cursor_vis_pos - (_vis_rows >> 1);
	if (_top_index < 0)        _top_index = 0;
	if (_top_index > _top_max) _top_index = _top_max;

	_draw_end = _top_index + _vis_rows;
	if (_draw_end > _vis_N) _draw_end = _vis_N;

	for (_i = _top_index; _i < _draw_end; _i++)
	{
	    _yt1 = _ScrollArea_YT + (_i - _top_index) * _ROW_H;

	    _enum = _vis_enum[_i];
	    _text = ChatX_dg[#_enum,0];

	    if (_enum==ChatX_cursor) _pi = PI_MENU1;
	    else                     _pi = PI_MENU2;
	    _xl = TextArea1_xl;
	    draw_text_(_xl,_yt1, _text, _font, _pi);

	    // ---- right-hand state column ----
	    _text = 0;
	    switch(_enum){

	    case ChatX.HINT:
	        _text = (variable_global_exists("tw_first_use_hint") && global.tw_first_use_hint) ? _ON : _OFF;
	    break;

	    case ChatX.ONEUP:
	        var _mn = variable_global_exists("tw_oneup_nudge_min") ? global.tw_oneup_nudge_min : 0;
	        _text = (_mn <= 0) ? _OFF : (string(_mn) + " MIN");
	    break;

	    case ChatX.SWARM_CAP:
	        _text = string(variable_global_exists("tw_swarm_cap") ? global.tw_swarm_cap : 14);
	    break;

	    case ChatX.TOASTY:
	        var _tp = variable_global_exists("tw_toasty_pct") ? global.tw_toasty_pct : 50;
	        _text = (_tp <= 0) ? _OFF : (string(_tp) + "%");
	    break;

	    case ChatX.ANNOUNCER:
	        _text = (!variable_global_exists("tw_announcer") || global.tw_announcer) ? _ON : _OFF;
	    break;

	    case ChatX.BABALITY:
	        var _bp = variable_global_exists("tw_babality_pct") ? global.tw_babality_pct : 15;
	        _text = (_bp <= 0) ? _OFF : (string(_bp) + "%");
	    break;

	    case ChatX.BETS:
	        _text = (!variable_global_exists("tw_bets_on") || global.tw_bets_on) ? _ON : _OFF;
	    break;

	    case ChatX.HELPCARD:
	        _text = (variable_global_exists("tw_help_card") && global.tw_help_card) ? _ON : _OFF;
	    break;

	    case ChatX.PRICES:
	        _text = (!variable_global_exists("tw_cmd_prices") || global.tw_cmd_prices) ? _ON : _OFF;
	    break;

	    case ChatX.BOUNTY:
	        _text = (variable_global_exists("tw_bounty_on") && global.tw_bounty_on) ? _ON : _OFF;
	    break;

	    }//switch(_enum)

	    if (_text != 0)
	    {
	        _xl  = TextArea2_xr;
	        _xl -= string_length(_text) * _font_w;
	        if (_enum == ChatX_cursor) _pi = PI_MENU1;
	        else if (_text == _OFF)    _pi = PI_DARK1; // dim the off states so the eye finds what is live
	        else                       _pi = PI_MENU2;
	        draw_text_(_xl,_yt1, _text, _font, _pi);
	    }

	    if (_enum == ChatX_cursor)
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
	    _text = ChatX_dg[#ChatX_cursor,2];
	    if (is_string(_text))
	    {
	        _xl = TextArea1_xl;
	        _yt = _yt1;
	        pal_swap_set(global.palette_image, PI_MENU1);
	        draw_text_plus(_xl,Info_xr, _yt, _text, Info_FONT);
	        pal_swap_reset();
	    }
	}

}
