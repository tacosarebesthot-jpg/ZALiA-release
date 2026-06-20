/// @description  get_random_color_midtone(use game colors)
/// @param use game colors
function get_random_color_midtone(argument0) {


	if (argument0) return p.dl_colors_m[|irandom(ds_list_size(p.dl_colors_m)-1)];
	else           return irandom($FFFFFF); // TODO: this color's brightness should be >=$40 && <$80 for a midtone color
	/*
	var _return  = 0;
	if(!irandom($17))
	{
	    _return = p.CI_GRY4;
	}
	else
	{
	    _return  = !irandom($03) + !irandom($3F);
	    _return  = _return<<4;
	    _return |= irandom($C)+1;
	    if (_return&$F==$D)
	    {   _return = p.CI_BLK1;  }
	}

	return _return;
	//_return  = !irandom($07) + !irandom($0F) + !irandom($17);
	//return !irandom($07) + !irandom($0F) + !irandom($0F);
	//return !irandom($03) + !irandom($05) + !irandom($07);
	//return !irandom($03) + !irandom($08) + !irandom($0A);
	*/







}
