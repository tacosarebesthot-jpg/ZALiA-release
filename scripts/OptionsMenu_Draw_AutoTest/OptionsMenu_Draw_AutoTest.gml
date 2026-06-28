/// @description  OptionsMenu_Draw_AutoTest(YT)
/// @param YT
function OptionsMenu_Draw_AutoTest() {


	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _xl1,_yt1;
	var _DIST1 = $4; // line spacing
	var _pi;
	var _text, _font, _font_w,_font_h;
	var _enum;
	var _sec_count;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max;

	var _dg_state_text = ds_grid_create(3,2);
	    _dg_state_text[#0,0] = "OFF";
	    _dg_state_text[#0,1] = "ON";
	//                                          //
	    _dg_state_text[#1,0] = "HIDE";
	    _dg_state_text[#1,1] = "SHOW";
	//                                          //
	    _dg_state_text[#2,0] = "NO";
	    _dg_state_text[#2,1] = "YES";
	//                                          //


	_font   = AutoTest_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt; // cap list above the info divider
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	var _vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;


	// -----------------------------------------------------------------------
	// Build visual items list.
	// _vis_type[i]: 0 = section header, 1 = option row
	// _vis_enum[i]: enum value (for option rows only)
	// _vis_hdr[i]:  header label string (for header rows only)
	// -----------------------------------------------------------------------
	_vis_N = 0;
	var _vis_type = array_create(50, 0);
	var _vis_enum = array_create(50, 0);
	var _vis_hdr  = array_create(50, "");


	// Section: SWEEP TESTS
	_sec_count = 0;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_FULL))        _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_OVERWORLD))   _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_PALACES))     _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_TOWNS))       _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES))       _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_WEST))  _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_EAST))  _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_DTHMT)) _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_MAZIS)) _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_OTHER))       _sec_count++;
	if (_sec_count > 0)
	{
	    _vis_type[_vis_N] = 0;
	    _vis_hdr[ _vis_N] = "- SWEEP TESTS -";
	    _vis_N++;
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_FULL))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_FULL; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_OVERWORLD))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_OVERWORLD; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_PALACES))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_PALACES; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_TOWNS))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_TOWNS; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_CAVES; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_WEST))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_CAVES_WEST; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_EAST))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_CAVES_EAST; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_DTHMT))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_CAVES_DTHMT; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_CAVES_MAZIS))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_CAVES_MAZIS; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.SW_OTHER))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.SW_OTHER; _vis_N++; }
	}


	// Section: TEST / CAPTURE (toggles moved from DEV TOOLS)
	_sec_count = 0;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.BUGPROBE))      _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.TAS_RECORD))    _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.TAS_PLAYBACK))  _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.INPUT_DISPLAY)) _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.PLAYLOG))       _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.WALKTUNE))      _sec_count++;
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.GP_DIAG))       _sec_count++;
	if (_sec_count > 0)
	{
	    _vis_type[_vis_N] = 0;
	    _vis_hdr[ _vis_N] = "- TEST / CAPTURE -";
	    _vis_N++;
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.BUGPROBE))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.BUGPROBE; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.TAS_RECORD))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.TAS_RECORD; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.TAS_PLAYBACK))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.TAS_PLAYBACK; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.INPUT_DISPLAY))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.INPUT_DISPLAY; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.PLAYLOG))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.PLAYLOG; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.WALKTUNE))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.WALKTUNE; _vis_N++; }
	    if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.GP_DIAG))
	    { _vis_type[_vis_N]=1; _vis_enum[_vis_N]=AutoTest.GP_DIAG; _vis_N++; }
	}


	// BACK — no header, normal selectable option at end
	if (OptionsMenu_option_is_avail(menu_state_AUTO_TEST, AutoTest.BACK))
	{
	    _vis_type[_vis_N] = 1;
	    _vis_enum[_vis_N] = AutoTest.BACK;
	    _vis_N++;
	}


	// -----------------------------------------------------------------------
	// Find the visual position of the currently selected cursor row
	// -----------------------------------------------------------------------
	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++)
	{
	    if (_vis_type[_i] == 1 && _vis_enum[_i] == AutoTest_cursor)
	    {
	        _cursor_vis_pos = _i;
	        break;//_i
	    }
	}

	_top_max   = max(0, _vis_N - _vis_rows);
	_top_index = _cursor_vis_pos - (_vis_rows >> 1);
	if (_top_index < 0)        _top_index = 0;
	if (_top_index > _top_max) _top_index = _top_max;


	// -----------------------------------------------------------------------
	// Draw visible rows
	// -----------------------------------------------------------------------
	_draw_end = _top_index + _vis_rows;
	if (_draw_end > _vis_N) _draw_end = _vis_N;

	for (_i = _top_index; _i < _draw_end; _i++)
	{
	    _yt1 = _ScrollArea_YT + (_i - _top_index) * _ROW_H;

	    if (_vis_type[_i] == 0)
	    {
	        // Section header — draw with dim palette, no cursor, no state text
	        _xl = TextArea1_xl;
	        draw_text_(_xl, _yt1, _vis_hdr[_i], _font, PI_DARK1);
	    }
	    else
	    {
	        // Option row
	        _enum = _vis_enum[_i];
	        _text = AutoTest_dg[#_enum,0];

	        if (_enum==AutoTest_cursor) _pi = PI_MENU1;
	        else                        _pi = PI_MENU2;
	        _xl = TextArea1_xl;
	        draw_text_(_xl,_yt1, _text, _font, _pi);


	        _text = 0;
	        switch(_enum){
	        case AutoTest.BUGPROBE:         {_text=_dg_state_text[#0,sign(global.bugprobe)]; break;}
	        case AutoTest.TAS_RECORD:       {_text=_dg_state_text[#0,sign(global.tas_rec_state)]; break;}
	        case AutoTest.TAS_PLAYBACK:     {_text=_dg_state_text[#0,sign(global.tas_pb_state)]; break;}
	        case AutoTest.INPUT_DISPLAY:    {_text=_dg_state_text[#1,sign(global.tas_overlay_on)]; break;}
	        case AutoTest.PLAYLOG:          {_text=_dg_state_text[#0,sign(global.playlog_active)]; break;}
	        case AutoTest.WALKTUNE:         {_text=_dg_state_text[#1,sign(global.walktune_on)]; break;}
	        case AutoTest.GP_DIAG:          {_text=_dg_state_text[#1,sign(global.gp_diag_on)]; break;}
	        // SWEEP STARTER rows are actions (no on/off state) -> no right-column text.
	        }//switch(_enum)

	        if (_text != 0)
	        {
	            _xl  = TextArea2_xr;
	            _xl -= string_length(_text) * _font_w;
	            if (_enum == AutoTest_cursor)
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


	        if (_enum == AutoTest_cursor)
	        {
	            _x = Cursor_xl + (Cursor_W>>1);
	            _y = _yt1 + (_font_h>>1); // text yc
	            draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	        }
	    }
	}


	// OPTION INFO -----------------------------------------------------------
	_yt1 = Info_yt;
	if (_yt1+Info_FONT_H < MenuWindow_yb)
	{
	    _text = AutoTest_dg[#AutoTest_cursor,2];
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
