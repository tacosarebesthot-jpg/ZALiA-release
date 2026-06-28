/// @description  twitch_irc_disconnect() -- tear down the in-game IRC client.
// ============================================================================
// TWITCH IRC (no-bot mode) -- DISCONNECT / OFF.
//
// Closes the live TCP socket (if any), clears the enable flag + socket handle,
// resets the status readout, and destroys the obj_twitch_irc receive-event host
// instance. Used by the DEV TOOLS toggle (press again to turn OFF).
//
// Deliberately does NOT touch global.tw_enabled -- that is the SHARED master gate
// for the whole twitch system (also used by the file-drop/bot path), so turning
// the IRC client off must not silently disable a separately-enabled drop path.
// ============================================================================
function twitch_irc_disconnect() {

	if (variable_global_exists("tw_irc_socket") && global.tw_irc_socket >= 0)
		network_destroy(global.tw_irc_socket);

	global.tw_irc_socket  = -1;
	global.tw_irc_enabled = false;
	global.tw_irc_status  = "idle";

	if (instance_exists(obj_twitch_irc)) instance_destroy(obj_twitch_irc);
}
