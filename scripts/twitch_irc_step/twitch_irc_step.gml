/// @description  twitch_irc_step() -- cheap per-frame tick for the in-game IRC client.
// ============================================================================
// TWITCH IRC (no-bot mode) -- PER-FRAME STEP.
//
// Called every frame from g_Step (after twitch_poll/twitch_tick). The socket
// RECEIVE is event-driven (obj_twitch_irc Async-Networking event), so this does
// almost nothing: it just advances a monotonic frame counter that the chat-command
// cooldown in twitch_irc_handle_line() compares against. Early-returns immediately
// while the IRC client is disabled, so it costs a single bool check on a normal run.
// ============================================================================
function twitch_irc_step() {

	// ---- boot auto-connect --------------------------------------------------------
	// If twitch_config.txt says autoconnect=1 (written when the TWITCH IRC toggle was
	// last switched ON), join chat ~2s after boot without a menu trip. 09-11 stream:
	// Lane restarted the game at 1:46 and the link silently stayed down until he
	// found the toggle at 2:00. Only flips tw_irc_enabled when the config is valid,
	// so a machine with no config never shows the "TWITCH: no config" label.
	if (!variable_global_exists("tw_irc_enabled") || !global.tw_irc_enabled)
	{
		if (!variable_global_exists("tw_irc_boot_frames")) global.tw_irc_boot_frames = 0;
		if (global.tw_irc_boot_frames < 120) { global.tw_irc_boot_frames++; return; }
		if (variable_global_exists("tw_irc_autoconnect_done") && global.tw_irc_autoconnect_done) return;
		global.tw_irc_autoconnect_done = true;
		if (twitch_irc_load_config()
		&&  variable_global_exists("tw_irc_autoconnect") && global.tw_irc_autoconnect)
		{
			global.tw_irc_enabled = true;
			twitch_irc_connect();
			global.tw_toast       = "TWITCH CHAT: auto-connecting";
			global.tw_toast_timer = 180;
		}
		else
		{
			global.tw_irc_status = "idle"; // load_config may have said "no config"; not enabled -> not drawn anyway
		}
		return;
	}

	// ---- auto-reconnect after a drop -----------------------------------------------
	// obj_twitch_irc arms tw_irc_reconnect_at on network_type_disconnect; a failed
	// connect() leaves status "error: ..." and we back off to 30s between tries.
	if (variable_global_exists("tw_irc_reconnect_at") && global.tw_irc_reconnect_at >= 0
	&&  variable_global_exists("tw_irc_status") && string_copy(string(global.tw_irc_status), 1, 5) == "error"
	&&  variable_global_exists("tw_irc_frame") && global.tw_irc_frame >= global.tw_irc_reconnect_at)
	{
		global.tw_irc_reconnect_n  = (variable_global_exists("tw_irc_reconnect_n") ? global.tw_irc_reconnect_n : 0) + 1;
		global.tw_irc_reconnect_at = global.tw_irc_frame + 1800; // next try in 30s if this one fails
		global.tw_toast       = "CHAT LINK: reconnect try " + string(global.tw_irc_reconnect_n);
		global.tw_toast_timer = 180;
		twitch_irc_connect();
	}

	if (!variable_global_exists("tw_irc_frame")) global.tw_irc_frame = 0;
	global.tw_irc_frame++;

	// Auto-hide countdown for the "connected" status line. twitch_irc_handle_line()
	// sets this to ~240 on the welcome 001; we tick it down here so the on-screen
	// "TWITCH: connected" label disappears after ~4s (the user is streaming and
	// doesn't want it stuck on-screen). Only counts while > 0 so it settles at 0;
	// "connecting"/error/no-config don't use it (they draw persistently).
	if (!variable_global_exists("tw_irc_status_timer")) global.tw_irc_status_timer = 0;
	if (global.tw_irc_status_timer > 0) global.tw_irc_status_timer--;
}
