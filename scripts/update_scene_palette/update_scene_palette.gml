/// @description  update_scene_palette()
function update_scene_palette() {


	// *** pal_rm_new is the current palette WITHIN the current frame of code. pal_rm_curr is what colors the palette_image currently has as it's not updated until the draw event later
	    p.pal_rm_new = string_copy(p.pal_rm_new, 1,global.PAL_CHAR_PER_SCENE);
	if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() A");
	if (g.rm_brightness==1)
	{   // When a scene is semi-lit, you can only see the bright colors of enemies. Make sure the palettes they use have the same color from the lit version as this color can depend on the particular scene.
	    p.pal_rm_new = strReplaceAt(p.pal_rm_new, get_pal_col_pos(global.PI_MOB_ORG+p.PI_DRK1,"W"), global.PAL_CHAR_PER_COLOR, color_str(get_pal_color(p.pal_rm_new,global.PI_MOB_ORG,"R")));
	    p.pal_rm_new = strReplaceAt(p.pal_rm_new, get_pal_col_pos(global.PI_MOB_RED+p.PI_DRK1,"W"), global.PAL_CHAR_PER_COLOR, color_str(get_pal_color(p.pal_rm_new,global.PI_MOB_RED,"R")));
	    p.pal_rm_new = strReplaceAt(p.pal_rm_new, get_pal_col_pos(global.PI_MOB_BLU+p.PI_DRK1,"W"), global.PAL_CHAR_PER_COLOR, color_str(get_pal_color(p.pal_rm_new,global.PI_MOB_BLU,"R")));
	    p.pal_rm_new = strReplaceAt(p.pal_rm_new, get_pal_col_pos(global.PI_MOB_PUR+p.PI_DRK1,"W"), global.PAL_CHAR_PER_COLOR, color_str(get_pal_color(p.pal_rm_new,global.PI_MOB_PUR,"R")));
	}




	if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B");
	var _COUNT1 = val(global.dm_pi[?STR_Permutation+STR_Count]);
	if (_COUNT1)
	{
	    var _i,_j;
	    var _char, _pos;
	    var _pi, _parent_pi,_parent_pal_pos, _order;
	    var _c_wht, _c_red, _c_blu, _c_grn, _c_ylw, _c_mgn, _c_blk, _c_cyn;
	    for(_i=0; _i<_COUNT1; _i++) // each pi permut
	    {
	        if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _iA-"+string(_i));
	        _pi        = val(global.dm_pi[?STR_Permutation+hex_str(_i+1)+STR_Palette+STR_Index]);
	        _parent_pi = val(global.dm_pi[?hex_str(_pi)+"_Parent"+STR_Palette+STR_Index]);
	        _order     = val(global.dm_pi[?hex_str(_pi)+STR_Color+STR_Order]);
	        _parent_pal_pos = get_pal_pos(_parent_pi);
	        _c_wht = p.C_WHT0_;
	        _c_red = p.C_RED0_;
	        _c_blu = p.C_BLU0_;
	        _c_grn = p.C_GRN0_;
	        _c_ylw = p.C_YLW0_;
	        _c_mgn = p.C_MGN0_;
	        _c_blk = p.C_BLK0_;
	        _c_cyn = p.C_CYN0_;
	        if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _iB-"+string(_i));
	        for(_j=0; _j<global.COLORS_PER_PALETTE; _j++) // each color
	        {
	            if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _jA-"+string(_j));
	            // `global.DB0`(silent app crash) occuring somewhere between here... \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
	            _char = string_char_at(_order, _j+1);
	            _pos  = string_pos(_char, global.PAL_BASE_COLOR_ORDER);
	            _pos  = max(0,_pos-1);
	            _pos *= global.PAL_CHAR_PER_COLOR;
	            _pos  = _parent_pal_pos + _pos;
	            _color = string_copy(p.pal_rm_new, _pos, global.PAL_CHAR_PER_COLOR);
	            // ...and here ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	            if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _jB-"+string(_j));
            
	            switch(string_char_at(global.PAL_BASE_COLOR_ORDER,_j+1)){
	            case "W":{_c_wht=_color; break;}
	            case "R":{_c_red=_color; break;}
	            case "B":{_c_blu=_color; break;}
	            case "G":{_c_grn=_color; break;}
	            case "Y":{_c_ylw=_color; break;}
	            case "M":{_c_mgn=_color; break;}
	            case "K":{_c_blk=_color; break;}
	            case "C":{_c_cyn=_color; break;}
	            }
	            if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _jC-"+string(_j));
	        }
	        if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _iC-"+string(_i));
	        p.pal_rm_new += build_pal(_c_wht, _c_red, _c_blu, _c_grn, _c_ylw, _c_mgn, _c_blk, _c_cyn);
	        if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() B _iD-"+string(_i));
	    }
	}


	if(global.DB0&&room==rmB_ContinueSave)show_debug_message("update_scene_palette() C");
	return p.pal_rm_new;







}
