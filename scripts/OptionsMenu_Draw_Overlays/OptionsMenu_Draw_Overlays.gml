/// @description  OptionsMenu_Draw_Overlays(YT)
/// @param YT
function OptionsMenu_Draw_Overlays() {

	// DEV TOOLS sub-folder draw: flat list (mirrors OptionsMenu_Draw_Display) with a
	// right-column ON/OFF state read from the SAME global each row toggles.

	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $4; // line spacing
	var _pi;
	var _text, _font, _font_w,_font_h;
	var _enum;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max, _vis_rows;

	var _dg_state_text = ds_grid_create(3,2);
	    _dg_state_text[#0,0] = "OFF";  _dg_state_text[#0,1] = "ON";
	    _dg_state_text[#1,0] = "HIDE"; _dg_state_text[#1,1] = "SHOW";
	    _dg_state_text[#2,0] = "NO";   _dg_state_text[#2,1] = "YES";


	_font   = Overlays_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt; // cap list above the info divider
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	_vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;


	_vis_N = 0;
	var _vis_enum = array_create(Overlays.COUNT, 0);
	for (_i = 0; _i < Overlays.COUNT; _i++)
	{
	    if (OptionsMenu_option_is_avail(menu_state_OVERLAYS, _i)) { _vis_enum[_vis_N] = _i; _vis_N++; }
	}


	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++) { if (_vis_enum[_i] == Overlays_cursor) { _cursor_vis_pos = _i; break; } }

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
	    _text = Overlays_dg[#_enum,0];

	    if (_enum==Overlays_cursor) _pi = PI_MENU1;
	    else                        _pi = PI_MENU2;
	    _xl = TextArea1_xl;
	    draw_text_(_xl,_yt1, _text, _font, _pi);


	    _text = 0;
	    switch(_enum){
	    case Overlays.HITBOXES:       {_text=_dg_state_text[#1,sign(g.can_draw_hb)]; break;}
	    case Overlays.SCP:            {_text=_dg_state_text[#1,sign(g.can_draw_cs)]; break;}
	    case Overlays.XY:             {_text=_dg_state_text[#1,sign(g.canDraw_ogXY)]; break;}
	    case Overlays.OG_CAM:         {_text=_dg_state_text[#1,sign(g.can_draw_og_cam_outline)]; break;}
	    case Overlays.HP:             {_text=_dg_state_text[#1,sign(g.can_draw_hp)]; break;}
	    case Overlays.SPRITE_OUTLINE: {_text=string(g.canDrawSprOutline); break;}
	    case Overlays.FRAME_COUNT:    {_text=_dg_state_text[#1,sign(global.App_frame_count_can_draw)]; break;}
	    case Overlays.DEPTH_DEBUG:    {_text=_dg_state_text[#1,sign(global.dbg_depth_show)]; break;}
	    case Overlays.DEATH_COUNTER:  {_text=_dg_state_text[#1,sign(global.dbg_death_counter_show)]; break;}
	    case Overlays.EXITS:          {_text=_dg_state_text[#1,sign(g.can_draw_Exit_hb)]; break;}
	    case Overlays.SOLID_TILES:    {_text=_dg_state_text[#1,sign(g.can_show_t_solid)]; break;}
	    case Overlays.UNIQUE_TILES:   {_text=_dg_state_text[#1,sign(g.can_show_t_unique)]; break;}
	    case Overlays.DUNGEON_MAP:    {_text=_dg_state_text[#2,sign(g.dev_DungeonMapShowAll)]; break;}
	    case Overlays.INPUT_DISPLAY:  {_text=_dg_state_text[#1,sign(global.tas_overlay_on)]; break;}
	    }//switch(_enum)

	    if (_text != 0)
	    {
	        _xl  = TextArea2_xr;
	        _xl -= string_length(_text) * _font_w;
	        if (_enum == Overlays_cursor)
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


	    if (_enum == Overlays_cursor)
	    {
	        _x = Cursor_xl + (Cursor_W>>1);
	        _y = _yt1 + (_font_h>>1); // text yc
	        draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	    }
	}


	// OPTION INFO -----------------------------------------------------------
	_yt1 = Info_yt;
	if (_yt1+Info_FONT_H < MenuWindow_yb)
	{
	    _text = Overlays_dg[#Overlays_cursor,2];
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
