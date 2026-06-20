/// @description  PaletteEditor_get_cursor_color(for palette grid)
/// @param for palette grid
function PaletteEditor_get_cursor_color(argument0) {


	if (argument0)
	{
	    var _PI = val(PalEdit_dm[?STR_Palette+hex_str(PalEdit_Cursor_clm+1)+STR_Palette+STR_Index]);
	    var _COLOR_CHAR = string_char_at(global.PAL_BASE_COLOR_ORDER, PalEdit_Cursor_row+1);
	    return get_pal_color(pal_during_edit, _PI, _COLOR_CHAR);
	}
	else
	{
	    var _IDX = (ColorGrid_Cursor_row*ColorGrid_CLMS) + ColorGrid_Cursor_clm;
	    return ColorGrid_dl_colors[|_IDX];
	    /*
	    var _IDX = (ColorGrid_Cursor_row<<4) | ColorGrid_Cursor_clm;
	    return p.dl_COLOR[|_IDX];
	    */
	}







}
