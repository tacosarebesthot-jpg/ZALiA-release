// In-game Twitch IRC (no-bot mode). Off by default.
//
// Async - Networking event (eventType 7 / eventNum 68): the standard GM TCP
// client receive path. Fires on any networking event for our socket. We handle:
//   * network_type_non_blocking_connect -> the async connect() finished: log in, or fail
//   * network_type_data                 -> append to the receive buffer, dispatch complete lines
//   * network_type_disconnect           -> socket dropped: clear handle + status, arm a retry
//
// IRC frames are CRLF-delimited, but TCP does not respect line boundaries: a packet can
// end mid-line, and on a busy chat Twitch batches many lines per packet. Everything after
// the last CRLF waits in global.tw_irc_rx until the next packet completes it. Before this
// buffer a split "!spawn moblin 6" ran as "!spawn mob", a split PING was never answered
// (-> dropped by Twitch -> reconnect), and the next packet's leading fragment was lost.

var _type = async_load[? "type"];
var _sock = async_load[? "id"];

// Only react to events on OUR socket.
if (!variable_global_exists("tw_irc_socket") || _sock != global.tw_irc_socket) exit;

if (_type == network_type_non_blocking_connect)
{
	// twitch_irc_connect() uses the async connect so a dead route can't stall the frame
	// (the blocking variant hung the game for the OS connect timeout on every retry).
	var _ok = async_load[? "succeeded"];
	if (is_undefined(_ok) || !_ok)
	{
		global.tw_irc_status = "error: connect";
		network_destroy(global.tw_irc_socket);
		global.tw_irc_socket = -1;
		exit;
	}
	twitch_irc_login();
}
else if (_type == network_type_data)
{
	var _buf  = async_load[? "buffer"];
	var _size = async_load[? "size"];

	if (_buf >= 0 && _size > 0)
	{
		// Read the received bytes as a raw string (IRC is line-based ASCII/UTF-8).
		buffer_seek(_buf, buffer_seek_start, 0);
		var _text = buffer_read(_buf, buffer_text); // reads up to a NUL / end

		if (!variable_global_exists("tw_irc_rx")) global.tw_irc_rx = "";
		_text = global.tw_irc_rx + _text;

		// Dispatch only up to the LAST CRLF; keep the tail for the next packet.
		var _cut = string_last_pos("\r\n", _text);
		if (_cut <= 0)
		{
			global.tw_irc_rx = _text;
		}
		else
		{
			var _done = string_copy(_text, 1, _cut - 1);
			global.tw_irc_rx = string_copy(_text, _cut + 2, string_length(_text) - _cut - 1);

			var _lines = string_split(_done, "\r\n");
			for (var _i = 0; _i < array_length(_lines); _i++)
			{
				var _line = _lines[_i];
				if (_line != "") twitch_irc_handle_line(_line);
			}
		}

		// A fragment that never terminates is not IRC (IRC lines are < 1 KB); drop it
		// rather than grow forever.
		if (string_length(global.tw_irc_rx) > 8192) global.tw_irc_rx = "";
	}
}
else if (_type == network_type_disconnect)
{
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
		exit;
	}

	// Twitch dropped us (network loss, server restart, etc). Mark it; leave tw_irc_enabled
	// up so the user can re-select the toggle to reconnect.
	global.tw_irc_status = "error: disconnected";
	// 09-11 stream: the link was down ~8 min (1:53 -> 2:01) before anyone noticed --
	// nothing on screen said so and the status dot is tiny. Shout, and let
	// twitch_irc_step() retry on its own (5s, then backing off from 30s).
	global.tw_irc_reconnect_at = (variable_global_exists("tw_irc_frame") ? global.tw_irc_frame : 0) + 300;
	global.tw_irc_reconnect_n  = 0;
	global.tw_toast       = "CHAT LINK LOST -- reconnecting";
	global.tw_toast_timer = 300;
}
