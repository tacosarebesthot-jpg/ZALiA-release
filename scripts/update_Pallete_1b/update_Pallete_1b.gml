/// @description  update_Pallete_1b()
function update_Pallete_1b() {


	with(p)
	{
	    // Update dark rm palette
	    if (g.rm_brightness<g.RM_BRIGHTNESS_MAX 
	    &&  pal_rm_dark_idx+1 ) // -1 means not a dark rm
	    {
	        var _DARK_PAL = dg_pal_rm_dark[#pal_rm_dark_idx, g.rm_brightness];
	        change_pal(string_copy(pal_rm_new, 1, COL_PER_SET*global.PAL_CHAR_PER_COLOR) + _DARK_PAL);
	    }
	}







}
