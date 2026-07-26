/// @description  Input_update1()
function Input_update1() {


	GP_DPadR_pressed  = false;
	GP_DPadR_held     = false;
	GP_DPadR_released = false;
	//                              //
	GP_DPadL_pressed  = false;
	GP_DPadL_held     = false;
	GP_DPadL_released = false;
	//                              //
	GP_DPadD_pressed  = false;
	GP_DPadD_held     = false;
	GP_DPadD_released = false;
	//                              //
	GP_DPadU_pressed  = false;
	GP_DPadU_held     = false;
	GP_DPadU_released = false;
	//                              //
	//                              //
	GP_Face1_pressed  = false;
	GP_Face1_held     = false;
	GP_Face1_released = false;
	//                              //
	GP_Face2_pressed  = false;
	GP_Face2_held     = false;
	GP_Face2_released = false;
	//                              //
	GP_Face3_pressed  = false;
	GP_Face3_held     = false;
	GP_Face3_released = false;
	//                              //
	GP_Face4_pressed  = false;
	GP_Face4_held     = false;
	GP_Face4_released = false;
	//                              //
	//                              //
	GP_Select_pressed  = false;
	GP_Select_held     = false;
	GP_Select_released = false;
	//                              //
	GP_Start_pressed  = false;
	GP_Start_held     = false;
	GP_Start_released = false;
	//                              //
	//                              //
	GP_Shoulder1L_pressed  = false;
	GP_Shoulder1L_held     = false;
	GP_Shoulder1L_released = false;
	//                              //
	GP_Shoulder1R_pressed  = false;
	GP_Shoulder1R_held     = false;
	GP_Shoulder1R_released = false;
	//                              //
	GP_Shoulder2L_pressed  = false;
	GP_Shoulder2L_held     = false;
	GP_Shoulder2L_released = false;
	//                              //
	GP_Shoulder2R_pressed  = false;
	GP_Shoulder2R_held     = false;
	GP_Shoulder2R_released = false;
	//                              //
	GP_Jukebox_Next_pressed  = false;
	GP_Jukebox_Next_held     = false;
	GP_Jukebox_Next_released = false;
	//                              //
	GP_Jukebox_Prev_pressed  = false;
	GP_Jukebox_Prev_held     = false;
	GP_Jukebox_Prev_released = false;
	//                              //


	GP_pressed  = false;
	GP_held     = false;
	GP_released = false;




	// -----------------------------------------------------------------
	// -----------------------------------------------------------------
	if (gamepad_slot != -1)
	{
	    // Trying to fix issue which dpad not recognized on some controllers.
	    if (false  // Set to 'true' to turn off this fix in case it doesn't resolve the issue.
	    ||  gamepad_axis_count(gamepad_slot) )
	    {
	        // d-pad RIGHT
	        GP_DPadR_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_padr); // pressed
	        GP_DPadR_held     = gamepad_button_check(         gamepad_slot, gp_padr); // held
	        GP_DPadR_released = gamepad_button_check_released(gamepad_slot, gp_padr); // released
	        // d-pad LEFT
	        GP_DPadL_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_padl); // pressed
	        GP_DPadL_held     = gamepad_button_check(         gamepad_slot, gp_padl); // held
	        GP_DPadL_released = gamepad_button_check_released(gamepad_slot, gp_padl); // released
	        // d-pad DOWN
	        GP_DPadD_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_padd); // pressed
	        GP_DPadD_held     = gamepad_button_check(         gamepad_slot, gp_padd); // held
	        GP_DPadD_released = gamepad_button_check_released(gamepad_slot, gp_padd); // released
	        // d-pad UP
	        GP_DPadU_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_padu); // pressed
	        GP_DPadU_held     = gamepad_button_check(         gamepad_slot, gp_padu); // held
	        GP_DPadU_released = gamepad_button_check_released(gamepad_slot, gp_padu); // released
	    }
	    else
	    {   // Unverified: For controllers that don't have an analog stick, Windows thinks the dpad is the left analog stick.
	        var _stick_const = gp_axislh; // gp_axislh: Left Analog Stick horizontal axis
	        var _stick_val   = gamepad_button_value(gamepad_slot,_stick_const); // returns -1 to 1
	        // d-pad RIGHT
	        GP_DPadR_pressed  = _stick_val>0 && gamepad_button_check_pressed( gamepad_slot, _stick_const); // pressed
	        GP_DPadR_held     = _stick_val>0 && gamepad_button_check(         gamepad_slot, _stick_const); // held
	        GP_DPadR_released =                 gamepad_button_check_released(gamepad_slot, _stick_const); // released
	        // d-pad LEFT
	        GP_DPadL_pressed  = _stick_val<0 && gamepad_button_check_pressed( gamepad_slot, _stick_const); // pressed
	        GP_DPadL_held     = _stick_val<0 && gamepad_button_check(         gamepad_slot, _stick_const); // held
	        GP_DPadL_released =                 gamepad_button_check_released(gamepad_slot, _stick_const); // released
        
	        _stick_const = gp_axislv; // gp_axislv: Left Analog Stick vertical axis
	        _stick_val   = gamepad_button_value(gamepad_slot,_stick_const); // returns -1 to 1
	        // d-pad DOWN
	        GP_DPadD_pressed  = _stick_val>0 && gamepad_button_check_pressed( gamepad_slot, _stick_const); // pressed
	        GP_DPadD_held     = _stick_val>0 && gamepad_button_check(         gamepad_slot, _stick_const); // held
	        GP_DPadD_released =                 gamepad_button_check_released(gamepad_slot, _stick_const); // released
	        // d-pad UP
	        GP_DPadU_pressed  = _stick_val<0 && gamepad_button_check_pressed( gamepad_slot, _stick_const); // pressed
	        GP_DPadU_held     = _stick_val<0 && gamepad_button_check(         gamepad_slot, _stick_const); // held
	        GP_DPadU_released =                 gamepad_button_check_released(gamepad_slot, _stick_const); // released
	    }
    
	    // Xbox A button, PS CROSS button
	    GP_Face1_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_face1); // Xbox A button
	    GP_Face1_held     = gamepad_button_check(         gamepad_slot, gp_face1); // Xbox A button
	    GP_Face1_released = gamepad_button_check_released(gamepad_slot, gp_face1); // Xbox A button
	    // Xbox B button, PS CIRCLE button
	    GP_Face2_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_face2); // Xbox B button
	    GP_Face2_held     = gamepad_button_check(         gamepad_slot, gp_face2); // Xbox B button
	    GP_Face2_released = gamepad_button_check_released(gamepad_slot, gp_face2); // Xbox B button
	    // Xbox X button, PS SQUARE button
	    GP_Face3_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_face3); // Xbox X button
	    GP_Face3_held     = gamepad_button_check(         gamepad_slot, gp_face3); // Xbox X button
	    GP_Face3_released = gamepad_button_check_released(gamepad_slot, gp_face3); // Xbox X button
	    // Xbox Y button, PS TRIANGLE button
	    GP_Face4_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_face4); // Xbox Y button
	    GP_Face4_held     = gamepad_button_check(         gamepad_slot, gp_face4); // Xbox Y button
	    GP_Face4_released = gamepad_button_check_released(gamepad_slot, gp_face4); // Xbox Y button
    
	    // Xbox Select button, PS4 "options" button
	    GP_Select_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_select); // pressed
	    GP_Select_held     = gamepad_button_check(         gamepad_slot, gp_select); // held
	    GP_Select_released = gamepad_button_check_released(gamepad_slot, gp_select); // released
	    // Xbox Start  button, PS4 touch-pad press
	    GP_Start_pressed   = gamepad_button_check_pressed( gamepad_slot, gp_start); // pressed
	    GP_Start_held      = gamepad_button_check(         gamepad_slot, gp_start); // held
	    GP_Start_released  = gamepad_button_check_released(gamepad_slot, gp_start); // released
    
	    // LEFT  bumper
	    GP_Shoulder1L_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_shoulderl);
	    GP_Shoulder1L_held     = gamepad_button_check(         gamepad_slot, gp_shoulderl);
	    GP_Shoulder1L_released = gamepad_button_check_released(gamepad_slot, gp_shoulderl);
	    // RIGHT bumper
	    GP_Shoulder1R_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_shoulderr);
	    GP_Shoulder1R_held     = gamepad_button_check(         gamepad_slot, gp_shoulderr);
	    GP_Shoulder1R_released = gamepad_button_check_released(gamepad_slot, gp_shoulderr);
	    // LEFT  trigger
	    GP_Shoulder2L_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_shoulderlb);
	    GP_Shoulder2L_held     = gamepad_button_check(         gamepad_slot, gp_shoulderlb);
	    GP_Shoulder2L_released = gamepad_button_check_released(gamepad_slot, gp_shoulderlb);
	    // RIGHT trigger
	    GP_Shoulder2R_pressed  = gamepad_button_check_pressed( gamepad_slot, gp_shoulderrb);
	    GP_Shoulder2R_held     = gamepad_button_check(         gamepad_slot, gp_shoulderrb);
	    GP_Shoulder2R_released = gamepad_button_check_released(gamepad_slot, gp_shoulderrb);
    
    
    
    
	    GP_pressed = GP_DPadR_pressed 
	              || GP_DPadL_pressed 
	              || GP_DPadD_pressed 
	              || GP_DPadU_pressed 
	              || GP_Face1_pressed 
	              || GP_Face2_pressed 
	              || GP_Face3_pressed 
	              || GP_Face4_pressed 
	              || GP_Select_pressed 
	              || GP_Start_pressed 
	              || GP_Shoulder1L_pressed 
	              || GP_Shoulder1R_pressed 
	              || GP_Shoulder2L_pressed 
	              || GP_Shoulder2R_pressed;
	    //
	    GP_held    = GP_DPadR_held 
	              || GP_DPadL_held 
	              || GP_DPadD_held 
	              || GP_DPadU_held 
	              || GP_Face1_held 
	              || GP_Face2_held 
	              || GP_Face3_held 
	              || GP_Face4_held 
	              || GP_Select_held 
	              || GP_Start_held 
	              || GP_Shoulder1L_held 
	              || GP_Shoulder1R_held 
	              || GP_Shoulder2L_held 
	              || GP_Shoulder2R_held;
	    //
	    GP_released= GP_DPadR_released 
	              || GP_DPadL_released 
	              || GP_DPadD_released 
	              || GP_DPadU_released 
	              || GP_Face1_released 
	              || GP_Face2_released 
	              || GP_Face3_released 
	              || GP_Face4_released 
	              || GP_Select_released 
	              || GP_Start_released 
	              || GP_Shoulder1L_released 
	              || GP_Shoulder1R_released 
	              || GP_Shoulder2L_released 
	              || GP_Shoulder2R_released;
	    //
    
    
    
    
	    // ---------------------------------------------------------------------------
	    // d-pad RIGHT
	    GP_Right_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_right); // pressed
	    GP_Right_held     = gamepad_button_check(         gamepad_slot, GP_right); // held
	    GP_Right_released = gamepad_button_check_released(gamepad_slot, GP_right); // released
	    // d-pad LEFT
	    GP_Left_pressed   = gamepad_button_check_pressed( gamepad_slot, GP_left); // pressed
	    GP_Left_held      = gamepad_button_check(         gamepad_slot, GP_left); // held
	    GP_Left_released  = gamepad_button_check_released(gamepad_slot, GP_left); // released
	    // d-pad DOWN
	    GP_Down_pressed   = gamepad_button_check_pressed( gamepad_slot, GP_down); // pressed
	    GP_Down_held      = gamepad_button_check(         gamepad_slot, GP_down); // held
	    GP_Down_released  = gamepad_button_check_released(gamepad_slot, GP_down); // released
	    // d-pad UP
	    GP_Up_pressed     = gamepad_button_check_pressed( gamepad_slot, GP_up); // pressed
	    GP_Up_held        = gamepad_button_check(         gamepad_slot, GP_up); // held
	    GP_Up_released    = gamepad_button_check_released(gamepad_slot, GP_up); // released
    
	    // Xbox Select button, PS4 "options" button
	    GP_Magic_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_magic); // pressed
	    GP_Magic_held     = gamepad_button_check(         gamepad_slot, GP_magic); // held
	    GP_Magic_released = gamepad_button_check_released(gamepad_slot, GP_magic); // released

	    // Quick spell cycle: NEXT / PREV (default Bumper R / Bumper L)
	    GP_Spell_Next_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_spell_next);
	    GP_Spell_Next_held     = gamepad_button_check(         gamepad_slot, GP_spell_next);
	    GP_Spell_Next_released = gamepad_button_check_released(gamepad_slot, GP_spell_next);
	    GP_Spell_Prev_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_spell_prev);
	    GP_Spell_Prev_held     = gamepad_button_check(         gamepad_slot, GP_spell_prev);
	    GP_Spell_Prev_released = gamepad_button_check_released(gamepad_slot, GP_spell_prev);
	    // Jukebox track skip: NEXT (R2 / gp_shoulderrb) / PREV (L2 / gp_shoulderlb)
	    //
	    // ANALOG-TRIGGER FIX (2026-07-26): gp_shoulderlb / gp_shoulderrb are the ANALOG
	    // triggers, and a DualShock 4 reports those as AXES, not buttons. On that pad
	    // gamepad_button_check_pressed() never returns true no matter how hard you pull,
	    // so pad track-skip was simply dead while the keyboard worked -- reported as
	    // "L2/R2 do nothing" (master bug list B78).
	    //
	    // gamepad_button_value() returns the 0..1 analog position for a trigger, and
	    // 0 or 1 for a plain digital button, so reading it covers BOTH pad styles. We
	    // OR it with the digital check so nothing regresses on pads where the digital
	    // read already worked, and derive the pressed/released EDGES ourselves from the
	    // previous frame's state, because the built-in edge functions are exactly what
	    // fails here.
	    //
	    // 0.5 threshold: a trigger has to be pulled about halfway, which stops a resting
	    // or slightly-drifting trigger from spamming track changes.
	    //
	    // The previous state is kept in GP_Jukebox_*_was, NOT in the _held vars: every
	    // GP_*_held is reset to false at the top of this script each frame, so testing
	    // against _held would report a fresh PRESS on every frame the trigger stayed
	    // down -- one track skip per frame. _was is only written here and survives that
	    // reset, so the edge is real.
	    var _jb_n_now = gamepad_button_check(gamepad_slot, GP_jukebox_next)
	                 || (gamepad_button_value(gamepad_slot, GP_jukebox_next) > 0.5);
	    var _jb_p_now = gamepad_button_check(gamepad_slot, GP_jukebox_prev)
	                 || (gamepad_button_value(gamepad_slot, GP_jukebox_prev) > 0.5);

	    GP_Jukebox_Next_pressed  =  _jb_n_now && !GP_Jukebox_Next_was;
	    GP_Jukebox_Next_released = !_jb_n_now &&  GP_Jukebox_Next_was;
	    GP_Jukebox_Next_held     =  _jb_n_now;
	    GP_Jukebox_Next_was      =  _jb_n_now;

	    GP_Jukebox_Prev_pressed  =  _jb_p_now && !GP_Jukebox_Prev_was;
	    GP_Jukebox_Prev_released = !_jb_p_now &&  GP_Jukebox_Prev_was;
	    GP_Jukebox_Prev_held     =  _jb_p_now;
	    GP_Jukebox_Prev_was      =  _jb_p_now;
	    // Xbox Start  button, PS4 touch-pad press
	    GP_Pause_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_pause); // pressed
	    GP_Pause_held     = gamepad_button_check(         gamepad_slot, GP_pause); // held
	    GP_Pause_released = gamepad_button_check_released(gamepad_slot, GP_pause); // released
    
	    // Xbox X button, PS SQUARE button
	    GP_Attack_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_attack);
	    GP_Attack_held     = gamepad_button_check(         gamepad_slot, GP_attack);
	    GP_Attack_released = gamepad_button_check_released(gamepad_slot, GP_attack);
	    // Xbox A button, PS CROSS button
	    GP_Jump_pressed    = gamepad_button_check_pressed( gamepad_slot, GP_jump);
	    GP_Jump_held       = gamepad_button_check(         gamepad_slot, GP_jump);
	    GP_Jump_released   = gamepad_button_check_released(gamepad_slot, GP_jump);
    
	    // Xbox B button, PS CIRCLE button
	    GP_Other1_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_other1);
	    GP_Other1_held     = gamepad_button_check(         gamepad_slot, GP_other1);
	    GP_Other1_released = gamepad_button_check_released(gamepad_slot, GP_other1);
	    // Xbox Y button, PS TRIANGLE button
	    GP_Other2_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_other2);
	    GP_Other2_held     = gamepad_button_check(         gamepad_slot, GP_other2);
	    GP_Other2_released = gamepad_button_check_released(gamepad_slot, GP_other2);
    
	    // LEFT  bumper
	    GP_Other3_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_other3);
	    GP_Other3_held     = gamepad_button_check(         gamepad_slot, GP_other3);
	    GP_Other3_released = gamepad_button_check_released(gamepad_slot, GP_other3);
	    // RIGHT bumper
	    GP_Other4_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_other4);
	    GP_Other4_held     = gamepad_button_check(         gamepad_slot, GP_other4);
	    GP_Other4_released = gamepad_button_check_released(gamepad_slot, GP_other4);
	    // LEFT  trigger
	    GP_Other5_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_other5);
	    GP_Other5_held     = gamepad_button_check(         gamepad_slot, GP_other5);
	    GP_Other5_released = gamepad_button_check_released(gamepad_slot, GP_other5);
	    // RIGHT trigger
	    GP_Other6_pressed  = gamepad_button_check_pressed( gamepad_slot, GP_other6);
	    GP_Other6_held     = gamepad_button_check(         gamepad_slot, GP_other6);
	    GP_Other6_released = gamepad_button_check_released(gamepad_slot, GP_other6);
	}







}
