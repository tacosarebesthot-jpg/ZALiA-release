/// @description  Cutscene_GameEnd_1B_end()
function Cutscene_GameEnd_1B_end() {


	//ar_CURTAIN      = 0;
	//ar_CURTAIN_TSRC = 0;
	//ar_ANIM_TSRC    = 0;

	/*
	var _exists = false;


	    _exists=variable_instance_exists(id,"dl_");
	if (_exists) _exists = !is_undefined(    dl_);
	if (_exists) _exists = ds_exists(        dl_,ds_type_list);
	if (_exists)           ds_list_destroy(  dl_);
	if (_exists)                             dl_=undefined;

	    _exists=variable_instance_exists(id,"dm_");
	if (_exists) _exists = !is_undefined(    dm_);
	if (_exists) _exists = ds_exists(        dm_,ds_type_map);
	if (_exists)           ds_map_destroy(   dm_);
	if (_exists)                             dm_=undefined;

	    _exists=variable_instance_exists(id,"dg_");
	if (_exists) _exists = !is_undefined(    dg_);
	if (_exists) _exists = ds_exists(        dg_,ds_type_grid);
	if (_exists)           ds_grid_destroy(  dg_);
	if (_exists)                             dg_=undefined;

	    _exists=variable_instance_exists(id,"ds_");
	if (_exists) _exists = !is_undefined(    ds_);
	if (_exists) _exists = ds_exists(        ds_,ds_type_stack);
	if (_exists)           ds_stack_destroy( ds_);
	if (_exists)                             ds_=undefined;
	*/


	var _exists;




	    _exists=variable_instance_exists(id,"dl_curtain_tsrc");
	if (_exists) _exists = !is_undefined(    dl_curtain_tsrc);
	if (_exists) _exists = ds_exists(        dl_curtain_tsrc,ds_type_list);
	if (_exists)           ds_list_destroy(  dl_curtain_tsrc);
	if (_exists)                             dl_curtain_tsrc=undefined;





	    _exists=variable_instance_exists(id,"dg_curtain");
	if (_exists) _exists = !is_undefined(    dg_curtain);
	if (_exists) _exists = ds_exists(        dg_curtain,ds_type_grid);
	if (_exists)           ds_grid_destroy(  dg_curtain);
	if (_exists)                             dg_curtain=undefined;

	    _exists = variable_instance_exists(id,  "dg_CREDITS");
	if (_exists) _exists =      !is_undefined(   dg_CREDITS);
	if (_exists) _exists =       ds_exists(      dg_CREDITS, ds_type_grid);
	if (_exists)                 ds_grid_destroy(dg_CREDITS);
	if (_exists)                                 dg_CREDITS = undefined;







}
