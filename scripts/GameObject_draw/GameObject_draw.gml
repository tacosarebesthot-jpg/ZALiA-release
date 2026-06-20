/// @description  GameObject_draw(can draw debug)
/// @param can draw debug
function GameObject_draw(argument0) {


	// GMS2: guard uninitialized vars — in GMS1.4 these defaulted to 0
	var _scr   = variable_instance_exists(id, "scr_draw")   ? scr_draw   : undefined;
	var _palidx= variable_instance_exists(id, "palidx")     ? palidx     : 0;
	var _spr   = variable_instance_exists(id, "sprite")     ? sprite     : sprite_index;
	     if (!is_undefined(_scr))   script_execute(_scr);
	else if (can_draw_self)         GameObject_draw_1a(_spr, _palidx); // draw self

	//  -----------------------------------------------------------
	//  Debug draw
	if (argument0) GO_debug_draw_1a(); // xlyt,xy point, sprite outline







}
