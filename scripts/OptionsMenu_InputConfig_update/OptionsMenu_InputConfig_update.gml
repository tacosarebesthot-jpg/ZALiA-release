/// @description  OptionsMenu_InputConfig_update()
function OptionsMenu_InputConfig_update() {


	// Keyboard rebind persistence: write all Key_* into the json-encoded config map + save.
	var _kb_persist = function()
	{
	    with(Input)
	    {
	        dm_UserInputConfig[?"keyboard_right"] =Key_right;  dm_UserInputConfig[?"keyboard_right_alt"] =Key_right_alt;
	        dm_UserInputConfig[?"keyboard_left"]  =Key_left;   dm_UserInputConfig[?"keyboard_left_alt"]  =Key_left_alt;
	        dm_UserInputConfig[?"keyboard_down"]  =Key_down;   dm_UserInputConfig[?"keyboard_down_alt"]  =Key_down_alt;
	        dm_UserInputConfig[?"keyboard_up"]    =Key_up;     dm_UserInputConfig[?"keyboard_up_alt"]    =Key_up_alt;
	        dm_UserInputConfig[?"keyboard_pause"] =Key_pause;  dm_UserInputConfig[?"keyboard_pause_alt"] =Key_pause_alt;
	        dm_UserInputConfig[?"keyboard_magic"] =Key_magic;  dm_UserInputConfig[?"keyboard_magic_alt"] =Key_magic_alt;
	        dm_UserInputConfig[?"keyboard_attack"]=Key_attack; dm_UserInputConfig[?"keyboard_attack_alt"]=Key_attack_alt;
	        dm_UserInputConfig[?"keyboard_jump"]  =Key_jump;   dm_UserInputConfig[?"keyboard_jump_alt"]  =Key_jump_alt;
	        dm_UserInputConfig[?"keyboard_spell_next"]=Key_spell_next; dm_UserInputConfig[?"keyboard_spell_next_alt"]=Key_spell_next_alt;
	        dm_UserInputConfig[?"keyboard_spell_prev"]=Key_spell_prev; dm_UserInputConfig[?"keyboard_spell_prev_alt"]=Key_spell_prev_alt;
	        dm_UserInputConfig[?"keyboard_tracker_toggle"]=Key_tracker_toggle; dm_UserInputConfig[?"keyboard_tracker_toggle_alt"]=Key_tracker_toggle_alt;
	        dm_UserInputConfig[?"keyboard_jukebox_toggle"]=Key_jukebox_toggle; dm_UserInputConfig[?"keyboard_jukebox_toggle_alt"]=Key_jukebox_toggle_alt;
	        dm_UserInputConfig[?"keyboard_jukebox_prev"]  =Key_jukebox_prev;   dm_UserInputConfig[?"keyboard_jukebox_prev_alt"]  =Key_jukebox_prev_alt;
	        dm_UserInputConfig[?"keyboard_jukebox_next"]  =Key_jukebox_next;   dm_UserInputConfig[?"keyboard_jukebox_next_alt"]  =Key_jukebox_next_alt;
	        dm_UserInputConfig[?"keyboard_jukebox_assign"]=Key_jukebox_assign; dm_UserInputConfig[?"keyboard_jukebox_assign_alt"]=Key_jukebox_assign_alt;
	    }
	    save_game_pref();
	};

	switch(InputConfigState)
	{
	    // ====================================================================
	    // -----------------------------------------------------------
	    case InputConfigState_MAIN:{
	    //if (timer2) break;//case InputConfigState_MAIN
    
	    if(!timer)
	    {
	        var _CLOSE = Backout_requested;
	        if(!_CLOSE)
	        {
	            if (keyboard_check_pressed(vk_space) 
	            ||  keyboard_check_pressed(vk_enter) 
	            ||  a_button_pressed 
	            ||  start_button_pressed )
	            {
	                if (InputSection == InputSection_KEYBOARD)
	                {
	                    if (InputConfigOption == KbOption_BACK) _CLOSE = true;
	                    else if (InputConfigOption == KbOption_DEFAULT)
	                    {   with(Input){ Key_right=Key_right_DEFAULT;Key_right_alt=Key_right_alt_DEFAULT;Key_left=Key_left_DEFAULT;Key_left_alt=Key_left_alt_DEFAULT;Key_down=Key_down_DEFAULT;Key_down_alt=Key_down_alt_DEFAULT;Key_up=Key_up_DEFAULT;Key_up_alt=Key_up_alt_DEFAULT;Key_pause=Key_pause_DEFAULT;Key_pause_alt=Key_pause_alt_DEFAULT;Key_magic=Key_magic_DEFAULT;Key_magic_alt=Key_magic_alt_DEFAULT;Key_attack=Key_attack_DEFAULT;Key_attack_alt=Key_attack_alt_DEFAULT;Key_jump=Key_jump_DEFAULT;Key_jump_alt=Key_jump_alt_DEFAULT;Key_spell_next=Key_spell_next_DEFAULT;Key_spell_next_alt=Key_spell_next_alt_DEFAULT;Key_spell_prev=Key_spell_prev_DEFAULT;Key_spell_prev_alt=Key_spell_prev_alt_DEFAULT;Key_tracker_toggle=Key_tracker_toggle_DEFAULT;Key_tracker_toggle_alt=Key_tracker_toggle_alt_DEFAULT;Key_jukebox_toggle=Key_jukebox_toggle_DEFAULT;Key_jukebox_toggle_alt=Key_jukebox_toggle_alt_DEFAULT;Key_jukebox_prev=Key_jukebox_prev_DEFAULT;Key_jukebox_prev_alt=Key_jukebox_prev_alt_DEFAULT;Key_jukebox_next=Key_jukebox_next_DEFAULT;Key_jukebox_next_alt=Key_jukebox_next_alt_DEFAULT;Key_jukebox_assign=Key_jukebox_assign_DEFAULT;Key_jukebox_assign_alt=Key_jukebox_assign_alt_DEFAULT; }
	                        _kb_persist(); aud_play_sound(CONFIRM_SOUND1); timer=DURATION1;
	                    }
	                    else { aud_play_sound(CONFIRM_SOUND1); timer=DURATION1; KbEdit_clear=false; InputConfigState=InputConfigState_KB_EDITING; exit; }
	                }
	                else if (InputSection == InputSection_DEBUG)
	                {
	                    if (InputConfigOption == DbgOption_BACK) _CLOSE = true;
	                    // BACK DOOR CLOSED (2026-07-26): this row jumped straight into DEV
	                    // TOOLS with no check, so hiding the DEV TOOLS row on the MAIN menu
	                    // achieved nothing -- any player could reach the cheats and sweeps
	                    // through EDIT CONTROLS > DEBUG. Same gate as the MAIN row now.
	                    else if (InputConfigOption == DbgOption_CHEATS) { if (dev_avail()) { aud_play_sound(CONFIRM_SOUND1); timer=DURATION1; menu_state=menu_state_DEV_TOOLS; } else { aud_play_sound(BACK_SOUND1); timer=DURATION1; } }
	                    else { aud_play_sound(BACK_SOUND1); timer=DURATION1; }
	                }
	                else
	                switch(InputConfigOption)
	                {
	                    case InputConfigOption_BACK:{
	                    _CLOSE = true;
	                    break;}//switch(InputConfigOption)
                    
	                    case InputConfigOption_DEFAULT:{
	                    gamepad_set_default();
	                    aud_play_sound(CONFIRM_SOUND1);
	                    timer = DURATION1;
	                    break;}//switch(InputConfigOption)

	                    case InputConfigOption_CALIBRATE:{
	                    if (Input.gamepad_slot == -1)
	                    {   aud_play_sound(BACK_SOUND1);
	                        Calib_msg = "NO CONTROLLER DETECTED";
	                        timer = DURATION1;
	                    }
	                    else
	                    {   Calib_active      = true;
	                        Calib_step        = 0;
	                        Calib_bindings    = "";
	                        Calib_input_clear = false; // wait for a clean release first
	                        Calib_msg         = "";
	                        aud_play_sound(CONFIRM_SOUND1);
	                        timer = DURATION1;
	                        InputConfigState  = InputConfigState_CALIBRATE;
	                        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	                    }
	                    break;}//switch(InputConfigOption)

	                    default:{
	                    aud_play_sound(CONFIRM_SOUND1);
	                    timer = DURATION1;
	                    //timer = $10;
	                    InputConfigState = InputConfigState_EDITING;
	                    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	                    break;}//switch(InputConfigOption)
	                }
	            }
	        }
        
	        if (_CLOSE)
	        {
	            aud_play_sound(BACK_SOUND1);
	            timer = DURATION1;
	            menu_state = menu_state_MAIN;
	            break;//case InputConfigState_MAIN
	        }
	    }
    
    
    
	    // update cursor
	    if(!timer2)
	    {
	        // active section's option count
	        var _oc = InputConfigOption_COUNT;
	        if (InputSection==InputSection_KEYBOARD) _oc = KbOption_COUNT;
	        else if (InputSection==InputSection_DEBUG) _oc = DbgOption_COUNT;

	        // LEFT / RIGHT: cycle section (KEYBOARD / GAMEPLAY / DEBUG)
	        if (left_input_pressed || right_input_pressed)
	        {
	            var _sd = -1; if (right_input_pressed) _sd = 1;
	            InputSection += InputSection_COUNT + _sd;
	            InputSection  = InputSection mod InputSection_COUNT;
	            InputConfigOption = 0;
	            aud_play_sound(CURSOR_SOUND1);
	            timer2 = DURATION2;
	            break;//case InputConfigState_MAIN
	        }

	        // UP / DOWN: move cursor within the active section
	        var     _Cursor_DIR = bit_dir(gui_tmr_cursor_v()); // 0,1,-1
	        if (abs(_Cursor_DIR))
	        {
	            InputConfigOption += _oc;
	            InputConfigOption += _Cursor_DIR; // 1,-1
	            InputConfigOption  = InputConfigOption mod _oc;
	            aud_play_sound(CURSOR_SOUND1);
	            timer2 = DURATION2;
	            break;//case InputConfigState_MAIN
	        }
	    }
	    break;}//case InputConfigState_MAIN
    
    
    
    
    
    
    
    
	    // ====================================================================
	    // -----------------------------------------------------------
	    case InputConfigState_EDITING:{
	    if (timer) break;//case InputConfigState_EDITING
    
	    if (keyboard_check_pressed(vk_escape) 
	    ||  keyboard_check_pressed(vk_backspace) )
	    //if (OpenClose_Key_pressed 
	    //||  keyboard_check_pressed(vk_escape) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        InputConfigState = InputConfigState_MAIN;
	        break;//case InputConfigState_EDITING
	    }
    
    
	    if (Input.GP_pressed)
	    {
	        var                                   _pressed_val=0;
	             if (Input.GP_DPadR_pressed)      _pressed_val=gp_padr; // dpad right
	        else if (Input.GP_DPadL_pressed)      _pressed_val=gp_padl; // dpad left
	        else if (Input.GP_DPadD_pressed)      _pressed_val=gp_padd; // dpad down
	        else if (Input.GP_DPadU_pressed)      _pressed_val=gp_padu; // dpad up
	        else if (Input.GP_Face1_pressed)      _pressed_val=gp_face1; // Xbox A button
	        else if (Input.GP_Face2_pressed)      _pressed_val=gp_face2; // Xbox B button
	        else if (Input.GP_Face3_pressed)      _pressed_val=gp_face3; // Xbox X button
	        else if (Input.GP_Face4_pressed)      _pressed_val=gp_face4; // Xbox Y button
	        else if (Input.GP_Select_pressed)     _pressed_val=gp_select;
	        else if (Input.GP_Start_pressed)      _pressed_val=gp_start;
	        else if (Input.GP_Shoulder1L_pressed) _pressed_val=gp_shoulderl;  // Bumper L
	        else if (Input.GP_Shoulder1R_pressed) _pressed_val=gp_shoulderr;  // Bumper R
	        else if (Input.GP_Shoulder2L_pressed) _pressed_val=gp_shoulderlb; // Trigger L
	        else if (Input.GP_Shoulder2R_pressed) _pressed_val=gp_shoulderrb; // Trigger R
        
	        var                              _option_val=0;
	        switch(InputConfigOption){
	        case   InputConfigOption_RIGHT: {_option_val=Input.GP_right;  break;}
	        case   InputConfigOption_LEFT:  {_option_val=Input.GP_left;   break;}
	        case   InputConfigOption_DOWN:  {_option_val=Input.GP_down;   break;}
	        case   InputConfigOption_UP:    {_option_val=Input.GP_up;     break;}
	        case   InputConfigOption_MAGIC: {_option_val=Input.GP_magic;  break;}
	        case   InputConfigOption_PAUSE: {_option_val=Input.GP_pause;  break;}
	        case   InputConfigOption_ATTACK:{_option_val=Input.GP_attack; break;}
	        case   InputConfigOption_JUMP:  {_option_val=Input.GP_jump;   break;}
        case   InputConfigOption_SPELL_NEXT:{_option_val=Input.GP_spell_next; break;}
        case   InputConfigOption_SPELL_PREV:{_option_val=Input.GP_spell_prev; break;}
        case   InputConfigOption_JUKEBOX_NEXT:{_option_val=Input.GP_jukebox_next; break;}
        case   InputConfigOption_JUKEBOX_PREV:{_option_val=Input.GP_jukebox_prev; break;}
	        }
        
	        if (_pressed_val 
	        &&  _option_val )
	        {
	            if (_option_val != _pressed_val )
	            {
	                // Swap with any action already set to _pressed_val (to prevent duplicate assignments)
	                switch(_pressed_val){
	                case Input.GP_right: {Input.GP_right =_option_val; break;}
	                case Input.GP_left:  {Input.GP_left  =_option_val; break;}
	                case Input.GP_down:  {Input.GP_down  =_option_val; break;}
	                case Input.GP_up:    {Input.GP_up    =_option_val; break;}
	                case Input.GP_magic: {Input.GP_magic =_option_val; break;}
	                case Input.GP_pause: {Input.GP_pause =_option_val; break;}
	                case Input.GP_attack:{Input.GP_attack=_option_val; break;} // XBox X
	                case Input.GP_jump:  {Input.GP_jump  =_option_val; break;} // XBox A
	                case Input.GP_other1:{Input.GP_other1=_option_val; break;} // XBox B
	                case Input.GP_other2:{Input.GP_other2=_option_val; break;} // XBox Y
	                case Input.GP_other3:{Input.GP_other3=_option_val; break;} // Bumper L
	                case Input.GP_other4:{Input.GP_other4=_option_val; break;} // Bumper R
	                case Input.GP_other5:{Input.GP_other5=_option_val; break;} // Trigger L
	                case Input.GP_other6:{Input.GP_other6=_option_val; break;} // Trigger R
	                case Input.GP_spell_next:{Input.GP_spell_next=_option_val; break;}
	                case Input.GP_spell_prev:{Input.GP_spell_prev=_option_val; break;}
	                case Input.GP_jukebox_next:{Input.GP_jukebox_next=_option_val; break;}
	                case Input.GP_jukebox_prev:{Input.GP_jukebox_prev=_option_val; break;}
	                }
                
	                // Set action to button pressed
	                switch(InputConfigOption){
	                case   InputConfigOption_RIGHT: {Input.GP_right =_pressed_val; break;}
	                case   InputConfigOption_LEFT:  {Input.GP_left  =_pressed_val; break;}
	                case   InputConfigOption_DOWN:  {Input.GP_down  =_pressed_val; break;}
	                case   InputConfigOption_UP:    {Input.GP_up    =_pressed_val; break;}
	                case   InputConfigOption_MAGIC: {Input.GP_magic =_pressed_val; break;}
	                case   InputConfigOption_PAUSE: {Input.GP_pause =_pressed_val; break;}
	                case   InputConfigOption_ATTACK:{Input.GP_attack=_pressed_val; break;}
	                case   InputConfigOption_JUMP:  {Input.GP_jump  =_pressed_val; break;}
	                case   InputConfigOption_SPELL_NEXT:{Input.GP_spell_next=_pressed_val; break;}
	                case   InputConfigOption_SPELL_PREV:{Input.GP_spell_prev=_pressed_val; break;}
	                case   InputConfigOption_JUKEBOX_NEXT:{Input.GP_jukebox_next=_pressed_val; break;}
	                case   InputConfigOption_JUKEBOX_PREV:{Input.GP_jukebox_prev=_pressed_val; break;}
	                }
                
                
	                with(Input)
	                {
	                    var _datakey,_datakey1;
	                    var _GP_NAME = gamepad_get_description(gamepad_slot);
                    
	                    var _num = val(dm_UserInputConfig[?_GP_NAME+"_gamepad_num"]);
	                    if(!_num) // New gamepad
	                    {   _num=0;
	                        while(true)
	                        {   _datakey = "gamepad"+hex_str(++_num);
	                            if (is_undefined(dm_UserInputConfig[?_datakey+"_name"])) break;//while(true)
	                        }
	                    }
                    
	                    _datakey  = "gamepad"+hex_str(_num);
	                    _datakey1 = _datakey+"_gp_";
                    
	                    dm_UserInputConfig[?_GP_NAME+"_gamepad_num"]= _num;
	                    dm_UserInputConfig[?_datakey+"_name"]       = _GP_NAME;
                    
	                    dm_UserInputConfig[?_datakey1+"right"]      = GP_right;
	                    dm_UserInputConfig[?_datakey1+"left"]       = GP_left;
	                    dm_UserInputConfig[?_datakey1+"down"]       = GP_down;
	                    dm_UserInputConfig[?_datakey1+"up"]         = GP_up;
                    
	                    dm_UserInputConfig[?_datakey1+"magic"]      = GP_magic;
	                    dm_UserInputConfig[?_datakey1+"pause"]      = GP_pause;
                    
	                    dm_UserInputConfig[?_datakey1+"jump"]       = GP_jump;   // Xbox A
	                    dm_UserInputConfig[?_datakey1+"attack"]     = GP_attack; // Xbox X
                    
	                    dm_UserInputConfig[?_datakey1+"other1"]     = GP_other1; // Xbox B
	                    dm_UserInputConfig[?_datakey1+"other2"]     = GP_other2; // Xbox Y
	                    dm_UserInputConfig[?_datakey1+"other3"]     = GP_other3; // bump L
	                    dm_UserInputConfig[?_datakey1+"other4"]     = GP_other4; // bump R
	                    dm_UserInputConfig[?_datakey1+"other5"]     = GP_other5; // trig L
	                    dm_UserInputConfig[?_datakey1+"other6"]     = GP_other6; // trig R
	                    dm_UserInputConfig[?_datakey1+"spell_next"] = GP_spell_next;
	                    dm_UserInputConfig[?_datakey1+"spell_prev"] = GP_spell_prev;
	                    dm_UserInputConfig[?_datakey1+"jukebox_next"] = GP_jukebox_next;
	                    dm_UserInputConfig[?_datakey1+"jukebox_prev"] = GP_jukebox_prev;
                    
	                    //sdm(" User input config saved. "+"Gamepad name: "+_GP_NAME+", _gamepad_num "+hex_str(_num)+", "+_datakey1);
	                }
                
                
	                save_game_pref();
	                aud_play_sound(CONFIRM_SOUND1);
	                //aud_play_sound(CONFIRM_SOUND2);
	                timer = DURATION1;
	            }
	        }
	        else
	        {
	            aud_play_sound(BACK_SOUND1);
	            timer = DURATION1;
	        }
        
	        InputConfigState = InputConfigState_MAIN;
	    }
	    break;}//case InputConfigState_EDITING




	    // ====================================================================
	    // -----------------------------------------------------------
	    case InputConfigState_CALIBRATE:{
	    if (timer) break;//case InputConfigState_CALIBRATE

	    var _slot = Input.gamepad_slot;

	    // Pad vanished mid-calibration -> bail safely.
	    if (_slot == -1)
	    {   aud_play_sound(BACK_SOUND1);
	        Calib_active = false;
	        Calib_msg = "CONTROLLER LOST";
	        timer = DURATION1;
	        InputConfigState = InputConfigState_MAIN;
	        break;//case InputConfigState_CALIBRATE
	    }

	    // ESC / BACKSPACE aborts the whole wizard.
	    if (keyboard_check_pressed(vk_escape)
	    ||  keyboard_check_pressed(vk_backspace) )
	    {   aud_play_sound(BACK_SOUND1);
	        Calib_active = false;
	        Calib_msg = "CALIBRATION CANCELLED";
	        timer = DURATION1;
	        InputConfigState = InputConfigState_MAIN;
	        break;//case InputConfigState_CALIBRATE
	    }

	    // Scan every RAW input on the pad (ignores any existing SDL mapping).
	    var _tok = "";
	    var _n, _k, _v;
	    _n = gamepad_button_count(_slot);
	    for(_k=0; _k<_n; _k++) { if (gamepad_button_check(_slot,_k)) { _tok = "b"+string(_k); break; } }
	    if (_tok=="")
	    {   _n = gamepad_axis_count(_slot);
	        for(_k=0; _k<_n; _k++) { _v = gamepad_axis_value(_slot,_k); if (abs(_v)>0.7) { _tok = "a"+string(_k); break; } }
	    }
	    if (_tok=="")
	    {   _n = gamepad_hat_count(_slot);
	        for(_k=0; _k<_n; _k++) { _v = gamepad_hat_value(_slot,_k); if (_v!=0) { _tok = "h"+string(_k)+"."+string(_v); break; } }
	    }

	    // Require a clean release between captures so one press != many.
	    if (!Calib_input_clear)
	    {   if (_tok=="") Calib_input_clear = true;
	        break;//case InputConfigState_CALIBRATE
	    }

	    // SPACE skips the current input (pad may not have it).
	    var _skip = keyboard_check_pressed(vk_space);

	    if (_tok!="" || _skip)
	    {
	        if (_tok!="")
	        {   Calib_bindings += string(Calib_dg[#0,Calib_step]) + ":" + _tok + ",";
	            aud_play_sound(CURSOR_SOUND1);
	        }
	        else aud_play_sound(BACK_SOUND1);

	        Calib_step++;
	        Calib_input_clear = false;

	        if (Calib_step >= Calib_COUNT)
	        {
	            // Build + apply the full SDL mapping string for this pad.
	            var _guid = gamepad_get_guid(_slot);
	            var _name = gamepad_get_description(_slot);
	            var _map  = _guid + "," + _name + "," + Calib_bindings + "platform:Windows,";
	            gamepad_test_mapping(_slot, _map);

	            // Persist so it re-applies next launch (see Input_System discovered).
	            with(Input) dm_UserInputConfig[?_guid+"_sdlmap"] = _map;
	            save_game_pref();

	            // Give the freshly mapped pad sane action defaults.
	            gamepad_set_default();

	            Calib_active = false;
	            Calib_msg = "CONTROLLER CALIBRATED";
	            aud_play_sound(CONFIRM_SOUND1);
	            timer = DURATION1;
	            InputConfigState = InputConfigState_MAIN;
	        }
	    }
	    break;}//case InputConfigState_CALIBRATE




	    // ====================================================================
	    // -----------------------------------------------------------
	    case InputConfigState_KB_EDITING:{
	    if (timer) break;//case InputConfigState_KB_EDITING

	    // cancel with ESC / BACKSPACE
	    if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_backspace))
	    {   aud_play_sound(BACK_SOUND1); timer = DURATION1; InputConfigState = InputConfigState_MAIN;
	        break;//case InputConfigState_KB_EDITING
	    }

	    // require a clean key release before capturing (so the confirm key isn't captured)
	    if (!KbEdit_clear)
	    {   if (!keyboard_check(vk_anykey)) KbEdit_clear = true;
	        break;//case InputConfigState_KB_EDITING
	    }

	    if (keyboard_check_pressed(vk_anykey))
	    {
	        var _vk = keyboard_key; // keycode of the key just pressed
	        // reject reserved menu/nav keys -> keep waiting
	        if (_vk==vk_escape || _vk==vk_backspace || _vk==vk_enter || _vk==0)
	        {   aud_play_sound(BACK_SOUND1);
	            break;//case InputConfigState_KB_EDITING
	        }

	        // assign to the selected action's PRIMARY key (uses KbOption_* enum names, NOT hardcoded indices)
	        with(Input)
	        {
	            switch(other.InputConfigOption)
	            {
	                case other.KbOption_RIGHT: Key_right =_vk; break;
	                case other.KbOption_LEFT:  Key_left  =_vk; break;
	                case other.KbOption_DOWN:  Key_down  =_vk; break;
	                case other.KbOption_UP:    Key_up    =_vk; break;
	                case other.KbOption_MAGIC: Key_magic =_vk; break;
	                case other.KbOption_PAUSE: Key_pause =_vk; break;
	                case other.KbOption_ATTACK:Key_attack=_vk; break;
	                case other.KbOption_JUMP:  Key_jump  =_vk; break;
	                case other.KbOption_SPELL_NEXT: Key_spell_next=_vk; break;
	                case other.KbOption_SPELL_PREV: Key_spell_prev=_vk; break;
	                case other.KbOption_TRACKER_TOGGLE: Key_tracker_toggle=_vk; break;
	                case other.KbOption_JUKEBOX_TOGGLE: Key_jukebox_toggle=_vk; break;
	                case other.KbOption_JUKEBOX_PREV:   Key_jukebox_prev  =_vk; break;
	                case other.KbOption_JUKEBOX_NEXT:   Key_jukebox_next  =_vk; break;
	                case other.KbOption_JUKEBOX_ASSIGN: Key_jukebox_assign=_vk; break;
	            }
	        }
	        _kb_persist();
	        aud_play_sound(CONFIRM_SOUND1);
	        timer = DURATION1;
	        InputConfigState = InputConfigState_MAIN;
	    }
	    break;}//case InputConfigState_KB_EDITING
    
    
    
    
    
    
    
    
	    /*
	    // ====================================================================
	    // -----------------------------------------------------------
	    default:{
	    if (timer2) break;//default
    
	    aud_play_sound(BACK_SOUND1);
	    timer = 0;
	    menu_state = menu_state_MAIN;
	    break;}//default
	    */
    
	}//switch(InputConfigState)







}
