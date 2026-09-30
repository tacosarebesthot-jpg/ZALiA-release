// STUB -- in-game Twitch IRC (no-bot mode). Off by default. Needs: real OAuth token, expanded command map, error handling/reconnect, and verification that GM TCP networking works in this VM build. Feeds the existing twitch_apply dispatcher.
//
// twitch_irc_send(sock, str) -- send a single IRC line. IRC frames are
// terminated with CRLF; we build a fixed-size byte buffer of exactly the line's
// bytes (buffer_text writes NO trailing null, so buffer_get_size == bytes on the
// wire), push it down the raw socket, and free it.
//
// TODO: no send-failure handling; a real build should check the socket is still
// connected and re-queue on failure.

function twitch_irc_send(_sock, _str) {

	if (_sock < 0) return; // not connected -- nothing to send

	var _line = string(_str) + "\r\n";

	// Exact-size fixed buffer: buffer_text writes the raw bytes with no null
	// terminator, so the allocated size equals the payload size we send.
	var _sz  = string_byte_length(_line);
	if (_sz <= 0) return;

	var _buf = buffer_create(_sz, buffer_fixed, 1);
	buffer_write(_buf, buffer_text, _line);

	// Over the WebSocket transport (tls=1) Twitch wants TEXT frames; a raw TCP socket ignores the flag.
	if (variable_global_exists("tw_irc_tls") && global.tw_irc_tls) network_send_raw(_sock, _buf, buffer_get_size(_buf), network_send_text);
	else                                                            network_send_raw(_sock, _buf, buffer_get_size(_buf));

	buffer_delete(_buf);
}
