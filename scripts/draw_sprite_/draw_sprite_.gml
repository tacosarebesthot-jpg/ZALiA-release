/// @description  draw_sprite_(sprite, sub image, x, y, *pal index, *xscale, *yscale, *color, *alpha, *rotation)
/// @param sprite
/// @param  sub image
/// @param  x
/// @param  y
/// @param  *pal index
/// @param  *xscale
/// @param  *yscale
/// @param  *color
/// @param  *alpha
/// @param  *rotation
function draw_sprite_() {


	if(argument[0] <= 0) exit; // GMS2: guard 0 AND -1 (no sprite)

	// !ghost, 10-24 (Gainey 1:43:03 "things don't go invisible, Claude", 2:56:22 "a couple of them
	// are broken cause of their sprite changes when they attack"): GO_draw_sprite / GameObject_draw_1a
	// fade enemies, but Daira, Bot, Eyenocc, Fokka and the rest draw through THIS wrapper from their
	// own _draw scripts and stayed solid. The fade lives here now, once, for any non-boss Enemy
	// instance that calls in (min(), so a caller that already faded is not faded twice).
	// !beef (Lane 10-28 "bigger sprites") rides the same hook: non-boss enemies draw at 1.5x while it runs.
	var _gh = variable_global_exists("tw_ghost") && global.tw_ghost;
	var _bf = variable_global_exists("tw_beef")  && global.tw_beef;
	if ((_gh || _bf) && argument_count >= 4 && !is_struct(self)
	&&  is_ancestor(object_index, Enemy) && !is_ancestor(object_index, Boss))
	{
		var _gp = (argument_count > 4) ? argument[4] : 0;
		if (_gp && _gp < global.palette_image_w) pal_swap_set(global.palette_image, _gp);
		var _gsc = _bf ? 1.5 : 1;
		var _gxs = ((argument_count > 5) ? argument[5] : 1) * _gsc;
		var _gys = ((argument_count > 6) ? argument[6] : 1) * _gsc;
		var _gco = (argument_count > 7) ? argument[7] : c_white;
		var _gal = (argument_count > 8) ? argument[8] : 1;
		if (_gh) _gal = min(_gal, 0.12);
		var _gro = (argument_count > 9) ? argument[9] : 0;
		draw_sprite_ext(argument[0], argument[1], argument[2], argument[3], _gxs, _gys, _gro, _gco, _gal);
		if (_gp && _gp < global.palette_image_w) pal_swap_reset();
		exit;
	}



	if (argument_count>4 
	&&  argument[4]  // if pal index >= .5
	&&  argument[4]<global.palette_image_w )
	{
	    pal_swap_set(global.palette_image, argument[4]); // Won't run if pal index is out of range
	}


	switch(argument_count)
	{
	    // --------------------------------------------------------------
	    case  1: exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    case  2: exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    case  3: exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
	    // --------------------------------------------------------------
	    case  4:{ //         sprite,  sub image,           x,          y
	    draw_sprite(    argument[0],argument[1], argument[2],argument[3]);
	            exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    break;}
    
    
    
	    // --------------------------------------------------------------
	    case  5:{ //         sprite,  sub image,           x,          y
	    draw_sprite(    argument[0],argument[1], argument[2],argument[3]);
	    break;}
    
	    // --------------------------------------------------------------
	    case  6:{ //         sprite,  sub image,           x,          y,      xscale,     yscale,    rotation,       color,      alpha
	    draw_sprite_ext(argument[0],argument[1], argument[2],argument[3], argument[5],          1,           0,     c_white,          1);
	    break;}
    
	    // --------------------------------------------------------------
	    case  7:{ //         sprite,  sub image,           x,          y,      xscale,     yscale,    rotation,       color,      alpha
	    draw_sprite_ext(argument[0],argument[1], argument[2],argument[3], argument[5],argument[6],           0,     c_white,          1);
	    break;}
    
	    // --------------------------------------------------------------
	    case  8:{ //         sprite,  sub image,           x,          y,      xscale,     yscale,    rotation,       color,      alpha
	    draw_sprite_ext(argument[0],argument[1], argument[2],argument[3], argument[5],argument[6],           0, argument[7],          1);
	    break;}
    
	    // --------------------------------------------------------------
	    case  9:{ //         sprite,  sub image,           x,          y,      xscale,     yscale,    rotation,       color,      alpha
	    draw_sprite_ext(argument[0],argument[1], argument[2],argument[3], argument[5],argument[6],           0, argument[7],argument[8]);
	    break;}
    
	    // --------------------------------------------------------------
	    case 10:{ //         sprite,  sub image,           x,          y,      xscale,     yscale,    rotation,       color,      alpha
	    draw_sprite_ext(argument[0],argument[1], argument[2],argument[3], argument[5],argument[6], argument[9], argument[7],argument[8]);
	    break;}
	}



	if (argument[4] 
	&&  argument[4]<global.palette_image_w )
	{
	    pal_swap_reset();
	}







}
