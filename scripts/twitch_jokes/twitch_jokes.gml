/// @description  twitch_jokes -- CHAT JOKES (Z3 port, 2026-09-12) + the achievement-plate toast drawer.
//
// CHAT JOKES: dialogue_jokes.txt (shipped as an included file; a copy in
// %LOCALAPPDATA%\ZALiA\ wins) holds alternate lines for town text, keyed on the
// dialogue data key with the underscores dropped ("02_00_" + "A" -> "0200A").
// The same key may repeat: one of its lines is picked at random every time the
// message shows. A key ending in x ("0200Ax:") is a DIRTY line (cursing); a line
// with a curse word counts as dirty without the tag. The TWITCH options page row
// CHAT JOKES picks NORMAL (original text) / CLEAN (no cursing) / DIRTY (all),
// saved as jokes= in twitch_config.txt. Tokens: {name} = the save name,
// {chatter} = someone from chat (live this session, else the pool),
// {boss} = the boss on screen / last fought / of this palace.
// Hint lines are never listed in the file (owner rule 09-12: jokes must not
// touch anything that affects the game); update_Dialogue also skips every
// hint-flagged key at runtime as a belt-and-braces guard.
//
// Text goes through tw_jokes_format(): tokens -> upper case -> font-safe chars
// (the sprite font has  _/\()*+-.,:'%&!?0-9A-Z) -> word wrap at 10 columns ->
// pages of 4 lines. "<" in a line forces a line break, "|" forces a page break;
// update_Dialogue's writer holds ~50 frames on a page break, clears, continues.

#macro TW_JOKES_COLS 10
#macro TW_JOKES_ROWS 4

function tw_jokes_init() {
	global.tw_jokes_mode      = 1;               // 0 NORMAL, 1 CLEAN, 2 DIRTY
	global.tw_jokes_map       = ds_map_create(); // key -> array of { text, dirty }
	global.tw_jokes_count     = 0;               // keys with at least one line
	global.tw_jokes_alts      = 0;               // lines beyond the first per key
	global.tw_jokes_dirty     = 0;
	global.tw_jokes_last_key  = "";
	global.tw_jokes_last_pick = -1;
	global.tw_chatters        = [];              // pool: chatters.txt + the chatters: line
	global.tw_chatters_live   = [];              // seen live this session, oldest first
	global.tw_last_boss       = "";              // object name of the last Boss seen (twitch_tick)

	// jokes= from twitch_config.txt (twitch_irc_load_config only runs when the IRC
	// link is used, and the jokes work without chat)
	var _p = working_directory + "twitch_config.txt";
	if (file_exists(_p))
	{
		var _fh = file_text_open_read(_p);
		if (_fh != -1)
		{
			while (!file_text_eof(_fh))
			{
				var _line = tw_trim(file_text_readln(_fh));
				var _eq = string_pos("=", _line);
				if (_eq > 1 && string_lower(tw_trim(string_copy(_line, 1, _eq - 1))) == "jokes")
				{
					global.tw_jokes_mode = clamp(tw_num(tw_trim(string_copy(_line, _eq + 1, string_length(_line) - _eq)), 1), 0, 2);
				}
				if (_eq > 1 && string_lower(tw_trim(string_copy(_line, 1, _eq - 1))) == "autosave")
				{
					global.tw_autosave = (tw_num(tw_trim(string_copy(_line, _eq + 1, string_length(_line) - _eq)), 1) != 0);
				}
			}
			file_text_close(_fh);
		}
	}

	tw_jokes_load();
	tw_chatters_load();
}

/// @description  tw_jokes_load() -- (re)read dialogue_jokes.txt into global.tw_jokes_map.
function tw_jokes_load() {
	ds_map_clear(global.tw_jokes_map);
	global.tw_jokes_count = 0; global.tw_jokes_alts = 0; global.tw_jokes_dirty = 0;

	var _name = "dialogue_jokes.txt";
	if (!file_exists(_name)) { if (DEV) show_debug_message("[JOKES] no " + _name); return; }
	var _fh = file_text_open_read(_name);
	if (_fh == -1) return;

	while (!file_text_eof(_fh))
	{
		var _line = file_text_readln(_fh);
		_line = tw_trim(_line);
		if (_line == "") continue;
		if (string_char_at(_line, 1) == "#") continue;
		var _colon = string_pos(":", _line);
		if (_colon <= 1) continue;

		var _key  = string_upper(tw_trim(string_copy(_line, 1, _colon - 1)));
		var _text = tw_trim(string_copy(_line, _colon + 1, string_length(_line) - _colon));

		if (_key == "CHATTERS")
		{
			var _names = string_split(_text, ",", true);
			for (var _i = 0; _i < array_length(_names); _i++) tw_chatter_pool_add(tw_trim(_names[_i]), false);
			continue;
		}

		var _dirty = false;
		if (string_char_at(_key, string_length(_key)) == "X" && string_length(_key) > 1)
		{
			_dirty = true;
			_key = string_copy(_key, 1, string_length(_key) - 1);
		}
		if (_text == "") continue;
		if (!_dirty) _dirty = tw_jokes_is_dirty(_text);

		var _arr = global.tw_jokes_map[? _key];
		if (is_undefined(_arr)) { _arr = []; global.tw_jokes_count++; }
		else global.tw_jokes_alts++;
		array_push(_arr, { text : _text, dirty : _dirty });
		global.tw_jokes_map[? _key] = _arr;
		if (_dirty) global.tw_jokes_dirty++;
	}
	file_text_close(_fh);

	if (DEV) show_debug_message("[JOKES] " + string(global.tw_jokes_count) + " keys, +" + string(global.tw_jokes_alts)
		+ " alternates, " + string(global.tw_jokes_dirty) + " dirty, mode " + tw_jokes_mode_label());
}

function tw_jokes_mode_label() {
	if (!variable_global_exists("tw_jokes_mode")) return "CLEAN";
	return global.tw_jokes_mode == 0 ? "NORMAL" : (global.tw_jokes_mode == 2 ? "DIRTY" : "CLEAN");
}

/// @description  tw_jokes_set_mode(m) -- 0/1/2, persisted to twitch_config.txt.
function tw_jokes_set_mode(_m) {
	global.tw_jokes_mode = clamp(floor(_m), 0, 2);
	twitch_config_save();
}

/// @description  tw_jokes_is_dirty(text) -- whole-word curse check (same list as Z3).
function tw_jokes_is_dirty(_text) {
	static _words = ["fuck", "fucking", "fucked", "fucker", "fuckin", "shit", "shitty", "bullshit", "ass",
		"asses", "badass", "bitch", "bitches", "damn", "dammit", "goddamn", "cunt", "dick",
		"cock", "pussy", "whore", "whores", "tits", "nowyafuckedup", "fucterbud"];
	var _t = string_lower(string(_text)) + " ";
	var _w = "";
	var _n = string_length(_t);
	for (var _i = 1; _i <= _n; _i++)
	{
		var _c = string_char_at(_t, _i);
		if (_c >= "a" && _c <= "z") { _w += _c; continue; }
		if (_w != "")
		{
			for (var _j = 0; _j < array_length(_words); _j++) if (_w == _words[_j]) return true;
			_w = "";
		}
	}
	return false;
}

/// @description  tw_jokes_pick(key, fallback, save_name) -- a formatted joke for this key,
/// or the fallback (the original text) when the mode says no / nothing fits.
function tw_jokes_pick(_key, _fallback, _save_name) {
	if (!variable_global_exists("tw_jokes_map") || global.tw_jokes_mode <= 0) return _fallback;
	var _arr = global.tw_jokes_map[? string_upper(string(_key))];
	if (is_undefined(_arr)) return _fallback;

	var _ok = [];
	for (var _i = 0; _i < array_length(_arr); _i++)
		if (global.tw_jokes_mode == 2 || !_arr[_i].dirty) array_push(_ok, _i);
	if (array_length(_ok) == 0) return _fallback;

	var _pick = _ok[irandom(array_length(_ok) - 1)];
	// not the same alternate twice in a row for the same NPC
	if (array_length(_ok) > 1 && _key == global.tw_jokes_last_key && _pick == global.tw_jokes_last_pick)
		_pick = _ok[irandom(array_length(_ok) - 1)];
	global.tw_jokes_last_key  = _key;
	global.tw_jokes_last_pick = _pick;

	var _out = tw_jokes_format(_arr[_pick].text, _save_name);
	if (_out == "") return _fallback;
	return _out;
}

/// @description  tw_jokes_format(text, save_name) -> "LINE<LINE<LINE<LINE|LINE..." for the dialogue writer.
function tw_jokes_format(_text, _save_name) {
	var _t = string(_text);
	while (string_pos("{chatter}", _t) > 0) _t = string_replace(_t, "{chatter}", tw_chatter_pick());
	if (string_pos("{boss}", _t) > 0) _t = string_replace_all(_t, "{boss}", tw_boss_name());
	if (string_pos("{name}", _t) > 0)
	{
		var _nm = string_upper(tw_trim(string(_save_name)));
		if (_nm == "") _nm = "LINK";
		_t = string_replace_all(_t, "{name}", _nm);
	}
	_t = string_upper(_t);

	// font-safe characters only (FONT_LAYOUT) plus the two control characters
	static _ok = " /\\()*+-.,:'%&!?0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ<|";
	var _clean = "";
	var _n = string_length(_t);
	for (var _i = 1; _i <= _n; _i++)
	{
		var _c = string_char_at(_t, _i);
		if (_c == "\"") _c = "'";
		else if (_c == ";") _c = ",";
		else if (_c == "_") _c = " ";     // "_" is the writer's CHAR_BLANK (fast-forward), never wanted here
		else if (ord(_c) > 127) continue;
		if (string_pos(_c, _ok) > 0) _clean += _c;
	}

	// wrap: pages ("|") of paragraphs ("<") of words
	var _pages_out = [];
	var _pages = string_split(_clean, "|", true);
	for (var _p = 0; _p < array_length(_pages); _p++)
	{
		var _lines = [];
		var _paras = string_split(_pages[_p], "<", true);
		for (var _q = 0; _q < array_length(_paras); _q++)
		{
			var _words = string_split(_paras[_q], " ", true);
			var _cur = "";
			for (var _w = 0; _w < array_length(_words); _w++)
			{
				var _word = _words[_w];
				while (string_length(_word) > TW_JOKES_COLS)   // a word longer than the box: hard split
				{
					if (_cur != "") { array_push(_lines, _cur); _cur = ""; }
					array_push(_lines, string_copy(_word, 1, TW_JOKES_COLS));
					_word = string_delete(_word, 1, TW_JOKES_COLS);
				}
				if (_word == "") continue;
				if (_cur == "") _cur = _word;
				else if (string_length(_cur) + 1 + string_length(_word) <= TW_JOKES_COLS) _cur += " " + _word;
				else { array_push(_lines, _cur); _cur = _word; }
			}
			if (_cur != "") array_push(_lines, _cur);
		}
		// balanced pages: 5 lines -> 3+2, not 4+1 (no one-line orphan page)
		var _nl = array_length(_lines);
		if (_nl == 0) continue;
		var _npg = ceil(_nl / TW_JOKES_ROWS);
		var _per = ceil(_nl / _npg);
		for (var _l = 0; _l < _nl; _l += _per)
		{
			var _page = "";
			for (var _r = _l; _r < min(_l + _per, _nl); _r++)
				_page += (_page == "" ? "" : "<") + _lines[_r];
			if (_page != "") array_push(_pages_out, _page);
		}
	}
	var _out = "";
	for (var _o = 0; _o < array_length(_pages_out); _o++) _out += (_out == "" ? "" : "|") + _pages_out[_o];
	return _out;
}

// ─── chatter pool ──────────────────────────────────────────────────────────────

function tw_chatter_pool_has(_arr, _name) {
	var _l = string_lower(_name);
	for (var _i = 0; _i < array_length(_arr); _i++) if (string_lower(_arr[_i]) == _l) return true;
	return false;
}

function tw_chatter_pool_add(_name, _persist) {
	var _n = tw_trim(string(_name));
	if (_n == "" || string_length(_n) > 25) return false;
	if (string_char_at(_n, 1) == "#") return false;
	if (tw_chatter_pool_has(global.tw_chatters, _n)) return false;
	array_push(global.tw_chatters, _n);
	if (_persist)
	{
		var _f = file_text_open_append("chatters.txt");   // save area, remembered for the next stream
		if (_f != -1) { file_text_write_string(_f, _n); file_text_writeln(_f); file_text_close(_f); }
	}
	return true;
}

function tw_chatters_load() {
	if (!file_exists("chatters.txt")) return;
	var _fh = file_text_open_read("chatters.txt");
	if (_fh == -1) return;
	while (!file_text_eof(_fh)) tw_chatter_pool_add(tw_trim(file_text_readln(_fh)), false);
	file_text_close(_fh);
}

/// @description  tw_chatter_note(name) -- every PRIVMSG sender (twitch_irc_handle_line), commands or not.
function tw_chatter_note(_name) {
	if (!variable_global_exists("tw_chatters")) return;
	var _n = tw_trim(string(_name));
	if (_n == "" || _n == "chat") return;
	static _bots = ["streamelements", "nightbot", "moobot", "fossabot", "wizebot", "sery_bot", "soundalerts", "streamlabs"];
	var _l = string_lower(_n);
	for (var _i = 0; _i < array_length(_bots); _i++) if (_l == _bots[_i]) return;

	if (!tw_chatter_pool_has(global.tw_chatters_live, _n))
	{
		array_push(global.tw_chatters_live, _n);
		while (array_length(global.tw_chatters_live) > 40) array_delete(global.tw_chatters_live, 0, 1);
	}
	tw_chatter_pool_add(_n, true);
}

/// @description  tw_chatter_pick() -- a font-safe chatter name: 2 in 3 from the last few live
/// chatters when there are any, else the pool, else "CHAT".
function tw_chatter_pick() {
	var _name = "";
	var _live = variable_global_exists("tw_chatters_live") ? global.tw_chatters_live : [];
	var _pool = variable_global_exists("tw_chatters")      ? global.tw_chatters      : [];
	if (array_length(_live) > 0 && (array_length(_pool) == 0 || irandom(2) > 0))
	{
		var _n = array_length(_live);
		var _from = max(0, _n - 8);
		_name = _live[_from + irandom(_n - 1 - _from)];
	}
	else if (array_length(_pool) > 0) _name = _pool[irandom(array_length(_pool) - 1)];
	if (_name == "") _name = "CHAT";
	_name = string_upper(_name);
	_name = string_replace_all(_name, "_", "");
	if (string_length(_name) > TW_JOKES_COLS) _name = string_copy(_name, 1, TW_JOKES_COLS);
	return _name;
}

// ─── boss token ────────────────────────────────────────────────────────────────

function tw_boss_pretty(_obj_name) {
	var _u = string_upper(string(_obj_name));
	if (string_pos("LONK", _u) > 0 || string_pos("SHADOW", _u) > 0) return "DARK LINK";
	if (string_pos("HELMET", _u) > 0)   return "HELMETHEAD";
	if (string_pos("REBONACK", _u) > 0) return "REBONACK";
	if (string_pos("HORSE", _u) > 0)    return "HORSEHEAD";
	if (string_pos("CAROCK", _u) > 0)   return "CAROCK";
	if (string_pos("GOOMA", _u) > 0)    return "GOOMA";
	if (string_pos("BARBA", _u) > 0)    return "BARBA";
	if (string_pos("THUNDER", _u) > 0)  return "THUNDERBIRD";
	var _l = string_letters(_u);
	if (_l == "") return "";
	return string_copy(_l, 1, TW_JOKES_COLS);
}

/// @description  tw_boss_name() -- the Boss on screen, else the last one seen, else this palace's, else Horsehead.
function tw_boss_name() {
	var _n = "";
	if (instance_exists(Boss)) { with (Boss) { _n = object_get_name(object_index); break; } }
	if (_n == "" && variable_global_exists("tw_last_boss")) _n = global.tw_last_boss;
	var _out = tw_boss_pretty(_n);
	if (_out == "")
	{
		var _d = 0;
		try { _d = g.dungeon_num; } catch (_e) { _d = 0; }
		switch (_d)
		{
			case 1: _out = "HORSEHEAD";   break;
			case 2: _out = "HELMETHEAD";  break;
			case 3: _out = "REBONACK";    break;
			case 4: _out = "CAROCK";      break;
			case 5: _out = "GOOMA";       break;
			case 6: _out = "BARBA";       break;
			case 7: _out = "THUNDERBIRD"; break;
			default: _out = "HORSEHEAD";  break;
		}
	}
	return _out;
}

// ─── TOASTS: achievement plate (owner 09-12: "the toast notices we have suck ass") ─
//
// One drawer for everything that used to be green text at the bottom: chat verbs,
// NOW PLAYING, CHAT KILL, level-up, link status, KONAMI. Plates stack bottom-left,
// slide in from the left edge, hold, slide out; a bar under the text drains as the
// plate times out. Sprite-font text, palette white for the title and the darker
// GUI palette for the second line, plate colour by kind:
//   "chat" lime (a viewer did something), "music" aqua, "win" yellow, "warn" red, "info" white.
// The old globals still work: tw_toast_legacy_poll() turns a freshly set
// tw_toast/konami_toast/tw_np_timer into a plate, so no caller had to change.

function tw_toast_clean(_s) {
	var _t = string_upper(string(_s));
	var _out = "";
	var _n = string_length(_t);
	for (var _i = 1; _i <= _n; _i++)
	{
		var _c = string_char_at(_t, _i);
		if (_c == "\"") _c = "'";
		else if (_c == ";") _c = ",";
		else if (_c == "_") _c = " ";
		else if (ord(_c) > 127) continue;
		if (string_pos(_c, FONT_LAYOUT) > 0) _out += _c;
	}
	return tw_trim(_out);
}

/// @description  tw_toast_push(title, sub, kind) -- queue one plate. kind: chat/music/win/warn/info.
function tw_toast_push(_title, _sub, _kind) {
	if (!variable_global_exists("tw_toasts")) global.tw_toasts = [];
	var _t = tw_toast_clean(_title);
	var _s = tw_toast_clean(_sub);
	if (_t == "") return;
	static _MAXT = 26;
	static _MAXS = 30;
	if (string_length(_t) > _MAXT && _s == "")
	{	// spill the tail of a long one-liner into the second line at a word boundary
		var _cut = _MAXT;
		while (_cut > 10 && string_char_at(_t, _cut) != " ") _cut--;
		if (_cut <= 10) _cut = _MAXT;
		_s = tw_trim(string_delete(_t, 1, _cut));
		_t = tw_trim(string_copy(_t, 1, _cut));
	}
	if (string_length(_t) > _MAXT) _t = string_copy(_t, 1, _MAXT - 1) + ".";
	if (string_length(_s) > _MAXS) _s = string_copy(_s, 1, _MAXS - 1) + ".";

	// the same plate twice within half a second is spam (e.g. !song sets both toast globals)
	var _n = array_length(global.tw_toasts);
	if (_n > 0)
	{
		var _last = global.tw_toasts[_n - 1];
		if (_last.title == _t && _last.age < 30) return;
	}
	var _life = (_kind == "music") ? 300 : ((_kind == "win") ? 300 : 240);
	array_push(global.tw_toasts, { title : _t, sub : _s, kind : string(_kind), age : 0, life : _life });
	while (array_length(global.tw_toasts) > 5) array_delete(global.tw_toasts, 0, 1);
}

/// @description  tw_toast_from_line(text) -- the legacy one-line toast strings become title/sub/kind.
function tw_toast_from_line(_line) {
	var _l = string(_line);
	var _p = string_pos(" -> ", _l);
	if (_p > 0)
	{	// "chatter -> what happened"
		var _who = string_copy(_l, 1, _p - 1);
		var _msg = string_delete(_l, 1, _p + 3);
		tw_toast_push(_msg, "FROM " + _who, "chat");
		return;
	}
	var _u = string_upper(_l);
	if (string_pos("NOW PLAYING: ", _u) == 1) { tw_toast_push(string_delete(_l, 1, 13), "NOW PLAYING", "music"); return; }
	var _kind = "info";
	if (string_pos("CHAT KILL", _u) > 0 || string_pos("LEVEL UP", _u) > 0 || string_pos("FLAWLESS", _u) > 0
	||  string_pos("FATALITY", _u) > 0  || string_pos("FRIENDSHIP", _u) > 0 || string_pos("KONAMI", _u) > 0
	||  string_pos("UNLOCKED", _u) > 0)  _kind = "win";
	else if (string_pos("LOST", _u) > 0 || string_pos("RECONNECT", _u) > 0 || string_pos("FAIL", _u) > 0) _kind = "warn";
	else if (string_pos("CHAT LINK", _u) > 0 || string_pos("TWITCH", _u) > 0 || string_pos("VS CHAT", _u) > 0) _kind = "info";
	tw_toast_push(_l, "", _kind);
}

/// @description  tw_toast_legacy_poll() -- adopt the old globals the moment a caller sets them.
function tw_toast_legacy_poll() {
	if (!variable_global_exists("tw_toast_seen")) { global.tw_toast_seen = 0; global.tw_konami_seen = 0; global.tw_np_seen = 0; }
	if (variable_global_exists("tw_np_timer"))
	{
		if (global.tw_np_timer > global.tw_np_seen)
		{
			if (variable_global_exists("tw_np_name") && string(global.tw_np_name) != "")
				tw_toast_push(global.tw_np_name, "NOW PLAYING", "music");
			global.tw_np_timer = 0;
		}
		global.tw_np_seen = global.tw_np_timer;
	}
	if (variable_global_exists("tw_toast_timer"))
	{
		if (global.tw_toast_timer > global.tw_toast_seen)
		{
			if (variable_global_exists("tw_toast")) tw_toast_from_line(global.tw_toast);
			global.tw_toast_timer = 0;
		}
		global.tw_toast_seen = global.tw_toast_timer;
	}
	if (variable_global_exists("konami_toast_timer"))
	{
		if (global.konami_toast_timer > global.tw_konami_seen)
		{
			if (variable_global_exists("konami_toast")) tw_toast_push(global.konami_toast, "KONAMI", "win");
			global.konami_toast_timer = 0;
		}
		global.tw_konami_seen = global.konami_toast_timer;
	}
}

function tw_toast_kind_colour(_kind) {
	switch (string(_kind))
	{
		case "chat":  return make_colour_rgb(88, 216, 84);    // NES green
		case "music": return make_colour_rgb(60, 188, 252);   // NES light blue
		case "win":   return make_colour_rgb(248, 184, 0);    // NES yellow
		case "warn":  return make_colour_rgb(248, 56, 0);     // NES red
	}
	return make_colour_rgb(252, 252, 252);
}

/// @description  tw_toast_text(x, y, str, scale, font, colour) -- sprite-font text; colour -1 = palette white,
/// -2 = palette dim, else the font blended with that colour (icon glyphs).
function tw_toast_text(_x, _y, _str, _s, _font, _col) {
	var _cw = sprite_get_width(_font);
	var _n = string_length(_str);
	if (_col == -1) pal_swap_set(global.palette_image, global.PI_GUI1);
	else if (_col == -2) pal_swap_set(global.palette_image, global.PI_GUI3);
	for (var _i = 1; _i <= _n; _i++)
	{
		var _c = string_char_at(_str, _i);
		if (_c == " ") continue;
		var _idx = string_pos(_c, FONT_LAYOUT) - 1;
		if (_idx < 0) continue;
		draw_sprite_ext(_font, _idx, _x + (_i - 1) * _cw * _s, _y, _s, _s, 0, (_col < 0 ? c_white : _col), 1);
	}
	if (_col < 0) pal_swap_reset();
}

/// @description  tw_toast_draw() -- call once per frame from Draw GUI End.
function tw_toast_draw() {
	tw_toast_legacy_poll();
	if (!variable_global_exists("tw_toasts")) return;
	var _n = array_length(global.tw_toasts);
	if (_n == 0) return;

	var _gw = display_get_gui_width();  if (_gw <= 0) _gw = 320;
	var _gh = display_get_gui_height(); if (_gh <= 0) _gh = 240;
	var _s  = max(1, floor(_gh / 240));            // 1 at the default GUI, 4 on a 1080p takeover
	var _font = global.dl_game_font[| global.game_font_idx];
	var _cw = sprite_get_width(_font) * _s;
	var _ph = 24 * _s;
	var _gap = 3 * _s;
	var _x0 = 8 * _s;
	var _yb = _gh - 10 * _s;                       // bottom edge of the newest plate

	var _pa = draw_get_alpha(); var _pc = draw_get_colour();
	var _slot = 0;
	for (var _i = _n - 1; _i >= 0; _i--)
	{
		var _e = global.tw_toasts[_i];
		_e.age++;
		if (_e.age >= _e.life) { array_delete(global.tw_toasts, _i, 1); continue; }
		if (_slot >= 3) continue;                  // older ones keep ageing off screen

		var _IN = 12, _OUT = 10;
		var _prog = 1;
		if (_e.age <= _IN) _prog = _e.age / _IN;
		else if (_e.age >= _e.life - _OUT) _prog = max(0, (_e.life - _e.age) / _OUT);
		var _ease = _prog * _prog * (3 - 2 * _prog);

		var _tw = max(string_length(_e.title), string_length(_e.sub)) * _cw;
		var _pw = max(112 * _s, _tw + 30 * _s);
		var _x = round(-_pw + (_x0 + _pw) * _ease);
		var _y = _yb - _ph - _slot * (_ph + _gap);
		var _col = tw_toast_kind_colour(_e.kind);

		draw_set_alpha(0.86); draw_set_colour(c_black);
		draw_rectangle(_x, _y, _x + _pw, _y + _ph, false);
		draw_set_alpha(0.95); draw_set_colour(_col);
		draw_rectangle(_x, _y, _x + _pw, _y + _ph, true);
		// icon tile
		draw_set_alpha(1); draw_set_colour(merge_colour(_col, c_black, 0.72));
		draw_rectangle(_x + 4 * _s, _y + 4 * _s, _x + 20 * _s, _y + 20 * _s, false);
		var _glyph = "!";
		switch (_e.kind) { case "music": _glyph = "%"; break; case "win": _glyph = "*"; break; case "warn": _glyph = "?"; break; case "info": _glyph = ":"; break; }
		tw_toast_text(_x + 8 * _s, _y + 8 * _s, _glyph, _s, _font, _col);
		// text
		var _tx = _x + 24 * _s;
		if (_e.sub == "") tw_toast_text(_tx, _y + 8 * _s, _e.title, _s, _font, -1);
		else
		{
			tw_toast_text(_tx, _y + 4 * _s,  _e.title, _s, _font, -1);
			tw_toast_text(_tx, _y + 13 * _s, _e.sub,   _s, _font, -2);
		}
		// drain bar
		var _frac = clamp(1 - _e.age / _e.life, 0, 1);
		draw_set_alpha(0.95); draw_set_colour(_col);
		draw_rectangle(_x, _y + _ph - 2 * _s, _x + _pw * _frac, _y + _ph, false);
		_slot++;
	}
	draw_set_alpha(_pa); draw_set_colour(_pc);
}

// ─── !help card (round 10c) ────────────────────────────────────────────────────
// One screen of "how chat plays" for new viewers (MrMaseTV, 09-11). !help / !cmds /
// !commands / !howto arm global.tw_help_timer; tw_help_draw() paints a panel top-centre
// for 8 s in the sprite font. Content is a fixed list, grouped, so it stays readable.

function tw_help_show() {
	global.tw_help_timer = 480;
}

function tw_help_draw() {
	if (!variable_global_exists("tw_help_timer") || global.tw_help_timer <= 0) return;
	global.tw_help_timer--;
	static _rows = [
		"HOW CHAT PLAYS: TYPE !WORD IN CHAT",
		"HELP  !HEAL !MP !REFILL !1UP !FAIRY !LINK",
		"      !PROTECT !REFLECT !INVULN",
		"HURT  !HURT !DRAIN !POISON !KILL !TAX",
		"      !DMGUP !ATTRITION !CURSE !STEAL",
		"CHAOS !SLOW !SPEED !FLIP !CONFUSE !DARK",
		"      !SHAKE !DISCO !MOON !ICE !ROOT !DENY",
		"      !STASIS !DISORIENT !TAX !DMGUP",
		"MOBS  !SPAWN !SWARM !FREEZE !SMITE !PARTY",
		"      !FLAME !ARISE !CUCCO !CHALLENGE",
		"FUN   !SONG !SUGGEST !METH !FATALITY",
		"      !QUANTUMENTANGLE !HELP",
		"ADD A NUMBER FOR SECONDS: !SLOW 20"
	];
	var _gw = display_get_gui_width();  if (_gw <= 0) _gw = 320;
	var _gh = display_get_gui_height(); if (_gh <= 0) _gh = 240;
	var _s  = max(1, floor(_gh / 240));
	var _font = global.dl_game_font[| global.game_font_idx];
	var _cw = sprite_get_width(_font) * _s;
	var _lh = 10 * _s;
	var _maxc = 0;
	for (var _i = 0; _i < array_length(_rows); _i++) _maxc = max(_maxc, string_length(_rows[_i]));
	var _pw = _maxc * _cw + 12 * _s;
	var _ph = array_length(_rows) * _lh + 12 * _s;
	var _x = round((_gw - _pw) * 0.5);
	var _y = 48 * _s;
	var _fade = min(1, global.tw_help_timer / 20);
	var _pa = draw_get_alpha(); var _pc = draw_get_colour();
	draw_set_alpha(0.9 * _fade); draw_set_colour(c_black);
	draw_rectangle(_x, _y, _x + _pw, _y + _ph, false);
	draw_set_alpha(_fade); draw_set_colour(make_colour_rgb(60, 188, 252));
	draw_rectangle(_x, _y, _x + _pw, _y + _ph, true);
	draw_set_alpha(_fade);
	for (var _r = 0; _r < array_length(_rows); _r++)
		tw_toast_text(_x + 6 * _s, _y + 6 * _s + _r * _lh, _rows[_r], _s, _font, (_r == 0) ? -1 : -2);
	draw_set_alpha(_pa); draw_set_colour(_pc);
}

// ─── rolling checkpoints (round 10d) ───────────────────────────────────────────
// Lane 09-11 (1:51:50): "spit out a save every 60 seconds into a folder, I'll delete
// it manually... or every time I get an item or a level up". The save SLOT is left
// exactly as the game last saved it: tw_checkpoint() lets file_save() write the live
// state, copies that file to checkpoints\SaveFile_N_<stamp>.txt, then puts the slot's
// previous bytes (and the in-memory copies file_save refreshed) back. Restoring =
// copy a checkpoint over SaveFile_N.txt in %LOCALAPPDATA%\ZALiA while the game is
// closed (README.txt in the folder says so). Newest 30 are kept.

function tw_checkpoint(_why) {
	if (!instance_exists(f) || f.file_num < 1) return false;
	if (!variable_global_exists("tw_autosave") || !global.tw_autosave) return false;
	var _slot_name = f.dl_file_names[| f.file_num - 1];
	var _slot_path = working_directory + _slot_name;
	if (!file_exists(_slot_name)) return false;

	// remember the slot as the game last saved it
	var _fh = file_text_open_read(_slot_path);
	if (_fh == -1) return false;
	var _old = file_text_read_string(_fh);
	file_text_close(_fh);
	var _key = STR_Save + STR_File + hex_str(f.file_num) + STR_Encoded;
	var _old_enc = global.dm_save_file_data[? _key];

	file_save(f.file_num, false);   // live state -> slot (and the rando data files, which are live anyway)

	var _dir = working_directory + "checkpoints";
	if (!directory_exists(_dir)) directory_create(_dir);
	var _stamp = string(current_year) + string_replace_all(string_format(current_month, 2, 0), " ", "0")
		+ string_replace_all(string_format(current_day, 2, 0), " ", "0") + "_"
		+ string_replace_all(string_format(current_hour, 2, 0), " ", "0")
		+ string_replace_all(string_format(current_minute, 2, 0), " ", "0")
		+ string_replace_all(string_format(current_second, 2, 0), " ", "0");
	var _prefix = f.dl_FILE_NAME_PREFIX[| f.file_num - 1];
	var _dest = _dir + "\\" + _prefix + "_" + _stamp + "_" + string(_why) + ".txt";
	file_copy(_slot_path, _dest);

	// put the slot back
	var _fw = file_text_open_write(_slot_path);
	if (_fw != -1) { file_text_write_string(_fw, _old); file_text_close(_fw); }
	if (!is_undefined(_old_enc)) global.dm_save_file_data[? _key] = _old_enc;
	var _dm = json_decode(_old);
	if (_dm != -1) { ds_map_copy(global.dm_save_file, _dm); ds_map_destroy(_dm); }

	// folder note + prune to the newest 30 of this slot
	var _readme = _dir + "\\README.txt";
	if (!file_exists("checkpoints\\README.txt"))
	{
		var _rf = file_text_open_write(_readme);
		if (_rf != -1)
		{
			file_text_write_string(_rf, "ZALiA rolling checkpoints (every 60 s of play, every item, every level-up)."); file_text_writeln(_rf);
			file_text_write_string(_rf, "To restore: close the game, copy one of these over SaveFile_N.txt one folder up, start the game."); file_text_writeln(_rf);
			file_text_write_string(_rf, "Delete anything you do not need. The game keeps the newest 30 per slot."); file_text_writeln(_rf);
			file_text_close(_rf);
		}
	}
	var _names = [];
	var _fn = file_find_first(_dir + "\\" + _prefix + "_*.txt", 0);
	while (_fn != "") { array_push(_names, _fn); _fn = file_find_next(); }
	file_find_close();
	array_sort(_names, true);
	while (array_length(_names) > 30) { file_delete(_dir + "\\" + _names[0]); array_delete(_names, 0, 1); }

	global.tw_ckpt_last  = current_time;
	global.tw_ckpt_count = (variable_global_exists("tw_ckpt_count") ? global.tw_ckpt_count : 0) + 1;
	if (DEV) show_debug_message("[CKPT] " + _dest);
	return true;
}

/// @description  tw_checkpoint_tick() -- called from twitch_tick every frame. 60 s of live play,
/// an item bit change, or the level-up flag makes a checkpoint. Never in menus, cutscenes,
/// transitions, the title or the death screen.
function tw_checkpoint_tick() {
	if (!variable_global_exists("tw_autosave") || !global.tw_autosave) return;
	if (!instance_exists(f) || !instance_exists(g) || f.file_num < 1) return;
	if (g.room_type == "B") return;
	if (g.gui_state != g.gui_state_NONE || g.cutscene || g.ChangeRoom_timer > 0) return;
	if (!instance_exists(global.pc)) return;
	if (!variable_global_exists("tw_ckpt_items")) { global.tw_ckpt_items = f.items; global.tw_ckpt_frames = 0; }
	if (!variable_global_exists("tw_ckpt_due")) global.tw_ckpt_due = "";
	var _why = "";
	if (f.items != global.tw_ckpt_items) { global.tw_ckpt_items = f.items; _why = "item"; }
	if (global.tw_ckpt_due != "") { _why = global.tw_ckpt_due; global.tw_ckpt_due = ""; }
	global.tw_ckpt_frames++;
	if (_why == "" && global.tw_ckpt_frames >= 3600) _why = "timer";
	if (_why == "") return;
	global.tw_ckpt_frames = 0;
	tw_checkpoint(_why);
}

// ─── reflect hint (round 10f) ──────────────────────────────────────────────────
// Lane 09-11 (2:43:22): "what's the point in going into dungeons if at the end I get to
// the reflect boss and can't kill him". Carock (Maze Island palace, dungeon 4) is the only
// boss that needs REFLECT. Say so on the way in, and again when the fight starts.
function tw_reflect_hint(_where) {
	if (!instance_exists(f)) return;
	if (f.spells & SPL_RFLC) return;
	if (!variable_global_exists("tw_reflect_hint_time")) global.tw_reflect_hint_time = -100000;
	if (current_time - global.tw_reflect_hint_time < 20000) return;   // not twice in 20 s
	global.tw_reflect_hint_time = current_time;
	if (_where == "boss") tw_toast_push("CAROCK NEEDS REFLECT", "YOU DONT HAVE IT. HE WONT DIE.", "warn");
	else                  tw_toast_push("THIS PALACE ENDS IN CAROCK", "HE NEEDS REFLECT. YOU HAVE NONE.", "warn");
}
