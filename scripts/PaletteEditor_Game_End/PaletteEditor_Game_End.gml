/// @description  PaletteEditor_Game_End()
function PaletteEditor_Game_End() {


	if (surface_exists(ObjPal_surf)) surface_free(ObjPal_surf);
	if (surface_exists(PalEdit_Outline_surf)) surface_free(PalEdit_Outline_surf);
	if (surface_exists(Cursor_surf)) surface_free(Cursor_surf);
	if (surface_exists(ColorGrid_surf)) surface_free(ColorGrid_surf);


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



	var _exists = false;





	             _exists = variable_instance_exists(id,  "dl_hist_sess");
	if (_exists) _exists =               !is_undefined(   dl_hist_sess);
	if (_exists) _exists =                ds_exists(      dl_hist_sess, ds_type_list);
	if (_exists)                          ds_list_destroy(dl_hist_sess);
	if (_exists)                                          dl_hist_sess = undefined;

	             _exists = variable_instance_exists(id,  "dl_hist_room");
	if (_exists) _exists =               !is_undefined(   dl_hist_room);
	if (_exists) _exists =                ds_exists(      dl_hist_room, ds_type_list);
	if (_exists)                          ds_list_destroy(dl_hist_room);
	if (_exists)                                          dl_hist_room = undefined;

	    _exists=variable_instance_exists(id,"ColorGrid_dl_colors");
	if (_exists) _exists = !is_undefined(    ColorGrid_dl_colors);
	if (_exists) _exists = ds_exists(        ColorGrid_dl_colors,ds_type_list);
	if (_exists)           ds_list_destroy(  ColorGrid_dl_colors);
	if (_exists)                             ColorGrid_dl_colors=undefined;




	    _exists=variable_instance_exists(id,"PalEdit_dm");
	if (_exists) _exists = !is_undefined(    PalEdit_dm);
	if (_exists) _exists = ds_exists(        PalEdit_dm,ds_type_map);
	if (_exists)           ds_map_destroy(   PalEdit_dm);
	if (_exists)                             PalEdit_dm=undefined;




	    _exists=variable_instance_exists(id,"Info1_dg");
	if (_exists) _exists = !is_undefined(    Info1_dg);
	if (_exists) _exists = ds_exists(        Info1_dg,ds_type_grid);
	if (_exists)           ds_grid_destroy(  Info1_dg);
	if (_exists)                             Info1_dg=undefined;







}
