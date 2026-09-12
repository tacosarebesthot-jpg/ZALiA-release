/// @description  GameObject_draw_1a(sprite, palette index)
/// @param sprite
/// @param  palette index
function GameObject_draw_1a(argument0, argument1) {


	// GMS2 port: GM1.4 auto-zeroed undeclared vars; objects with no scr_ini (e.g. spawners)
	// can reach this draw chokepoint before xScale/yScale are set. Default to identity scale.
	if (!variable_instance_exists(id, "xScale")) xScale = 1;
	if (!variable_instance_exists(id, "yScale")) yScale = 1;

	// !ghost (round 10h): non-boss enemies fade to a whisper while the effect is live
	if (variable_global_exists("tw_ghost") && global.tw_ghost
	&&  is_ancestor(object_index, Enemy) && !is_ancestor(object_index, Boss))
	{   draw_sprite_(argument0,0, drawX,drawY, argument1, xScale,yScale, c_white, 0.12);  }
	else
	{   draw_sprite_(argument0,0, drawX,drawY, argument1, xScale,yScale);  }







}
