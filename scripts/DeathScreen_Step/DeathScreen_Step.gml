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
	        }
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
