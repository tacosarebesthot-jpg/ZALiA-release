/// @description  GameOverScreen_Create()
function GameOverScreen_Create() {


	GANON_SPR = spr_Game_Over_Screen;

	x = viewXC() - (sprite_get_width( GANON_SPR)>>1);  // centered
	y = viewYB() -  sprite_get_height(GANON_SPR);      // bottom aligned


	timer = $F2; // $0501


	TEXT_LINE1 =    "GAME  OVER";
	TEXT_LINE2 = "RETURN OF GANON";

	LINE1_X = viewXC() - ((string_length(TEXT_LINE1)<<3)>>1);
	LINE2_X = viewXC() - ((string_length(TEXT_LINE2)<<3)>>1);
	LINE1_Y =       y + ($A<<3);
	LINE2_Y = LINE1_Y + ($3<<3);
	/* OG
	TEXT_LINE1 =    "GAME  OVER";
	TEXT_LINE2 = "RETURN OF GANON ";

	LINE1_X = viewXC() - ((string_length(TEXT_LINE1)>>1)<<3);
	LINE2_X = viewXC() - ((string_length(TEXT_LINE2)>>1)<<3);
	LINE1_Y =       y + ($A<<3);
	LINE2_Y = LINE1_Y + ($3<<3);
	*/

	// p.Room_Start() changes PI_MOB_RED pal to CI_BLK1_+CI_WHT1_+CI_RED3_+CI_BLK1_
	// I'm not sure why it doesn't work changing the palette here.
	TEXT_PI = global.PI_MOB_RED;


	aud_play_sound(get_audio_theme_track(dk_GannonLaugh));


	f.xp = round(f.xp*g.mod_Gameover_XP_PENALTY);
	f.xp = clamp(f.xp, 0,XP_MAX);


	// ROCKET LEAGUE (round 11): chat gets the last word on the game over screen, but only when
	// chat actually did this -- same 90 s "who last hurt you" test the death-screen assists
	// plate uses, so a run that ended on its own merits dies in dignified silence.
	if (variable_global_exists("tw_rl") && global.tw_rl
	&&  variable_global_exists("tw_last_hurter") && global.tw_last_hurter != ""
	&&  current_time - global.tw_last_hurter_t < 90000)
	{   tw_toast_push(choose("GG", "EZ"), "", "chat", "game");  } // game callout: GAME TOASTS setting







}
