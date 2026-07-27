/// @description  jukebox_export_list()
// ============================================================================
// Writes every playable music track to "jukebox_list.json" in the save directory
// (%LOCALAPPDATA%\ZALiA\), for the standalone ZALiA Jukebox window to read.
//
// Same file-IPC pattern the tracker companion already uses (tracker_state.json):
// the game owns the data and writes it out; the companion is a read-only view
// plus a command file coming back. Nothing here depends on the companion
// existing -- if it is never run, this is a single file write at boot.
//
// Each entry carries the grouping the browser needs so ~440 tracks can be
// collapsed into ~15 headings rather than presented as one endless list:
//     idx    index into the EVERYTHING playlist (what the play command uses)
//     name   display name, "mus_" stripped
//     set    soundtrack pack (_Default, _SteelCrescent, _NESmix, ...) or ""
//     asset  raw asset name, so the companion can show something stable
//
// The SET comes from jukebox_build_set_map(), because a track's set is NOT
// recoverable from its asset index -- add_sound_data only records the set
// alongside a track's position within a THEME.
//
// Called once from jukebox_init(), and again whenever the playlist is rebuilt,
// so the companion sees an accurate list after any playlist switch.
// ============================================================================
function jukebox_export_list() {

    if (!variable_global_exists("jukebox_assets")) return;
    if (!variable_global_exists("jukebox_names"))  return;

    var _n = array_length(global.jukebox_assets);
    if (_n <= 0) return;

    // NOTE: do NOT gate this on is_real(). ds_map_create() returns a ds_map REFERENCE
    // in current GameMaker, not a plain number, so is_real() is false for a perfectly
    // valid map -- that check silently threw away every set and exported the whole list
    // ungrouped. Test existence directly instead.
    var _set_of   = variable_global_exists("jukebox_set_of") ? global.jukebox_set_of : -1;
    var _has_sets = false;
    if (!is_undefined(_set_of)) _has_sets = ds_exists(_set_of, ds_type_map);

    // Hand-built JSON: json_stringify on a big array of structs is fine, but this
    // keeps the file readable so the companion (and a human) can eyeball it.
    var _s = "{\n";
    _s += "  \"count\": " + string(_n) + ",\n";
    _s += "  \"playlist\": " + string(variable_global_exists("jukebox_playlist") ? global.jukebox_playlist : 0) + ",\n";
    _s += "  \"tracks\": [\n";

    for (var _i = 0; _i < _n; _i++)
    {
        var _asset = global.jukebox_assets[_i];
        var _aname = "";
        if (_asset != -1 && audio_exists(_asset)) _aname = audio_get_name(_asset);

        var _set = "";
        if (_has_sets && _aname != "")
        {
            var _v = _set_of[?_aname];
            if (!is_undefined(_v)) _set = string(_v);
        }

        // escape the few characters that would break the JSON
        var _disp = string_replace_all(string(global.jukebox_names[_i]), "\\", "");
        _disp = string_replace_all(_disp, "\"", "'");

        // Track length, so the companion can show a duration column. Streamed
        // assets can report 0 or a non-real until loaded -- emit 0 and let the
        // UI hide it rather than printing a bogus time.
        var _len = 0;
        if (_asset != -1 && audio_exists(_asset))
        {
            var _sl = audio_sound_length(_asset);
            if (is_real(_sl) && _sl > 0) _len = _sl;
        }

        _s += "    {\"idx\":" + string(_i)
            + ",\"name\":\"" + _disp + "\""
            + ",\"set\":\""  + _set + "\""
            + ",\"len\":"    + string(_len)
            + ",\"asset\":\"" + _aname + "\"}";
        if (_i < _n - 1) _s += ",";
        _s += "\n";
    }

    _s += "  ]\n}\n";

    var _fh = file_text_open_write("jukebox_list.json");
    if (_fh == -1)
    {
        if (DEV) show_debug_message("[JUKEBOX] export: could not open jukebox_list.json");
        return;
    }
    file_text_write_string(_fh, _s);
    file_text_close(_fh);

    if (DEV) show_debug_message("[JUKEBOX] exported " + string(_n) + " tracks to jukebox_list.json");

}
