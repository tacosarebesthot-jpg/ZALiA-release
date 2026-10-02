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

/// @description  tw_vote_line() -- one-line status for the EFFECT TIMERS strip, "" when no vote runs.
function tw_vote_line() {
	if (!tw_vote_active()) return "";
	var _v = global.tw_vote;
	return "VOTE " + string_upper(_v.a) + " " + string(_v.na) + " : " + string_upper(_v.b) + " " + string(_v.nb) + "  " + string(ceil(_v.frames / 60)) + "S";
}
