/// @description  set_hspd_dir()
function set_hspd_dir() {


	// GMS2 port: default hspd + hspd_dir so callers can't read them unset.
	if (!variable_instance_exists(id, "hspd")) hspd = 0;
	hspd_dir = 0; // always defined; overridden below when hspd has magnitude

	if (hspd)
	{
	    if (hspd&$80) hspd_dir = -1;
	    else          hspd_dir =  1;
	}







}
