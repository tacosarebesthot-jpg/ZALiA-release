// In-game Twitch IRC (no-bot mode). Off by default. Feeds the existing twitch_apply
// dispatcher from live chat.
//
// twitch_irc_handle_line(line) -- parse ONE raw IRC line and, if it's a chat
// "!command", route it to twitch_apply().
//
// Line shapes we handle:
//   PING :tmi.twitch.tv                              -> reply PONG (keepalive)
//   :tmi.twitch.tv 001 nick :Welcome ...             -> logged in (status=connected)
//   :nick!user@host PRIVMSG #channel :!heal please   -> a chat command
//
// A bare "!<verb> [arg]" maps DIRECTLY to a twitch_apply verb (heal/hurt/mp/drain/
// 1up/invuln/shake/dark/music/shrink/grow/slow/spell/speed/flame/spawn/swarm/flip/
// confuse/disco/freeze/smite/curse/party/refill, plus aliases). Unknown commands
// are ignored. A GLOBAL cooldown (global.tw_irc_cooldown_frames) throttles spam.

function twitch_irc_handle_line(_line) {

	if (_line == "") return;

	// ---- keepalive: Twitch PINGs, we must PONG or we get dropped -----------
	if (string_copy(_line, 1, 4) == "PING")
	{
		if (variable_global_exists("tw_irc_socket"))
			twitch_irc_send(global.tw_irc_socket, "PONG :tmi.twitch.tv");
		return;
	}

	// ---- welcome (numeric 001): we are logged in --------------------------
	// flip status -> connected AND raise the shared master gate so verbs fire.
	if (string_pos(" 001 ", _line) > 0)
	{
		global.tw_irc_status = "connected";
		// arm the auto-hide timer so the "connected" status line shows only
		// transiently (~4s @60fps) and then disappears -- the user is streaming
		// and doesn't want a permanent "connected" label on screen. Decremented
		// each frame in twitch_irc_step(); the Surface_Draw_GUI_End status block
		// hides "connected" once this reaches <= 0.
		global.tw_irc_status_timer = 240;
		global.tw_enabled    = true;
		return;
	}

	// ---- only chat messages from here on ----------------------------------
	if (string_pos("PRIVMSG", _line) <= 0) return;

	// sender = text between the leading ':' and the '!'  (":nick!user@host ...")
	var _sender = "chat";
	if (string_char_at(_line, 1) == ":")
	{
		var _bang = string_pos("!", _line);
		if (_bang > 2) _sender = string_copy(_line, 2, _bang - 2);
	}

	// message = everything after the SECOND ':'  (":prefix PRIVMSG #chan :msg")
	var _msg = "";
	var _first = string_pos(":", _line); // leading ':' (position 1 for a normal line)
	if (_first > 0)
	{
		var _rest   = string_copy(_line, _first + 1, string_length(_line) - _first);
		var _second = string_pos(":", _rest);
		if (_second > 0)
			_msg = string_copy(_rest, _second + 1, string_length(_rest) - _second);
	}

	_msg = tw_trim(_msg); // strip a trailing CR and any padding
	if (_msg == "" || string_char_at(_msg, 1) != "!") return;

	// split "!verb arg..." into verb + (everything after the first space) arg.
	var _verb = _msg;
	var _arg  = "";
	var _sp   = string_pos(" ", _msg);
	if (_sp > 0)
	{
		_verb = string_copy(_msg, 1, _sp - 1);
		_arg  = tw_trim(string_copy(_msg, _sp + 1, string_length(_msg) - _sp));
	}

	// drop the leading '!' and lowercase -> bare verb ("!heal" -> "heal")
	_verb = string_lower(string_delete(_verb, 1, 1));
	if (_verb == "") return;

	// ignore unknown commands BEFORE they can consume the cooldown
	if (!tw_irc_is_verb(_verb)) return;

	// ---- global cooldown (spam guard) -------------------------------------
	// One throttle for everyone: ignore any accepted command within
	// global.tw_irc_cooldown_frames of the previous accepted one.
	if (variable_global_exists("tw_irc_cooldown_frames")
	&&  variable_global_exists("tw_irc_last_cmd")
	&&  variable_global_exists("tw_irc_frame"))
	{
		if (global.tw_irc_frame - global.tw_irc_last_cmd < global.tw_irc_cooldown_frames) return;
		global.tw_irc_last_cmd = global.tw_irc_frame;
	}

	// hand off to the EXISTING dispatcher (itself gated on global.tw_enabled).
	// default duration 300 frames (5s @60fps) for timed effects.
	twitch_apply(_verb, _arg, _sender, 300);
}
