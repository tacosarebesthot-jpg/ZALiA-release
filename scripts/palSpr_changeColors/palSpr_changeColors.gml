/// @description  palSpr_changeColors()
function palSpr_changeColors() {


	if (is_undefined(pal_rm_def)) exit; // !!!!!!!!!!!!!!!!!!!!!!!!

	if (pal_rm_new==pal_rm_curr)
	{
	    if(!global.palette_image_IS_SURFACE 
	    ||  surface_exists(global.palette_image) )
	    {
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}



	// -----------------------------------------------------------------------------
	// -----------------------------------------------------------------------------
	var _i,_j, _idx, _val;
	var _color;


	if (is_undefined(pal_rm_new) 
	||  pal_rm_new=="" )
	{
	    pal_rm_new = pal_rm_DEFAULT;
	}


	pal_rm_curr = pal_rm_new;


	var _W = string_length(pal_rm_curr) div global.PAL_CHAR_PER_PAL;
	var _SURF = surface_create(_W,global.COLORS_PER_PALETTE);
	surface_set_target(_SURF);
	draw_clear_alpha(c_black,0);

	for(_i=0; _i<_W; _i++) // each palette index
	{
	    for(_j=0; _j<global.COLORS_PER_PALETTE; _j++) // each color of this palette index
	    {
	        _idx  =  global.COLORS_PER_PALETTE*_i;
	        _idx += _j; // pal-colors index
	        _idx *=  global.PAL_CHAR_PER_COLOR;
        
	        _val = string_copy(pal_rm_curr, _idx+1, global.PAL_CHAR_PER_COLOR);
	        _val = str_hex(_val);
        
	        _color = _val;
        
	        // drawing top to bottom vs left to right
	        draw_point_colour(_i,_j, _color);
	    }
	}


	if (global.palette_image_IS_SURFACE)
	{
	    if (surface_exists(global.palette_image))
	    {   surface_free(  global.palette_image);  }
    
	    global.palette_image   = surface_create(_W,global.COLORS_PER_PALETTE);
	    surface_copy(global.palette_image, 0,0, _SURF);
	    global.palette_image_w = surface_get_width( global.palette_image);
	    global.palette_image_h = surface_get_height(global.palette_image);
    
	}
	else
	{
	    if (sprite_exists(global.palette_image)) 
	    {   sprite_delete(global.palette_image);  }
    
	    global.palette_image   = sprite_create_from_surface(_SURF, 0,0, _W,global.COLORS_PER_PALETTE, 0,0, 0,0);
	    global.palette_image_w = sprite_get_width( global.palette_image);
	    global.palette_image_h = sprite_get_height(global.palette_image);
	}


	surface_reset_target();
	surface_free(_SURF);







}
