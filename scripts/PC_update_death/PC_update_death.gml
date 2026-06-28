/// @description  PC_update_death()
function PC_update_death() {


	// C2D5: JSR D385, C2E9: JSR D385, D3CC
	if (!instance_exists(global.pc)) return false; // GMS2 port: PC absent in cutscene scenes

	// ── CO-OP REVIVE ── the fairy revives a dead P1 in place (consuming one token)
	// instead of sending the run to the death room. Must run BEFORE the death block
	// below: clearing is_dead + restoring HP here makes that block's guard false, and
	// returning false skips its room_goto_(rmB_Death) entirely this frame. Gated on
	// co-op + tokens, so solo play (coop_enabled==false) is byte-identical.
	if (global.coop_enabled
	&&  global.coop_revive_tokens > 0
	&&  global.pc.is_dead
	&& !global.pc.stun_timer )
	{
	    global.pc.is_dead       = 0;
	    adjust_stat(8, 0);            // restore some HP so death isn't re-triggered next frame
	    global.pc.iframes_timer = 60; // brief invuln after the revive
	    global.coop_revive_tokens--;
	    return false; // !!!!! revived -> do NOT fall through to the rmB_Death transition
	}

	if (global.pc.is_dead
	&& !global.pc.stun_timer )
	{
	    global.BackgroundColor_at_death = __background_get_colour( );
	    global.pc.is_dead = 0;
	    global.pc.state   = global.pc.state_DEAD;
    
	    audio_stop_sound(Audio.mus_rm_inst);
	    aud_play_sound(get_audio_theme_track(STR_PC+STR_Death));
    
	    room_goto_(rmB_Death);
	    return true;
	}


	return false;







}
