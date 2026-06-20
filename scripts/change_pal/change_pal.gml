/// @description  change_pal(new palette)
/// @param new palette
function change_pal(argument0) {


	p.pal_rm_new = argument0;
	if(global.DB0&&room==rmB_ContinueSave)show_debug_message("change_pal() A");
	// re-build all the permut pi's in case they've changed in the middle of the frame
	update_scene_palette();
	if(global.DB0&&room==rmB_ContinueSave)show_debug_message("change_pal() B");
	return p.pal_rm_new;







}
