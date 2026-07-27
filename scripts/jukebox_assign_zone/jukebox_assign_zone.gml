/// @description  jukebox_assign_zone(asset_name, zone, *persist)
/// @param asset_name  raw mus_* asset name
/// @param zone        0..6, see jukebox_zone_themes
/// @param persist     optional, default true -- false while replaying the save file
// ============================================================================
// Registers a track into a ZONE so it actually plays there. Takes effect
// immediately and survives restart.
//
// WHY THIS EXISTS: jukebox_assign() (the END key) only ever APPENDED A LINE TO A
// LOG. It captured "current theme -> current track" into jukebox_assignments.txt
// for the dev to hand-edit into Audio_Create later. It never changed what plays.
// So "assign a track to an area" looked like a feature and was a notepad.
//
// add_sound_data() is the game's own registration lever and works at runtime, so
// calling it per theme in the zone puts the track into those themes' random
// pools exactly as a boot-time registration would.
//
// Registered under dk_NESmix, matching how the owner's imported tracks are
// already binned.
// ============================================================================
function jukebox_assign_zone(_asset_name, _zone, _persist = true) {

    var _asset = asset_get_index(_asset_name);
    if (_asset == -1)
    {
        if (DEV) show_debug_message("[JUKEBOX] assign: no such asset " + string(_asset_name));
        return false;
    }

    var _themes = jukebox_zone_themes(_zone);
    if (array_length(_themes) == 0) return false;

    // Registering is only HALF the job. Under audio_set == dk_RandomCustom -- which
    // is what the owner actually plays on -- get_audio_theme_track_random() walks the
    // theme's unique-music list and skips any index whose
    //     dm_random_custom[?theme + hex_str(i) + STR_Qualified]
    // is not true. Audio_Create seeds that flag true for every track that exists AT
    // BOOT, and load_game_pref then REPLACES the whole map with the saved one
    // (load_game_pref.gml:73). A track registered later lands at a brand new index
    // that no seed and no save file ever mentions, so val(undefined)==0 and it is
    // filtered straight back out. The registration "worked" and the track still
    // never played -- which is exactly the symptom we were about to go chasing.
    //
    // So qualify each new index as we create it. This is the same flag the AUDIO
    // CUSTOM menu toggles, so the track shows up there ticked and the owner can
    // untick it; save_game_pref writes the whole map, so it persists.
    //
    // NOTE: add_sound_data de-duplicates only on the UNIQUE index (keyed by sound
    // name). Its plain per-theme track list grows on every call, so we must not call
    // it twice for the same track+theme -- see the guard below.
    for (var _i = 0; _i < array_length(_themes); _i++)
    {
        var _theme = _themes[_i];

        with (Audio)
        {
            var _sname = audio_get_name(_asset);
            var _dk_u  = _theme + STR_Unique + STR_Track;

            // Already registered in this theme? Then the plain track list already
            // counts it, and calling add_sound_data again would add a second copy
            // and skew the random pool toward it. Just make sure it is qualified.
            var _idx = dm[?_dk_u + STR_Num + _sname + STR_Music];

            if (is_undefined(_idx))
            {
                add_sound_data(_asset, 0.9, _theme, dk_NESmix);
                _idx = dm[?_dk_u + STR_Num + _sname + STR_Music];
            }

            if (!is_undefined(_idx)
            &&  !is_undefined(dm_random_custom)
            &&  ds_exists(dm_random_custom, ds_type_map))
            {
                dm_random_custom[?_theme + hex_str(_idx) + STR_Qualified] = true;
            }
        }
    }

    if (_persist)
    {
        // Append-only log, replayed at boot by jukebox_load_zones(). Append rather
        // than rewrite so a crash mid-write cannot lose earlier assignments.
        var _f = file_text_open_append(working_directory + "jukebox_zones.txt");
        if (_f != -1)
        {
            file_text_write_string(_f, _asset_name + "|" + string(_zone));
            file_text_writeln(_f);
            file_text_close(_f);
        }

        global.jukebox_msg       = string_upper(jukebox_zone_name(_zone)) + " <- "
                                 + string_upper(string_delete(_asset_name, 1, 4));
        global.jukebox_msg_timer = 150;
    }

    if (DEV) show_debug_message("[JUKEBOX] assigned " + _asset_name
        + " -> " + jukebox_zone_name(_zone) + " (" + string(array_length(_themes)) + " themes)");

    return true;

}


/// @description  jukebox_selftest() -- prove zone assignment reaches the rotation
// ============================================================================
// Automated. No human, no clicking, no walking into a town.
//
// Runs when "_jukebox_selftest.flag" is present in working_directory (same
// dev-flag shape as the _sweep_*.flag harness), from the g_Step one-shot that
// fires once Audio.dm is really populated. Writes jukebox_selftest_result.txt
// to the save directory and quits, so an unattended Igor run terminates.
//
// It samples the ACTUAL resolver the game plays through -- get_audio_theme_track()
// -- before and after an assignment. Before must be 0 hits, after must be >0.
// Asserting only "add_sound_data wrote a key" would have passed even while the
// track was being filtered out one step later, which is the exact bug this
// tests for.
// ============================================================================
function jukebox_selftest() {

    var _SAMPLES = 400;
    var _out     = "";
    var _fails   = 0;
    var _asset_name = "mus_Castlevania2_Night_Body";
    var _zone    = 2; // TOWN
    var _themes  = jukebox_zone_themes(_zone);

    var _asset = asset_get_index(_asset_name);
    if (_asset == -1)
    {
        jukebox_selftest_write("FAIL: test asset missing: " + _asset_name);
        game_end();
        return;
    }

    // Force the set the owner actually plays on. dk_RandomCustom is the only mode
    // that filters on the Qualified flag, so it is the mode that can silently drop
    // a runtime-registered track.
    var _set_before = Audio.audio_set;
    Audio.audio_set = dk_RandomCustom;

    // -- sample BEFORE -------------------------------------------------------
    var _before = jukebox_selftest_sample(_themes, _asset, _SAMPLES);
    _out += "before assign: " + string(_before) + " hits across "
          + string(array_length(_themes)) + " town themes\n";
    if (_before != 0)
    {
        _out += "  WARN: track already in the town rotation; before/after is not conclusive\n";
    }

    // -- assign --------------------------------------------------------------
    // persist=false: a test must not write into the owner's real zone file.
    var _ok = jukebox_assign_zone(_asset_name, _zone, false);
    _out += "assign returned: " + string(_ok) + "\n";
    if (!_ok) _fails++;

    // -- sample AFTER --------------------------------------------------------
    var _after = jukebox_selftest_sample(_themes, _asset, _SAMPLES);
    _out += "after assign:  " + string(_after) + " hits\n";
    if (_after <= 0)
    {
        _out += "  FAIL: assigned track never came back from get_audio_theme_track()\n";
        _fails++;
    }

    // -- assert the Qualified flag itself, per theme --------------------------
    with (Audio)
    {
        var _sname = audio_get_name(_asset);
        for (var _i = 0; _i < array_length(_themes); _i++)
        {
            var _t   = _themes[_i];
            var _idx = dm[?_t + STR_Unique + STR_Track + STR_Num + _sname + STR_Music];
            if (is_undefined(_idx))
            {
                _out += "  FAIL: " + _t + " has no unique-music index for the track\n";
                _fails++;
            }
            else if (!val(dm_random_custom[?_t + hex_str(_idx) + STR_Qualified]))
            {
                _out += "  FAIL: " + _t + " index " + string(_idx) + " is NOT qualified\n";
                _fails++;
            }
        }
    }

    // -- assign twice must not double-weight the pool ------------------------
    var _count_1 = val(Audio.dm[?_themes[0] + STR_Track + STR_Count]);
    jukebox_assign_zone(_asset_name, _zone, false);
    var _count_2 = val(Audio.dm[?_themes[0] + STR_Track + STR_Count]);
    _out += "track count on " + _themes[0] + ": " + string(_count_1)
          + " -> " + string(_count_2) + " after re-assign\n";
    if (_count_2 != _count_1)
    {
        _out += "  FAIL: re-assigning stacked a duplicate into the pool\n";
        _fails++;
    }

    Audio.audio_set = _set_before;

    _out = (_fails == 0 ? "PASS" : "FAIL (" + string(_fails) + ")") + "\n" + _out;
    jukebox_selftest_write(_out);
    game_end();

}

/// @description  jukebox_selftest_sample(themes, asset, n) -- how often does the resolver return it
function jukebox_selftest_sample(_themes, _asset, _n) {

    var _hits = 0;
    for (var _i = 0; _i < array_length(_themes); _i++)
    {
        for (var _s = 0; _s < _n; _s++)
        {
            if (get_audio_theme_track(_themes[_i]) == _asset) _hits++;
        }
    }
    return _hits;

}

/// @description  jukebox_selftest_write(text)
function jukebox_selftest_write(_text) {

    var _f = file_text_open_write(working_directory + "jukebox_selftest_result.txt");
    if (_f != -1)
    {
        file_text_write_string(_f, _text);
        file_text_close(_f);
    }
    show_debug_message("[JUKEBOX-SELFTEST] " + string_replace_all(_text, "\n", " | "));

}

/// @description  jukebox_load_zones() -- replay saved zone assignments
// Called once after Audio.dm is live (from the same one-shot in g_Step that
// rebuilds the playlist). Cannot run during Audio_Create because the theme
// structures add_sound_data writes into are still being built at that point.
function jukebox_load_zones() {

    var _path = working_directory + "jukebox_zones.txt";
    if (!file_exists(_path)) return 0;

    var _f = file_text_open_read(_path);
    if (_f == -1) return 0;

    var _n = 0;
    while (!file_text_eof(_f))
    {
        var _line = string_trim(file_text_readln(_f));
        if (_line == "") continue;

        var _bar = string_pos("|", _line);
        if (_bar <= 1) continue;

        var _name = string_copy(_line, 1, _bar - 1);
        var _zone = real(string_copy(_line, _bar + 1, string_length(_line) - _bar));

        // persist=false: we are replaying the file, not adding to it
        if (jukebox_assign_zone(_name, _zone, false)) _n++;
    }
    file_text_close(_f);

    if (DEV) show_debug_message("[JUKEBOX] replayed " + string(_n) + " saved zone assignments");
    return _n;

}
