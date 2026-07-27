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
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_XP])
	// ADDED 2026-07-27. The list above mirrored FileSelect_Step, but the file is
	// actually MADE a rando file by the wider test in FileSelect_register_file
	// (:23-24) -- which counts palette and dungeon-tileset too. A file randomized
	// only on colours or dungeon graphics still gets a generated seed there
	// (:197-198), so the narrower test reported is_rando:false and blanked a seed
	// line that genuinely exists. Enemy difficulty is in register_file's test too.
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Palette])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Dungeon +STR_Tileset])
	||  val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy   +STR_Difficulty]) )
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

	    // ACTIVE spells -- what is currently running ON the character, not what is
	    // merely learned. FIRE active means you can throw fireballs right now; SHIELD
	    // active is the defence buff; FAIRY active is the Cucco transform. This is a
	    // live, moment-to-moment state that the owned/unowned spell chips cannot
	    // express, and it is exactly what a viewer wants to see. Cleared on room
	    // change (g_Room_Start), so it genuinely tracks the current screen.
	    spells_active       : g.spells_active,

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

	// ── GAME OVER WARPING PENALTY (rando setup > OTHER) ─────────────────────────
	// dk_ForceQuitPenalty, chosen at file creation. It decides what a FORCED
	// ("quick") game over costs: ON charges every remaining life as a death
	// (update_QuitAppMenu:158), OFF makes it a free warp. A normal death via
	// rmB_Death is unaffected either way.
	//
	// The companion needs this because death_count means two different things
	// depending on it -- 18 deaths with the penalty on may be mostly free-warp
	// charges, not 18 real deaths. Undefined = no choice made in setup, which the
	// game treats as ON, so mirror that default here rather than showing "off".
	var _fqp = global.dm_save_file_settings[? dk_ForceQuitPenalty];
	_s.warp_penalty = is_undefined(_fqp) ? 1 : (_fqp ? 1 : 0);

	// Of death_count, the portion that was lives forfeited to a quick reset
	// rather than actual deaths. 0 on saves made before the field existed.
	_s.deaths_warped = val(f.death_count_warped, 0);
	_s.deaths_real   = max(0, f.death_count - val(f.death_count_warped, 0));

	// ── VS CHAT MODE ────────────────────────────────────────────────────────────
	// Moved here from the Twitch SETUP page 2026-07-27. The kill counter is the one
	// piece of the Twitch feature an AUDIENCE wants to look at, and setup pages do
	// not belong on stream -- they hold a channel name, a client id, and buttons that
	// change the run. The tracker is the thing pointed at OBS, so the scoreboard
	// lives here and the controls stay on the setup page.
	_s.vs_mode  = (variable_global_exists("tw_vs_mode")  && global.tw_vs_mode) ? 1 : 0;
	_s.vs_kills = variable_global_exists("tw_vs_kills") ? global.tw_vs_kills : 0;

	// ── CRYSTALS REQUIRED (rando setup > REQUIREMENTS) ──────────────────────────
	// This -- not a hardcoded 6 -- is what gates the Great Palace barrier
	// (Barrier_init2.gml:105, Barrier_update_2.gml:114/132). A seed can require
	// fewer, so a companion drawing six slots is wrong. It is ALSO the only rando
	// setting changeable mid-run (OptionsMenu_RandoOptions_update.gml:179-199),
	// so it must be re-read every write rather than cached at boot.
	_s.crystals_required =
	    val(global.dm_save_file_settings[? STR_Crystal + STR_Required + STR_Count], 6);

	// ── KAKUSU (gold slimes) REQUIRED ───────────────────────────────────────────
	// Gates a reward (Cutscene_MoaiOpenMouth_1_init_2.gml:34) and counts toward
	// completion (Cutscene_GameEnd_1B_update.gml:918). Was not exported at all.
	_s.kakusu_required =
	    val(global.dm_save_file_settings[? STR_Kakusu + STR_Required + STR_Count],
	        val(g.dm_spawn[? STR_Kakusu + STR_Count], 0));

	// HOW MANY YOU HAVE. get_kakusu_count() reads the authoritative
	// dm_kakusu[Defeated_Count] rather than f.kakusu_count, which
	// Cutscene_MoaiOpenMouth_1_init_2 overwrites with a derived value.
	// Required is a RANDO SETTING, so the denominator moves per seed -- which is
	// exactly why the pair has to be exported rather than a bare count.
	_s.kakusu_got = get_kakusu_count();

	// ── CONTAINERS GRANTED AT FILE CREATION ─────────────────────────────────────
	// START HEART/MAGIC CONTAINERS pre-fill the piece string in
	// FileSelect_register_file.gml:110-131, so hearts_got/magic_got are NEVER 0 at
	// the start of a run -- a default file already reads 9/27. Exporting the
	// baseline lets a companion show "found since the run began" instead of
	// counting the handout as progress.
	_s.start_containers_hp =
	    val(global.dm_save_file_settings[? STR_File + STR_Start + STR_Container + STR_HP], 3);
	_s.start_containers_mp =
	    val(global.dm_save_file_settings[? STR_File + STR_Start + STR_Container + STR_MP], 3);

	// ── keys: TOTAL placed in each palace ───────────────────────────────────────
	// Same source the in-game key readout uses (draw_key_stats.gml:73), so the two
	// can never disagree. With found + held + total the companion can show all
	// three numbers a runner actually wants: USED (found-held), COLLECTED (found),
	// and TOTAL. Rando changes these per seed, which is exactly why the total has
	// to be read from dm_spawn rather than hardcoded to the vanilla counts.
	for (var _kp = 1; _kp <= 6; _kp++)
	{
	    _s[$ ("keys_total_p" + string(_kp))] =
	        val(g.dm_spawn[? STR_Dungeon + hex_str(_kp) + STR_Key + STR_Count]);
	}

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

	    // HINTS TOTAL -- must be the SEED's count, not the world's.
	    // g.dm_RandoHints[?STR_Hint+STR_Count] counts every hint-CAPABLE dialogue
	    // in the world data (incremented per spawn in data_spawn.gml:577-579). It
	    // is identical for every seed, so using it showed a fixed denominator
	    // ("0/38") that had nothing to do with how many hints the seed placed.
	    // f.dm_rando[?STR_Rando+STR_Hint+STR_Count] is the real per-seed count,
	    // built in Rando_generate_hints.gml:208-209 (+1 for the Zelda hint), and
	    // it is what the game itself iterates in g_Room_Start.gml:1654.
	    // NOTE: TrackerWin_draw.gml:283 still has the original bug.
	    var _seed_hints = val(f.dm_rando[? STR_Rando + STR_Hint + STR_Count], 0);
	    _s.hints_total = _seed_hints;

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

	            // Coarse area, from the item's randomized spawn datakey. Kept, but it is
	            // only ever as precise as "WESTERN HYRULE" -- see the real text below.
	            var _sdk = g.dm_spawn[? _item + STR_Spawn + STR_Datakey + STR_Randomized];
	            var _loc = "?";
	            if (!is_undefined(_sdk))
	                _loc = _area_label(string_copy(_sdk, 1, AreaID_LEN));

	            // THE GAME'S OWN SENTENCE. update_Dialogue splits the NPC's line around
	            // the item name and stores the halves, so Text01 + ITEM + Text02
	            // rebuilds exactly what the villager said ("PUSH SOME STATUES TO GET
	            // THE CANDLE"). That is the actual clue; the area label alone is too
	            // vague to act on -- owner's words: "Western Hyrule is not very
	            // specific". The "<" and ">" are the dialogue engine's line breaks.
	            var _t1 = val(g.dm_RandoHintsRecorder[? STR_Hint + _num_ + STR_Text + "01"], "");
	            var _t2 = val(g.dm_RandoHintsRecorder[? STR_Hint + _num_ + STR_Text + "02"], "");
	            var _full = _t1 + _it + _t2;
	            _full = string_replace_all(_full, "<", " ");
	            _full = string_replace_all(_full, ">", " ");

	            // WHICH TOWN GAVE IT. data_spawn records the source town per hint
	            // (STR_Other when it is not a town). Without this you cannot tell which
	            // villagers you have already exhausted, and you walk a town twice.
	            var _from = val(g.dm_RandoHints[? _num_ + STR_Area], "");
	            if (string_length(_from) > 0 && string_char_at(_from, 1) == "_")
	                _from = string_delete(_from, 1, 1);

	            // The SCENE THE ITEM IS IN. Take it from the item's own randomized spawn
	            // datakey -- the same string the area label above is derived from -- whose
	            // first RmName_LEN chars are area+room.
	            //
	            // NOT from dm_RandoHints[<n>_Rm_Name]: that is recorded when the HINT NPC
	            // spawns, so it is the NPC's room, not the item's. Using it printed
	            // "CHILD ... PALACE 4 / TownA_01" -- a town room under a palace heading,
	            // duplicating the source town in the column that answers "where do I go".
	            var _hrm = "";
	            if (!is_undefined(_sdk)) _hrm = string_copy(_sdk, 1, RmName_LEN);
	            if (string_length(_hrm) > 0 && string_char_at(_hrm, 1) == "_")
	                _hrm = string_delete(_hrm, 1, 1);

	            array_push(_hints, {
	                item     : _it,
	                location : _loc,
	                scene    : _hrm,
	                text     : _full,
	                from     : _from
	            });
	        }
	    }
	    _s.hints = _hints;
	}

	// ── BOULDER CIRCLE HINTS ────────────────────────────────────────────────────
	// The SECOND hint system, and the one the tracker was blind to. These exist in
	// EVERY game mode -- vanilla included -- because the boulder circle is a quest
	// puzzle, not a randomizer feature. Owner hit this: he got a boulder hint on a
	// vanilla file and the tracker showed nothing, because it only ever read
	// g.dm_RandoHintsRecorder (rando item locations).
	//
	// Model (new_quest_init_puzzles.gml): the eight compass directions are shuffled
	// per file. `..._Received` is a hex string of the hint numbers collected so far,
	// two chars each, in the order they were GIVEN. For each, `..._Dialogue` is the
	// direction word and the bare key is its position in the push sequence.
	var _b_order = STR_Boulder + STR_Circle + STR_Order;
	var _b_recv  = val(f.dm_quests[? _b_order + "_Received"], "");
	var _b_cnt   = string_length(_b_recv) >> 1;
	var _boulders = [];
	for (var _bi = 0; _bi < _b_cnt; _bi++)
	{
	    var _bnum = string_copy(_b_recv, (_bi << 1) + 1, 2);
	    var _bdir = val(f.dm_quests[? _b_order + _bnum + STR_Dialogue], "");

	    // PUSH ORDER IS _bnum, NOT the value stored at the bare key. Got this wrong
	    // first time: `Order<n>` holds the COMPASS INDEX of that direction (SOUTH is
	    // 5th on the compass), while `<n>` itself is the position in the push
	    // sequence. Rauru is town 1 and reported step 5, which is how it surfaced.
	    // Overworld_Draw wants the compass index because it maps to a physical
	    // boulder; the tracker wants the ORDER, because the order is the answer.
	    var _bstep    = str_hex(_bnum);
	    var _bcompass = val(f.dm_quests[? _b_order + _bnum]);
	    if (_bdir != "" && _bstep)
	    {
	        array_push(_boulders, { step : _bstep, dir : _bdir, compass : _bcompass });
	    }
	}
	_s.boulder_hints    = _boulders;
	_s.boulder_total    = val(f.dm_quests[? _b_order + STR_Count], 8);
	_s.boulder_complete = val(f.dm_quests[? STR_Boulder + STR_Circle + STR_Complete]) ? 1 : 0;

	// ── write ───────────────────────────────────────────────────────────────────
	var _fh = file_text_open_write("tracker_state.json");
	file_text_write_string(_fh, json_stringify(_s));
	file_text_close(_fh);

}
