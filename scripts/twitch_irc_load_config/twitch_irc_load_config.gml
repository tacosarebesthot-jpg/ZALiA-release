/// @description  twitch_irc_load_config() -- read the user's Twitch connection settings.
// ============================================================================
// TWITCH IRC (no-bot mode) -- CONFIG LOADER.
//
// Reads a plain "key=value" text file the USER creates at:
//     working_directory + "twitch_config.txt"   (== %LOCALAPPDATA%\ZALiA\twitch_config.txt)
//
// Recognised keys (one per line, case-insensitive key, '#' or '//' = comment line):
//     token=oauth:xxxxxxxxxxxxxxxxxxxxxxxxxxxxx   (chat OAuth token; "oauth:" optional)
//     user=yourbotname                            (the login nick)
//     channel=yourchannel                         (channel to join; leading '#' optional)
//     cooldown=600                                (OPTIONAL global anti-spam cooldown, FRAMES)
//
// NEVER hardcodes a token -- the user supplies their own. If the file is missing
// or any required field is blank, sets global.tw_irc_status = "no config" and
// returns false (the caller then refuses to connect). Returns true when token +
// user + channel are all present.
//
// Stores into: global.tw_irc_token (BARE -- "oauth:" stripped here, re-added on send),
// global.tw_irc_user, global.tw_irc_channel, global.tw_irc_cooldown_frames.
// ============================================================================
function twitch_irc_load_config() {

	// defaults (idempotent)
	if (!variable_global_exists("tw_irc_cooldown_frames")) global.tw_irc_cooldown_frames = 600;

	var _path = working_directory + "twitch_config.txt";
	if (!file_exists(_path))
	{
		global.tw_irc_status = "no config";
		return false;
	}

	var _fh = file_text_open_read(_path);
	if (_fh == -1)
	{
		global.tw_irc_status = "no config";
		return false;
	}

	var _token    = "";
	var _user     = "";
	var _channel  = "";
	var _cooldown = global.tw_irc_cooldown_frames;

	while (!file_text_eof(_fh))
	{
		var _line = file_text_read_string(_fh);
		file_text_readln(_fh);

		_line = tw_trim(_line);
		if (_line == "") continue;
		if (string_char_at(_line, 1) == "#")        continue; // comment
		if (string_copy(_line, 1, 2) == "//")       continue; // comment

		var _eq = string_pos("=", _line);
		if (_eq <= 1) continue; // no key, or "=value" with empty key

		var _key = string_lower(tw_trim(string_copy(_line, 1, _eq - 1)));
		var _val = tw_trim(string_copy(_line, _eq + 1, string_length(_line) - _eq));

		switch (_key)
		{
			case "token":    _token   = _val;               break;
			case "user":     _user    = _val;               break;
			case "nick":     _user    = _val;               break; // alias
			case "channel":  _channel = _val;               break;
			case "cooldown": _cooldown = tw_num(_val, 600); break;
		}
	}
	file_text_close(_fh);

	// normalise token: store BARE so twitch_irc_connect() can prepend "oauth:" cleanly
	// (accepts either "oauth:xxxx" or "xxxx" in the file).
	if (string_lower(string_copy(_token, 1, 6)) == "oauth:")
		_token = string_copy(_token, 7, string_length(_token) - 6);

	// normalise channel: strip a leading '#', lowercase (Twitch channels are lowercase).
	if (string_char_at(_channel, 1) == "#")
		_channel = string_copy(_channel, 2, string_length(_channel) - 1);
	_channel = string_lower(_channel);

	global.tw_irc_token           = _token;
	global.tw_irc_user            = string_lower(_user);
	global.tw_irc_channel         = _channel;
	global.tw_irc_cooldown_frames = max(0, floor(_cooldown));

	if (_token == "" || _user == "" || _channel == "")
	{
		global.tw_irc_status = "no config";
		return false;
	}

	global.tw_irc_status = "idle"; // config valid -- ready to connect
	return true;
}


/// @description  tw_trim(str) -- strip leading/trailing whitespace (space, tab, CR, LF).
/// Self-contained (no dependency on string_trim) so config parsing is robust against
/// Windows CRLF line endings and stray padding around "key = value".
function tw_trim(_s) {

	var _str = string(_s);
	var _len = string_length(_str);

	var _a = 1;
	while (_a <= _len)
	{
		var _c = string_char_at(_str, _a);
		if (_c == " " || _c == "\t" || _c == "\r" || _c == "\n") _a++;
		else break;
	}

	var _b = _len;
	while (_b >= _a)
	{
		var _c2 = string_char_at(_str, _b);
		if (_c2 == " " || _c2 == "\t" || _c2 == "\r" || _c2 == "\n") _b--;
		else break;
	}

	if (_b < _a) return "";
	return string_copy(_str, _a, _b - _a + 1);
}


/// @description  tw_irc_is_verb(name) -- true if a bare verb maps to a twitch_apply() case.
/// Gate used by twitch_irc_handle_line() so UNKNOWN "!commands" are ignored BEFORE they
/// can consume the cooldown. Mirrors the switch in twitch_apply() (aliases included).
function tw_irc_is_verb(_v) {

	switch (string_lower(string(_v)))
	{
		case "heal":   case "hurt":  case "mp":    case "drain":  case "1up":
		case "invuln": case "shake": case "dark":  case "music":
		case "shrink": case "grow":  case "slow":  case "spell":  case "speed":
		case "flame":  case "heckler":
		case "spawn":  case "swarm":
		case "flip":   case "confuse": case "disco":
		case "freeze": case "stun":  case "smite": case "clearscreen":
		case "curse":  case "party": case "refill":
		case "arise":  case "chicken": case "cucco":
			return true;
		default:
			return false;
	}
}
