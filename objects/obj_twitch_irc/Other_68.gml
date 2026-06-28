// In-game Twitch IRC (no-bot mode). Off by default.
//
// Async - Networking event (eventType 7 / eventNum 68): the standard GM TCP
// client receive path. Fires on any networking event for our socket. We handle:
//   * network_type_data       -> read text, split on CRLF, dispatch each line
//   * network_type_disconnect  -> socket dropped: clear handle + status
//
// IRC frames are CRLF-delimited. Partial lines split across two packets are NOT
// reassembled here (rare for the small command traffic we care about).

var _type = async_load[? "type"];
var _sock = async_load[? "id"];

// Only react to events on OUR socket.
if (!variable_global_exists("tw_irc_socket") || _sock != global.tw_irc_socket) exit;

if (_type == network_type_data)
{
	var _buf  = async_load[? "buffer"];
	var _size = async_load[? "size"];

	if (_buf >= 0 && _size > 0)
	{
		// Read the received bytes as a raw string (IRC is line-based ASCII/UTF-8).
		buffer_seek(_buf, buffer_seek_start, 0);
		var _text = buffer_read(_buf, buffer_text); // reads up to a NUL / end

		// IRC frames are CRLF-delimited; split and dispatch each line.
		var _lines = string_split(_text, "\r\n");
		for (var _i = 0; _i < array_length(_lines); _i++)
		{
			var _line = _lines[_i];
			if (_line != "") twitch_irc_handle_line(_line);
		}
	}
}
else if (_type == network_type_disconnect)
{
	// Twitch dropped us (bad token, network loss, etc). Mark it; leave tw_irc_enabled
	// up so the user can re-select the toggle to reconnect.
	global.tw_irc_status = "error: disconnected";
	global.tw_irc_socket = -1;
}
