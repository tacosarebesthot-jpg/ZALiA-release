/// @description  PC_update_horizontal()
function PC_update_horizontal() {


	// 93CD
	var _C0 = g.mod_StabFrenzy 
	       && StabFrenzy_charge_counter>$80 
	       && Input.Attack_held;
	//
	var _HSPD_MAX = hspd_max>>_C0;
	var _HSPD = byte_to_int(hspd);

	if (ogr               // NOT on ground
	|| !attack_phase      // NOT attacking
	||  g.control1_timer  // stab does NOT inhibit hspd
	||  _C0 )             // is frenzy stabbing
	{
	    var _C1 = is_cucco 
	           && abs8b(hspd)<=hspd_max  // cucco slow walk while crouching
	           && Input.dHeld;           // down is held
	    //
	    // 93DC
	    if(!(g.pc_lock&PC_LOCK_HSPD)   // horizontal control NOT locked
	    &&   Input.hHeld               // left || right held
	    && (!Input.dHeld || _C1)       // down NOT held || cucco crawl
	    && (!_C0 || attack_phase==2) ) // NOT frenzy stabbing || in stab phase of attack
	    {   // 93FD. (left || right held) && down NOT held
	        var _HELD_DIR = bit_dir(Input.hHeld); // 1,-1
	        var _C2 = _HELD_DIR!=hspd_dir;
        
	        var _hspd_maxL = -_HSPD_MAX;
	        var _hspd_maxR =  _HSPD_MAX;
	        if (1)
	        {   // 2024/12/10. Maintain faster than normal max hspd from stabbing Bloobys. Otherwise, pressing left/right abruptly drops speed to normal max hspd(_HSPD_MAX).
	            _hspd_maxL = min(_HSPD,_hspd_maxL);
	            _hspd_maxR = max(_HSPD,_hspd_maxR);
	        }
        
	        var _amount = 1;
        
	        if (abs(_HSPD)>_HSPD_MAX  // moving faster than the normal max hspd(_HSPD_MAX).
	        && (!ogr || _C2) )        // is on ground || holding dir opposite of hspd_dir
	        {   // 2024/12/28. Smooth deceleration towards _HSPD_MAX when faster than it. Right now those speeds are only possible when stabbing a Blooby.
	            if(!ogr) hyper_hspd_friction += _amount/2;
	            if (_C2) hyper_hspd_friction += _amount;
	            _amount  = floor(hyper_hspd_friction);
	            _amount *= -hspd_dir;
	            hyper_hspd_friction = frac(hyper_hspd_friction);
	        }
	        else
	        {
	            _amount += _C2;
	            _amount *= _HELD_DIR;
	        }
        
	        hspd  = clamp(_HSPD+_amount, _hspd_maxL,_hspd_maxR);
	        hspd &= $FF;
	        hspd_impel = _HELD_DIR;
	        //sdm("A. "+"hspd $"+hex_str(hspd)+", _HSPD "+string(_HSPD)+", _HSPD_MAX "+string(_HSPD_MAX)+", _hspd_maxL "+string(_hspd_maxL)+", _hspd_maxR "+string(_hspd_maxR)+", _HELD_DIR "+string(_HELD_DIR)+", hspd_dir "+string(hspd_dir)+", _amount "+string(_amount));
	    }
	    else
	    {   // 93E6. left and right NOT held || down held
	        if(!ogr    // is on ground
	        &&  hspd )
	        {
	            /*
	            TODO: 2024/12/28. One issue with speeds greater than _HSPD_MAX from stabbing a Blooby:
	            If PC is on the ground when the attack reaches its final phase, PC_update_attack_2() will set hspd=0 which feels very abrupt at the faster speed.
	            */
	            //sdm("B. "+"hspd $"+hex_str(hspd)+", _HSPD "+string(_HSPD)+", _HSPD_MAX "+string(_HSPD_MAX)+", hspd_dir "+string(hspd_dir));
            // chat !ice: thin the ground friction to every 4th frame while the flag
            // is set, so momentum carries -- you keep sliding after releasing the
            // d-pad (ported from the Z3 mod's ice-floor effect).
            if (!(variable_global_exists("tw_ice") && global.tw_ice)
            ||  (global.App_frame_count & 3) == 0)
            {
                hspd += -hspd_dir;
                hspd &= $FF;
            }
	        }
	    }
    
    
    
	    // 943A: JSR 9610
	    if!(cs&$3) PC_update_1b(); // updateX()
    
	    PC_update_walk();
    
    
    
	    // 9420
	    if (Input.dHeld  // down held
	    && !ogr          // is on ground
	    &&  cs&$4 )      // bottom colliding with solid
	    {
	        PC_set_behavior(behavior_CROUCH);
	    }
	}


	if (abs(_HSPD)<=_HSPD_MAX) // NOT moving faster than the normal max hspd(_HSPD_MAX).
	{
	    hyper_hspd_friction = 0.00;
	}







}
