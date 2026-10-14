/// @description  twitch_vote -- "!vote dark flip [secs]": chat picks between two effects (09-30 review).
//
// Anyone starts one (normal cooldown rules apply to the START). Starting is FREE and so is
// the winner -- owner's ruling 2026-10-01, knowing that this lets chat vote a paid effect in
// for nothing; do not add a price. While it runs, plain chat counts as a ballot: "dark",
// "!dark", "a" or "1" for the first option, the same shapes for the second. One vote per
// chatter, last one wins. When the clock runs out the winner fires through twitch_apply() in
// the starter's name -- no cooldown, no points -- and a tie with votes on both sides fires
// both. Nobody voted: nothing happens.
// State lives in global.tw_vote (undefined = no vote). Drawn by tw_effects_draw().

function tw_vote_active() {
	return variable_global_exists("tw_vote") && is_struct(global.tw_vote);
}

/// @description  tw_vote_start(arg, who) -> true if a vote started; toasts the reason when it did not.
function tw_vote_start(_arg, _who) {
	if (tw_vote_active())
	{
		global.tw_toast       = _who + " -> a vote is already running (" + string(ceil(global.tw_vote.frames / 60)) + "s left)";
		global.tw_toast_timer = 180;
		return false;
	}
	var _parts = string_split(tw_trim(string_lower(string(_arg))), " ", true);
	var _verbs = [];
	var _secs  = 20;
	for (var _i = 0; _i < array_length(_parts); _i++)
	{
		var _p = _parts[_i];
		if (_p == "") continue;
		if (string_digits(_p) == _p) { _secs = tw_num(_p, 20); continue; }
		if (string_char_at(_p, 1) == "!") _p = string_delete(_p, 1, 1);
		array_push(_verbs, tw_alias_verb(tw_clean_command(_p)));
	}
	if (array_length(_verbs) != 2)
	{
		global.tw_toast       = "!vote dark flip 20   (two effects, seconds optional)"; // no < > [ ] in the sprite font
		global.tw_toast_timer = 300;
		return false;
	}
	var _a = _verbs[0], _b = _verbs[1];
	if (_a == _b)
	{
		global.tw_toast       = _who + " -> vote: pick two DIFFERENT effects";
		global.tw_toast_timer = 180;
		return false;
	}
	for (var _j = 0; _j < 2; _j++)
	{
		var _v = _verbs[_j];
		if (!tw_verb_is_canon(_v) || tw_vote_verb_blocked(_v))
		{
			global.tw_toast       = _who + " -> vote: !" + _v + " is not something chat can vote on";
			global.tw_toast_timer = 240;
			return false;
		}
	}
	_secs = clamp(_secs, 10, 60);
	global.tw_vote = {
		a : _a, b : _b, na : 0, nb : 0,
		voters : ds_map_create(),          // lowercase name -> "a" / "b"
		frames : _secs * 60, total : _secs * 60,
		who : _who
	};
	global.tw_toast       = "VOTE (" + string(_secs) + "s): type " + _a + " or " + _b;
	global.tw_toast_timer = 300;
	return true;
}

/// @description  tw_vote_verb_blocked(v) -- meta verbs that make no sense as a ballot option.
function tw_vote_verb_blocked(_v) {
	switch (_v)
	{
		case "vote": case "help": case "points": case "pts": case "bal": case "top": case "kills":
		case "suggest": case "version": case "ver": case "build": case "song": case "np":
		case "nowplaying": case "track": case "donothing": case "rip": case "blip":
		case "coincidence": case "getfed": case "reshuffle": case "challenge":
			return true;
	}
	return false;
}

/// @description  tw_vote_cast(who, msg) -> true if the message was a ballot (and is consumed).
function tw_vote_cast(_who, _msg) {
	if (!tw_vote_active()) return false;
	var _m = tw_trim(string_lower(string(_msg)));
	if (string_char_at(_m, 1) == "!") _m = string_delete(_m, 1, 1);
	if (_m == "") return false;
	var _c = "";
	var _mv = tw_alias_verb(tw_clean_command(_m));
	if (_m == "1" || _m == "a" || _mv == global.tw_vote.a) _c = "a";
	else if (_m == "2" || _m == "b" || _mv == global.tw_vote.b) _c = "b";
	if (_c == "") return false;
	var _k = string_lower(string(_who));
	var _prev = global.tw_vote.voters[? _k];
	if (!is_undefined(_prev))
	{
		if (_prev == _c) return true;               // same ballot again: nothing changes
		if (_prev == "a") global.tw_vote.na--; else global.tw_vote.nb--;
	}
	global.tw_vote.voters[? _k] = _c;
	if (_c == "a") global.tw_vote.na++; else global.tw_vote.nb++;
	return true;
}

/// @description  tw_vote_tick() -- from twitch_tick every frame: run the clock, fire the winner.
function tw_vote_tick() {
	if (!tw_vote_active()) return;
	global.tw_vote.frames--;
	if (global.tw_vote.frames > 0) return;

	var _v  = global.tw_vote;
	var _a = _v.a, _b = _v.b, _na = _v.na, _nb = _v.nb;
	// The winner fires in the STARTER's name: he called it, and a death it causes is his kill.
	// Fired as "CHAT", every vote kill went to a chatter called "chat" who then sat on top of !kills.
	var _by = (string(_v.who) != "") ? string(_v.who) : "CHAT";
	if (ds_exists(_v.voters, ds_type_map)) ds_map_destroy(_v.voters);
	global.tw_vote = undefined;                         // cleared BEFORE the winner fires: its toast must win

	if (_na == 0 && _nb == 0)
	{
		tw_toast_push("VOTE: NOBODY VOTED", "chat is asleep", "chat");
		return;
	}
	if (_na > _nb)       { tw_toast_push("VOTE: " + string_upper(_a) + " WINS " + string(_na) + "-" + string(_nb), "", "chat"); twitch_apply(_a, "", _by, ""); }
	else if (_nb > _na)  { tw_toast_push("VOTE: " + string_upper(_b) + " WINS " + string(_nb) + "-" + string(_na), "", "chat"); twitch_apply(_b, "", _by, ""); }
	else
	{
		tw_toast_push("VOTE: TIE " + string(_na) + "-" + string(_nb), "both it is", "chat");
		twitch_apply(_a, "", _by, "");
		twitch_apply(_b, "", _by, "");
	}
}

// ═══ 10-14 fun round: GAMBLING. Owner: "they gamble crazy, so always think about that for them." ═══

/// @description  tw_bet_place(arg, who) -- "!bet flawless 50" / "!bet win" / "!bet death 20" while a
/// boss is on screen. The stake leaves the chatter's points now; tw_bets_resolve pays when the fight
/// ends: flawless 5x, win 2x (a flawless also pays the win bettors), death 3x. One bet per chatter
/// per boss. Needs the points economy on. bets=0 turns the verb off. Returns false on a refusal.
function tw_bet_place(_arg, _who) {
	var _w = string(_who);
	if (!variable_global_exists("tw_bets_on") || !global.tw_bets_on)
	{   global.tw_toast = _w + " -> bets are off"; global.tw_toast_timer = 180; return false;  }
	if (!variable_global_exists("tw_points_on") || !global.tw_points_on)
	{   global.tw_toast = _w + " -> bets need the points economy on"; global.tw_toast_timer = 240; return false;  }
	if (!variable_global_exists("tw_boss_seen") || !global.tw_boss_seen || !instance_exists(Boss))
	{   global.tw_toast = _w + " -> no boss on screen to bet on"; global.tw_toast_timer = 240; return false;  }
	var _parts = string_split(tw_trim(string_lower(string(_arg))), " ", true);
	var _o = "", _amt = 20;
	for (var _i = 0; _i < array_length(_parts); _i++)
	{
		var _p = _parts[_i]; if (_p == "") continue;
		if (string_digits(_p) == _p) { _amt = tw_num(_p, 20); continue; }
		switch (_p)
		{
			case "flawless": case "flaw": case "perfect": case "clean": _o = "flawless"; break;
			case "win": case "boss": case "kill": case "beat": case "link":  _o = "win";      break;
			case "death": case "die": case "dies": case "dead": case "lose": case "lane": _o = "death"; break;
		}
	}
	if (_o == "")
	{   global.tw_toast = "!bet win 20  (or flawless / death, then points)"; global.tw_toast_timer = 300; return false;  }
	_amt = clamp(floor(_amt), 5, 200);
	if (!ds_exists(global.tw_bets, ds_type_map)) global.tw_bets = ds_map_create();
	var _k = string_lower(_w);
	if (!is_undefined(global.tw_bets[? _k]))
	{   global.tw_toast = _w + " -> already has a bet on this boss"; global.tw_toast_timer = 240; return false;  }
	var _have = tw_points_get(_k);
	if (!tw_points_is_free(_k) && _have < _amt)
	{   global.tw_toast = _w + " -> bet needs " + string(_amt) + " pts (has " + string(floor(_have)) + ")"; global.tw_toast_timer = 240; return false;  }
	if (!tw_points_is_free(_k)) tw_points_add(_k, -_amt);
	global.tw_bets[? _k] = _o + "," + string(_amt);
	tw_toast_push(string_upper(_w) + " BETS " + string(_amt) + " ON " + string_upper(_o), "flawless 5x   win 2x   death 3x", "chat");
	return true;
}

/// @description  tw_bets_resolve(outcome) -- "flawless" / "win" / "death" from twitch_tick when the
/// boss fight ends. Pays the winners, names up to three, clears the book.
function tw_bets_resolve(_outcome) {
	if (!variable_global_exists("tw_bets") || !ds_exists(global.tw_bets, ds_type_map)) return;
	if (ds_map_size(global.tw_bets) == 0) return;
	var _names = "", _nw = 0, _nl = 0;
	var _k = ds_map_find_first(global.tw_bets);
	while (!is_undefined(_k))
	{
		var _v = string(global.tw_bets[? _k]); var _p = string_pos(",", _v);
		var _o = string_copy(_v, 1, _p - 1); var _amt = tw_num(string_delete(_v, 1, _p), 0);
		var _hit = (_o == _outcome) || (_o == "win" && _outcome == "flawless");
		if (_hit)
		{
			var _mult = (_o == "flawless") ? 5 : ((_o == "death") ? 3 : 2);
			tw_points_add(_k, _amt * _mult); _nw++;
			if (_nw <= 3) _names += ((_names == "") ? "" : "  ") + _k + " +" + string(_amt * _mult);
		}
		else _nl++;
		_k = ds_map_find_next(global.tw_bets, _k);
	}
	ds_map_clear(global.tw_bets);
	if (_nw > 0) tw_toast_push("BETS: " + string_upper(_outcome) + " PAYS", _names, "win");
	else         tw_toast_push("BETS: " + string_upper(_outcome) + ". HOUSE WINS", string(_nl) + " lost", "chat");
}

/// @description  tw_bets_refund() -- the boss fight ended without a result (walked out, file load):
/// every stake goes back.
function tw_bets_refund() {
	if (!variable_global_exists("tw_bets") || !ds_exists(global.tw_bets, ds_type_map)) return;
	if (ds_map_size(global.tw_bets) == 0) return;
	var _k = ds_map_find_first(global.tw_bets);
	while (!is_undefined(_k))
	{
		var _v = string(global.tw_bets[? _k]); var _p = string_pos(",", _v);
		tw_points_add(_k, tw_num(string_delete(_v, 1, _p), 0));
		_k = ds_map_find_next(global.tw_bets, _k);
	}
	ds_map_clear(global.tw_bets);
	tw_toast_push("BETS REFUNDED", "no result on that boss", "chat");
}

/// @description  tw_bounty_place(arg, who) -- "!bounty moblin 30": points on the NEXT Link kill of that
/// enemy type (the !spawn names). One open bounty per type; pays 2x to the chatter who posted it.
/// OFF by default: bounty=1 in twitch_config.txt. Kills are detected by tw_bounty_tick (live count
/// of that object dropping inside one room), so a mob that despawns on a room change never pays.
function tw_bounty_place(_arg, _who) {
	var _w = string(_who);
	if (!variable_global_exists("tw_bounty_on") || !global.tw_bounty_on)
	{   global.tw_toast = _w + " -> bounties are off"; global.tw_toast_timer = 180; return false;  }
	if (!variable_global_exists("tw_points_on") || !global.tw_points_on)
	{   global.tw_toast = _w + " -> bounties need the points economy on"; global.tw_toast_timer = 240; return false;  }
	var _parts = string_split(tw_trim(string_lower(string(_arg))), " ", true);
	var _name = "", _amt = 20;
	for (var _i = 0; _i < array_length(_parts); _i++)
	{
		var _p = _parts[_i]; if (_p == "") continue;
		if (string_digits(_p) == _p) _amt = tw_num(_p, 20); else if (_name == "") _name = _p;
	}
	var _obj = (_name == "") ? undefined : tw_spawn_obj(_name);
	if (is_undefined(_obj) || _obj == noone)
	{   global.tw_toast = "!bounty daira 20  (daira moblin goriya zora stalfos bat atta myu)"; global.tw_toast_timer = 300; return false;  }
	_amt = clamp(floor(_amt), 5, 100);
	if (!ds_exists(global.tw_bounties, ds_type_map)) global.tw_bounties = ds_map_create();
	if (!ds_exists(global.tw_bounty_prev, ds_type_map)) global.tw_bounty_prev = ds_map_create();
	var _open = global.tw_bounties[? _name];
	if (!is_undefined(_open))
	{   global.tw_toast = _w + " -> there is already a bounty on " + _name; global.tw_toast_timer = 240; return false;  }
	var _k = string_lower(_w); var _have = tw_points_get(_k);
	if (!tw_points_is_free(_k) && _have < _amt)
	{   global.tw_toast = _w + " -> bounty needs " + string(_amt) + " pts (has " + string(floor(_have)) + ")"; global.tw_toast_timer = 240; return false;  }
	if (!tw_points_is_free(_k)) tw_points_add(_k, -_amt);
	global.tw_bounties[? _name]   = _k + "," + string(_amt);
	global.tw_bounty_prev[? _name] = instance_number(_obj);
	global.tw_bounty_room          = room;
	tw_toast_push("BOUNTY: " + string(_amt) + " ON THE NEXT " + string_upper(_name), "by " + _w + ", pays 2x", "chat");
	return true;
}

/// @description  tw_bounty_tick() -- from twitch_tick. A bountied type's live count dropping inside the
/// same room (no transition, Link alive) is a kill: pay 2x, close the bounty.
function tw_bounty_tick() {
	if (!variable_global_exists("tw_bounties") || !ds_exists(global.tw_bounties, ds_type_map)) return;
	if (ds_map_size(global.tw_bounties) == 0) return;
	var _loading = instance_exists(g) && g.ChangeRoom_timer > 0;
	var _alive   = instance_exists(global.pc) && !global.pc.is_dead;
	if (room != global.tw_bounty_room || _loading)
	{   // new room: re-baseline every count, no payout for what vanished in the move
		var _r = ds_map_find_first(global.tw_bounties);
		while (!is_undefined(_r)) { var _ro = tw_spawn_obj(_r); global.tw_bounty_prev[? _r] = (is_undefined(_ro) || _ro == noone) ? 0 : instance_number(_ro); _r = ds_map_find_next(global.tw_bounties, _r); }
		global.tw_bounty_room = room;
		return;
	}
	var _k = ds_map_find_first(global.tw_bounties);
	while (!is_undefined(_k))
	{
		var _next = ds_map_find_next(global.tw_bounties, _k);
		var _obj  = tw_spawn_obj(_k);
		var _now  = (is_undefined(_obj) || _obj == noone) ? 0 : instance_number(_obj);
		var _prev = global.tw_bounty_prev[? _k]; if (is_undefined(_prev)) _prev = _now;
		if (_now < _prev && _alive)
		{
			var _v = string(global.tw_bounties[? _k]); var _p = string_pos(",", _v);
			var _who = string_copy(_v, 1, _p - 1); var _amt = tw_num(string_delete(_v, 1, _p), 0);
			tw_points_add(_who, _amt * 2);
			tw_toast_push("BOUNTY CLAIMED: " + string_upper(_k), _who + " +" + string(_amt * 2), "win");
			ds_map_delete(global.tw_bounties, _k);
		}
		else global.tw_bounty_prev[? _k] = _now;
		_k = _next;
	}
}

/// @description  tw_vote_line() -- one-line status for the EFFECT TIMERS strip, "" when no vote runs.
function tw_vote_line() {
	if (!tw_vote_active()) return "";
	var _v = global.tw_vote;
	return "VOTE " + string_upper(_v.a) + " " + string(_v.na) + " : " + string_upper(_v.b) + " " + string(_v.nb) + "  " + string(ceil(_v.frames / 60)) + "S";
}
