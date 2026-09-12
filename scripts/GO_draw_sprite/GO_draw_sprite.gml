/// @description  GO_draw_sprite(sprite, *palette index)
/// @param sprite
/// @param  *palette index
function GO_draw_sprite() {


	if(argument[0] <= 0) exit; // GMS2: guard 0 AND -1 (no sprite)
	// !ghost: non-boss enemies fade to a whisper while the effect is live (same rule as GameObject_draw_1a)
	var _ga = 1;
	if (variable_global_exists("tw_ghost") && global.tw_ghost
	&&  is_ancestor(object_index, Enemy) && !is_ancestor(object_index, Boss)) _ga = 0.12;
	switch(argument_count)
	{
	    // --------------------------------------------------------------
	    case 1:{ // sprite
	    if (_ga < 1) draw_sprite_(argument[0],0, drawX,drawY, -1,          xScale,yScale, c_white, _ga);
	    else         draw_sprite_(argument[0],0, drawX,drawY, -1,          xScale,yScale);
	    break;}
	    // --------------------------------------------------------------
	    case 2:{ // sprite, palette index
	    if (_ga < 1) draw_sprite_(argument[0],0, drawX,drawY, argument[1], xScale,yScale, c_white, _ga);
	    else         draw_sprite_(argument[0],0, drawX,drawY, argument[1], xScale,yScale);
	    break;}
	}







}
