/// @description  pal_swap_set_tiles(palette sprite or surface, pal index, start layer, end layer);
/// @param palette sprite or surface
/// @param  pal index
/// @param  start layer
/// @param  end layer
function pal_swap_set_tiles() {

	// Call this every step you want to draw the tiles palette swapped.  
	// Stop calling it, or set the pal index to 0 to stop palette swapping.
	// Does not need to be called in a draw event.  In fact, I recommend the step event.


	// ------------------------------------------------------------
	if(!global.use_pal_swap 
	|| !argument[1] 
	||  argument[1]>=global.palette_image_w )
	{
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}

	if (global.palette_image_IS_SURFACE)
	{    if(!surface_exists(argument[0])) exit;  } // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	else if(!sprite_exists( argument[0])) exit;    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// ------------------------------------------------------------
	var _PALETTE_IMAGE = argument[0]; // `global.palette_image`
	var _PALETTE_INDEX = argument[1];

	argument[2]++;
	argument[3]--;
	var _LOW  = max(argument[2],argument[3]);
	var _HIGH = min(argument[2],argument[3]);




	///Check the start object-------------------------
	var _start_exists = false;
	with(TileSwapperStart)
	{
	    if (depth==_LOW)
	    {   //Object already exists, update the values.
	        _start_exists  = true;
	        active         = true;
	        pal_sprite     = _PALETTE_IMAGE;
	        pal_index      = _PALETTE_INDEX;
	        pal_is_surface = global.palette_image_IS_SURFACE;
	    }
	}

	if(!_start_exists)
	{   //Object does not exist.  Create it.
	    with(instance_create(0,0,TileSwapperStart))
	    {
	        active         = true;
	        depth          = _LOW;
	        pal_sprite     = _PALETTE_IMAGE;
	        pal_index      = _PALETTE_INDEX;
	        pal_is_surface = global.palette_image_IS_SURFACE;
	    }
	}




	///Check the end object-------------------------
	var _end_exists = false;
	with(TileSwapperEnd)
	{
	    if (depth==_HIGH)
	    {   //Object already exists, update the values.
	        _end_exists = true;
	        active      = true;
	    }
	}

	if(!_end_exists)
	{   //Object does not exist.  Create it.
	    with(instance_create(0,0,TileSwapperEnd))
	    {
	        active = true;
	        depth  = _HIGH;
	    }
	}




	/* // ------------------ ORIGINAL ------------------
	///pal_swap_set_tiles(palette sprite or surface, pal index, start layer, end layer, pal is surface);
	//Call this every step you want to draw the tiles palette swapped.  
	// Stop calling it, or set the pal index to 0 to stop palette swapping.
	//Does not need to be called in a draw event.  In fact, I recommend the step event.
	var _pal_sprite = argument[0];
	var _pal_index = argument[1];

	var _low =argument[2]+1;
	var _high = argument[3]-1;
	var _is_surface = argument[4];

	if(_low<_high)
	{   //You passed the arguments in backwards, nimrod.
	    _low=argument[3]-1;
	    _high=argument[2]+1;
	    //Sorry.  It's not really a big deal.  If it makes you feel better, Nimrod was actually a mighty warrior.
	    //Look it up.
	}    

	///Check the start object-------------------------
	var _start_exists=false;
	with(TileSwapperStart)
	{
	    if(depth==_low)
	    {   //Object already exists, update the values.
	        _start_exists=true;
	        active=true;
	        pal_sprite=_pal_sprite;
	        pal_index=_pal_index;
	        pal_is_surface=_is_surface;
	    }
	}

	if(!_start_exists)
	{   //Object does not exist.  Create it.
	    with(instance_create(0,0,TileSwapperStart))
	    {
	        active=true;
	        depth=_low;
	        pal_sprite=_pal_sprite;
	        pal_index=_pal_index;
	        pal_is_surface=_is_surface;
	    }
	}

	///Check the end object-------------------------
	var _end_exists=false;
	with(TileSwapperEnd)
	{
	    if(depth==_high)
	    {   //Object already exists, update the values.
	        _end_exists=true;
	        active=true;
	    }
	}

	if(!_end_exists)
	{   //Object does not exist.  Create it.
	    with(instance_create(0,0,TileSwapperEnd))
	    {
	        active=true;
	        depth=_high;
	    }
	}
	*/







}
