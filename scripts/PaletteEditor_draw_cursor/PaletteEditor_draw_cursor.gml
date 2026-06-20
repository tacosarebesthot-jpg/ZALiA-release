/// @description  PaletteEditor_draw_cursor(XL, YT)
/// @param XL
/// @param  YT
function PaletteEditor_draw_cursor() {


	if(!surface_exists(Cursor_surf))
	{
	    Cursor_surf = surface_create(Cursor_W,Cursor_H);
	    surface_set_target(Cursor_surf);
	    draw_clear_alpha(c_black,0);
	    draw_rect_(c_black,      0,0, Cursor_W,  Cursor_H,   1,true);
	    draw_rect_(Cursor_COLOR, 1,1, Cursor_W-2,Cursor_H-2, 1,true);
	    surface_reset_target();
	}

	draw_surface(Cursor_surf,argument[0],argument[1]);







}
