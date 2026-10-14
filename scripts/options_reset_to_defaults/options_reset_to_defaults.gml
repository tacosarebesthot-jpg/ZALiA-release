/// @description  options_reset_to_defaults() -- OTHER -> RESET ALL SETTINGS (09-30 review).
// Puts every player-facing preference back to its first-run value and saves. Deliberately
// NOT touched: controls (EDIT CONTROLS has its own SET DEFAULTS), the whole DISPLAY page --
// fullscreen, window scale and the scaling mode (they describe the monitor, not a taste; the
// scaling mode was reset at first, owner 2026-10-01: keep it), the audio SET (re-loads a whole soundtrack), the
// randomizer options (they belong to a save), and the Twitch login (token / user / channel).
// Values mirror the init sites: Audio_Create, g_Create, p_init, init_mod_control_props,
// twitch_jokes / twitch_points defaults.
function options_reset_to_defaults() {

	// AUDIO (volumes only)
	if (instance_exists(Audio))
	{
		Audio.snd_vol = Audio.Volume_DEFAULT;
		Audio.mus_vol = Audio.Volume_DEFAULT;
		audio_group_set_gain(audiogroup_snd, Audio.snd_vol / 10, 0);
		audio_group_set_gain(audiogroup_mus, Audio.mus_vol / 10, 0);
	}

	// OTHER page
	if (instance_exists(p)) p.BackgroundFlash_setting = $2;
	if (instance_exists(g))
	{
		g.ScreenShake_user_pref     = true;
		g.mod_DLG_SPEED             = 2;
		g.mod_IndicateSpellActive   = 1;
		g.torch_lighting_method     = 1;
		g.mod_StabFrenzy            = 0;
		g.HiddenExitIndicator_enabled = false;
		g.DoubleJump_state          = false;
		g.all_bg_black_only         = false; // BLACK BGR
		g.anarkhyaOverworld_enabled = false; // ANARKHYA OW
	}
	global.Halloween1_enabled     = (current_month == 10 && current_day == 31); // HALLOWEEN: the g_Create rule
	global.game_font_idx          = max(0, ds_list_find_index(global.dl_game_font, spr_Font1));
	global.HUD_state              = 2;
	global.QuestTimer_show        = false;
	global.dbg_death_counter_show = false;
	global.LowHPBeep_disabled     = false;

	// TWITCH OPTIONS page (the login lines in twitch_config.txt are kept by twitch_config_save)
	global.tw_irc_cooldown_frames  = 600;
	global.tw_effect_secs          = 5;
	global.tw_user_cooldown_frames = 1800;
	global.tw_mod_bypass           = true;
	global.tw_effects_hud          = true;
	global.tw_cmd_sound            = true; // COMMAND SOUND (10-09 VOD round)
	global.tw_points_on            = true; // POINTS ECONOMY (written by twitch_config_save below)
	global.tw_autosave             = true;
	global.tw_rl                   = true;
	global.tw_splash_enabled       = true;
	global.tw_loz_jingle           = true;
	global.QuestTimer_scale        = 1.25;
	global.tw_toast_secs           = { music : 0, chat : 4, game : 0 };
	if (variable_global_exists("tw_jokes_mode")) global.tw_jokes_mode = 1;

	save_game_pref();
	twitch_config_save();
	tw_toast_push("SETTINGS RESET", "controls and twitch login kept", "info", "system");
}
