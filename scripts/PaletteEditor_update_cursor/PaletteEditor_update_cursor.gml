/// @description  PaletteEditor_update_cursor()
function PaletteEditor_update_cursor() {


	if (Input.pressedHV)
	{
	    if (state==state_EDIT1A)
	    {
	        if (Input.pressedH) PalEdit_Cursor_clm = ((PalEdit_Cursor_clm+bit_dir(Input.pressedH)) + PalEdit_PAL_COUNT)         mod PalEdit_PAL_COUNT;
	        if (Input.pressedV) PalEdit_Cursor_row = ((PalEdit_Cursor_row+bit_dir(Input.pressedV)) + global.COLORS_PER_PALETTE) mod global.COLORS_PER_PALETTE;
	    }
	    else // state_EDIT1B, state_BGR_COLOR
	    {
	        if (Input.pressedH) ColorGrid_Cursor_clm = ((ColorGrid_Cursor_clm+bit_dir(Input.pressedH)) + ColorGrid_CLMS) mod ColorGrid_CLMS;
	        if (Input.pressedV) ColorGrid_Cursor_row = ((ColorGrid_Cursor_row+bit_dir(Input.pressedV)) + ColorGrid_ROWS) mod ColorGrid_ROWS;
	    }
	}







}
