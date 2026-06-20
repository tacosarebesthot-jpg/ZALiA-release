/// @description  get_random_color_shadow(use game colors)
/// @param use game colors
function get_random_color_shadow(argument0) {


	if (argument0) return p.dl_colors_s[|irandom(ds_list_size(p.dl_colors_s)-1)];
	else           return irandom($FFFFFF); // TODO: this color's brightness should be <$40 for a midtone color
	/*
	var _return  = 0;
	if(!irandom($17))
	{
	    _return = p.CI_GRY4;
	}
	else
	{
	    _return  = !irandom($17) + !irandom($4F);
	    _return  = _return<<4;
	    _return |= irandom($C)+1;
	    if (_return&$F==$D)
	    {   _return = p.CI_BLK1;  }
	}

	return _return;
	//return !irandom($17) + !irandom($1B) + !irandom($23);
	//return !irandom($13) + !irandom($17) + !irandom($1F);
	//return !irandom($10) + !irandom($11) + !irandom($12);
	//return irandom((1 + !irandom($0A)) + !irandom($0D));
	*/







}
