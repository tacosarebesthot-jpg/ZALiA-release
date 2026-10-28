/// @description  OptionsMenu_ChatX_update()
function OptionsMenu_ChatX_update() {

	// CHAT EXTRAS (TWITCH sub-page, owner 10-14). On/off rows flip on confirm; value rows
	// step with left/right, same split as OptionsMenu_Twitch_update (do NOT fold pressedH
	// into confirm, that is what made the value rows one-directional once).
	// Every change goes straight to twitch_config.txt via twitch_config_save().

	var _i;

	var _InputConfirm_pressed = a_button_pressed || start_button_pressed; // xbox A / START
	var _HORIZONTAL = bit_dir(gui_tmr_cursor_h());

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;

	if(!timer)
	{
	    if (Backout_requested
	    ||  (ChatX_cursor==ChatX.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        Twitch_cursor = Twitch.EXTRAS;
	        menu_state = menu_state_TWITCH;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}

	if(!timer2)
	{
	    if (select_button_pressed
	    ||  Input.pressedV )
	    {
	        var _DIR = sign_(select_button_pressed || Input.Down_pressed);
	        for(_i=0; _i<ChatX.COUNT; _i++)
	        {
	            ChatX_cursor += _DIR;
	            ChatX_cursor += ChatX.COUNT;
	            ChatX_cursor  = ChatX_cursor mod ChatX.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_CHAT_EXTRAS,ChatX_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}

	switch(ChatX_cursor){

	    // FIRST-USE HINT: tw_help_line toast the first time a verb lands (first_use_hint=)
	    case ChatX.HINT:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        if (!variable_global_exists("tw_first_use_hint")) global.tw_first_use_hint = false;
	        global.tw_first_use_hint = !global.tw_first_use_hint;
	        twitch_config_save();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // 1UP REMINDER: minutes on the last life before the !1up toast, 0 = off (oneup_nudge=)
	    case ChatX.ONEUP:{
	    if (_HORIZONTAL != 0)
	    {
	        if (!variable_global_exists("tw_oneup_nudge_min")) global.tw_oneup_nudge_min = 0;
	        global.tw_oneup_nudge_min = clamp(global.tw_oneup_nudge_min + _HORIZONTAL, 0, 30);
	        global.tw_oneup_nudge_frames = 0;
	        twitch_config_save();
	        aud_play_sound(_SOUND1);
	        timer = DURATION0;
	    }
	    break;}

	    // SWARM CAP: live enemies at which !swarm refuses, 4..40 in steps of 2 (swarm_cap=)
	    case ChatX.SWARM_CAP:{
	    if (_HORIZONTAL != 0)
	    {
	        if (!variable_global_exists("tw_swarm_cap")) global.tw_swarm_cap = 14;
	        global.tw_swarm_cap = clamp(global.tw_swarm_cap + _HORIZONTAL * 2, 4, 40);
	        twitch_config_save();
	        aud_play_sound(_SOUND1);
	        timer = DURATION0;
	    }
	    break;}

	    // TOASTY: percent chance after a flawless finisher, 0 = off, steps of 10 (toasty=)
	    case ChatX.TOASTY:{
	    if (_HORIZONTAL != 0)
	    {
	        if (!variable_global_exists("tw_toasty_pct")) global.tw_toasty_pct = 50;
	        global.tw_toasty_pct = clamp(global.tw_toasty_pct + _HORIZONTAL * 10, 0, 100);
	        twitch_config_save();
	        aud_play_sound(_SOUND1);
	        timer = DURATION0;
	    }
	    break;}

	    // MK2 ANNOUNCER: FIGHT / FINISH HIM / EXCELLENT samples (announcer=)
	    case ChatX.ANNOUNCER:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        if (!variable_global_exists("tw_announcer")) global.tw_announcer = true;
	        global.tw_announcer = !global.tw_announcer;
	        twitch_config_save();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // BABALITY: percent chance a flawless is a Babality when not shrunk, steps of 5 (babality=)
	    case ChatX.BABALITY:{
	    if (_HORIZONTAL != 0)
	    {
	        if (!variable_global_exists("tw_babality_pct")) global.tw_babality_pct = 15;
	        global.tw_babality_pct = clamp(global.tw_babality_pct + _HORIZONTAL * 5, 0, 100);
	        twitch_config_save();
	        aud_play_sound(_SOUND1);
	        timer = DURATION0;
	    }
	    break;}

	    // CHAT BETS: !bet while a boss is up (bets=)
	    case ChatX.BETS:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        if (!variable_global_exists("tw_bets_on")) global.tw_bets_on = true;
	        global.tw_bets_on = !global.tw_bets_on;
	        twitch_config_save();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // BOUNTIES: !bounty <enemy> N (bounty=), off by default
	    case ChatX.BOUNTY:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        if (!variable_global_exists("tw_bounty_on")) global.tw_bounty_on = false;
	        global.tw_bounty_on = !global.tw_bounty_on;
	        twitch_config_save();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // HELP CARD: !help / !commands draw the full card over the game (help_card=), off by default
	    // (10-24 VOD 0:55:51, the card blocked Lane's screen mid-fight)
	    case ChatX.HELPCARD:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        if (!variable_global_exists("tw_help_card")) global.tw_help_card = false;
	        global.tw_help_card = !global.tw_help_card;
	        twitch_config_save();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // COMMAND PRICES: chat commands cost points when the economy is on (cmd_prices=), on by default
	    // (10-24 VOD 0:13:18, Lane: "I don't want them to cost anything" -- but he wants the bets)
	    case ChatX.PRICES:{ if (timer) break;
	    if (_InputConfirm_pressed)
	    {
	        if (!variable_global_exists("tw_cmd_prices")) global.tw_cmd_prices = true;
	        global.tw_cmd_prices = !global.tw_cmd_prices;
	        twitch_config_save();
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    case ChatX.BACK:{ break;} // handled above with Backout_requested
	}

}
