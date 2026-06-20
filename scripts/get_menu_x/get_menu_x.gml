/// @description  get_menu_x()
function get_menu_x() {


	var    _return  = viewXC() - 8;
	       _return  = (_return>>4)<<4;
	if (g.rm_pages_x>=2)
	{      _return += $7<<3;  }

	return _return;







}
