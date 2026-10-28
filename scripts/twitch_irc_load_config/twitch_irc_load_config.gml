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
	file_text_recover_tmp(_path);
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
	global.tw_irc_tls = false; // the file decides, every load: a removed tls= line used to leave TLS on until restart

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
			case "autosave": global.tw_autosave = (tw_num(_val, 1) != 0); break;
			// rl=0/1: the ROCKET LEAGUE row (round 11). Read here as well as in tw_jokes_init so
			// a reload after a menu toggle or a web save never drops it.
			case "rl": global.tw_rl = (tw_num(_val, 1) != 0); break;
			case "points": if (variable_global_exists("tw_points_on")) global.tw_points_on = (tw_num(_val, 0) != 0); break;
			// 09-30 review: per-user cooldown (FRAMES, like cooldown=), mod bypass, effect timers HUD
			case "user_cooldown": global.tw_user_cooldown_frames = clamp(floor(tw_num(_val, 1800)), 0, 7200); break;
			case "mod_bypass":    global.tw_mod_bypass  = (tw_num(_val, 1) != 0); break;
			case "effects_hud":   global.tw_effects_hud = (tw_num(_val, 1) != 0); break;
			// 10-09 VOD round: Lane's on-air asks (sound cue, first-use hint, 1up reminder), the swarm cap, Toasty
			case "cmd_sound":      global.tw_cmd_sound       = (tw_num(_val, 0) != 0); break; // default OFF since 2.1.10 (Lane 10-24 0:15:33)
			// 10-24: the two new CHAT EXTRAS rows
			case "help_card":      global.tw_help_card       = (tw_num(_val, 0) != 0); break;
			case "cmd_prices":     global.tw_cmd_prices      = (tw_num(_val, 1) != 0); break;
			case "halloween":      global.tw_halloween_force = tw_num(_val, -1); break; // 1 = on, 0 = off, else the calendar (Oct 24-31)
			case "cmd_sound_name": if (string(_val) != "") global.tw_cmd_sound_name = string(_val); break;
			case "first_use_hint": global.tw_first_use_hint  = (tw_num(_val, 0) != 0); break;
			case "oneup_nudge":    global.tw_oneup_nudge_min = clamp(floor(tw_num(_val, 0)), 0, 60); break;
			case "swarm_cap":      global.tw_swarm_cap       = clamp(floor(tw_num(_val, 14)), 4, 40); break;
			case "toasty":         global.tw_toasty_pct      = clamp(floor(tw_num(_val, 50)), 0, 100); break;
			// 10-14 fun round
			case "announcer":      global.tw_announcer       = (tw_num(_val, 1) != 0); break;
			case "bets": case "bet": global.tw_bets_on       = (tw_num(_val, 1) != 0); break;
			case "bounty":         global.tw_bounty_on       = (tw_num(_val, 0) != 0); break;
			case "babality":       global.tw_babality_pct    = clamp(floor(tw_num(_val, 15)), 0, 100); break;
			// tls=1: the token crosses the wire inside TLS (wss://irc-ws.chat.twitch.tv:443). Still
			// opt-in; plaintext 6667 is the default. Checked 2026-10-01 on LTS 2026: the WebSocket
			// connects and the 001 welcome arrives ("connected"). Chat commands over it not yet run live.
			case "tls": case "ssl": case "wss": global.tw_irc_tls = (tw_num(_val, 0) != 0); break;
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
	// Same clamps the menu and /twitch/save apply: a hand-edited effect_secs=100000 made
	// every timed effect ~28 h (the 60 s cap in twitch_apply only covers explicit "!verb N").
	global.tw_irc_cooldown_frames = clamp(floor(_cooldown), 0, 3600);
	global.tw_effect_secs         = clamp(floor(_effect), 1, 60);

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

	// Canonicalise FIRST (the shared alias map), then check THE list (tw_verb_all).
	// v2.1.7: this used to be its own hardcoded switch AND the fuzzy matcher needed
	// the same list -- two copies guaranteed drift, so the list lives in ONE place
	// now (tw_verb_all below) and both callers read it.
	var _cv = tw_alias_verb(string_lower(string(_v)));
	return tw_verb_is_canon(_cv);
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
		case "beef": case "beefup":       return "dmgup";    // Lane 10-24 0:37:58 "!beef ... beefs up the monsters. Just change it to beef, that's funnier"
		case "slime": case "slimes": case "slimerain": case "apocalypse": return "slimed"; // asm0deus 10-24 2:43:13 / 2:45:45
		case "rusty": case "rusted":      return "rust";     // asm0deus 10-24 2:49:19
		case "cantstop": case "fidget":   return "adhd";     // asm0deus 10-24 2:52:50
		case "tot": case "trick": case "treat": case "knock": case "trickortreet": return "trickortreat"; // Halloween week
		case "boo": case "spook": case "spooky": case "haunted":                   return "haunt";
		case "bleed":  case "hunger":     return "attrition";
		case "cmds": case "commands": case "howto": case "howtoplay": return "help";
		case "entangle": case "quantum": case "qe": return "quantumentangle";
		case "confuseall": case "disorientate": return "disorient";
		case "flippalace": case "nomercy": case "noreprieve": return "challenge";
		case "freezelink": case "hold": case "statis": case "stais": return "stasis";
		case "balance": case "point": case "mypoints": return "points";
		case "invisible": case "invis": case "ghosts": return "ghost";
		case "drop": case "block": case "squash": return "crush";
		case "reroll": case "reshuffleenemies": case "enemyreshuffle": case "reshuffler": return "reshuffle";
		case "poll": case "votes":                        return "vote";     // chat picks between two effects
		case "leaderboard": case "leaders": case "rich": case "richest": return "top";
		case "killers": case "blame": case "deaths": case "killcount":  return "kills";
		// round 11 RL quick chat -- the short forms chat will actually type. Deliberately NO
		// "np" alias for "noproblem": !np is already NOW PLAYING and every stream uses it.
		case "slap": case "catslaps": case "cat_slap": return "catslap";     // Tangia's "Cat Slap"
		case "flash": case "flashbag": case "flash_bang": return "flashbang"; // Tedw3rd typed !flashbang 09-25
		case "nice":                      return "niceshot";
		case "save":                      return "whatasave";
		case "calc":                      return "calculated";
		case "close":                     return "closeone";
		case "ok":                        return "okay";
		case "fake":                      return "faking";
		case "ty":                        return "thanks";
	}
	return _v;
}


/// @description  tw_verb_all() -- THE canonical verb list, post-alias names only.
/// Single source of truth: tw_irc_is_verb gates on it and tw_fuzzy_verb suggests
/// from it. When you add a dispatch case in twitch_apply, add the name HERE.
function tw_verb_all() {
	static _all = [
		"heal","hurt","mp","drain","1up","invuln","shake","dark","music",
		"shrink","grow","slow","spell","speed","flame","heckler","spawn","swarm",
		"flip","confuse","disco","freeze","stun","smite","clearscreen",
		"curse","party","refill","arise","chicken","cucco","fairy","fary",
		"protect","prtc","shield","reflect","rflc",
		"fire","thunder","thun","enigma","spel","jump","life","summon","summ",
		"ice","icefloor","moon","root","deny","undeny",
		"poison","catslap","flashbang","suggest","steal","rob","thief","pickpocket",
		"fatality","friendship","flawless","finisher","babality","np","nowplaying","track",
		"link","unchicken","donothing","rip","blip","coincidence","getfed",
		"tax","dmgup","attrition","meth","quantumentangle","help","challenge","disorient",
		"stasis","points","pts","bal","ghost","crush",
		"slimed","rust","adhd", // 10-24 chat !suggest round (asm0deus), approved by the owner 10-28
		"trickortreat","haunt", // Halloween week 2026
		"version","ver","build","reshuffle","gorilla",
		"vote","top","kills","bet","bounty",
		"niceshot","whatasave","calculated","savage","closeone","okay","faking","gg",
		"ez","wow","noproblem","thanks"
	];
	return _all;
}

/// @description  tw_verb_is_canon(v) -- is v (already alias-canonicalised) a real verb?
function tw_verb_is_canon(_v) {
	var _all = tw_verb_all();
	for (var _i = 0; _i < array_length(_all); _i++)
		if (_all[_i] == _v) return true;
	return false;
}

/// @description  tw_edit_le(a, b, cap) -- Levenshtein distance with an early bail:
/// anything provably over cap returns cap+1. Inputs are tiny verb strings, so the
/// two-row DP table costs nothing even called per unknown chat message.
function tw_edit_le(_a, _b, _cap) {
	var _la = string_length(_a), _lb = string_length(_b);
	if (abs(_la - _lb) > _cap) return _cap + 1;
	var _prev = array_create(_lb + 1, 0);
	var _cur  = array_create(_lb + 1, 0);
	for (var _j = 0; _j <= _lb; _j++) _prev[@_j] = _j;
	for (var _i = 1; _i <= _la; _i++)
	{
		_cur[@0] = _i;
		var _rowmin = _i;
		var _ca = string_char_at(_a, _i);
		for (var _j = 1; _j <= _lb; _j++)
		{
			var _cost = (_ca == string_char_at(_b, _j)) ? 0 : 1;
			var _d = min(_prev[@_j] + 1, _cur[@(_j - 1)] + 1, _prev[@(_j - 1)] + _cost);
			_cur[@_j] = _d;
			if (_d < _rowmin) _rowmin = _d;
		}
		if (_rowmin > _cap) return _cap + 1;
		var _t = _prev; _prev = _cur; _cur = _t;
	}
	return _prev[@_lb];
}

/// @description  tw_fuzzy_verb(typed) -- closest canonical verb within tolerance, or "".
/// Powers the "did you mean" typo plate (stasus -> stasis, refil -> refill...). Distance
/// 1 always counts; 2 only for verbs >= 6 chars so short verbs can't false-positive on
/// each other. Returns "" for anything already real or too far from everything.
function tw_fuzzy_verb(_typed) {
	var _t = tw_alias_verb(string_lower(string(_typed)));
	if (_t == "" || tw_verb_is_canon(_t)) return "";
	var _best = "", _bestd = 99;
	var _all = tw_verb_all();
	for (var _i = 0; _i < array_length(_all); _i++)
	{
		var _d = tw_edit_le(_t, _all[_i], 2);
		if (_d < _bestd) { _bestd = _d; _best = _all[_i]; }
	}
	if (_bestd <= ((string_length(_t) >= 6) ? 2 : 1)) return _best;
	return "";
}


// ─── IGNORE LIST (09-30 review) ────────────────────────────────────────────────
// Mods (and the broadcaster) type !ignore <name>; that chatter's messages are dropped
// before anything else looks at them. Persists in ignored.txt (save area, one lowercase
// name per line) so a restart does not un-mute anyone.
function tw_ignore_load() {
	global.tw_ignored = [];
	if (!file_exists("ignored.txt")) return;
	var _fh = file_text_open_read("ignored.txt");
	if (_fh == -1) return;
	while (!file_text_eof(_fh))
	{
		var _n = string_lower(tw_trim(file_text_readln(_fh)));
		if (_n != "") array_push(global.tw_ignored, _n);
	}
	file_text_close(_fh);
}

function tw_ignore_save() {
	if (!variable_global_exists("tw_ignored")) return;
	var _text = "";
	for (var _i = 0; _i < array_length(global.tw_ignored); _i++) _text += global.tw_ignored[_i] + "\r\n";
	file_text_write_atomic(working_directory + "ignored.txt", _text);
}

function tw_ignore_has(_who) {
	if (!variable_global_exists("tw_ignored")) tw_ignore_load();
	var _k = string_lower(string(_who));
	for (var _i = 0; _i < array_length(global.tw_ignored); _i++) if (global.tw_ignored[_i] == _k) return true;
	return false;
}

function tw_ignore_count() {
	if (!variable_global_exists("tw_ignored")) tw_ignore_load();
	return array_length(global.tw_ignored);
}

function tw_ignore_add(_who) {
	if (tw_ignore_has(_who)) return false;
	array_push(global.tw_ignored, string_lower(string(_who)));
	tw_ignore_save();
	return true;
}

function tw_ignore_remove(_who) {
	if (!variable_global_exists("tw_ignored")) tw_ignore_load();
	var _k = string_lower(string(_who));
	for (var _i = array_length(global.tw_ignored) - 1; _i >= 0; _i--)
	{
		if (global.tw_ignored[_i] == _k) { array_delete(global.tw_ignored, _i, 1); tw_ignore_save(); return true; }
	}
	return false;
}
