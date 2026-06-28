/// @description  OptionsMenu_Draw_InputConfig(YT)
/// @param YT
function OptionsMenu_Draw_InputConfig() {


	var _YT0 = argument[0];

	var _i, _val;
	var _x,_y, _xl,_yt, _xl1,_yt1;
	var _pi;
	var _text, _font, _font_w,_font_h;


	_pi = PI_MENU1;
	_yt1 = drawY+$20;

	// pick the active section's grid/count + draw the section header
	var _dg, _count;
	switch(InputSection){
	case InputSection_KEYBOARD: _dg=dg_KbOptions;        _count=KbOption_COUNT;          break;
	case InputSection_DEBUG:    _dg=dg_DbgOptions;       _count=DbgOption_COUNT;         break;
	default:                    _dg=dg_InputConfigOptions;_count=InputConfigOption_COUNT; break;
	}
	draw_text_(TextArea1_xl, _yt1, "< "+InputSection_NAME[InputSection]+" >", FONT2, PI_MENU1);
	_yt1 += sprite_get_height(FONT2) + $8;

	// vk -> short display name (inline so no new script resource)
	var _vkname = function(_vk) {
	    if (_vk==0) return "---";
	    if ((_vk>=ord("A") && _vk<=ord("Z")) || (_vk>=ord("0") && _vk<=ord("9"))) return chr(_vk);
	    switch(_vk){
	    case vk_space:return "SPACE"; case vk_enter:return "ENTER"; case vk_control:return "CTRL";
	    case vk_shift:return "SHIFT"; case vk_alt:return "ALT"; case vk_tab:return "TAB";
	    case vk_up:return "UP"; case vk_down:return "DOWN"; case vk_left:return "LEFT"; case vk_right:return "RIGHT";
	    case vk_escape:return "ESC"; case vk_backspace:return "BKSP";
	    case vk_insert:return "INSERT"; case vk_home:return "HOME"; case vk_end:return "END";
	    case vk_pageup:return "PAGEUP"; case vk_pagedown:return "PAGEDOWN"; }
	    return "K"+string(_vk);
	};

	for(_i=0; _i<_count; _i++)
	{
	    _text = _dg[#_i,0];
	    _font = _dg[#_i,1];
	    _font_w = sprite_get_width( _font);
	    _font_h = sprite_get_height(_font);
    
	    _xl = TextArea1_xl;
	    switch(_i){
	    case InputConfigOption_DEFAULT: {_yt1+=$8; break;} // extra pad
	    //case InputConfigOption_BACK:    {_yt1+=$6; break;} // extra pad
	    }
    
	    if (_yt1+_font_h >= MenuWindow_yb)
	    {
	        break;//_i
	    }
    
    
	    _text = _dg[#_i,0];
    
	    if ((InputConfigState==InputConfigState_EDITING || InputConfigState==InputConfigState_KB_EDITING)
	    &&  _i!=InputConfigOption )
	    {
	        _pi = PI_DARK2;
	    }
	    else if (_i==InputConfigOption)
	    {
	        _pi = PI_MENU1;
	    }
	    else
	    {
	        _pi = PI_MENU2;
	    }
	    draw_text_(_xl,_yt1, _text, _font, _pi);
    
    
	    if (InputSection==InputSection_GAMEPLAY && _i<InputConfigOption_CALIBRATE)
	    {
	        if (_font_w<8) _xl = TextArea1_xl + ($10*_font_w);
	        else           _xl = TextArea1_xl + ($0C*_font_w);
        
	        switch(_i){
	        case InputConfigOption_RIGHT: {_val=Input.GP_right;  break;}
	        case InputConfigOption_LEFT:  {_val=Input.GP_left;   break;}
	        case InputConfigOption_DOWN:  {_val=Input.GP_down;   break;}
	        case InputConfigOption_UP:    {_val=Input.GP_up;     break;}
	        case InputConfigOption_MAGIC: {_val=Input.GP_magic;  break;}
	        case InputConfigOption_PAUSE: {_val=Input.GP_pause;  break;}
	        case InputConfigOption_ATTACK:{_val=Input.GP_attack; break;}
	        case InputConfigOption_JUMP:  {_val=Input.GP_jump;   break;}
        case InputConfigOption_SPELL_NEXT:{_val=Input.GP_spell_next; break;}
        case InputConfigOption_SPELL_PREV:{_val=Input.GP_spell_prev; break;}
        case InputConfigOption_JUKEBOX_NEXT:{_val=Input.GP_jukebox_next; break;}
        case InputConfigOption_JUKEBOX_PREV:{_val=Input.GP_jukebox_prev; break;}
	        }
        
	        _text = val(Input.Buttons_dm[?string(_val)+STR_Name], "BUTTON");
	        draw_text_(_xl,_yt1, _text, _font, _pi);
	    }
    
    
    
	    if (InputSection==InputSection_KEYBOARD && _i<KbOption_DEFAULT)
	    {
	        if (_font_w<8) _xl = TextArea1_xl + ($10*_font_w);
	        else           _xl = TextArea1_xl + ($0C*_font_w);
	        var _kv=0, _ka=0;
	        switch(_i){
	        case KbOption_RIGHT: {_kv=Input.Key_right; _ka=Input.Key_right_alt; break;}
	        case KbOption_LEFT:  {_kv=Input.Key_left;  _ka=Input.Key_left_alt;  break;}
	        case KbOption_DOWN:  {_kv=Input.Key_down;  _ka=Input.Key_down_alt;  break;}
	        case KbOption_UP:    {_kv=Input.Key_up;    _ka=Input.Key_up_alt;    break;}
	        case KbOption_MAGIC: {_kv=Input.Key_magic; _ka=Input.Key_magic_alt; break;}
	        case KbOption_PAUSE: {_kv=Input.Key_pause; _ka=Input.Key_pause_alt; break;}
	        case KbOption_ATTACK:{_kv=Input.Key_attack;_ka=Input.Key_attack_alt;break;}
	        case KbOption_JUMP:  {_kv=Input.Key_jump;  _ka=Input.Key_jump_alt;  break;}
	        case KbOption_SPELL_NEXT:{_kv=Input.Key_spell_next; _ka=Input.Key_spell_next_alt; break;}
	        case KbOption_SPELL_PREV:{_kv=Input.Key_spell_prev; _ka=Input.Key_spell_prev_alt; break;}
	        case KbOption_TRACKER_TOGGLE:{_kv=Input.Key_tracker_toggle; _ka=Input.Key_tracker_toggle_alt; break;}
	        case KbOption_JUKEBOX_TOGGLE:{_kv=Input.Key_jukebox_toggle; _ka=Input.Key_jukebox_toggle_alt; break;}
	        case KbOption_JUKEBOX_PREV:  {_kv=Input.Key_jukebox_prev;   _ka=Input.Key_jukebox_prev_alt;   break;}
	        case KbOption_JUKEBOX_NEXT:  {_kv=Input.Key_jukebox_next;   _ka=Input.Key_jukebox_next_alt;   break;}
	        case KbOption_JUKEBOX_ASSIGN:{_kv=Input.Key_jukebox_assign; _ka=Input.Key_jukebox_assign_alt; break;}
	        }
	        _text = _vkname(_kv);
	        if (_ka!=0) _text += " /"+_vkname(_ka);
	        if (InputConfigState==InputConfigState_KB_EDITING && _i==InputConfigOption) _text = "PRESS A KEY";
	        draw_text_(_xl,_yt1, _text, _font, _pi);
	    }

	    if (_i==InputConfigOption)
	    {
	        _x = Cursor_xl + (Cursor_W>>1);
	        _y = _yt1 + (_font_h>>1); // text yc
	        draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	    }
    
    
	    _yt1 += _font_h;
	    _yt1 += _font_h; // extra pad
	}


	// ------------------------------------------------------------------
	// Calibration-wizard overlay: current prompt + progress, or last result.
	if (InputConfigState == InputConfigState_CALIBRATE)
	{
	    var _cf = FONT1;
	    var _cfh = sprite_get_height(_cf);
	    var _cy = drawY + $10;
	    var _step  = clamp(Calib_step, 0, Calib_COUNT-1);
	    var _prompt = string(Calib_dg[#1,_step]);

	    draw_text_(TextArea1_xl, _cy, "CALIBRATE: "+string(Calib_step+1)+"/"+string(Calib_COUNT), _cf, PI_MENU1);
	    _cy += _cfh + $4;
	    draw_text_(TextArea1_xl, _cy, _prompt, _cf, PI_MENU1);
	    _cy += _cfh + $8;
	    draw_text_(TextArea1_xl, _cy, "SPACE = SKIP    ESC = CANCEL", FONT2, PI_MENU2);
	}
	else if (Calib_msg != "")
	{
	    draw_text_(TextArea1_xl, drawY + $10, Calib_msg, FONT2, PI_MENU1);
	}







}
