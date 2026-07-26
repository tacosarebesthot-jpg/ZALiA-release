/// @description  jukebox_build_playlist_external()
// ============================================================================
// NES-MUSIC JUKEBOX, playlist 5: play the player's OWN music files from disk,
// with no import into the project at all. Drop .ogg files into
//     <working_directory>\music\
// and they show up in the jukebox.
//
// This is a genuinely different path from the other four playlists, and the
// difference matters:
//
//   * These are RUNTIME STREAMS created by audio_create_stream(), not project
//     assets. A runtime stream belongs to NO audiogroup, so it cannot be found
//     by audio_group_get_assets() and the normal scan will never see it.
//   * Because it is in no audiogroup, aud_play_sound() would take its SFX
//     branch (aud_play_sound.gml:36) -- it would skip the audiogroup_mus stop
//     and, worse, the audiogroup_mus master gain would not apply, so the
//     player's music volume slider would do nothing. jukebox_play() therefore
//     plays these with audio_play_sound + audio_sound_gain instead, applying
//     Audio.mus_vol by hand. See jukebox_play().
//   * Streams must be freed with audio_destroy_stream() or they leak. We keep
//     the handles in global.jukebox_streams and destroy them on every rebuild.
//
// Only .ogg is scanned. GameMaker's audio_create_stream supports ogg reliably
// across platforms; mp3 support is platform-dependent, so a stray mp3 silently
// failing to play would look like a bug in the jukebox rather than an
// unsupported format.
//
// Play-safe (NOT DEV-gated). Reversible: delete script + yyp/.yy entry and the
// EXTERNAL branch in jukebox_build_playlist().
// ============================================================================
function jukebox_build_playlist_external() {

    // ---- free the streams from the previous build ---------------------------
    // Must happen before we lose the handles, or every playlist switch leaks.
    if (variable_global_exists("jukebox_streams") && is_array(global.jukebox_streams))
    {
        for (var _s = 0; _s < array_length(global.jukebox_streams); _s++)
        {
            var _old = global.jukebox_streams[_s];
            if (_old != -1 && audio_exists(_old)) audio_destroy_stream(_old);
        }
    }
    global.jukebox_streams = [];

    var _dir = working_directory + "music\\";

    // Create the folder on first use so the player has somewhere obvious to put
    // files, rather than having to guess the path.
    if (!directory_exists(_dir)) directory_create(_dir);

    var _names  = [];
    var _assets = [];

    var _file = file_find_first(_dir + "*.ogg", 0);
    while (_file != "")
    {
        var _stream = audio_create_stream(_dir + _file);

        // audio_create_stream returns -1 on a file it cannot open (corrupt, or
        // not actually ogg despite the extension). Skip it rather than putting a
        // dead entry in the list that would silently play nothing.
        if (_stream != -1)
        {
            array_push(_assets, _stream);
            array_push(global.jukebox_streams, _stream);

            // Display name: filename without the .ogg, uppercased to match how
            // the asset-based playlists present themselves.
            var _disp = string_copy(_file, 1, string_length(_file) - 4);
            array_push(_names, string_upper(_disp));
        }
        else if (DEV)
        {
            show_debug_message("[JUKEBOX] external: could not open " + _file);
        }

        _file = file_find_next();
    }
    file_find_close();

    global.jukebox_assets = _assets;
    global.jukebox_names  = _names;
    global.jukebox_count  = array_length(_assets);
    global.jukebox_idx    = 0;

    if (global.jukebox_count == 0 && variable_global_exists("jukebox_msg"))
    {
        // Point at the actual folder -- the player cannot act on "list is empty".
        global.jukebox_msg       = "PUT .OGG FILES IN " + string_upper(_dir);
        global.jukebox_msg_timer = 240;
    }

    if (DEV) show_debug_message("[JUKEBOX] external: " + string(global.jukebox_count)
        + " .ogg files in " + _dir);

}
