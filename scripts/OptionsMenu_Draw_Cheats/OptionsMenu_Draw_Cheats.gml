/// @description  OptionsMenu_Draw_Cheats(YT)
/// @param YT
function OptionsMenu_Draw_Cheats() {

	// DEV TOOLS sub-folder draw: flat list with a right-column state read from the
	// SAME global each cheat toggles (mirrors OptionsMenu_Draw_Display).

	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $4;
	var _pi;
	var _text, _font, _font_w,_font_h;
	var _enum;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max, _vis_rows;

	var _dg_state_text = ds_grid_create(3,2);
	    _dg_state_text[#0,0] = "OFF";  _dg_state_text[#0,1] = "ON";
	    _dg_state_text[#1,0] = "HIDE"; _dg_state_text[#1,1] = "SHOW";
	    _dg_state_text[#2,0] = "NO";   _dg_state_text[#2,1] = "YES";


	_font   = Cheats_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt;
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	_vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;


	_vis_N = 0;
	var _vis_enum = array_create(Cheats.COUNT, 0);
	for (_i = 0; _i < Cheats.COUNT; _i++)
	{
	    if (OptionsMenu_option_is_avail(menu_state_CHEATS, _i)) { _vis_enum[_vis_N] = _i; _vis_N++; }
	}


	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++) { if (_vis_enum[_i] == Cheats_cursor) { _cursor_vis_pos = _i; break; } }

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
	    _text = Cheats_dg[#_enum,0];

	    if (_enum==Cheats_cursor) _pi = PI_MENU1;
	    else                      _pi = PI_MENU2;
	    _xl = TextArea1_xl;
	    draw_text_(_xl,_yt1, _text, _font, _pi);


	    _text = 0;
	    switch(_enum){
	    case Cheats.ADD_ITEMS: {_text=_dg_state_text[#0,sign(g.use_StabToCheat)]; break;}
	    case Cheats.PC_DASH:   {_text=_dg_state_text[#0,sign(g.DevDash_state)]; break;} // 0: Off, 1: On, 2: On and dash input held
	    case Cheats.INF_HP:    {_text=_dg_state_text[#1,sign(g.cheat_inf_hp)]; break;}
	    case Cheats.INF_MP:    {_text=_dg_state_text[#1,sign(g.cheat_inf_mp)]; break;}
	    case Cheats.INF_LIVES: {_text=_dg_state_text[#1,sign(g.cheat_inf_lives)]; break;}
	    case Cheats.INVULN:    {_text=_dg_state_text[#1,sign(g.cheat_invuln)]; break;}
	    }//switch(_enum)

	    if (_text != 0)
	    {
	        _xl  = TextArea2_xr;
	        _xl -= string_length(_text) * _font_w;
	        if (_enum == Cheats_cursor)
	        {
	            _pi = PI_MENU1;
	        }
	        else
	        {
	            if (_text==_dg_state_text[#0,0]
	            ||  _text==_dg_state_text[#1,0]
	            ||  _text==_dg_state_text[#2,0])
	            {
	                _pi = PI_DARK1;
	            }
	            else
	            {
	                _pi = PI_MENU2;
	            }
	        }
	        draw_text_(_xl,_yt1, _text, _font, _pi);
	    }


	    if (_enum == Cheats_cursor)
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
	    _text = Cheats_dg[#Cheats_cursor,2];
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
