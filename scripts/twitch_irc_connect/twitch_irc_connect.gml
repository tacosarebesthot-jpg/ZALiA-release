// In-game Twitch IRC (no-bot mode). Off by default. Reads connection settings from
// %LOCALAPPDATA%\ZALiA\twitch_config.txt (the user supplies their OWN chat OAuth
// token -- nothing is ever hardcoded here), joins the channel, and feeds chat
// "!commands" into the existing twitch_apply() dispatcher.
//
// twitch_irc_connect() -- load config, open a raw TCP socket to Twitch's IRC
// gateway, and log in (PASS/NICK/JOIN). The socket RECEIVE is event-driven in
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

	global.tw_irc_socket = network_create_socket(network_socket_tcp);
	if (global.tw_irc_socket < 0)
	{
		global.tw_irc_status = "error: socket";
		return; // socket alloc failed
	}

	// Connect to the Twitch IRC gateway (plain, non-TLS port). Blocking variant.
	var _res = network_connect_raw(global.tw_irc_socket, "irc.chat.twitch.tv", 6667);
	if (_res < 0)
	{
		global.tw_irc_status = "error: connect";
		network_destroy(global.tw_irc_socket);
		global.tw_irc_socket = -1;
		return;
	}

	// Master gate ON so accepted chat verbs actually fire through twitch_apply()
	// (the IRC path needs the shared master gate up; confirmed again on welcome 001).
	global.tw_enabled = true;

	// IRC login handshake: password (OAuth), nick, then join the channel.
	// load_config() stores the token BARE, so re-add the "oauth:" prefix here.
	twitch_irc_send(global.tw_irc_socket, "PASS oauth:" + string(global.tw_irc_token));
	twitch_irc_send(global.tw_irc_socket, "NICK " + string(global.tw_irc_user));
	twitch_irc_send(global.tw_irc_socket, "JOIN #" + string(global.tw_irc_channel));
}
