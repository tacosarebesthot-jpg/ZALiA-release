/// @description  updateX()
function updateX() {


	if(!hspd)
	{
	    hspd = (hspd+hspd_grav) &$FF;
	    return 0;
	}



	var _hspd_sub_CARRY = 0;
	if ( hspd&$F)
	{
	     hspd_sub += (hspd&$F)<<4;
	    _hspd_sub_CARRY = hspd_sub>$FF;
	     hspd_sub &= $FF;
	}

	var            _HSPD  = hspd>>4;
	if ( hspd&$80) _HSPD |= $F0;



	var _X_CHANGE  = (_HSPD+_hspd_sub_CARRY) &$FF;
	    _X_CHANGE -= (_X_CHANGE&$80)<<1;

	// MOVESPEED CHEAT (revert: delete this if-block) -- action-room horizontal walk speed.
	// updateX() is a SHARED mover (enemies call it too), so we gate on id==global.pc to scale
	// ONLY Link, never enemies. SCALE the per-frame whole-pixel step by global.cheat_movespeed
	// (1=off/faithful). This is collision-SAFE rather than tunnelling because: (1) updateX only
	// runs for the PC when NOT already touching a wall (callers gate on !(cs&$3) and PC_update_1d
	// zeroes hspd on wall contact), so each frame starts clear; (2) the scaled step is tiny --
	// normal walk hspd is $18 -> 1.5px/frame, so even at 4x the step is ~6px (dash ~8px), well
	// under the 16px minimum room-wall thickness; (3) the body hitbox is wider than Link, so the
	// cs&$3 wall-sense flips a frame BEFORE the visual edge. This is the same multi-pixel regime
	// the engine already tolerates for Blooby-stab hyperspeed, so no per-pixel loop is needed.
	if (variable_global_exists("cheat_movespeed") && global.cheat_movespeed > 1
	&&  id == global.pc && _X_CHANGE != 0)
	{
	    _X_CHANGE *= global.cheat_movespeed;
	}

	if (_X_CHANGE != 0)
	{
	    set_xy(id, x+_X_CHANGE, y);
	     x_change += _X_CHANGE;
	}



	var _HSPD_PREV = hspd;

	hspd = (hspd+hspd_grav) &$FF;

	if (abs(hspd_grav))
	{   // 2023/06/03. Prevent potential springing back and forth
	    if (hspd_grav<0 && _HSPD_PREV&$80) hspd = clamp(hspd, $80,$FF);
	    if (hspd_grav>0 && _HSPD_PREV<$80) hspd = clamp(hspd, $00,$7F);
	}


	return (_HSPD+_hspd_sub_CARRY) > $FF;







}
