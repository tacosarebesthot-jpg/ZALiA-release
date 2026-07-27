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

    // ---- PLAYLIST FILTER (2026-07-26) -----------------------------------------
    // Which subset of the music are we listing? See jukebox_init for the enum.
    // The set a track belongs to is NOT derivable from its asset index, so
    // jukebox_build_set_map() harvests name -> set by walking the theme index.
    var _pl = 0;
    if (variable_global_exists("jukebox_playlist")) _pl = global.jukebox_playlist;

    // PL_EXTERNAL loads .ogg files off disk and has nothing to do with the
    // audiogroup scan below, so it gets its own builder entirely.
    if (_pl == JukeboxPL.EXTERNAL)
    {
        jukebox_build_playlist_external();
        return;
    }

    var _set_of = jukebox_build_set_map();

    // ORDERING GUARD: jukebox_init() runs from g_Create(), which is BEFORE Audio.dm is
    // populated -- the boot log shows "set_map: Audio.dm not ready, empty map". With no
    // set data, every set-filtered playlist would come back EMPTY and look broken. That
    // is harmless for the default view (EVERYTHING does no filtering), but if the active
    // playlist is a filtered one at that moment, fall back to EVERYTHING for this build
    // rather than presenting an empty jukebox. The next rebuild -- on jukebox toggle-on
    // or a playlist cycle, both long after Audio.dm is live -- gets the real list.
    if (_pl != JukeboxPL.EVERYTHING && ds_map_size(_set_of) == 0)
    {
        if (DEV) show_debug_message("[JUKEBOX] set map empty (Audio.dm not ready yet) -- "
            + "falling back to EVERYTHING for this build");
        _pl = JukeboxPL.EVERYTHING;
    }

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

        // STINGER + INTRO-PART FILTER (2026-07-26): the list was carrying every short
        // fanfare (GetItem, GetSpell, LevelUp, Fanfare, PlaceCrystal, DungeonClear...) once
        // per SET, which is dozens of 1-3 second jingles nobody wants to sit on in a jukebox.
        // Filter by REAL DURATION, not by name: keyword matching would wrongly kill genuine
        // songs like mus_IsabelleChiming_EvilHeart and mus_Overworld_DeathMtn. Only exclude
        // when we actually got a positive length back, so an unloaded stream that reports 0
        // is kept rather than silently dropped.
        if (!_skip)
        {
            var _len = audio_sound_length(_asset);
            if (is_real(_len) && _len > 0 && _len < 15) _skip = true; // 15s = stinger cutoff
        }

        // "_Intro" assets are the intro HALF of an intro+body pair -- the body is the real
        // track and already listed, so the intro on its own is a duplicate fragment.
        if (!_skip && string_length(_name) > 6
        &&  string_copy(_name, string_length(_name) - 5, 6) == "_Intro") _skip = true;

        // STINGER SUFFIX FILTER (2026-07-26). The duration test above is the right idea
        // but it only fires when audio_sound_length() returns a real number, and for a
        // lot of these it does not -- so ~50 jingles were reaching the jukebox and the
        // owner heard them as "sound effects in the music list".
        //
        // Matched on the END of the name (after any trailing digits), NOT anywhere in it.
        // That distinction matters: a plain substring test for "Heart" would kill
        // mus_IsabelleChiming_EvilHeart, which is a real song. A suffix test cannot,
        // because these jingles are always named <set>_<Event>.
        if (!_skip)
        {
            var _base = _name;
            while (string_length(_base) > 0
            &&     string_digits(string_char_at(_base, string_length(_base))) != "")
            {   _base = string_copy(_base, 1, string_length(_base) - 1);  }

            var _stingers = ["GetItem","Get_Spell","GetSpell","Fanfare","DungeonClear",
                             "GameClear","GameOver","GameStart","LevelUp","PlaceCrystal",
                             "SecretFound","Jingle","Victory","Triforce",
                             // Flute is the WARP FLUTE cue -- a sound effect that happens
                             // to carry a mus_ prefix, so the audiogroup scan picks it up.
                             "Flute"];

            for (var _st = 0; _st < array_length(_stingers); _st++)
            {
                var _tk = _stingers[_st];
                var _tl = string_length(_tk);
                if (string_length(_base) < _tl) continue;
                if (string_lower(string_copy(_base, string_length(_base) - _tl + 1, _tl))
                 == string_lower(_tk))
                {   _skip = true; break;  }
            }
        }

        if (!_skip)
        {
            // ASSIGNED = sound was registered in Audio.dm via add_sound_data().
            // The key "_AudioGroup" is set at line 47 of add_sound_data for every
            // call regardless of whether a theme string was supplied.
            var _is_assigned = false;
            if (_has_dm)
                _is_assigned = !is_undefined(Audio.dm[?_name + "_AudioGroup"]);

            // ---- apply the playlist filter ------------------------------------
            // A track with no set at all is UNREGISTERED (a standalone import that
            // never went through add_sound_data with a theme). Those belong only to
            // EVERYTHING, since no soundtrack pack claims them.
            var _set = _set_of[?_name];              // undefined = no set
            switch (_pl)
            {
                case JukeboxPL.HOVERBAT_OG:
                    // HoverBat's original soundtrack only.
                    if (is_undefined(_set) || _set != STR_Default) _skip = true;
                break;

                case JukeboxPL.REMIXED_NES:
                    // Every HoverBat set EXCEPT the original -- and excluding the
                    // player's own imports, which get their own list.
                    if (is_undefined(_set) || _set == STR_Default || _set == dk_NESmix) _skip = true;
                break;

                case JukeboxPL.MY_NESMIX:
                    // The player's own added tracks (registered under _NESmix).
                    if (is_undefined(_set) || _set != dk_NESmix) _skip = true;
                break;

                case JukeboxPL.EVERYTHING:
                default:
                    // no filtering -- registered and unregistered alike
                break;
            }

            if (_skip)
            {
                _i++;
                continue;
            }

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
    // A filtered playlist legitimately CAN come back empty (e.g. the player has
    // imported nothing of their own yet). Report which list was empty rather than
    // implying the whole audiogroup is.
    if (_count == 0)
    {
        global.jukebox_count  = 0;
        global.jukebox_assets = [];
        global.jukebox_names  = [];
        global.jukebox_idx    = 0;
        if (variable_global_exists("jukebox_msg"))
        {
            global.jukebox_msg       = jukebox_playlist_name(_pl) + " IS EMPTY";
            global.jukebox_msg_timer = 120;
        }
        if (DEV) show_debug_message("[JUKEBOX] build_playlist: 0 tracks for playlist "
            + jukebox_playlist_name(_pl));
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

    // Keep the companion window's view in step with whatever we just built.
    jukebox_export_list();

    if (DEV) show_debug_message("[JUKEBOX] build_playlist [" + jukebox_playlist_name(_pl) + "]: "
        + string(_count) + " tracks ("
        + string(_un_count) + " unassigned, " + string(_as_count) + " assigned)");

}
