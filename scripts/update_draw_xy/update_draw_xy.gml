/// @description  update_draw_xy()
function update_draw_xy() {


	// GMS2 port: GM1.4 auto-zeroed undeclared vars; objects with no scr_ini (e.g. spawners)
	// can reach here before these are set. Default on the instance so later reads are safe too.
	if (!variable_instance_exists(id, "DRAW_XOFF")) DRAW_XOFF = 0;
	if (!variable_instance_exists(id, "DRAW_YOFF")) DRAW_YOFF = 0;
	if (!variable_instance_exists(id, "draw_xoff")) draw_xoff = 0;
	if (!variable_instance_exists(id, "draw_yoff")) draw_yoff = 0;

	drawX = x + DRAW_XOFF + draw_xoff;
	drawY = y + DRAW_YOFF + draw_yoff;







}
