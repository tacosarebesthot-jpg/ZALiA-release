/// @description  SpikeBall1_init3()
function SpikeBall1_init3() {


	if (ver==2)
	{
	    var _i, _count1;
	    var _new_pi = 0;
    
	    // Holds the flash pi's in its bytes for SpikeBall1_udp(). Example: $0C12130B. $0C1213(0B) 1st pi, $0C12(13)0B 2nd pi, $0C(12)130B 3rd pi, $(0C)12130B 4th pi
	    flash_pal_indices = 0;
    
    
	    var _dl_color_order = ds_list_create();
	    ds_list_add(_dl_color_order,global.PAL_BASE_COLOR_ORDER);
	    ds_list_add(_dl_color_order,"RBWGMKYC");
	    ds_list_add(_dl_color_order,"BWRGKYMC");
	    ds_list_add(_dl_color_order,"RBWGMKYC");
    
    
	    _count1 = ds_list_size(_dl_color_order);
	    for(_i=0; _i<_count1; _i++)
	    {
	        _new_pi = add_pi_permut(palidx, _dl_color_order[|_i], "SpikeBall1 ver2 flash "+string(_i+1));
	        flash_pal_indices |= _new_pi<<(_i<<3);
	    }
    
    
	    ds_list_destroy(_dl_color_order); _dl_color_order=undefined;
	}



	/*
	if (ver==2)
	{
	    var _i,_j, _idx1, _count1;
	    var _char, _pos;
	    var _PARENT_PI = palidx;
	    var _new_pi = 0;
    
	    // Holds the flash pi's in its bytes for SpikeBall1_udp(). Example: $0C121312
	    flash_pal_indices = 0;
    
    
	    var _dl_color_order = ds_list_create();
    
	    if (p.PAL_SYS_VER==4) ds_list_add(_dl_color_order,p.PAL_BASE_COLOR_ORDER);
	    else                  ds_list_add(_dl_color_order,p.PAL_BASE_COLOR_ORDER);
    
	    if (p.PAL_SYS_VER==4) ds_list_add(_dl_color_order,"RBWGYMKC");
	    else                  ds_list_add(_dl_color_order,"GRBW");
    
	    if (p.PAL_SYS_VER==4) ds_list_add(_dl_color_order,"BWRGYMKC");
	    else                  ds_list_add(_dl_color_order,"GBWR");
    
	    if (p.PAL_SYS_VER==4) ds_list_add(_dl_color_order,"RBWGYMKC");
	    else                  ds_list_add(_dl_color_order,"GRBW");
    
    
	    _count1 = ds_list_size(_dl_color_order);
	    for(_i=0; _i<_count1; _i++)
	    {
	        _new_pi = 0;
        
	        if (_dl_color_order[|_i]==p.PAL_BASE_COLOR_ORDER)
	        {
	            _new_pi = _PARENT_PI;
	        }
        
	        if(!_new_pi)
	        {
	            for(_j=ds_grid_width(global.dg_pi_permuts)-1; _j>=0; _j--)
	            {
	                if (global.dg_pi_permuts[#_j,1]==_PARENT_PI 
	                &&  global.dg_pi_permuts[#_j,2]==_dl_color_order[|_i] )
	                {
	                    _new_pi = global.dg_pi_permuts[#_j,0];
	                    break;//_j
	                }
	            }
	        }
        
	        if(!_new_pi)
	        {
	            _new_pi = string_length(p.pal_rm_new) div global.PAL_CHAR_PER_PAL;
	            //_new_pi = global.palette_image_w+_i;
            
	            _idx1 = ds_grid_width(global.dg_pi_permuts);
	            ds_grid_resize(global.dg_pi_permuts, _idx1+1,ds_grid_height(global.dg_pi_permuts));
	            global.dg_pi_permuts[#_idx1,0] = _new_pi; // new palette index
	            global.dg_pi_permuts[#_idx1,1] = _PARENT_PI; // parent palette index
	            global.dg_pi_permuts[#_idx1,2] = _dl_color_order[|_i]; // permut color order
	            global.dg_pi_permuts[#_idx1,3] = "SpikeBall1 ver2 flash "+string(_i+1); // description
            
	            for(_j=0; _j<global.COLORS_PER_PALETTE; _j++)
	            {
	                _char = string_char_at(global.dg_pi_permuts[#_idx1,2], _j+1);
	                _pos  = string_pos(_char, p.PAL_BASE_COLOR_ORDER);
	                _pos  = get_pal_pos(global.dg_pi_permuts[#_idx1,1]) + (max(_pos-1,0)*global.PAL_CHAR_PER_COLOR);
	                p.pal_rm_new += string_copy(p.pal_rm_curr, _pos, global.PAL_CHAR_PER_COLOR);
	            }
	        }
        
	        if (_new_pi)
	        {
	            flash_pal_indices |= _new_pi<<(_i<<3);
	        }
	    }
    
    
	    ds_list_destroy(_dl_color_order); _dl_color_order=undefined;
	}
	*/



}
