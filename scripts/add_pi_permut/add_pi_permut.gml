/// @description  add_pi_permut(parent pi, color order, pi description)
/// @param parent pi
/// @param  color order
/// @param  pi description
function add_pi_permut() {


	var _PARENT_PI   = argument[0];
	var _COLOR_ORDER = argument[1];


	if (_COLOR_ORDER==global.PAL_BASE_COLOR_ORDER  // this is NOT a permutation
	||  _PARENT_PI>=p.PAL_PER_SCENE ) // _PARENT_PI is already a permutation
	{
	    return _PARENT_PI;
	}


	// make sure this isn't a dark palette
	_PARENT_PI = _PARENT_PI mod p.PAL_PER_SET;




	var _DATAKEY1 = STR_Palette+STR_Index;
	var _return_pi = val(global.dm_pi[?hex_str(_PARENT_PI)+_COLOR_ORDER+_DATAKEY1]);
	if (_return_pi)
	{
	    return _return_pi;
	}




	var _DESCRIPTION = argument[2];
	var _i, _parent_pi, _permut_num;

	_return_pi = p.PAL_PER_SCENE + val(global.dm_pi[?STR_Permutation+STR_Count]);

	global.dm_pi[?hex_str(_return_pi)  +STR_Description] = _DESCRIPTION;  // permut description
	global.dm_pi[?hex_str(_return_pi+1)+STR_Description] = _DESCRIPTION+STR_Dark+"1";  // permut description
	global.dm_pi[?hex_str(_return_pi)+STR_Dark+"1"] = _return_pi+1;

	for(_i=0; _i<2; _i++)
	{
	    if (_i) _parent_pi = _PARENT_PI + p.PI_DRK1;
	    else    _parent_pi = _PARENT_PI;
    
	    global.dm_pi[?STR_Permutation+STR_Count] = val(global.dm_pi[?STR_Permutation+STR_Count]) + 1;
	    _permut_num = val(global.dm_pi[?STR_Permutation+STR_Count]);
	    global.dm_pi[?STR_Permutation+hex_str(_permut_num)+_DATAKEY1] = _return_pi+_i;
	    global.dm_pi[?hex_str(_parent_pi)+_COLOR_ORDER    +_DATAKEY1] = _return_pi+_i; // new palette index
	    global.dm_pi[?hex_str(_return_pi+_i)+"_Parent"    +_DATAKEY1] = _parent_pi;    // parent palette index
	    global.dm_pi[?hex_str(_return_pi+_i)+STR_Color+STR_Order]     = _COLOR_ORDER;  // permut color order
	}

	if (string_length(p.pal_rm_new)) // if a palette has been built for the scene yet (if this is after p_Room_Start() has built p.pal_rm_def)
	{
	    update_scene_palette();
	}


	return _return_pi;




	    /*
	    if (_CAN_ADD_PAL)
	    {
	        _parent_pal_pos = get_pal_pos(_parent_pi);
	        for(_j=0; _j<global.COLORS_PER_PALETTE; _j++)
	        {
	            _char = string_char_at(_COLOR_ORDER, _j+1);
	            _pos  = string_pos(_char,global.PAL_BASE_COLOR_ORDER);
	            _pos  = max(0,_pos-1);
	            _pos *= global.PAL_CHAR_PER_COLOR;
	            _pos  = _parent_pal_pos + _pos;
	            _val1 = string_copy(p.pal_rm_new, _pos, global.PAL_CHAR_PER_COLOR);
	            p.pal_rm_new += _val1;
	        }
	    }
	    */




	/*
	//==================================
	/// add_pi_permut(parent pi, color order, pi description)


	var _PARENT_PI   = argument[0];
	var _COLOR_ORDER = argument[1];

	var _return_pi = 0;


	if (_COLOR_ORDER!=global.PAL_BASE_COLOR_ORDER)
	{
	    var _i;
	    var _DATAKEY1 = STR_Palette+STR_Index;
    
	    var _grid_W = ds_grid_width(global.dg_pi_permuts);
	    for(_i=0; _i<_grid_W; _i++)
	    {
	        if (global.dg_pi_permuts[#_i,1]==_PARENT_PI 
	        &&  global.dg_pi_permuts[#_i,2]==_COLOR_ORDER )
	        {
	            _return_pi = global.dg_pi_permuts[#_i,0];
	            break;//_i
	        }
	    }
    
	    if(!_return_pi)
	    {
	        var _DESCRIPTION = argument[2];
	        var _char, _pos;
	        var _val1, _parent_pi;
	        // var _val2;
	        var _IDX = _grid_W;
	        _return_pi = p.PAL_PER_SET + _IDX;
	        // lit scene palette index
	        ds_grid_resize(global.dg_pi_permuts, _IDX+1,ds_grid_height(global.dg_pi_permuts));
	        global.dg_pi_permuts[#_IDX,0] = _return_pi; // new palette index
	        global.dg_pi_permuts[#_IDX,1] = _PARENT_PI; // parent palette index
	        global.dg_pi_permuts[#_IDX,2] = _COLOR_ORDER; // permut color order
	        global.dg_pi_permuts[#_IDX,3] = _DESCRIPTION; // description
	        global.dm_pi[?hex_str(_PARENT_PI)          +_DATAKEY1] = global.dg_pi_permuts[#_IDX,  0];
        
	        // dark scene palette index
	        ds_grid_resize(global.dg_pi_permuts, _IDX+2,ds_grid_height(global.dg_pi_permuts));
	        global.dg_pi_permuts[#_IDX+1,0] = _return_pi+1; // new palette index
	        global.dg_pi_permuts[#_IDX+1,1] = _PARENT_PI + p.PI_DRK1; // parent palette index
	        global.dg_pi_permuts[#_IDX+1,2] = _COLOR_ORDER; // permut color order
	        global.dg_pi_permuts[#_IDX+1,3] = _DESCRIPTION+" - DARK"+"1"; // description
	        global.dm_pi[?hex_str(_return_pi)+STR_Dark+"1"] = _return_pi + 1;
	        global.dm_pi[?hex_str(_PARENT_PI+p.PI_DRK1)+_DATAKEY1] = global.dg_pi_permuts[#_IDX+1,0];
        
	        if (string_length(p.pal_rm_new)) // if a palette has been built for the scene yet
	        {
	            var _j;
	            //_val2 = "";
	            for(_i=0; _i<2; _i++)
	            {
	                for(_j=0; _j<global.COLORS_PER_PALETTE; _j++)
	                {
	                    _char = string_char_at(global.dg_pi_permuts[#_IDX+_i,2], _j+1); // 2: color order
	                    _pos  = string_pos(_char,global.PAL_BASE_COLOR_ORDER);
	                    _pos  = max(0,_pos-1);
	                    _pos *= global.PAL_CHAR_PER_COLOR;
	                    _pos  = get_pal_pos(global.dg_pi_permuts[#_IDX+_i,1]) + _pos; // 1: parent pi
	                    _val1 = string_copy(p.pal_rm_new, _pos, global.PAL_CHAR_PER_COLOR);
	                    p.pal_rm_new += _val1;
	                    //_val2 += _val1;
	                }
	            }
            
	            //sdm(_val2);
	        }
	    }
	}
	else
	{
	    _return_pi = _PARENT_PI;
	}



	return _return_pi;
	*/







}
