/// @description  GO_instance_end()
function GO_instance_end() {


	// Called from three GameObject events (Destroy, Game End, Room End), so it used to run up
	// to three times per instance; the second pass tore down lists the first had already
	// freed (Kakusu001_end grew a crash guard for exactly that). Run once: the flag is reset
	// where dl_sprites is (re)created (init_vars_draw_1a), so a re-initialised instance
	// gets its cleanup again.
	if (variable_instance_exists(id, "go_instance_ended") && go_instance_ended) return;
	go_instance_ended = true;

	if (variable_instance_exists(id,"ocs_draw_x"))
	{                                ocs_draw_x = 0;  }
	if (variable_instance_exists(id,"ocs_draw_y"))
	{                                ocs_draw_y = 0;  }

	// inst_end: Instance End
	if (variable_instance_exists(id,"scr_inst_end")
	&& !is_undefined(                scr_inst_end)
	&&  is_callable(                 scr_inst_end) )
	{   script_execute(              scr_inst_end);  }


	with(g)
	{
	    if(!is_undefined(      dl_solid_inst)
	    &&  ds_list_find_index(dl_solid_inst,other)!=-1 )
	    {   ds_list_delete(    dl_solid_inst, ds_list_find_index(dl_solid_inst,other));  }
	}



	if (is_ancestor(object_index,GOB1))
	{
	    var _exists = false;
    
	        _exists = variable_instance_exists(id,  "dl_sprites");
	    if (_exists) _exists =      !is_undefined(   dl_sprites);
	    if (_exists) _exists =       ds_exists(      dl_sprites,ds_type_list);
	    if (_exists)                 ds_list_destroy(dl_sprites);
	    if (_exists)                                 dl_sprites=undefined;
    
	        _exists = variable_instance_exists(id,  "dl_ProjVuln");
	    if (_exists) _exists =      !is_undefined(   dl_ProjVuln);
	    if (_exists) _exists =       ds_exists(      dl_ProjVuln,ds_type_list);
	    if (_exists)                 ds_list_destroy(dl_ProjVuln);
	    if (_exists)                                 dl_ProjVuln=undefined;
	}







}
