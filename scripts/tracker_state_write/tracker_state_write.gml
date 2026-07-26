/// @description  tracker_state_write()
function tracker_state_write() {

	// ── 2nd-window companion tracker: STATE WRITER (file-IPC) ───────────────────
	// Serializes the live tracker state to "tracker_state.json" (relative -> lands
	// in the game's save area, %LOCALAPPDATA%\ZALiA\, same as the flag files). A
	// separate small GM2026 "ZALiA Tracker" process reads + redraws it. Bitfields
	// (items/spells/skills/crystals) are emitted RAW; the companion decodes them
	// with the corrected SPL_ spell order. Keys are emitted as BOTH gathered
	// (get_key_count_acquired = never decrements) and held (get_key_count = left),
	// so the companion can show "<held>/<found>" and avoid the old "first key shows
	// 0" bug. Hints (when enabled) are resolved here into final 38-char lines.
	// Called every 4 frames from g_Step(). Self-guards on instance_exists(f).

	// No save loaded. Careful here -- this is the "tracker icons didn't carry over"
	// bug (RECONCILE P6-6 / master list B68).
	//
	// `f` is briefly absent during ordinary transitions: room changes, save loads,
	// death-respawn. Writing {live:false} the instant it goes missing means the
	// companion app sees the run END and blanks every icon, then sees it start again
	// a few frames later -- which reads as "the tracker lost my items". Randomizer
	// runs hit this far more often because they transition more, which is why it
	// looked rando-specific.
	//
	// So: DEBOUNCE. While f is missing, simply leave the last good payload on disk
	// (the companion keeps showing the real state). Only after f has stayed missing
	// for a sustained stretch -- i.e. we genuinely are back at the title/file-select
	// rather than mid-transition -- do we declare the run over. This writer is called
	// every 4 frames from g_Step, so ~15 consecutive misses is about one second.
	if (!instance_exists(f))
	{
	    if (!variable_global_exists("tracker_f_absent")) global.tracker_f_absent = 0;
	    global.tracker_f_absent++;

	    // Under the threshold: a transition, not an ended run. Leave the file alone.
	    if (global.tracker_f_absent < 15) return;

	    // Sustained absence -> really no save loaded. Announce it once, then stop
	    // rewriting the same payload every tick.
	    if (global.tracker_f_absent == 15)
	    {
	        var _fh0 = file_text_open_write("tracker_state.json");
	        file_text_write_string(_fh0, json_stringify({ live : false }));
	        file_text_close(_fh0);
	    }
	    return;
	}

	// f is present -- any pending absence was just a transition.
	global.tracker_f_absent = 0;

	// Selected-spell display name. dm_Spell stores names with a leading "_"
	// (e.g. "_PROTECT") — strip it so the companion shows "PROTECT".
	var _sel_name = val(g.dm_Spell[? hex_str(g.spell_selected) + STR_Name], "");
	if (string_length(_sel_name) > 0 && string_char_at(_sel_name, 1) == "_")
	    _sel_name = string_delete(_sel_name, 1, 1);

	// -- rando detection ---------------------------------------------------------
	// The SEED only matters on a RANDO run; in VANILLA f.dm_rando has no seed key
	// (val defaults it to 0), yet the companion was drawing "SEED 0". Mirror
	// FileSelect_Step's _USE_RANDO_SEED gate: a run is "rando" if ANY randomization
	// is set in the loaded save's settings map. Emit is_rando so the companion can
	// hide the SEED line, and blank the seed itself when not rando.
	var _is_rando = false;
	if (val(global.dm_save_file_settings[?STR_Randomize+STR_Item    +STR_Locations])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_PBAG    +STR_Locations])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Skill   +STR_Locations])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Spell   +STR_Locations])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Spell   +STR_Cost])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy   +STR_Method])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy   +STR_Spawner])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy   +STR_ENIGMA])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy   +STR_HP])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy   +STR_Damage])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Dungeon +STR_Room])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Dungeon +STR_Locations])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Dungeon +STR_Boss])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Town    +STR_Locations])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Level   +STR_Cost])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_XP]) )
	{
	    _is_rando = true;
	}

	// ── core fields (maps resolved on this writer side) ─────────────────────────
	var _s =
	{
	    live                : true,
	    room_name           : room_get_name(room),
	    seed                : _is_rando ? val(f.dm_rando[? STR_Rando + STR_Seed], 0) : 0,
	    is_rando            : _is_rando,

	    quest_num           : f.quest_num,
	    death_count         : f.death_count,
	    lives               : global.pc_lives,

	    level_atk           : f.level_atk,
	    level_mag           : f.level_mag,
	    level_lif           : f.level_lif,
	    xp                  : f.xp,
	    xp_next             : val(f.xpNext, 0),

	    hp                  : f.hp,
	    hp_max              : get_stat_max(STR_Heart),   // current max HP (containers*$20)
	    cont_pieces_hp      : val(f.cont_pieces_hp, 0),  // raw piece-id string (kept)
	    mp                  : f.mp,
	    mp_max              : get_stat_max(STR_Magic),   // current max MP (containers*$20)
	    cont_pieces_mp      : val(f.cont_pieces_mp, 0),  // raw piece-id string (kept)

	    // Heart / Magic CONTAINER pieces — two numbers, like keys:
	    //   *_got   = pieces collected so far (string_length(cont_pieces_*) >> 2)
	    //   *_total = pieces placed in the world = CONT_MAX * CONT_PIECE_PER (9*3 = 27)
	    hearts_got          : cont_piece_cnt_hp(),
	    hearts_total        : f.CONT_PIECE_MAX_HP,
	    magic_got           : cont_piece_cnt_mp(),
	    magic_total         : f.CONT_PIECE_MAX_MP,

	    items               : f.items,
	    // Bottle (quest-2 blood bottle): acquired = has the bottle item; full = blood
	    // collected (dm_quests STR_Bottle+"01"+STR_State == 1). val(...,0) safe-defaults.
	    bottle_acquired     : (f.items & ITM_BTL1) != 0,
	    bottle_full         : (val(f.dm_quests[? STR_Bottle + "01" + STR_State], 0) == 1),
	    spells              : f.spells,
	    skills              : f.skills,
		cucco_skills        : f.Cucco_skills,
	    crystals            : f.crystals,

	    spell_selected      : g.spell_selected,
	    spell_selected_name : _sel_name,

	    quest_timer_text    : global.QuestTimer_text,
	    quest_timer_us      : global.QuestTimer_time,
	    rando_hints_enabled : global.RandoHints_enabled,
	};

	// ── keys: emit BOTH numbers per palace (found = gathered total, held = left) ─
	_s.keys_found_p1 = get_key_count_acquired(1);
	_s.keys_found_p2 = get_key_count_acquired(2);
	_s.keys_found_p3 = get_key_count_acquired(3);
	_s.keys_found_p4 = get_key_count_acquired(4);
	_s.keys_found_p5 = get_key_count_acquired(5);
	_s.keys_found_p6 = get_key_count_acquired(6);

	_s.keys_held_p1 = get_key_count(1);
	_s.keys_held_p2 = get_key_count(2);
	_s.keys_held_p3 = get_key_count(3);
	_s.keys_held_p4 = get_key_count(4);
	_s.keys_held_p5 = get_key_count(5);
	_s.keys_held_p6 = get_key_count(6);

	// ── hints (only when the rando hint system is on) ───────────────────────────
	// Found hint numbers are stored as 2-char hex pairs in dm_RandoHintsRecorder.
	// Each found hint is emitted as a STRUCT { item, location }: item = letters of
	// the recorded item id (e.g. "CANDLE"); location = the area label of that item's
	// randomized PLACEMENT (resolved via dm_spawn, NOT the free-form hint sentence).
	if (global.RandoHints_enabled)
	{
	    var _found_nums  = val(g.dm_RandoHintsRecorder[? STR_Found + STR_Hint + STR_Num], "");
	    var _found_count = string_length(_found_nums) >> 1;

	    _s.hints_found = _found_count;
	    _s.hints_total = val(g.dm_RandoHints[? STR_Hint + STR_Count], 0);

	    // Clean "ITEM on LOCATION" hints: location = the item's randomized PLACEMENT
	    // area (NOT the free-form hint sentence). Map a 7-char area-id prefix
	    // (= AreaID_LEN chars, e.g. "_WestA_") to a clean stream label. Kept local.
	    var _area_label = function(_aid)
	    {
	        switch (_aid)
	        {
	            case Area_WestA: return "WEST HYRULE";
	            case Area_DthMt: return "DEATH MTN";
	            case Area_EastA: return "EAST HYRULE";
	            case Area_MazIs: return "MAZE ISLAND";
	            case Area_OvrwA: return "OVERWORLD";
	            case Area_PalcA: return "PALACE 1";
	            case Area_PalcB: return "PALACE 2";
	            case Area_PalcC: return "PALACE 3";
	            case Area_PalcD: return "PALACE 4";
	            case Area_PalcE: return "PALACE 5";
	            case Area_PalcF: return "PALACE 6";
	            case Area_PalcG: return "PALACE 7";
	            case Area_PalcH: return "PALACE 8";
	            case Area_TownA:
	            case Area_TownB: return "TOWN";
	            default:
	                var _trim = string_replace_all(_aid, "_", "");
	                return (_trim == "") ? "?" : _trim;
	        }
	    };

	    var _hints = [];
	    var _i;
	    for (_i = 0; _i < _found_count; _i++)
	    {
	        var _num_ = string_copy(_found_nums, (_i << 1) + 1, 2);
	        var _item = g.dm_RandoHintsRecorder[? STR_Hint + _num_ + STR_Item];
	        if (!is_undefined(_item))
	        {
	            // Item display name: letters only, e.g. "CANDLE".
	            var _it = string_letters(val(g.dm_RandoHintsRecorder[? STR_Hint + _num_ + STR_Item], ""));

	            // Location: look up this item id's randomized spawn datakey; its first
	            // AreaID_LEN chars are the area prefix, mapped to a clean label above.
	            var _sdk = g.dm_spawn[? _item + STR_Spawn + STR_Datakey + STR_Randomized];
	            var _loc = "?";
	            if (!is_undefined(_sdk))
	                _loc = _area_label(string_copy(_sdk, 1, AreaID_LEN));

	            array_push(_hints, { item : _it, location : _loc });
	        }
	    }
	    _s.hints = _hints;
	}

	// ── write ───────────────────────────────────────────────────────────────────
	var _fh = file_text_open_write("tracker_state.json");
	file_text_write_string(_fh, json_stringify(_s));
	file_text_close(_fh);

}
