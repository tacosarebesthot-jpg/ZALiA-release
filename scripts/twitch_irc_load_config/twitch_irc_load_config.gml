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
//     effect_secs=10                              (OPTIONAL default effect duration, SECONDS --
//                                                  what OPTIONS > TWITCH and the web companion
//                                                  both save via twitch_config_save()/"/twitch/save")
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
	if (!variable_global_exists("tw_effect_secs"))         global.tw_effect_secs         = 5;

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
	var _effect   = global.tw_effect_secs;
	var _autoconnect = (variable_global_exists("tw_irc_autoconnect") && global.tw_irc_autoconnect) ? 1 : 0;

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
			// Same key twitch_config_save() and the web companion's /twitch/save both
			// write. Without this case the duration they saved was silently dropped
			// on every restart and effects reverted to the 5s default.
			case "effect": case "effect_secs": _effect = tw_num(_val, _effect); break;
			// autoconnect=1: join chat on boot without touching the menu. Written by
			// twitch_config_save() when the TWITCH IRC toggle is switched ON (09-11 stream:
			// after a game restart the link stayed down for 8 min and nobody noticed).
			case "autoconnect": case "auto": _autoconnect = tw_num(_val, 0); break;
			// jokes=0/1/2: the CHAT JOKES row (twitch_jokes). Read here too so a reload
			// (menu toggle, web save) never drops it; tw_jokes_init reads it at boot.
			case "jokes": if (variable_global_exists("tw_jokes_mode")) global.tw_jokes_mode = clamp(tw_num(_val, 1), 0, 2); break;
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
	global.tw_effect_secs         = max(1, floor(_effect)); // same clamp /twitch/save applies live

	if (_token == "" || _user == "" || _channel == "")
	{
		global.tw_irc_status = "no config";
		return false;
	}

	global.tw_irc_autoconnect = (_autoconnect != 0);
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

	// Canonicalise FIRST. The alias map (tiny/huge/filp/span/restore/gorilla...) used
	// to live only inside twitch_apply(), so every alias shipped on 09-10 was dead
	// over IRC: this gate returned false before the dispatcher ever saw the name
	// (Lane, 09-11 stream 2:01:02 "I think tiny just doesn't work"; !filp x2 at 2:50).
	switch (tw_alias_verb(string_lower(string(_v))))
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
		case "fairy":  case "fary":                  // advertised by !cmds, was dead -> now refill-alias
		case "protect": case "prtc": case "shield":  // advertised by !cmds, was dead -> now spell
		case "reflect": case "rflc":                 // advertised by !cmds, was dead -> now spell
		case "fire":   case "thunder": case "thun":  // bare spell names (lane typed these himself)
		case "enigma": case "spel": case "jump": case "life": case "summon": case "summ":
		case "ice":    case "icefloor":              // Z3 port
		case "moon":                                 // gravity verb (Z2 is a platformer)
		case "root":   case "deny":                  // Z3-family ports
		case "kill":   case "killlink": case "poison": case "suggest":
		case "steal":  case "rob": case "thief": case "pickpocket": // dispatch case existed since 07-27, never passed this gate (verb audit 09-11)
		case "fatality": case "friendship": case "flawless": case "finisher": // MK2 splash (fun / on-stream test)
		case "song":   case "np": case "nowplaying": case "track": // "what song is this" (every stream)
		case "link":   case "unchicken":                       // force Link form back (Lane 09-11 2:30:53 "exclamation point be link again")
		case "donothing": case "rip": case "blip": case "coincidence": case "getfed": // joke verbs
		case "tax": case "dmgup": case "attrition":   // Z3 ports, round 10b
			return true;
		default:
			return false;
	}
}

/// @description  tw_alias_verb(v) -- ONE alias map shared by the IRC gate and the dispatcher.
/// Pure renames only (no argument rewriting). Every name here was typed live by a real
/// chatter and died silently (CHAT_IDEAS_2026-09-10.md, vod7 09-11). Add new typos HERE,
/// never in only one of the two callers -- that split is exactly the bug this fixes.
function tw_alias_verb(_v) {

	switch (_v)
	{
		case "span":                      return "spawn";
		case "conuse": case "confiuse":   return "confuse";
		case "filp":                      return "flip";
		case "speeed":                    return "speed";
		case "huge":                      return "grow";
		case "tiny":  case "small":       return "shrink";   // !small: Gainey 09-11 2:01:16
		case "restore":                   return "refill";
		case "suggestion":                return "suggest";  // asm0deus 09-11 1:07:44 "!suggestion !meth"
		case "smith":                     return "smite";    // Gainey 09-11 1:53:32 (and Lane's "million ancient smiths" joke)
		case "poson": case "posion":      return "poison";   // Gainey 09-11 1:11:29, 1:15:40 "my god i cant type"
		case "mana":                      return "mp";       // asm0deus 09-11 2:12:40
		case "up":                        return "1up";      // Gainey 09-11 1:15:24
		case "rupees": case "rupeesteal": case "xpsteal": case "xp": case "taxes": return "tax"; // Z3 names, Z2 taxes XP
		case "doubledamage": case "dmg2": case "damageup": return "dmgup";
		case "bleed":  case "hunger":     return "attrition";
	}
	return _v;
}
