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
///
/// @param {bool} _arm_playback  Optional, default true. Pass FALSE to restore the snapshot
///        WITHOUT arming input playback -- i.e. "put me back where I marked and give me the
///        controls". Wired to TEST/CAPTURE > SPAWN AT LAST MARK, so a tester can re-run a
///        bug from its exact state repeatedly without walking back to the spot each time.
function mark_replay_load(_arm_playback = true)
{
	// DISK FIRST (2026-07-26) -- THE actual bug behind "replay only does movement" and
	// "spawn does nothing". global.mark_snapshot is NOT your last MARK: g_Room_Start:1733
	// overwrites it at the end of EVERY room start, so it always describes the room you are
	// standing in. Restoring it is a no-op you cannot see -- replay looked like inputs-only
	// and spawn looked dead. The REAL marks are the problems/mark_NNN_state.json files that
	// mark_dump_replay writes when you press MARK, so read the newest of those FIRST and only
	// fall back to the ambient in-memory struct when no dump exists. Fully guarded: any
	// failure leaves the old behaviour untouched.
	{
	    var _mdir  = working_directory + "problems/";
	    var _best  = "";
	    var _bestn = -1;
	    var _fn    = file_find_first(_mdir + "mark_*_state.json", 0);
	    while (_fn != "")
	    {
	        var _n = real(string_digits(_fn));
	        if (_n > _bestn) { _bestn = _n; _best = _fn; }
	        _fn = file_find_next();
	    }
	    file_find_close();

	    if (_best != "" && file_exists(_mdir + _best))
	    {
	        var _jf   = file_text_open_read(_mdir + _best);
	        var _jstr = "";
	        while (!file_text_eof(_jf)) { _jstr += file_text_read_string(_jf); file_text_readln(_jf); }
	        file_text_close(_jf);

	        try
	        {
	            var _snap = json_parse(_jstr);
	            // json stores the room by NAME; room_goto() needs the asset index.
	            if (is_struct(_snap) && variable_struct_exists(_snap, "room"))
	            {
	                var _ridx = asset_get_index(string(_snap.room));
	                if (_ridx >= 0)
	                {
	                    _snap.room_name = string(_snap.room);
	                    _snap.room      = _ridx;
	                    global.mark_snapshot = _snap;
	                    show_debug_message("[MARK] replay-load: restored snapshot from disk (" + _best + ")");
	                }
	            }
	        }
	        catch (_e)
	        {
	            show_debug_message("[MARK] replay-load: disk snapshot parse failed (" + _best + ")");
	        }
	    }
	}

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

	// SCHEMA-DRIFT GUARD (2026-07-26): this used to read _s.f.* and _s.randomOG* as a fixed
	// hardcoded list, which was safe only while the snapshot came from memory. The on-disk
	// mark_NNN_state.json does NOT carry every field the in-memory struct has, so reading
	// disk-first crashed instantly on `_s.randomOG` ("not set before reading it"). Copy
	// whatever the snapshot ACTUALLY contains instead of what we assume it contains -- then
	// the two snapshot shapes can never diverge into a crash again.
	if (!variable_struct_exists(_s, "f") || !is_struct(_s.f))
	{
	    show_debug_message("[MARK] replay-load: snapshot has no f block -- aborting");
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}

	// ── 1. restore f.* save scalars (whatever this snapshot carries) ────────────
	var _f     = _s.f;
	var _names = variable_struct_get_names(_f);
	for (var _i = 0; _i < array_length(_names); _i++)
	{
	    variable_instance_set(f, _names[_i], variable_struct_get(_f, _names[_i]));
	}

	// ── 2. restore the OG LFSR RNG (copy bytes + started flag back onto g) ──────
	if (variable_struct_exists(_s, "randomOG")
	&&  is_array(_s.randomOG)
	&&  variable_instance_exists(g, "dl_RandomOG")
	&&  ds_exists(g.dl_RandomOG, ds_type_list))
	{
	    var _cnt = array_length(_s.randomOG);
	    for (var _j = 0; _j < _cnt; _j++) g.dl_RandomOG[| _j] = _s.randomOG[_j];
	}
	if (variable_struct_exists(_s, "randomOG_started")) g.RandomOG_started = _s.randomOG_started;

	// ── 3. restore the GML built-in RNG seed (irandom/random/choose) ────────────
	if (variable_struct_exists(_s, "gml_seed")) random_set_seed(_s.gml_seed);

	// ── 4. go to the snapshot room: re-inits every object deterministically ─────
	room_goto(_s.room);

	// ── 5. arm TAS playback of the dumped ring (reads TAS_recording.txt) ────────
	// Skipped when _arm_playback is false: the caller wants the state restored but the
	// controls left to the player (SPAWN AT LAST MARK).
	if (_arm_playback) tas_pb_load_start();

	show_debug_message("[MARK] replay-load: room=" + string(_s.room_name)
	    + " seed=" + string(_s.gml_seed)
	    + (_arm_playback ? " -> playback armed" : " -> SPAWN ONLY (controls yours)"));
}
