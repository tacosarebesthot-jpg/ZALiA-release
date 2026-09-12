/// @description  twitch_points -- the chat points economy (round 10h, 2026-09-12).
//
// Chat kept asking "is it points based?" (asm0deus, HungSo1o). OFF by default: the
// TWITCH page row POINTS ECONOMY (points= in twitch_config.txt) turns it on.
// Earning: 1 point per chat message (any message, max 6 a minute per person) and
// 5 points every 5 minutes to everyone who talked in the last 10 minutes. Balance
// cap 999. Spending: every verb has a cost (tw_points_cost); a command a viewer
// cannot afford is refused with "needs N pts (has M)". Free: !points !help !song
// !suggest and the joke verbs. The broadcaster is always free. Channel-point
// redeems (twitch_poll's external commands) never pay. Balances persist in
// points.txt (save area, "name=points" per line), written at most once a minute.

function tw_points_init() {
	global.tw_points_on     = false;
	global.tw_points        = ds_map_create();   // lowercase name -> points
	global.tw_points_rate   = ds_map_create();   // lowercase name -> "frame,count" this minute
	global.tw_points_seen   = ds_map_create();   // lowercase name -> last frame heard
	global.tw_points_dirty  = false;
	global.tw_points_frame  = 0;
	global.tw_points_saved  = 0;
	global.tw_points_stipend= 0;
	global.tw_points_on = (tw_num(tw_config_get("points", "0"), 0) != 0);
	if (file_exists("points.txt"))
	{
		var _fh = file_text_open_read("points.txt");
		if (_fh != -1)
		{
			while (!file_text_eof(_fh))
			{
				var _line = tw_trim(file_text_readln(_fh));
				var _eq = string_pos("=", _line);
				if (_eq > 1) global.tw_points[? string_lower(string_copy(_line, 1, _eq - 1))] = clamp(tw_num(string_copy(_line, _eq + 1, string_length(_line) - _eq), 0), 0, 999);
			}
			file_text_close(_fh);
		}
	}
}

function tw_points_save() {
	if (!variable_global_exists("tw_points")) return;
	var _fw = file_text_open_write("points.txt");
	if (_fw == -1) return;
	var _k = ds_map_find_first(global.tw_points);
	while (!is_undefined(_k))
	{
		file_text_write_string(_fw, string(_k) + "=" + string(floor(global.tw_points[? _k])));
		file_text_writeln(_fw);
		_k = ds_map_find_next(global.tw_points, _k);
	}
	file_text_close(_fw);
	global.tw_points_dirty = false;
	global.tw_points_saved = global.tw_points_frame;
}

function tw_points_get(_who) {
	var _n = global.tw_points[? string_lower(string(_who))];
	return is_undefined(_n) ? 0 : _n;
}

function tw_points_add(_who, _n) {
	var _k = string_lower(string(_who));
	global.tw_points[? _k] = clamp(tw_points_get(_k) + _n, 0, 999);
	global.tw_points_dirty = true;
}

function tw_points_is_free(_who) {
	var _w = string_lower(string(_who));
	if (variable_global_exists("tw_irc_channel") && _w == string_lower(string(global.tw_irc_channel))) return true;
	return false;
}

/// @description  tw_points_cost(verb) -- after the alias map. 0 = free.
function tw_points_cost(_v) {
	switch (string(_v))
	{
		case "points": case "pts": case "bal": case "help": case "song": case "np": case "nowplaying": case "track":
		case "suggest": case "donothing": case "rip": case "blip": case "coincidence": case "getfed": case "link": case "unchicken":
		case "version": case "ver": case "build":
			return 0;
		case "heal": return 20;   case "mp": return 15;   case "refill": case "fairy": case "fary": return 40;
		case "1up": return 60;    case "invuln": return 30;
		case "protect": case "prtc": case "shield": case "reflect": case "rflc": return 20;
		case "jump": case "life": case "summon": case "summ": case "fire": case "thunder": case "thun": case "enigma": case "spel": case "spell": return 15;
		case "arise": case "cucco": case "cuco": case "chicken": return 20;
		case "freeze": case "stun": return 25;   case "smite": case "clearscreen": return 60;
		case "hurt": case "drain": return 10;    case "poison": return 30;   case "kill": case "killlink": return 100;
		case "curse": return 20;  case "steal": case "rob": case "thief": case "pickpocket": return 30;
		case "slow": return 15;   case "root": return 20;  case "spawn": return 15;  case "swarm": return 25;
		case "flame": case "heckler": return 5;  case "deny": return 25;
		case "tax": case "dmgup": case "attrition": return 30;  case "stasis": return 20;  case "challenge": return 50;
		case "confuse": return 15; case "disorient": return 25; case "flip": return 10;  case "dark": return 15;
		case "ice": case "icefloor": return 15; case "moon": return 10;  case "disco": return 5;  case "party": return 15;
		case "shrink": case "grow": return 10;  case "speed": return 15; case "shake": return 5;  case "music": return 5;
		case "meth": return 40;   case "quantumentangle": return 10;  case "ghost": return 25;  case "crush": return 25;
		case "fatality": case "friendship": case "flawless": case "finisher": return 20;
	}
	return 10;
}

/// @description  tw_points_earn(who) -- every PRIVMSG. 1 pt, max 6 a minute.
function tw_points_earn(_who) {
	if (!variable_global_exists("tw_points_on") || !global.tw_points_on) return;
	var _k = string_lower(string(_who));
	if (_k == "" || _k == "chat") return;
	global.tw_points_seen[? _k] = global.tw_points_frame;
	var _r = global.tw_points_rate[? _k];
	var _f0 = 0, _c = 0;
	if (!is_undefined(_r)) { var _p = string_pos(",", _r); _f0 = tw_num(string_copy(_r, 1, _p - 1), 0); _c = tw_num(string_delete(_r, 1, _p), 0); }
	if (global.tw_points_frame - _f0 >= 3600) { _f0 = global.tw_points_frame; _c = 0; }
	if (_c >= 6) { global.tw_points_rate[? _k] = string(_f0) + "," + string(_c); return; }
	_c++;
	global.tw_points_rate[? _k] = string(_f0) + "," + string(_c);
	tw_points_add(_k, 1);
}

/// @description  tw_points_afford(who, verb) -> true if the viewer may run it (free, or can pay). No deduction.
function tw_points_afford(_who, _v) {
	if (!variable_global_exists("tw_points_on") || !global.tw_points_on) return true;
	if (tw_points_is_free(_who)) return true;
	var _cost = tw_points_cost(_v);
	if (_cost <= 0) return true;
	var _have = tw_points_get(_who);
	if (_have < _cost)
	{
		global.tw_toast       = string(_who) + " -> " + string(_v) + " needs " + string(_cost) + " pts (has " + string(floor(_have)) + ")";
		global.tw_toast_timer = 180;
		return false;
	}
	return true;
}

/// @description  tw_points_deduct(who, verb) -- pay for a command that actually took effect.
function tw_points_deduct(_who, _v) {
	if (!variable_global_exists("tw_points_on") || !global.tw_points_on) return;
	if (tw_points_is_free(_who)) return;
	var _cost = tw_points_cost(_v);
	if (_cost > 0) tw_points_add(_who, -_cost);
}

/// @description  tw_points_tick() -- from twitch_tick every frame: the 5-minute stipend and the throttled save.
function tw_points_tick() {
	if (!variable_global_exists("tw_points_on")) return;
	global.tw_points_frame++;
	if (!global.tw_points_on) return;
	if (global.tw_points_frame - global.tw_points_stipend >= 18000)
	{
		global.tw_points_stipend = global.tw_points_frame;
		var _k = ds_map_find_first(global.tw_points_seen);
		while (!is_undefined(_k))
		{
			if (global.tw_points_frame - global.tw_points_seen[? _k] <= 36000) tw_points_add(_k, 5);
			_k = ds_map_find_next(global.tw_points_seen, _k);
		}
	}
	if (global.tw_points_dirty && global.tw_points_frame - global.tw_points_saved >= 3600) tw_points_save();
}

/// @description  tw_points_set_on(bool) -- the options row / config.
function tw_points_set_on(_on) {
	global.tw_points_on = _on;
	twitch_config_save();
	if (!_on && variable_global_exists("tw_points_dirty") && global.tw_points_dirty) tw_points_save();
}
