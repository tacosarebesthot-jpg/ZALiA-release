/// @description  PaletteEditor_Step_1()
function PaletteEditor_Step_1() {


	// DEV GATE (2026-07-27, round 2). CTRL+P was gated in PaletteEditor_Step, but
	// BARE 'P' was not: it toggles the all-palettes overlay, which a player found
	// immediately after ctrl+P stopped working. Also forces the overlay OFF rather
	// than merely refusing to toggle it -- otherwise an overlay left on during a dev
	// session stays burned on screen with its only off-switch now unreachable.
	var _PAL_DEV = dev_avail();
	if (!_PAL_DEV) PalView_enabled = false;

	if (state==state_EDIT1A
	||  state==state_EDIT1B
	||  state==state_BGR_COLOR )
	{   // if in an edit mode
	    PalView_enabled = false;
	}
	else if (PP0 && _PAL_DEV) // PP0: Only 'P' pressed
	{   // Toggle show all palettes
	    PalView_enabled = !PalView_enabled;
	}
	else if (state==state_IDLE)
	//&&  g.gui_state!=g.gui_state_EDIT_PAL )
	{
	    /*
	    // Turn off palette randomizing & restore default palette
	    if (PP && ALT && CTL)
	    {
	        change_pal(p.pal_rm_def);
	        var _COLOR = val(g.dm_rm[?g.rm_name+dk_BackgroundColor], p.C_ERR0);
	        set_background_color(_COLOR);
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	    */
    
	    // Randomize palette right now. DEV-gated 2026-07-27: CTRL+SHIFT+P recolours
	    // the whole room for anyone who hits it, and there is no undo -- a player who
	    // trips this just thinks the game's art broke.
	    if (_PAL_DEV
	    && ((PP && CTL && SHF)
	    ||  (Input.GP_Other6_held && Input.GP_Other1_held && Input.GP_Other2_pressed)) ) // hold(TrigR + XBox-B), press(XBox-Y)
	    {
	        var _i, _pi, _palette;
	        _palette = p.pal_rm_curr;
        
	        for(_i=0; _i<PalEdit_PAL_COUNT; _i++)
	        {
	            _pi = val(PalEdit_dm[?STR_Palette+hex_str(_i+1)+STR_Palette+STR_Index]);
	            _palette = strReplaceAt(_palette, get_pal_pos(_pi), global.PAL_CHAR_PER_PAL, get_random_palette2(-1));
	            //_palette = strReplaceAt(_palette, get_pal_pos(_pi), global.PAL_CHAR_PER_PAL, get_random_palette1(1,true));
	        }
        
	        change_pal(_palette);
	    }
	}







}
