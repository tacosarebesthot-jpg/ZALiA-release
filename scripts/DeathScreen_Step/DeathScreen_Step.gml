/// @description  DeathScreen_Step()
function DeathScreen_Step() {


	if (deathScreenEndTimer)
	{
	    deathScreenEndTimer--;
	    if(!deathScreenEndTimer)
	    {
	        f.death_count++;
	            global.pc_lives--;

	        // VS CHAT MODE scoreboard: a death while chat is hostile is a point
	        // for chat. Counted here rather than derived from death_count so a
	        // mid-run toggle can't retroactively award kills for earlier deaths.
	        if (variable_global_exists("tw_vs_mode") && global.tw_vs_mode)
	        {
	            if (!variable_global_exists("tw_vs_kills")) global.tw_vs_kills = 0;
	            global.tw_vs_kills++;
	            // on-stream scoreboard moment: the kill toast rides the standard
	            // twitch toast draw, and twitch_tick ages it even across the death
	            // screen (it runs unconditionally near the top of g_Step).
	            global.tw_toast       = "CHAT KILL!  x" + string(global.tw_vs_kills);
	            global.tw_toast_timer = 240;
	        }
	        // assists on the death toast (round 10c): who last hurt / helped within 90 s
	        if (variable_global_exists("tw_last_hurter") && global.tw_last_hurter != "" && current_time - global.tw_last_hurter_t < 90000)
	        {
	            var _dt_sub = "";
	            if (variable_global_exists("tw_last_helper") && global.tw_last_helper != "" && current_time - global.tw_last_helper_t < 90000)
	                _dt_sub = "HEALED BY " + string(global.tw_last_helper);
	            tw_toast_push("KILLED BY " + string(global.tw_last_hurter), _dt_sub, "win");
	        }
	        // ROCKET LEAGUE (round 11): the apology plate. Random so the same death never reads
	        // the same way twice. Pushed AFTER the assists plate so the credit line stays on top.
	        // The grawlix is "%&*!" and not "$#@%!" -- $ # @ are not in the sprite font
	        // (FONT_LAYOUT) and tw_font_clean would drop them, leaving a bare "%!".
	        if (variable_global_exists("tw_rl") && global.tw_rl)
	        {   tw_toast_push(choose("WHOOPS...", "SORRY!", "NOOOO!", "%&*!"), "", "warn");  }
	        if (variable_global_exists("tw_challenge")) global.tw_challenge = false; // !challenge ends on death
	        if (global.pc_lives>0) room_goto_(rmB_NextLife);
	        else         room_goto_(rmB_GameOver);
	    }
	}




	if (deathFlashTimer 
	&&  g.timer_b==g.timer_b_DURATION1 ) // timer_b_DURATION1=$14, tmr_b resets at -1. So this happens every 21 frames
	{
	        deathFlashTimer--;
	    if(!deathFlashTimer)
	    {
	        deathScreenEndTimer = DEATH_SCREEN_END_DUR; // DEATH_SCREEN_END_DUR = 3
	    }
	}

	if (counter==DEATH_FLASH_TIMER_START_CUE) // DEATH_FLASH_TIMER_START_CUE = 4
	{
	    deathFlashTimer = DEATH_FLASH_TIMER_DUR; // DEATH_FLASH_TIMER_DUR = 7
	}

	counter++;







}
