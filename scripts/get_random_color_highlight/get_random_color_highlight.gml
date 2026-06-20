/// @description  get_random_color_highlight(use game colors)
/// @param use game colors
function get_random_color_highlight(argument0) {


	if (argument0) return p.dl_colors_h[|irandom(ds_list_size(p.dl_colors_h)-1)];
	else           return irandom($FFFFFF); // TODO: this color's brightness should be >=$80 for a highlight color
	/*
	var _return  = 0;
	_return  = !irandom($01) + !irandom($03) + !irandom($05);
	//_return  = !irandom($01) + !irandom($03) + !irandom($05);
	//_return  = !irandom($01) + !irandom($02) + !irandom($03);
	//_return  = !irandom($08) + !irandom($0D) + !irandom($10);
	_return  = _return<<4;
	_return |= irandom($D);

	return _return;
	*/







}
