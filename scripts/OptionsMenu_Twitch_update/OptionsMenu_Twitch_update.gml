/// @description  OptionsMenu_Twitch_update()
function OptionsMenu_Twitch_update() {

	// PLAYER-FACING Twitch menu. The two toggles used to live in DEV TOOLS ->
	// TEST/CAPTURE; once DEV TOOLS was hidden behind the unlock code that made the
	// stream features unreachable by the people they exist for. Same actions, new home,
	// plus the two value rows the streamer actually wants to change mid-stream.
	//
	// The oauth token is NEVER surfaced here -- channel/token stay in
	// %LOCALAPPDATA%\ZALiA\twitch_config.txt, because this menu gets shown on stream.

	var _i;

	var _InputConfirm_pressed  = a_button_pressed || start_button_pressed; // xbox A / START

	// NOTE: the toggle rows use confirm ONLY -- deliberately NOT `|| Input.pressedH` the
	// way some other menus do. Left/right belongs to the value rows below, and folding
	// it into confirm is what made COOLDOWN and EFFECT LENGTH one-directional.
	var _InputConfirm_pressed2 = _InputConfirm_pressed;

	// one step per press, -1 / 0 / +1 -- the same helper the volume rows use
	var _HORIZONTAL = bit_dir(gui_tmr_cursor_h());

	var _SOUND1 = CURSOR_SOUND1;
	var _SOUND2 = CONFIRM_SOUND1;


	if(!timer)
	{
	    if (Backout_requested
	    ||  (Twitch_cursor==Twitch.BACK && _InputConfirm_pressed) )
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	        menu_state = menu_state_MAIN;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	if(!timer2)
	{
	    if (select_button_pressed
	    ||  Input.pressedV )
	    {
	        var _DIR = sign_(select_button_pressed || Input.Down_pressed);
	        for(_i=0; _i<Twitch.COUNT; _i++)
	        {
	            Twitch_cursor += _DIR;
	            Twitch_cursor += Twitch.COUNT;
	            Twitch_cursor  = Twitch_cursor mod Twitch.COUNT;
	            if (OptionsMenu_option_is_avail(menu_state_TWITCH,Twitch_cursor))
	            {
	                aud_play_sound(_SOUND1);
	                break;//_i
	            }
	        }
	        timer2 = DURATION2;
	        exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    }
	}


	switch(Twitch_cursor){

	    // CHANNEL REWARDS: the file-drop poll. An external bot writes verb files into
	    // working_directory\twitch_drop\ and twitch_poll picks them up. Independent of
	    // the IRC connection below -- either path can drive effects on its own.
	    case Twitch.REWARDS:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        if (!variable_global_exists("tw_enabled")) global.tw_enabled = false;
	        global.tw_enabled = !global.tw_enabled;
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // CONNECT TO CHAT: the in-game IRC client, no external bot needed. ON -> load
	    // config + connect; OFF -> disconnect.
	    case Twitch.CHAT:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        if (variable_global_exists("tw_irc_enabled") && global.tw_irc_enabled)
	        {
	            twitch_irc_disconnect();
	        }
	        else
	        {
	            global.tw_irc_enabled = true;
	            twitch_irc_load_config();
	            twitch_irc_connect();
	        }
	        aud_play_sound(_SOUND2);
	        timer = DURATION1;
	    }
	    break;}

	    // COMMAND COOLDOWN: seconds between accepted chat commands. Stored internally in
	    // FRAMES (global.tw_irc_cooldown_frames) because twitch_irc_handle_line counts
	    // down in frames, but shown and edited in SECONDS -- nobody thinks in frames.
	    //
	    // LEFT lowers, RIGHT raises, and it CLAMPS at each end rather than wrapping.
	    // The first version only ever incremented and wrapped 60 -> 0, so nudging it
	    // down meant cycling the whole way round. Uses _HORIZONTAL, the same
	    // one-step-per-press helper every other value row in this menu system uses, so
	    // it feels identical to the volume sliders.
	    // Range 0..60s in 5s steps; 0 = no cooldown at all.
	    case Twitch.COOLDOWN:{
	    if (_HORIZONTAL != 0)
	    {
	        var _fps = game_get_speed(gamespeed_fps);
	        if (_fps <= 0) _fps = 60;

	        if (!variable_global_exists("tw_irc_cooldown_frames")) global.tw_irc_cooldown_frames = 600;

	        var _secs = round(global.tw_irc_cooldown_frames / _fps) + (_HORIZONTAL * 5);
	        _secs = clamp(_secs, 0, 60);

	        global.tw_irc_cooldown_frames = _secs * _fps;
	        twitch_config_save();

	        aud_play_sound(CURSOR_SOUND1);
	        timer = DURATION0;
	    }
	    break;}

	    // EFFECT LENGTH: how long a timed effect (slow, confuse, dark, party...) lasts.
	    // Bug list B22 -- both the streamer and chat reported effects ending too fast to
	    // notice. twitch_apply reads global.tw_effect_secs when it builds an effect's
	    // frame count. LEFT/RIGHT, clamped 5..60s in 5s steps (never 0 -- a zero-length
	    // effect would look like the command silently failed).
	    case Twitch.DURATION:{
	    if (_HORIZONTAL != 0)
	    {
	        if (!variable_global_exists("tw_effect_secs")) global.tw_effect_secs = 5;

	        global.tw_effect_secs = clamp(global.tw_effect_secs + (_HORIZONTAL * 5), 5, 60);

	        twitch_config_save();

	        aud_play_sound(CURSOR_SOUND1);
	        timer = DURATION0;
	    }
	    break;}

	    // COMMANDS: read-only reference. The verb list lives in this row's description
	    // string, so it draws in the info area like every other row's help text.
	    case Twitch.COMMANDS:{ if (timer) break;
	    if (_InputConfirm_pressed2)
	    {
	        aud_play_sound(BACK_SOUND1);
	        timer = DURATION1;
	    }
	    break;}

	    case Twitch.BACK:{ if (timer) break;
	    if (_InputConfirm_pressed){ aud_play_sound(BACK_SOUND1); timer = DURATION1; menu_state = menu_state_MAIN; }
	    break;}
	}

}
