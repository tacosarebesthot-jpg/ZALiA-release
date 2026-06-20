/// @description  color_tiles()
function color_tiles() {


	if (is_undefined(p.pal_rm_def)) // if there's NO pal for this rm/room
	{
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}


	if (global.palette_image_IS_SURFACE)
	{    if(!surface_exists(global.palette_image)) exit;  } // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	else if(!sprite_exists( global.palette_image)) exit;    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	var _i, _idx;
	var _depth, _pi;

	var _DARK_LEVEL = 0;
	if (!rm_pal_qual_lit()) _DARK_LEVEL = 1;

	for(_i=ds_list_size(g.dl_pal_swap_depths)-1; _i>=0; _i--)
	{   // Note: All depths(tile layers) could use any mix of pi(Palette Index).
	    _depth =        g.dl_pal_swap_depths[|_i];
	    _idx = ds_list_find_index(g.dl_TILE_DEPTHS,_depth);
    
	    _pi = p.dg_depth_pi[#_idx,1];
	    if (_DARK_LEVEL)
	    {
	        _pi = val(global.dm_pi[?hex_str(_pi)+STR_Dark+string(_DARK_LEVEL)], _pi);
	    }
    
	    pal_swap_set_tiles(global.palette_image,_pi, _depth,_depth);
	}







}
