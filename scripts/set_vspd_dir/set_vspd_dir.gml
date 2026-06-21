/// @description  set_vspd_dir()
function set_vspd_dir() {


	// GMS2 port: some objects (e.g. SpawnerHostile) reach here before vspd is set.
	// Default vspd + vspd_dir on the instance so this and all later reads are safe.
	if (!variable_instance_exists(id, "vspd")) vspd = 0;
	vspd_dir = 0; // always defined; overridden below when vspd has magnitude

	if (vspd)
	{
	    if (vspd&$80) vspd_dir = -1;
	    else          vspd_dir =  1;
	}







}
