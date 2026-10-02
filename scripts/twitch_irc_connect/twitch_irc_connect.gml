// In-game Twitch IRC (no-bot mode). Off by default. Reads connection settings from
// %LOCALAPPDATA%\ZALiA\twitch_config.txt (the user supplies their OWN chat OAuth
// token -- nothing is ever hardcoded here), joins the channel, and feeds chat
// "!commands" into the existing twitch_apply() dispatcher.
//
// twitch_irc_connect() -- load config, open a raw TCP socket to Twitch's IRC
// gateway (async), and once it is up log in (PASS/NICK/JOIN, twitch_irc_login()).
// Both the connect result and the socket RECEIVE are event-driven in
// obj_twitch_irc's Async-Networking event, so we just ensure a host instance
// exists for that event before connecting. Idempotent enough to double as a
// reconnect (any prior socket is dropped first so we never leak one).
//
// Status is reported through global.tw_irc_status:
//   "idle" / "connecting" / "connected" / "no config" / "error: <stage>"

function twitch_irc_connect() {

	// Don't even try unless explicitly enabled.
	if (!variable_global_exists("tw_irc_enabled") || !global.tw_irc_enabled) return;

	// Load + validate the user's config FIRST. Missing/blank -> refuse to connect.
	twitch_irc_load_config();
	if (!variable_global_exists("tw_irc_status") || global.tw_irc_status == "no config")
	{
		global.tw_irc_status = "no config";
		return;
	}

	// Clean reconnect: drop any prior socket so a re-enable never leaks one.
	if (variable_global_exists("tw_irc_socket") && global.tw_irc_socket >= 0)
	{
		network_destroy(global.tw_irc_socket);
		global.tw_irc_socket = -1;
	}

	// The Async-Networking RECEIVE event lives on obj_twitch_irc (persistent, no
	// sprite). Make sure an instance exists to host it before we open the socket.
	if (!instance_exists(obj_twitch_irc))
		instance_create_depth(0, 0, 0, obj_twitch_irc);

	global.tw_irc_status = "connecting";

	var _tls = variable_global_exists("tw_irc_tls") && global.tw_irc_tls;
	global.tw_irc_socket = network_create_socket(_tls ? network_socket_wss : network_socket_tcp);
	if (global.tw_irc_socket < 0)
	{
		global.tw_irc_status = "error: socket";
		twitch_irc_arm_retry();
		return; // socket alloc failed
	}

	// Connect to the Twitch IRC gateway (plain, non-TLS port). ASYNC: the blocking
	// variant stalled the whole frame for the OS connect timeout whenever the route was
	// down, and the auto-reconnect loop called it every 30 s -- on stream. The result
	// arrives as network_type_non_blocking_connect in obj_twitch_irc's Async-Networking
	// event, which then runs twitch_irc_login() below (or marks "error: connect").
	global.tw_irc_rx          = "";    // fresh receive buffer for the new socket
	global.tw_irc_auth_failed = false; // a new attempt gets to fail on its own
	global.tw_irc_last_rx     = variable_global_exists("tw_irc_frame") ? global.tw_irc_frame : 0; // the watchdog in twitch_irc_step counts silence from here
	global.tw_irc_ping_at     = -1;
	network_set_config(network_config_connect_timeout, 10000);
	var _res = _tls ? network_connect_raw_async(global.tw_irc_socket, "wss://irc-ws.chat.twitch.tv", 443)   // tls=1: token never crosses the wire in the clear
	                : network_connect_raw_async(global.tw_irc_socket, "irc.chat.twitch.tv", 6667);
	if (_res < 0)
	{
		global.tw_irc_status = "error: connect";
		network_destroy(global.tw_irc_socket);
		global.tw_irc_socket = -1;
		twitch_irc_arm_retry();
		return;
	}
}

/// @description  twitch_irc_dropped(status) -- the link is gone: free the socket, say so, arm the retry.
/// Called from the Async-Networking disconnect event AND from the watchdog in twitch_irc_step,
/// because on this runtime that event does NOT fire when the far end closes a client socket
/// (probe 2026-10-01: a local listener took the game's login and closed the connection; 28 s
/// later the game still said "connecting"). Until the watchdog, a dropped link was never
/// noticed at all -- the 09-11 stream sat ~8 minutes on a dead chat with "connected" showing.
function twitch_irc_dropped(_status) {
	if (variable_global_exists("tw_irc_socket") && global.tw_irc_socket >= 0) network_destroy(global.tw_irc_socket); // the handle outlives the connection
	global.tw_irc_socket = -1;
	global.tw_irc_rx     = "";

	// Twitch closes the socket right after "NOTICE * :Login authentication failed".
	// twitch_irc_handle_line() flagged that; a retry cannot fix a dead token, so keep the
	// readable status and do NOT arm the reconnect loop (it used to retry every 30 s forever,
	// toasting each time, with nothing on screen saying the token was the problem).
	if (variable_global_exists("tw_irc_auth_failed") && global.tw_irc_auth_failed)
	{
		global.tw_irc_status       = "error: bad token";
		global.tw_irc_reconnect_at = -1;
		return;
	}

	// Twitch dropped us (network loss, server restart, etc). Mark it; leave tw_irc_enabled
	// up so the user can re-select the toggle to reconnect.
	global.tw_irc_status = _status;
	// 09-11 stream: the link was down ~8 min (1:53 -> 2:01) before anyone noticed --
	// nothing on screen said so and the status dot is tiny. Shout, and let
	// twitch_irc_step() retry on its own (5s, then backing off from 30s).
	// The retry count is zeroed by the welcome 001 (twitch_irc_handle_line), not here. Still
	// > 0 at a drop means the last retry connected and was thrown out before it logged in
	// (Twitch restarting, a rate limit): keep the backoff growing. Zeroing it here restarted
	// the cycle at 5 s every time, with a fresh LOST + "reconnect try 1" pair of toasts.
	var _rn = variable_global_exists("tw_irc_reconnect_n") ? global.tw_irc_reconnect_n : 0;
	global.tw_irc_reconnect_at = (variable_global_exists("tw_irc_frame") ? global.tw_irc_frame : 0)
	                           + ((_rn <= 0) ? 300 : min(1800 * power(2, _rn - 1), 18000));
	if (_rn <= 0)
	{
		global.tw_toast       = "CHAT LINK LOST -- reconnecting";
		global.tw_toast_timer = 300;
	}
}

/// @description  twitch_irc_arm_retry() -- make sure twitch_irc_step() tries again after a failed connect.
/// Only a DROP used to arm the retry, so a FIRST connect that failed (the game booted before
/// the network was up) sat on "error: connect" until someone found the toggle. A retry that is
/// already scheduled is left alone: that is twitch_irc_step's backoff, mid-count.
function twitch_irc_arm_retry() {
	if (!variable_global_exists("tw_irc_reconnect_at") || global.tw_irc_reconnect_at < 0)
		global.tw_irc_reconnect_at = (variable_global_exists("tw_irc_frame") ? global.tw_irc_frame : 0) + 300;
}

/// @description  twitch_irc_login() -- the IRC handshake, sent once the async connect succeeds.
/// Called from obj_twitch_irc's networking event on network_type_non_blocking_connect.
function twitch_irc_login() {

	if (!variable_global_exists("tw_irc_socket") || global.tw_irc_socket < 0) return;

	// Master gate ON so accepted chat verbs actually fire through twitch_apply()
	// (the IRC path needs the shared master gate up; confirmed again on welcome 001).
	global.tw_enabled = true;

	// IRC login handshake: capabilities, password (OAuth), nick, then join the channel.
	// twitch.tv/tags prefixes every PRIVMSG with "@badges=...;mod=1;..." so the handler can
	// tell mods and the broadcaster apart (cooldown bypass, !ignore). Harmless if refused.
	// load_config() stores the token BARE, so re-add the "oauth:" prefix here.
	twitch_irc_send(global.tw_irc_socket, "CAP REQ :twitch.tv/tags");
	twitch_irc_send(global.tw_irc_socket, "PASS oauth:" + string(global.tw_irc_token));
	twitch_irc_send(global.tw_irc_socket, "NICK " + string(global.tw_irc_user));
	twitch_irc_send(global.tw_irc_socket, "JOIN #" + string(global.tw_irc_channel));
}
