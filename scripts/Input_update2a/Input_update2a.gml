/// @description  Input_update2a()
function Input_update2a() {


	var _R_KEY = 0;
	var _L_KEY = 0;
	var _D_KEY = 0;
	var _U_KEY = 0;
	var _S_KEY = 0;
	var _E_KEY = 0;
	var _B_KEY = 0;
	var _A_KEY = 0;

	var _tas_inject = 0;
	if (global.tas_pb_state == 1)
	{
	    if (global.tas_pb_index >= global.tas_pb_count)
	    {
	        global.tas_pb_state = 2;
	    }
	    else
	    {
	        var _pk = ds_list_find_value(global.dl_tas_pb, global.tas_pb_index);
	        global.tas_pb_index++;
	        tas_apply_held(_pk);
	        _tas_inject = 1;
	    }
	}
	// (Phase 2 will OR-in the TCP-queued packet here via the same tas_apply_held path.)

	if (!_tas_inject) // Temporary until controller support is implemented. Certain players need the keyboard inputs so they can bind controller buttons through 3rd party controller support app.
	//if (gamepad_slot==-1) // -1: Gamepad NOT connected
	{
	    // Read the rebindable keyboard bindings (set in Input_Create, edited via the controls
	    // menu). 0 = unbound -> guarded so keyboard_check(0) never spuriously fires.
	    _R_KEY = (Key_right >0 && keyboard_check(Key_right )) || (Key_right_alt >0 && keyboard_check(Key_right_alt ));
	    _L_KEY = (Key_left  >0 && keyboard_check(Key_left  )) || (Key_left_alt  >0 && keyboard_check(Key_left_alt  ));
	    _D_KEY = (Key_down  >0 && keyboard_check(Key_down  )) || (Key_down_alt  >0 && keyboard_check(Key_down_alt  ));
	    _U_KEY = (Key_up    >0 && keyboard_check(Key_up    )) || (Key_up_alt    >0 && keyboard_check(Key_up_alt    ));
	    _S_KEY = (Key_pause >0 && keyboard_check(Key_pause )) || (Key_pause_alt >0 && keyboard_check(Key_pause_alt ));
	    _E_KEY = (Key_magic >0 && keyboard_check(Key_magic )) || (Key_magic_alt >0 && keyboard_check(Key_magic_alt ));
	    _B_KEY = (Key_attack>0 && keyboard_check(Key_attack)) || (Key_attack_alt>0 && keyboard_check(Key_attack_alt));
	    _A_KEY = (Key_jump  >0 && keyboard_check(Key_jump  )) || (Key_jump_alt  >0 && keyboard_check(Key_jump_alt  ));
	}

	// Quick spell cycle: NEXT / PREV. Not part of the NES bitfield (no R/L/D/U/S/E/B/A
	// slot), so combine gamepad-held + sentinel-safe keyboard-held directly into the
	// final action vars (same guarded 0=unbound pattern as the NES-mapped keys above).
	var _SPELL_NEXT_KEY = 0;
	var _SPELL_PREV_KEY = 0;
	if (!_tas_inject)
	{
	    _SPELL_NEXT_KEY = (Key_spell_next>0 && keyboard_check(Key_spell_next)) || (Key_spell_next_alt>0 && keyboard_check(Key_spell_next_alt));
	    _SPELL_PREV_KEY = (Key_spell_prev>0 && keyboard_check(Key_spell_prev)) || (Key_spell_prev_alt>0 && keyboard_check(Key_spell_prev_alt));
	}

	var _SPELL_NEXT_NEW = GP_Spell_Next_held || _SPELL_NEXT_KEY;
	var _SPELL_PREV_NEW = GP_Spell_Prev_held || _SPELL_PREV_KEY;

	Spell_Next_pressed  = _SPELL_NEXT_NEW && !Spell_Next_held;
	Spell_Prev_pressed  = _SPELL_PREV_NEW && !Spell_Prev_held;

	Spell_Next_released = !_SPELL_NEXT_NEW && Spell_Next_held;
	Spell_Prev_released = !_SPELL_PREV_NEW && Spell_Prev_held;

	// Held.  *** Held MUST be AFTER Pressed and Released
	Spell_Next_held = _SPELL_NEXT_NEW;
	Spell_Prev_held = _SPELL_PREV_NEW;

	// Tracker/Jukebox controls: keyboard edge (keyboard_check_pressed) + optional GP_Jukebox_*_pressed.
	// Not part of the NES bitfield; keyboard reads are sentinel-guarded (0 = unbound).
	var _TRACKER_TOGGLE_KBDP = 0;
	var _JUKEBOX_TOGGLE_KBDP = 0;
	var _JUKEBOX_PREV_KBDP   = 0;
	var _JUKEBOX_NEXT_KBDP   = 0;
	var _JUKEBOX_ASSIGN_KBDP = 0;
	if (!_tas_inject)
	{
	    _TRACKER_TOGGLE_KBDP = (Key_tracker_toggle>0 && keyboard_check_pressed(Key_tracker_toggle)) || (Key_tracker_toggle_alt>0 && keyboard_check_pressed(Key_tracker_toggle_alt));
	    _JUKEBOX_TOGGLE_KBDP = (Key_jukebox_toggle>0 && keyboard_check_pressed(Key_jukebox_toggle)) || (Key_jukebox_toggle_alt>0 && keyboard_check_pressed(Key_jukebox_toggle_alt));
	    _JUKEBOX_PREV_KBDP   = (Key_jukebox_prev>0   && keyboard_check_pressed(Key_jukebox_prev))   || (Key_jukebox_prev_alt>0   && keyboard_check_pressed(Key_jukebox_prev_alt));
	    _JUKEBOX_NEXT_KBDP   = (Key_jukebox_next>0   && keyboard_check_pressed(Key_jukebox_next))   || (Key_jukebox_next_alt>0   && keyboard_check_pressed(Key_jukebox_next_alt));
	    _JUKEBOX_ASSIGN_KBDP = (Key_jukebox_assign>0 && keyboard_check_pressed(Key_jukebox_assign)) || (Key_jukebox_assign_alt>0 && keyboard_check_pressed(Key_jukebox_assign_alt));
	}
	Tracker_Toggle_pressed = _TRACKER_TOGGLE_KBDP;
	Jukebox_Toggle_pressed = _JUKEBOX_TOGGLE_KBDP;
	Jukebox_Prev_pressed   = _JUKEBOX_PREV_KBDP || GP_Jukebox_Prev_pressed;
	Jukebox_Next_pressed   = _JUKEBOX_NEXT_KBDP || GP_Jukebox_Next_pressed;
	Jukebox_Assign_pressed = _JUKEBOX_ASSIGN_KBDP;

	var _R_NEW = R * (GP_Right_held  || _R_KEY);  // $01 NES d-pad  RIGHT
	var _L_NEW = L * (GP_Left_held   || _L_KEY);  // $02 NES d-pad  LEFT
	var _D_NEW = D * (GP_Down_held   || _D_KEY);  // $04 NES d-pad  DOWN
	var _U_NEW = U * (GP_Up_held     || _U_KEY);  // $08 NES d-pad  UP
	//                                                              // 
	var _S_NEW = S * (GP_Pause_held  || _S_KEY);  // $10 NES button START
	var _E_NEW = E * (GP_Magic_held  || _E_KEY);  // $20 NES button SELECT
	//                                                              // 
	var _B_NEW = B * (GP_Attack_held || _B_KEY);  // $40 NES button B
	var _A_NEW = A * (GP_Jump_held   || _A_KEY);  // $80 NES button A
	//                                                              // 
	//                                                              // 
	//                                                              // 
	//                                                              // 
	//                                                              // 
	// Pressed
	Right_pressed  = R * (_R_NEW && !Right_held);  // $01
	Left_pressed   = L * (_L_NEW && !Left_held);   // $02
	Down_pressed   = D * (_D_NEW && !Down_held);   // $04
	Up_pressed     = U * (_U_NEW && !Up_held);     // $08

	Pause_pressed  = S * (_S_NEW && !Pause_held);  // $10
	Magic_pressed  = E * (_E_NEW && !Magic_held);  // $20

	Attack_pressed = B * (_B_NEW && !Attack_held); // $40
	Jump_pressed   = A * (_A_NEW && !Jump_held);   // $80

	// DEV AUTOSWEEP: let the boot auto-pilot inject a virtual START/confirm press.
	if (variable_global_exists("dev_inject_pause") && global.dev_inject_pause)
	{
	    Pause_pressed = true;
	    global.dev_inject_pause = false;
	}


	// Released
	Right_released  = R * (!_R_NEW && Right_held); // $01
	Left_released   = L * (!_L_NEW && Left_held);  // $02
	Down_released   = D * (!_D_NEW && Down_held);  // $04
	Up_released     = U * (!_U_NEW && Up_held);    // $08

	Pause_released  = S * (!_S_NEW && Pause_held); // $10
	Magic_released  = E * (!_E_NEW && Magic_held); // $20

	Attack_released = B * (!_B_NEW && Attack_held);// $40
	Jump_released   = A * (!_A_NEW && Jump_held);  // $80


	// Held.  *** Held MUST be AFTER Pressed and Released
	Right_held  = R * _R_NEW; // $01
	Left_held   = L * _L_NEW; // $02
	Down_held   = D * _D_NEW; // $04
	Up_held     = U * _U_NEW; // $08

	Pause_held  = S * _S_NEW; // $10
	Magic_held  = E * _E_NEW; // $20

	Attack_held = B * _B_NEW; // $40
	Jump_held   = A * _A_NEW; // $80

	// DEV BUGPROBE BUG6: let the bug probe drive a virtual held direction on the overworld
	// (e.g. hold Right for N frames) without a real keyboard/gamepad press. Consumed every
	// frame (NOT cleared here -- Dev_Bugprobe_Step sets/clears global.dev_inject_hv itself
	// each frame it wants to drive movement), same convention as dev_inject_pause above.
	// $1 R, $2 L, $4 D, $8 U (matches Input.heldHV's bit layout).
	if (variable_global_exists("dev_inject_hv") && global.dev_inject_hv)
	{
	    if (global.dev_inject_hv & $1) Right_held = R;
	    if (global.dev_inject_hv & $2) Left_held  = L;
	    if (global.dev_inject_hv & $4) Down_held  = D;
	    if (global.dev_inject_hv & $8) Up_held    = U;
	}

	// TWITCH "confuse" (drunk controls): swap LEFT<->RIGHT after all real input is
	// resolved (incl. dev injects) but before Input_update2b/c/d derive the held/
	// pressed/released bitfields, so horizontal movement comes out mirrored. Timed
	// flag (global.tw_confuse) is set by twitch_apply and cleared on revert in
	// twitch_tick -> fully reversible; single-bool no-op when off.
	if (variable_global_exists("tw_confuse") && global.tw_confuse)
	{
	    var _cf_h = Right_held;     Right_held     = Left_held;     Left_held     = _cf_h;
	    var _cf_p = Right_pressed;  Right_pressed  = Left_pressed;  Left_pressed  = _cf_p;
	    var _cf_r = Right_released; Right_released = Left_released; Left_released = _cf_r;
	}

	// Pack the FINAL resolved input (post dev-inject + twitch-confuse) into the 10-bit
	// frame word ONCE -- this is exactly what the sim consumed this frame. Consumed by
	// BOTH the TAS recorder (only while recording) and the always-on MARK ring below.
	var _rec = 0;
	_rec |= (Right_held  != 0) * $01;
	_rec |= (Left_held   != 0) * $02;
	_rec |= (Down_held   != 0) * $04;
	_rec |= (Up_held     != 0) * $08;
	_rec |= (Pause_held  != 0) * $10;
	_rec |= (Magic_held  != 0) * $20;
	_rec |= (Attack_held != 0) * $40;
	_rec |= (Jump_held   != 0) * $80;
	_rec |= (Spell_Next_held != 0) * $100;
	_rec |= (Spell_Prev_held != 0) * $200;

	if (global.tas_rec_state == 1)
	{
	    tas_rec_append(_rec);
	}

	// MARK input ring (always-on, cheap): one circular-buffer store of this frame's
	// packed input. ring frame 0 is realigned to room entry by g_Room_Start. Guarded
	// so a missing global (e.g. hot-reload before g_Create) can never throw.
	if (variable_global_exists("mark_ring"))
	{
	    global.mark_ring[global.mark_ring_head] = _rec;
	    global.mark_ring_head = (global.mark_ring_head + 1) mod global.mark_ring_n;
	    if (global.mark_ring_filled < global.mark_ring_n) global.mark_ring_filled++;
	}
	//                                                              //
	//                                                              //
	//                                                              //
	// Xbox B button, PS CIRCLE button
	Other1_pressed  =  GP_Other1_held && !Other1_held; // 
	Other1_released = !GP_Other1_held &&  Other1_held; // 
	Other1_held     =  GP_Other1_held;                 // 
	// Xbox Y button, PS TRIANGLE button
	Other2_pressed  =  GP_Other2_held && !Other2_held; // 
	Other2_released = !GP_Other2_held &&  Other2_held; // 
	Other2_held     =  GP_Other2_held;                 // 
	// LEFT  bumper
	Other3_pressed  =  GP_Other3_held && !Other3_held; // 
	Other3_released = !GP_Other3_held &&  Other3_held; // 
	Other3_held     =  GP_Other3_held;                 // 
	// RIGHT bumper
	Other4_pressed  =  GP_Other4_held && !Other4_held; // 
	Other4_released = !GP_Other4_held &&  Other4_held; // 
	Other4_held     =  GP_Other4_held;                 // 
	// LEFT  trigger
	Other5_pressed  =  GP_Other5_held && !Other5_held; // 
	Other5_released = !GP_Other5_held &&  Other5_held; // 
	Other5_held     =  GP_Other5_held;                 // 
	// RIGHT trigger
	Other6_pressed  =  GP_Other6_held && !Other6_held; //
	Other6_released = !GP_Other6_held &&  Other6_held; //
	Other6_held     =  GP_Other6_held;                 //
	//                                                              //




}
