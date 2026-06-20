/// @description  build_pal(WHT, *RED, *BLU, *GRN, *YLW, *MGN, *BLK, *CYN)
/// @param WHT
/// @param  *RED
/// @param  *BLU
/// @param  *GRN
/// @param  *YLW
/// @param  *MGN
/// @param  *BLK
/// @param  *CYN
function build_pal() {


	var                                                            _i=0;
	var                                          _C_WHT = p.C_WHT0;
	if (argument_count>_i && argument[_i++]!=-1) _C_WHT = argument[_i-1];

	var                                          _C_RED = p.C_RED0;
	if (argument_count>_i && argument[_i++]!=-1) _C_RED = argument[_i-1];

	var                                          _C_BLU = p.C_BLU0;
	if (argument_count>_i && argument[_i++]!=-1) _C_BLU = argument[_i-1];

	var                                          _C_GRN = p.C_GRN0;
	if (argument_count>_i && argument[_i++]!=-1) _C_GRN = argument[_i-1];

	var                                          _C_YLW = p.C_YLW0;
	if (argument_count>_i && argument[_i++]!=-1) _C_YLW = argument[_i-1];

	var                                          _C_MGN = p.C_MGN0;
	if (argument_count>_i && argument[_i++]!=-1) _C_MGN = argument[_i-1];

	var                                          _C_BLK = p.C_BLK0;
	if (argument_count>_i && argument[_i++]!=-1) _C_BLK = argument[_i-1];

	var                                          _C_CYN = p.C_CYN0;
	if (argument_count>_i && argument[_i++]!=-1) _C_CYN = argument[_i-1];


	var _base_color_char, _color;
	var _return = "";

	for(_i=0; _i<global.COLORS_PER_PALETTE; _i++)
	{
	    _base_color_char = string_char_at(global.PAL_BASE_COLOR_ORDER,_i+1);
    
	    switch(_base_color_char){
	    default: {_color=p.C_BLK1; break;}
	    case "W":{_color=_C_WHT; break;}
	    case "R":{_color=_C_RED; break;}
	    case "B":{_color=_C_BLU; break;}
	    case "G":{_color=_C_GRN; break;}
	    case "Y":{_color=_C_YLW; break;}
	    case "M":{_color=_C_MGN; break;}
	    case "K":{_color=_C_BLK; break;}
	    case "C":{_color=_C_CYN; break;}
	    }
    
	    if (_color==-2)
	    {
	        switch(_base_color_char){
	        case "W":{_color=p.C_WHT0; break;}
	        case "R":{_color=p.C_RED0; break;}
	        case "B":{_color=p.C_BLU0; break;}
	        case "G":{_color=p.C_GRN0; break;}
	        case "Y":{_color=_C_WHT; break;}
	        case "M":{_color=_C_RED; break;}
	        case "K":{_color=_C_BLU; break;}
	        case "C":{_color=_C_GRN; break;}
	        }
	    }
    
	    _return += color_str(_color);
	}


	return _return;







}
