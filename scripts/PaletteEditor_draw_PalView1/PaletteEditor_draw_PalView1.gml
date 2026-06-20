/// @description  PaletteEditor_draw_PalView1(content xl, content yt, palette index, palette count, scale)
/// @param content xl
/// @param  content yt
/// @param  palette index
/// @param  palette count
/// @param  scale
function PaletteEditor_draw_PalView1(argument0, argument1, argument2, argument3, argument4) {


	if (PalView_Outline_W)
	{
	    var _W = argument3                 * argument4;
	    var _H = global.COLORS_PER_PALETTE * argument4;
	    if (PalView_Outline_W>1) draw_sprite_(spr_1x1_WHT,0, argument0-2,argument1-2, -1, _W+4,_H+4, PalView_Outline_COLOR2);
	    if (PalView_Outline_W>0) draw_sprite_(spr_1x1_WHT,0, argument0-1,argument1-1, -1, _W+2,_H+2, PalView_Outline_COLOR1);
	}

	if (global.palette_image_IS_SURFACE) draw_surface_part_ext(global.palette_image,   argument2,0, argument3,global.COLORS_PER_PALETTE, argument0,argument1, argument4,argument4, c_white,1);
	else                                 draw_sprite_part_ext( global.palette_image,0, argument2,0, argument3,global.COLORS_PER_PALETTE, argument0,argument1, argument4,argument4, c_white,1);







}
