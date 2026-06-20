/// @description  GOB_rm_end_clean_up_1()
function GOB_rm_end_clean_up_1() {

	// Gives permission for any remaining GOB to spawn if pc comes back to this rm


	// E18A
	var _i;

	var _dl_gob1 = g.go_mgr.dl_gob1;
	var _dl_gob2 = g.go_mgr.dl_gob2;
	var _inst;

	for(_i=ds_list_size(_dl_gob1)-1; _i>=0; _i--)
	{
	    _inst = _dl_gob1[|_i];
	    if (!instance_exists(_inst)) continue;
	    with(_inst)
	    {
	        if (state)
	        {
	            GOB_despawn(id);
	            state = state_NORMAL;
	        }
	    }
	}


	for(_i=ds_list_size(_dl_gob2)-1; _i>=0; _i--)
	{
	    _inst = _dl_gob2[|_i];
	    if (!instance_exists(_inst)) continue;
	    with(_inst)
	    {
	        if (state
	        && !is_undefined(dk_spawn) )
	        {
	            g.dm_spawn[? dk_spawn+STR_Spawn_Permission] = 1;
	        }
	    }
	}







}
