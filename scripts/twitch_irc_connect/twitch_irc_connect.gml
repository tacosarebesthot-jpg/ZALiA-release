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
		return; // socket alloc failed
	}

	// Connect to the Twitch IRC gateway (plain, non-TLS port). ASYNC: the blocking
	// variant stalled the whole frame for the OS connect timeout whenever the route was
	// down, and the auto-reconnect loop called it every 30 s -- on stream. The result
	// arrives as network_type_non_blocking_connect in obj_twitch_irc's Async-Networking
	// event, which then runs twitch_irc_login() below (or marks "error: connect").
	global.tw_irc_rx          = "";    // fresh receive buffer for the new socket
	global.tw_irc_auth_failed = false; // a new attempt gets to fail on its own
	network_set_config(network_config_connect_timeout, 10000);
	var _res = _tls ? network_connect_raw_async(global.tw_irc_socket, "wss://irc-ws.chat.twitch.tv", 443)   // tls=1: token never crosses the wire in the clear
	                : network_connect_raw_async(global.tw_irc_socket, "irc.chat.twitch.tv", 6667);
	if (_res < 0)
	{
		global.tw_irc_status = "error: connect";
		network_destroy(global.tw_irc_socket);
		global.tw_irc_socket = -1;
		return;
	}
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
