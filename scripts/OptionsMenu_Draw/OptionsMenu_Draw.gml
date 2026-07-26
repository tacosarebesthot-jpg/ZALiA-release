/// @description  OptionsMenu_Draw()
function OptionsMenu_Draw() {


	if(!draw_rows_count) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// ----------------------------------------------------------------------------------
	var _i,_j, _x,_y;
	var _tsrc, _ts_x,_ts_y;
	var _text, _font, _font_w,_font_h;




	// ----------------------------------------------------------------------------------
	// Draw menu background
	switch(3)
	{
	    default:{ // Draw menu background solid black
	    draw_sprite_(spr_1x1_WHT,0, drawX,drawY, -1, MenuWindow_w,MenuWindow_h, c_black);
	    break;}//default
    
	    case 2:{ // Draw menu background with a texture to give a backdrop/contrast for pc skins using a lot of black
	    for(_i=0; _i<draw_rows_count; _i++) // each row
	    {
	        for(_j=draw_clms_count-1; _j>=0; _j--) // 8x8. each column of the row
	        {
	            _ts_x = $D<<3;
	            _ts_y = $F<<3;
	            _x    = drawX+(_j<<3);
	            _y    = drawY+(_i<<3);
	            draw_background_part(g.TS_MENU, _ts_x,_ts_y, 8,8, _x,_y);
	        }
	    }
	    break;}//case 2
    
	    case 3:{
	    var _PAD = 2;
	    draw_sprite_(spr_1x1_WHT,0, drawX+_PAD,drawY+_PAD, -1, MenuWindow_w-(_PAD<<1),MenuWindow_h-(_PAD<<1), c_black, 0.90);
	    break;}
	}//switch(background appearance)


	// Draw menu frame
	pal_swap_set(global.palette_image, PI_MENU1);
	for(_i=0; _i<draw_rows_count; _i++) // each row
	{
	    for(_j=draw_clms_count-1; _j>=0; _j--) // 8x8. each column of the row
	    {
	        _tsrc = -1;
        
	        if (Info_Divider_can_draw 
	        &&  Info_Divider_row==_i 
	        &&  _j>0 
	        &&  _j<draw_clms_count-1 )
	        {
	            _tsrc = g.dl_MenuFrame_TSRC[|0]; // 0: horizontal bar
	        }
	        else
	        {
	            if (_i==0 
	            ||  _i==draw_rows_max-1 
	            ||  _j==0 
	            ||  _j==draw_clms_count-1 )
	            //||  _j==draw_clms_max-1 )
	            {
	                     if (_i>0 && _i<draw_rows_max-1)   _tsrc = g.dl_MenuFrame_TSRC[|1]; // 1: vertical bar
	                else if (_j>0 && _j<draw_clms_count-1) _tsrc = g.dl_MenuFrame_TSRC[|0]; // 0: horizontal bar
	                else                                   _tsrc = g.dl_MenuFrame_TSRC[|2]; // 2: corner
	            }
	        }
        
	        if (_tsrc!=-1)
	        {
	            _ts_x = ((_tsrc>>0)&$F) <<3;
	            _ts_y = ((_tsrc>>4)&$F) <<3;
	            _x    = drawX+(_j<<3);
	            _y    = drawY+(_i<<3);
	            draw_background_part(g.TS_MENU, _ts_x,_ts_y, 8,8, _x,_y);
	        }
	    }
	}
	pal_swap_reset();








	// ----------------------------------------------------------------------------------
	//_font = spr_Font3_1; // Testing fonts
	_font   = FONT1;
	_font_w = sprite_get_width( _font);
	_font_h = sprite_get_height(_font);

	_y = drawY + (YOFF_HEAD*_font_h);

	pal_swap_set(global.palette_image, PI_MENU1);
	if (_y+_font_h<MenuWindow_yb-$8)
	{
	    switch(menu_state){
	    default:                        {_text="OPTIONS"; break;}
	    case   menu_state_INPUT_CONFIG: {_text=MainOptions_dg[#MainOption_INPUT_CONFIG,0]; break;}
	    case   menu_state_AUDIO_CUSTOM: {_text="CUSTOMIZE RANDOM AUDIO"; break;}
	    case   menu_state_DEV_TOOLS:    {_text=MainOptions_dg[#MainOption_DEV_TOOLS,0]; break;}
	    case   menu_state_OVERLAYS:     {_text="OVERLAYS"; break;}
	    case   menu_state_CHEATS:       {_text="CHEATS"; break;}
	    case   menu_state_TWITCH:       {_text="TWITCH"; break;}
	    case   menu_state_COLOR:        {_text="COLOR"; break;}
	    case   menu_state_TEST_CAP:     {_text="TEST / CAPTURE"; break;}
	    case   menu_state_SWEEPS:       {_text="SWEEPS"; break;}
	    case   menu_state_MISC:         {_text="MISC"; break;}
	    case   menu_state_AUTO_TEST:    {_text="AUTOMATED TEST"; break;} // ORPHANED (unreachable)
	    case   menu_state_DISPLAY:      {_text=MainOptions_dg[#MainOption_DISPLAY,0]; break;}
	    case   menu_state_RANDO:        {_text="RANDO OPTIONS"; break;} // pad
	    case   menu_state_OTHER:        {_text="OTHER"; break;}
	    }
	    _text = "-"+_text+"-";
	    _x  = drawX+(MenuWindow_w>>1); // window xc
	    _x -= (string_length(_text)*_font_w)>>1;
	    draw_text_(_x,_y, _text, _font);
	}
	pal_swap_reset();

	_y += _font_h; // bottom of head








	// ----------------------------------------------------------------------------------
	switch(menu_state){
	case   menu_state_MAIN:         {OptionsMenu_Draw_Main(_y+6);         break;}//case Menu_MAIN
	case   menu_state_AUDIO_CUSTOM: {OptionsMenu_Draw_AudioCustom(_y+8);  break;}//case Menu_AUDIO_CUSTOM
	case   menu_state_INPUT_CONFIG: {OptionsMenu_Draw_InputConfig(_y+8);  break;}//case menu_state_INPUT_CONFIG
	case   menu_state_DEV_TOOLS:    {OptionsMenu_Draw_DevTools(_y+4);     break;}//case Menu_DEV_TOOLS (launcher)
	case   menu_state_OVERLAYS:     {OptionsMenu_Draw_Overlays(_y+4);     break;}//DEV TOOLS sub-folder
	case   menu_state_CHEATS:       {OptionsMenu_Draw_Cheats(_y+4);       break;}//DEV TOOLS sub-folder
	case   menu_state_TWITCH:       {OptionsMenu_Draw_Twitch(_y+4);       break;}//player-facing
	case   menu_state_COLOR:        {OptionsMenu_Draw_Color(_y+4);        break;}//DEV TOOLS sub-folder
	case   menu_state_TEST_CAP:     {OptionsMenu_Draw_TestCap(_y+4);      break;}//DEV TOOLS sub-folder
	case   menu_state_SWEEPS:       {OptionsMenu_Draw_Sweeps(_y+4);       break;}//DEV TOOLS sub-folder
	case   menu_state_MISC:         {OptionsMenu_Draw_Misc(_y+4);         break;}//DEV TOOLS sub-folder
	case   menu_state_AUTO_TEST:    {OptionsMenu_Draw_AutoTest(_y+4);     break;}//case menu_state_AUTO_TEST (ORPHANED, unreachable)
	case   menu_state_DISPLAY:      {OptionsMenu_Draw_Display(_y+4);      break;}//case menu_state_DISPLAY
	case   menu_state_RANDO:        {OptionsMenu_Draw_RandoOptions(_y+4); break;}//case Menu_RANDO_OPTIONS
	case   menu_state_OTHER:        {OptionsMenu_Draw_Other(_y+4);        break;}//case menu_state_OTHER
	}//switch(menu_state)




	// ----------------------------------------------------------------------------------
	draw_rows_count = 0;







}
