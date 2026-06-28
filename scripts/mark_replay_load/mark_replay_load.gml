/// @description  mark_replay_load()
/// MARK -> REPRODUCIBLE REPLAY loader. Restores the last room-entry snapshot
/// (global.mark_snapshot, captured at the end of g_Room_Start) and arms the existing
/// TAS playback so the marked moment re-runs deterministically:
///   1. restore the f.* save scalars,
///   2. copy the OG LFSR bytes (g.dl_RandomOG) + g.RandomOG_started back,
///   3. random_set_seed(saved GML seed)  -- restores irandom/random/choose,
///   4. room_goto(snapshot room)         -- g_Room_Start re-inits every object deterministically,
///   5. tas_pb_load_start()              -- loads working_directory TAS_recording.txt (the dumped ring).
/// Wired to DEV TOOLS > TEST/CAPTURE > REPLAY LAST MARK. Self-guards; logs its result.
function mark_replay_load()
{
	if (!variable_global_exists("mark_snapshot") || !is_struct(global.mark_snapshot))
	{
	    show_debug_message("[MARK] replay-load: no snapshot captured (mark a spot first)");
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}
	if (!instance_exists(f))
	{
	    show_debug_message("[MARK] replay-load: no f instance");
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}

	var _s  = global.mark_snapshot;
	var _f  = _s.f;

	// ── 1. restore f.* save scalars (mirror what file_save serializes) ──────────
	f.quest_num            = _f.quest_num;
	f.game_completed_count = _f.game_completed_count;
	f.death_count          = _f.death_count;
	f.level_atk            = _f.level_atk;
	f.level_mag            = _f.level_mag;
	f.level_lif            = _f.level_lif;
	f.cont_pieces_hp       = _f.cont_pieces_hp;
	f.cont_pieces_mp       = _f.cont_pieces_mp;
	f.spells               = _f.spells;
	f.items                = _f.items;
	f.skills               = _f.skills;
	f.Cucco_skills         = _f.Cucco_skills;
	f.crystals             = _f.crystals;
	f.hp                   = _f.hp;
	f.mp                   = _f.mp;
	f.xp                   = _f.xp;
	f.xpNext               = _f.xpNext;
	f.xpPending            = _f.xpPending;
	f.xpDrain              = _f.xpDrain;
	f.key_count            = _f.key_count;
	f.reen                 = _f.reen;

	// ── 2. restore the OG LFSR RNG (copy bytes + started flag back onto g) ──────
	if (is_array(_s.randomOG)
	&&  variable_instance_exists(g, "dl_RandomOG")
	&&  ds_exists(g.dl_RandomOG, ds_type_list))
	{
	    var _cnt = array_length(_s.randomOG);
	    for (var _i = 0; _i < _cnt; _i++) g.dl_RandomOG[| _i] = _s.randomOG[_i];
	}
	g.RandomOG_started = _s.randomOG_started;

	// ── 3. restore the GML built-in RNG seed (irandom/random/choose) ────────────
	random_set_seed(_s.gml_seed);

	// ── 4. go to the snapshot room: re-inits every object deterministically ─────
	room_goto(_s.room);

	// ── 5. arm TAS playback of the dumped ring (reads TAS_recording.txt) ────────
	tas_pb_load_start();

	show_debug_message("[MARK] replay-load: room=" + string(_s.room_name)
	    + " seed=" + string(_s.gml_seed) + " -> playback armed");
}
