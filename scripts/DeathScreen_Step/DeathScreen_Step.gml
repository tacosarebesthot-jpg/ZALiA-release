/// @description  DeathScreen_Step()
function DeathScreen_Step() {


	if (deathScreenEndTimer)
	{
	    deathScreenEndTimer--;
	    if(!deathScreenEndTimer)
	    {
	        f.death_count++;
	        // INFINITE LIVES (Lane 10-28 Discord: "an infinite life mode that I can toggle, so that people
	        // don't feel so bad killing link all the time and making me game over"): the death still
	        // happens and the area restarts, but the count never drops, so no game over and no XP penalty.
	        if (variable_global_exists("tw_inf_lives") && global.tw_inf_lives)
	        {
	            global.tw_toast       = "INFINITE LIVES: no life lost";
	            global.tw_toast_timer = 180;
	        }
	        else
	        {   global.pc_lives--;  }

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
	        // assists on the death toast (round 10c): who last hurt / helped within 90 s.
	        // 09-30: names the VERB and keeps a per-chatter kill tally ("!SWARM  KILLS: 3", !kills).
	        // (It was written "KILL #3"; the sprite font has no "#", so the plate read "KILL 3".)
	        if (variable_global_exists("tw_last_hurter") && global.tw_last_hurter != "" && current_time - global.tw_last_hurter_t < 90000)
	        {
	            var _kn = tw_kills_add(global.tw_last_hurter);
	            var _dt_sub = "";
	            if (variable_global_exists("tw_last_hurt_verb") && global.tw_last_hurt_verb != "")
	                _dt_sub = "!" + string_upper(string(global.tw_last_hurt_verb)) + "  KILLS: " + string(_kn);
	            else if (variable_global_exists("tw_last_helper") && global.tw_last_helper != "" && current_time - global.tw_last_helper_t < 90000)
	                _dt_sub = "HEALED BY " + string(global.tw_last_helper);
	            tw_toast_push("KILLED BY " + string(global.tw_last_hurter), _dt_sub, "win");
	            // one death, one credit -- the next one needs a fresh hurt. Kept on the LAST life:
	            // the game-over screen's GG/EZ callout reads it next and clears it there.
	            if (global.pc_lives > 0) global.tw_last_hurter = "";
	        }
	        // ROCKET LEAGUE (round 11): the apology plate. Random so the same death never reads
	        // the same way twice. Pushed AFTER the assists plate so the credit line stays on top.
	        // The grawlix is "%&*!" and not "$#@%!" -- $ # @ are not in the sprite font
	        // (FONT_LAYOUT) and tw_font_clean would drop them, leaving a bare "%!".
	        if (variable_global_exists("tw_rl") && global.tw_rl)
	        {   tw_toast_push(choose("WHOOPS...", "SORRY!", "NOOOO!", "%&*!"), "", "warn");  }
	        // (!challenge used to be cleared here; it now survives a death on purpose -- the entry is
	        //  tagged keep_on_death in twitch_apply and tw_effects_clear_all honours that.)
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
