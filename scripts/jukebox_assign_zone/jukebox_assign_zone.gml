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

    // add_sound_data de-duplicates per theme (its unique-track index is keyed on
    // the sound name), so re-assigning the same track is safe and will not stack
    // duplicate entries in a theme's random pool.
    for (var _i = 0; _i < array_length(_themes); _i++)
    {
        add_sound_data(_asset, 0.9, _themes[_i], dk_NESmix);
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
