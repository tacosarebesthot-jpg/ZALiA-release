/// @description  mark_dump_replay(mark_num)
/// @param mark_num
/// MARK -> REPRODUCIBLE REPLAY dumper. Called from the key-3 MARK handler
/// (Surface_Draw_GUI_End) with the current mark number. Serializes the always-on
/// rolling input ring (global.mark_ring, filled in Input_update2a) PLUS the
/// room-entry snapshot (global.mark_snapshot, captured at the end of g_Room_Start)
/// so the marked moment replays via the EXISTING TAS playback. Writes:
///   working_directory + "TAS_recording.txt"            (ZTAS1 stream, oldest->newest;
///                                                        tas_pb_load_start reads it as-is)
///   working_directory + "problems/mark_NNN_replay.txt" (archival copy of the same stream)
///   working_directory + "problems/mark_NNN_state.json" (snapshot: room, f.* scalars,
///                                                        both RNG states as hex, PC pose)
/// Self-guards on the ring being initialized; never throws back into gameplay.
function mark_dump_replay(_mark_num)
{
	if (!variable_global_exists("mark_ring"))
	{
	    show_debug_message("[MARK] dump skipped: input ring not initialized");
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}

	// zero-padded mark id (shares the key-3 dev_flag numbering: 001, 002, ...)
	var _ns = string(_mark_num);
	if (_mark_num < 100) _ns = "0" + _ns;
	if (_mark_num < 10)  _ns = "0" + _ns;

	var _dir = working_directory + "problems/";
	directory_create(_dir);

	// ── ring window (oldest -> newest) ──────────────────────────────────────────
	// Not yet wrapped: frames live at [0 .. filled). Wrapped: oldest is at head.
	var _n     = global.mark_ring_n;
	var _fill  = global.mark_ring_filled;
	var _start = 0;
	var _count = _fill;
	if (_fill >= _n)
	{
	    _start = global.mark_ring_head;
	    _count = _n;
	}

	// ── (a) write the ZTAS1 stream tas_pb_load_start consumes (+ an archival copy) ──
	var _paths = [ working_directory + "TAS_recording.txt",
	               _dir + "mark_" + _ns + "_replay.txt" ];
	for (var _pi = 0; _pi < array_length(_paths); _pi++)
	{
	    var _fh = file_text_open_write(_paths[_pi]);
	    if (_fh < 0)
	    {
	        show_debug_message("[MARK] dump open FAILED: " + _paths[_pi]);
	        continue; // _pi
	    }
	    file_text_write_string(_fh, "ZTAS1");
	    file_text_writeln(_fh);
	    for (var _i = 0; _i < _count; _i++)
	    {
	        var _idx = (_start + _i) mod _n;
	        file_text_write_string(_fh, string(global.mark_ring[_idx]));
	        file_text_writeln(_fh);
	    }
	    file_text_close(_fh);
	}

	// ── (b) write the room-entry snapshot JSON ──────────────────────────────────
	var _snap_json;
	if (variable_global_exists("mark_snapshot") && is_struct(global.mark_snapshot))
	{
	    var _s = global.mark_snapshot;

	    // OG LFSR list -> space-separated hex (decode-friendly + human-readable)
	    var _oghex = "";
	    if (is_array(_s.randomOG))
	    {
	        for (var _k = 0; _k < array_length(_s.randomOG); _k++)
	        {
	            if (_k > 0) _oghex += " ";
	            _oghex += hex_str(_s.randomOG[_k]);
	        }
	    }

	    var _out =
	    {
	        mark             : _mark_num,
	        room             : _s.room_name,
	        room_index       : _s.room,
	        frames           : _count,
	        f                : _s.f,
	        randomOG_hex     : _oghex,
	        randomOG_started : _s.randomOG_started,
	        gml_seed         : _s.gml_seed,
	        gml_seed_hex     : hex_str(_s.gml_seed),
	        pc               : _s.pc,
	    };
	    _snap_json = json_stringify(_out);
	}
	else
	{
	    _snap_json = json_stringify({ mark : _mark_num,
	        error : "no room snapshot captured yet (enter an action room first)" });
	}

	var _jh = file_text_open_write(_dir + "mark_" + _ns + "_state.json");
	if (_jh >= 0)
	{
	    file_text_write_string(_jh, _snap_json);
	    file_text_close(_jh);
	}

	show_debug_message("[MARK] dump #" + _ns + " frames=" + string(_count)
	    + " -> TAS_recording.txt + problems/mark_" + _ns + "_{replay.txt,state.json}");
}
