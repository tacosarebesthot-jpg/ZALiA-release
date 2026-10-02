/// @description  OptionsMenu_Draw_Other(YT)
/// @param YT
function OptionsMenu_Draw_Other() {


	var _YT0 = argument[0];

	var _i, _count;
	var _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $6; // line spacing
	var _dk, _pi;
	var _text, _font, _font_w,_font_h;
	var _STR_UNDEFINED = "UNDEFINED";
	var _DK0 = "Other";


	_yt1  = _YT0;
	_yt1 += _DIST1; // line spacing

	_font   = FONT2;
	_font_w = sprite_get_width( _font);
	_font_h = sprite_get_height(_font);




	var          _COUNT0 = val(dm_options[?_DK0+STR_Count]);

	// SCROLL (2026-10-01). This page had no scrolling and its rows ran on to MenuWindow_yb,
	// the window's bottom edge, straight through the description panel: once DEATH COUNTER
	// and RESET ALL SETTINGS were added, BACK printed on top of the description text. Same
	// windowing as the TWITCH page: only the rows that fit above the divider, centred on the
	// cursor. With room to spare nothing moves and BACK keeps its extra gap.
	var _ROW_H     = _font_h + _DIST1;
	var _area_h    = Info_Divider_yt - _yt1;
	var _area_rows = max(1, _area_h div _ROW_H);
	var _vis_N = 0, _cursor_pos = 0;
	for(_i=0; _i<_COUNT0; _i++)
	{
	    if(!OptionsMenu_option_is_avail(menu_state_OTHER,_i)) continue;//_i
	    if (_i==Other_cursor) _cursor_pos = _vis_N;
	    _vis_N++;
	}
	var _back_gap  = (_vis_N*_ROW_H + $6 <= _area_h) ? $6 : 0;
	var _top_index = (_vis_N>_area_rows) ? clamp(_cursor_pos - (_area_rows>>1), 0, _vis_N-_area_rows) : 0;
	var _vis_idx   = -1;

	for(_i=0; _i<_COUNT0; _i++)
	{
	    if(!OptionsMenu_option_is_avail(menu_state_OTHER,_i))
	    {
	        continue;//_i
	    }

	    _vis_idx++;
	    if (_vis_idx <  _top_index)            continue;//_i
	    if (_vis_idx >= _top_index+_area_rows) break;//_i


	    switch(_i){
	    case Other_BACK:{_yt1+=_back_gap; break;} // extra spacing
	    }
    
    
	    if (_yt1+_font_h>=MenuWindow_yb)
	    {
	        break;//_i
	    }
    
    
	    _font = FONT2;
	    _font_w = sprite_get_width( _font);
	    _font_h = sprite_get_height(_font);
    
	    _text = val(dm_options[?_DK0+hex_str(_i)+STR_Option+STR_Text]);
	    _xl = TextArea1_xl;
	    _yt = _yt1;
	    if (_i==Other_cursor) _pi = PI_MENU1;
	    else                  _pi = PI_MENU2;
	    draw_text_(_xl,_yt, _text, _font, _pi);
    
    
	    _pi = PI_MENU1;
	    _text = 0;
	    _dk = _DK0+hex_str(_i)+STR_State;
	    switch(_i)
	    {   // --------------------------------------------------------------------
	        case Other_FLASHING:{
	        _xl  = drawX + MenuWindow_w; // window xr
	        _xl -= 8; // window border
	        _xl -= 4; // pad
        
	        if(!p.BackgroundFlash_setting)
	        {
	            //_text = "NO FLASH";
	            //_text = "NO COLOR";
	            _text = "NONE";
	            //_text = "OFF";
	            _xl -= string_length(_text) * _font_w;
	            _yt  = _yt1;       // text yt
	            draw_text_(_xl,_yt, _text, _font, PI_MENU1);
	        }
	        else
	        {
	            _xl -= BackgroundFlash_W;
            
	            _yt  = _yt1;       // text yt
	            _yt += _font_h>>1; // text yc
	            _yt -= BackgroundFlash_H>>1; // color box yt
	            if (p.BackgroundFlash_setting==1) _color = p.dg_color_seq[#0,g.counter0&$3];
	            else                              _color = p.dl_BackgroundFlash_COLORS[|p.BackgroundFlash_setting];
	            draw_sprite_(spr_1x1_WHT,0, _xl,_yt, -1, BackgroundFlash_W,BackgroundFlash_H, _color);
	        }
	        break;}//case Other_FLASHING
        
	        // --------------------------------------------------------------------
	        case Other_DIALOGUE_SPEED:{
	        _text = string(g.mod_DLG_SPEED+1);
	        if (_i==Other_cursor) _pi = PI_MENU1;
	        else                  _pi = PI_MENU2;
	        break;}//case Other_DIALOGUE_SPEED
        
	        // --------------------------------------------------------------------
	        case Other_GAME_FONT:{
	        _text = "FONT " + string(global.game_font_idx) + " EXAMPLE TEXT";
	        _font = global.dl_game_font[|global.game_font_idx];
	        _font_w = sprite_get_width( _font);
	        //_font_h = sprite_get_height(_font);
	        if (_i==Other_cursor) _pi = PI_MENU1;
	        else                  _pi = PI_MENU2;
	        break;}//case Other_GAME_FONT
        
	        // --------------------------------------------------------------------
	        case Other_HIDDEN_OW_EXITS:{
	        _text = val(dm_options[?_dk+hex_str(g.HiddenExitIndicator_enabled)+STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)              _pi = PI_MENU1;
	        else if(!g.HiddenExitIndicator_enabled) _pi = PI_DARK1;
	        else                                    _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_HUD:{
	        _text = val(dm_options[?_dk+hex_str(global.HUD_state)           +STR_Text],_STR_UNDEFINED);
	        if (_i==Other_cursor) _pi = PI_MENU1;
	        else                  _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_QUEST_TIMER:{
	        _text = val(dm_options[?_dk+hex_str(global.QuestTimer_show)     +STR_Text],_STR_UNDEFINED);
	        if (_i==Other_cursor) _pi = PI_MENU1;
	        else                  _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_TORCH_LIGHTING:{
	        _text = val(dm_options[?_dk+hex_str(g.torch_lighting_method)    +STR_Text],_STR_UNDEFINED);
	        if (_i==Other_cursor) _pi = PI_MENU1;
	        else                  _pi = PI_MENU2;
	        break;}
	        /*
	        // --------------------------------------------------------------------
	        case Other_RENDER_DELAY:{
	        _text = val(dm_options[?_dk+hex_str(global.RenderFrameDelay_state)+STR_Text],_STR_UNDEFINED);
	        if(!global.RenderFrameDelay_state) _pi = PI_DARK1;
	        else if (_i==Other_cursor)         _pi = PI_MENU1;
	        else                               _pi = PI_MENU2;
	        break;}
	        */
	        // --------------------------------------------------------------------
	        case Other_SCREEN_SHAKE:{
	        _text = val(dm_options[?_dk+hex_str(g.ScreenShake_user_pref)    +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)        _pi = PI_MENU1;
	        else if(!g.ScreenShake_user_pref) _pi = PI_DARK1;
	        else                              _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_BLACK_BGR:{
	        _text = val(dm_options[?_dk+hex_str(g.all_bg_black_only)        +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)    _pi = PI_MENU1;
	        else if(!g.all_bg_black_only) _pi = PI_DARK1;
	        else                          _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_STAB_FRENZY:{
	        _text = val(dm_options[?_dk+hex_str(g.mod_StabFrenzy)           +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor) _pi = PI_MENU1;
	        else if(!g.mod_StabFrenzy) _pi = PI_DARK1;
	        else                       _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_ANARKHYA_OW:{
	        _text = val(dm_options[?_dk+hex_str(g.anarkhyaOverworld_enabled)+STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)            _pi = PI_MENU1;
	        else if(!g.anarkhyaOverworld_enabled) _pi = PI_DARK1;
	        else                                  _pi = PI_MENU2;
	        break;}
        
	        // --------------------------------------------------------------------
	        case Other_HP_BEEP:{
	        _text = val(dm_options[?_dk+hex_str(global.LowHPBeep_disabled)    +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)           _pi = PI_MENU1;
	        else if( global.LowHPBeep_disabled)  _pi = PI_DARK1;
	        else                                 _pi = PI_MENU2;
	        break;}

	        // --------------------------------------------------------------------
	        case Other_HALLOWEEN1:{
	        _text = val(dm_options[?_dk+hex_str(global.Halloween1_enabled)  +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)          _pi = PI_MENU1;
	        else if(!global.Halloween1_enabled) _pi = PI_DARK1;
	        else                                _pi = PI_MENU2;
	        break;}

	        /*
	        // --------------------------------------------------------------------
	        case Other_CHRISTMAS1:{
	        _text = val(dm_options[?_dk+hex_str(global.Christmas_enabled)   +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)         _pi = PI_MENU1;
	        else if(!global.Christmas_enabled) _pi = PI_DARK1;
	        else                               _pi = PI_MENU2;
	        break;}
	        */

	        // --------------------------------------------------------------------
	        case Other_DEATH_COUNTER:{
	        _text = val(dm_options[?_dk+hex_str(global.dbg_death_counter_show)+STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)               _pi = PI_MENU1;
	        else if(!global.dbg_death_counter_show) _pi = PI_DARK1;
	        else                                    _pi = PI_MENU2;
	        break;}
	        // --------------------------------------------------------------------
	        case Other_RESET:{
	        if (Other_reset_armed) { _text = "PRESS AGAIN?"; _pi = PI_MENU1; }
	        break;}
	        // --------------------------------------------------------------------
	        case Other_DOUBLE_JUMP:{
	        _text = val(dm_options[?_dk+hex_str(g.DoubleJump_state)+STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)   _pi = PI_MENU1;
	        else if(!g.DoubleJump_state) _pi = PI_DARK1;
	        else                         _pi = PI_MENU2;
	        break;}
	        /*
	        // --------------------------------------------------------------------
	        case Other_SHOW_ACTIVE_SPELLS:{
	        _text = val(dm_options[?_dk+hex_str(g.mod_IndicateSpellActive)  +STR_Text],_STR_UNDEFINED);
	             if (_i==Other_cursor)          _pi = PI_MENU1;
	        else if(!g.mod_IndicateSpellActive) _pi = PI_DARK1;
	        else                                _pi = PI_MENU2;
	        break;}
	        */
	    }//switch(_i)
    
	    if (_text!=0)
	    {
	        _xl  = TextArea2_xr;
	        _xl -= string_length(_text) * _font_w;
	        _yt = _yt1;
	        draw_text_(_xl,_yt, _text, _font, _pi);
	    }
    
    
	    if (_i==Other_cursor)
	    {
	        _x = Cursor_xl + (Cursor_W>>1);
	        _y = _yt1 + (_font_h>>1); // text yc
	        draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	    }
    
    
	    _yt1 += _font_h; // text yb
	    _yt1 += _DIST1;  // line spacing
	}








	// OPTION INFO -----------------------------------------------------------
	_yt1 = Info_yt;
	if (_yt1+Info_FONT_H<MenuWindow_yb)
	{
	    _dk = _DK0+hex_str(Other_cursor)+STR_Description;
	    _count = val(dm_options[?_dk+STR_Count]);
	    if (_count)
	    {
	        _xl = TextArea1_xl;
	        _yt = _yt1;
	        pal_swap_set(global.palette_image, PI_MENU1);
	        for(_i=0; _i<_count; _i++)
	        {
	            if (_yt1+Info_FONT_H>=MenuWindow_yb)
	            {
	                break;//_i
	            }
            
	            _text = val(dm_options[?_dk+hex_str(_i)]);
	            if(!is_string(_text))
	            {
	                break;//_i
	            }
            
	            _yt = _yt1;
	            _yt1  = draw_text_plus(_xl,Info_xr, _yt, _text, Info_FONT);
	            _yt1 += Info_PAD1; // line spacing
	        }
	        pal_swap_reset();
	    }
	}








}
