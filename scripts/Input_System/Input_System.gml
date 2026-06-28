/// @description  Input_System()
function Input_System() {


	var _TYPE = async_load[?"event_type"];
	var _SLOT = async_load[?"pad_index"];
	if(!is_undefined(_TYPE) 
	&& !is_undefined(_SLOT) )
	{
	    switch(_TYPE)
	    {
	        // =========================================================================
	        // ------------------------------------------------------------------
	        case "gamepad discovered":{
	        if (gamepad_slot==-1) gamepad_slot = _SLOT;
	        // CO-OP P2 is NOT auto-captured on connect anymore. The old auto-bind of the
	        // first "extra" slot made a single physical controller that enumerates as TWO
	        // gamepad slots (e.g. a PS4 pad through DS4Windows = native DS4 + emulated
	        // XInput) drive BOTH players: the phantom 2nd slot mirrored P1. P2 now joins
	        // ONLY by a deliberate, NON-mirrored button press on a separate pad, handled
	        // in Input_update_p2(). Never bind gamepad_slot_p2 here.

	        gamepad_name = gamepad_get_description(_SLOT);
	        show_debug_message("gamepad discovered"+", slot: "+string(_SLOT)+", gamepad name: "+gamepad_name);

	        // Re-apply a saved hand-calibrated SDL mapping for this pad, if one exists.
	        var _guid = gamepad_get_guid(_SLOT);
	        var _sdlmap = dm_UserInputConfig[?_guid+"_sdlmap"];
	        if (!is_undefined(_sdlmap))
	        {   gamepad_test_mapping(_SLOT, _sdlmap);
	            show_debug_message("  re-applied calibrated mapping for guid "+string(_guid));
	        }
        
	        gamepad_set_axis_deadzone(   _SLOT, 0.5); // Set the "deadzone" for the axis
	        gamepad_set_button_threshold(_SLOT, 0.1); // Set the "threshold" for the triggers
        
        
	        var _num = dm_UserInputConfig[?gamepad_name+"_gamepad_num"];
	        if(!is_undefined(_num))
	        {
	            var _DATAKEY = "gamepad"+hex_str(_num)+"_gp_";
            
	            GP_right  = val(dm_UserInputConfig[?_DATAKEY+"right"],  GP_right_DEFAULT);
	            GP_left   = val(dm_UserInputConfig[?_DATAKEY+"left"],   GP_left_DEFAULT);
	            GP_down   = val(dm_UserInputConfig[?_DATAKEY+"down"],   GP_down_DEFAULT);
	            GP_up     = val(dm_UserInputConfig[?_DATAKEY+"up"],     GP_up_DEFAULT);
	            //                                                                      //
	            GP_magic  = val(dm_UserInputConfig[?_DATAKEY+"magic"],  GP_magic_DEFAULT);
	            GP_pause  = val(dm_UserInputConfig[?_DATAKEY+"pause"],  GP_pause_DEFAULT);
	            //                                                                      //
	            GP_jump   = val(dm_UserInputConfig[?_DATAKEY+"jump"],   GP_jump_DEFAULT);
	            GP_attack = val(dm_UserInputConfig[?_DATAKEY+"attack"], GP_attack_DEFAULT);
	            //                                                                      //
	            GP_other1 = val(dm_UserInputConfig[?_DATAKEY+"other1"], GP_other1_DEFAULT);
	            GP_other2 = val(dm_UserInputConfig[?_DATAKEY+"other2"], GP_other2_DEFAULT);
	            GP_other3 = val(dm_UserInputConfig[?_DATAKEY+"other3"], GP_other3_DEFAULT);
	            GP_other4 = val(dm_UserInputConfig[?_DATAKEY+"other4"], GP_other4_DEFAULT);
	            GP_other5 = val(dm_UserInputConfig[?_DATAKEY+"other5"], GP_other5_DEFAULT);
	            GP_other6 = val(dm_UserInputConfig[?_DATAKEY+"other6"], GP_other6_DEFAULT);
	            //                                                                      //
	            GP_spell_next = val(dm_UserInputConfig[?_DATAKEY+"spell_next"], GP_spell_next_DEFAULT);
	            GP_spell_prev = val(dm_UserInputConfig[?_DATAKEY+"spell_prev"], GP_spell_prev_DEFAULT);
	            //                                                                      //
	            GP_jukebox_next = val(dm_UserInputConfig[?_DATAKEY+"jukebox_next"], GP_jukebox_next_DEFAULT);
	            GP_jukebox_prev = val(dm_UserInputConfig[?_DATAKEY+"jukebox_prev"], GP_jukebox_prev_DEFAULT);
	            //                                                                      //
	            //show_debug_message("_gamepad_num "+hex_str(_num)+", "+_DATAKEY);
	            //show_debug_message("GP_magic "+string(GP_magic)+", GP_magic_DEFAULT "+string(GP_magic_DEFAULT)+", gp_shoulderlb "+string(gp_shoulderlb));
	            //show_debug_message("GP_magic==GP_magic_DEFAULT: "+string(GP_magic==GP_magic_DEFAULT)+", GP_magic==gp_shoulderlb: "+string(GP_magic==gp_shoulderlb));
	        }
	        else
	        {
	            gamepad_set_default();
	        }
	        break;}//case "gamepad discovered"
        
        
        
        
        
        
	        // =========================================================================
	        // ------------------------------------------------------------------
	        case "gamepad lost":{
	        gamepad_name = gamepad_get_description(_SLOT);
	        show_debug_message("gamepad lost"+", slot: "+string(_SLOT)+", gamepad name: "+gamepad_name);
        
	        if (gamepad_slot == _SLOT)
	        {   gamepad_slot =  -1;  }
	        if (gamepad_slot_p2 == _SLOT) // CO-OP P2: release the fairy's pad if it unplugs
	        {   gamepad_slot_p2 = -1;  }
	        break;}//case "gamepad lost"
	    }//switch(_TYPE)
	}







}
