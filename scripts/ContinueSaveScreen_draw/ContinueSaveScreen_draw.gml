/// @description  ContinueSaveScreen_draw()
function ContinueSaveScreen_draw() {


	set_background_color(p.C_BLK1);


	if (state==state_DELAY1) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// -------------------------------------------------------------------------------
	var _i, _text, _xl,_yt;
	var _pi = global.PI_GUI1;


	if(!surface_exists(Caution_srf))
	{
	    var _j, _tsrc, _ts_x,_ts_y;
	    var _CLMS1 = Caution_W>>3;
	    var _ROWS1 = Caution_H>>3;
	    Caution_srf = surface_create(Caution_W,Caution_H);
	    surface_set_target(Caution_srf);
	    draw_clear_alpha(c_black,0);
	    for(_i=0; _i<_ROWS1; _i++)
	    {
	        for(_j=0; _j<_CLMS1; _j++)
	        {
	            if (_j==0 
	            ||  _j==_CLMS1-1 
	            ||  _i==0 
	            ||  _i==_ROWS1-1 )
	            {
	                _xl = _j<<3;
	                _yt = _i<<3;
                
	                if ((_j==0 || _j==_CLMS1-1) 
	                &&  (_i==0 || _i==_ROWS1-1) )
	                {    _tsrc = $22;  } // Corner
	                else if (_j==0 || _j==_CLMS1-1)
	                {    _tsrc = $21;  } // Vertical
	                else _tsrc = $20;    // Horizontal
                
	                _ts_x = ((_tsrc>>0)&$F)<<3;
	                _ts_y = ((_tsrc>>4)&$F)<<3;
	                draw_background_part(ts_Menu01, _ts_x,_ts_y, 8,8, _xl,_yt);
	            }
	        }
	    }
    
	    var _XL1 = PAD1;
	    var _YT1 = PAD1;
	    for(_i=ds_list_size(Caution_dl_text)-1; _i>=0; _i--)
	    {
	        _yt = _YT1 + (PAD1*_i);
	        draw_text_(_XL1,_yt, Caution_dl_text[|_i], -1, 0);
	    }
	    surface_reset_target();
	}

	if (surface_exists(Caution_srf))
	{
	    pal_swap_set(global.palette_image, global.PI_BGR1);
	    draw_surface(Caution_srf, Caution_XL,Caution_YT);
	    pal_swap_reset();
	}




	// -------------------------------------------------------------------------------
	if (state==state_SELECTED 
	&&  Options_idx==Option_SAVE 
	&&  SaveFlash_count<=SaveFlash_LIMIT 
	&&  counter&$4 )
	{    _pi = global.PI_BGR1;  }
	else _pi = global.PI_GUI1;
	Options_dg[#Option_SAVE,3] = _pi;

	for(_i=0; _i<Options_COUNT; _i++)
	{
	    _text = Options_dg[#_i,0];
	    _xl   = Options_dg[#_i,1];
	    _yt   = Options_dg[#_i,2];
	    _pi   = Options_dg[#_i,3];
	    draw_text_(_xl,_yt, _text,-1, _pi);
	}




	// -------------------------------------------------------------------------------
	draw_sprite_(Cursor_SPRITE,0, Cursor_XC, Cursor_YC+(Options_idx*PAD1), global.PI_GUI1);







}
