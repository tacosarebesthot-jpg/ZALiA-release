/// @description  jukebox_build_playlist()
// ============================================================================
// NES-MUSIC JUKEBOX: rebuild the playlist from the actual audiogroup_mus assets
// instead of the old hard-coded mus_NESJUKE_001..056 scan.
//
// Ordering: UNASSIGNED tracks first (mus_NESJUKE_* and other standalones not
// registered in Audio.dm), then ASSIGNED tracks (game-music registered via
// add_sound_data). Within each group order follows audio_group_get_assets().
//
// Exclusions (layered-channel parts and utility assets, not standalone tracks):
//   name == "mus_gain"
//   name contains "Square1_1a"       (e.g. mus_House_1a_Square1_1a)
//   name contains "Triangle_Square"  (e.g. mus_House_1a_Triangle_Square1_1a)
//   name contains "Square1_only"     (e.g. mus_Palace_Body_Part1_Square1_only_1a)
//   name contains "Square2_1a"       (e.g. mus_House_1a_Triangle_Square2_1a)
//
// ASSIGNED detection: Audio.dm[? audio_get_name(asset)+"_AudioGroup"] is set
// by add_sound_data() (line 47) for every sound registered to a game theme.
// mus_NESJUKE_* tracks are never passed to add_sound_data so the key is
// undefined for them (= unassigned).
//
// Safety fallback: if the combined list is empty (Audio.dm not ready or the
// audiogroup is empty) we fall back to the legacy 56-track hard-coded scan so
// the jukebox never starts with 0 tracks.
//
// Called from Surface_Draw_GUI_End at the F8 toggle-ON point, before
// jukebox_play(). Cheap to call every toggle-on; keeps the list fresh.
//
// Reversible: delete this script (+ its yyp/.yy entry) and the call in
// Surface_Draw_GUI_End. Play-safe (NOT DEV-gated).
// ============================================================================
function jukebox_build_playlist() {

    // Check whether Audio.dm is ready (Audio object exists and has a live ds_map)
    var _has_dm = instance_exists(Audio)
               && variable_instance_exists(Audio, "dm")
               && ds_exists(Audio.dm, ds_type_map);

    var _all   = audio_group_get_assets(audiogroup_mus);
    var _total = array_length(_all);

    // Accumulate unassigned and assigned ids + names into parallel arrays.
    // Pre-allocate to _total (upper bound), track real counts separately.
    var _un_ids   = array_create(_total, -1);
    var _un_names = array_create(_total, "");
    var _as_ids   = array_create(_total, -1);
    var _as_names = array_create(_total, "");
    var _un_count = 0;
    var _as_count = 0;

    var _i = 0;
    repeat(_total)
    {
        var _asset = _all[_i];
        var _name  = audio_get_name(_asset);
        var _skip  = false;

        // Must start with "mus_"
        if (string_copy(_name, 1, 4) != "mus_")          _skip = true;
        else if (_name == "mus_gain")                     _skip = true;
        else if (string_pos("Square1_1a",    _name) > 0)  _skip = true;
        else if (string_pos("Triangle_Square",_name) > 0) _skip = true;
        else if (string_pos("Square1_only",  _name) > 0)  _skip = true;
        else if (string_pos("Square2_1a",    _name) > 0)  _skip = true;

        if (!_skip)
        {
            // ASSIGNED = sound was registered in Audio.dm via add_sound_data().
            // The key "_AudioGroup" is set at line 47 of add_sound_data for every
            // call regardless of whether a theme string was supplied.
            var _is_assigned = false;
            if (_has_dm)
                _is_assigned = !is_undefined(Audio.dm[?_name + "_AudioGroup"]);

            if (_is_assigned)
            {
                _as_ids[_as_count]   = _asset;
                _as_names[_as_count] = _name;
                _as_count++;
            }
            else
            {
                _un_ids[_un_count]   = _asset;
                _un_names[_un_count] = _name;
                _un_count++;
            }
        }

        _i++;
    }

    var _count = _un_count + _as_count;

    // ---- Safety fallback: empty result ----------------------------------------
    // The old fallback rebuilt a hardcoded mus_NESJUKE_001..056 list. Those assets were
    // byte-identical re-imports of tracks already present under readable names and have
    // been removed, so the scan can only ever have produced 56 x asset_get_index()==-1.
    // An empty list is now reported honestly and the jukebox simply has nothing to play,
    // rather than filling itself with invalid ids.
    if (_count == 0)
    {
        global.jukebox_count  = 0;
        global.jukebox_assets = [];
        global.jukebox_names  = [];
        global.jukebox_idx    = 0;
        if (DEV) show_debug_message("[JUKEBOX] build_playlist: no tracks found in audiogroup_mus");
        return;
    }

    // ---- Populate globals: unassigned first, then assigned --------------------
    global.jukebox_count  = _count;
    global.jukebox_assets = array_create(_count, -1);
    global.jukebox_names  = array_create(_count, "");

    var _m = 0;

    // Unassigned (mus_NESJUKE_* and other standalones)
    var _u = 0;
    repeat(_un_count)
    {
        global.jukebox_assets[_m] = _un_ids[_u];
        // Display name: strip leading "mus_" (4 chars), uppercase
        global.jukebox_names[_m]  = string_upper(string_delete(_un_names[_u], 1, 4));
        _m++;
        _u++;
    }

    // Assigned (game music tracks)
    var _a = 0;
    repeat(_as_count)
    {
        global.jukebox_assets[_m] = _as_ids[_a];
        global.jukebox_names[_m]  = string_upper(string_delete(_as_names[_a], 1, 4));
        _m++;
        _a++;
    }

    global.jukebox_idx = 0;

    if (DEV) show_debug_message("[JUKEBOX] build_playlist: " + string(_count) + " tracks ("
        + string(_un_count) + " unassigned, " + string(_as_count) + " assigned)");

}
