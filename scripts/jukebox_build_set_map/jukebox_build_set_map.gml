/// @description  jukebox_build_set_map()
// ============================================================================
// NES-MUSIC JUKEBOX: build a lookup of  track asset NAME -> audio SET name.
//
// Why this exists: the jukebox playlists need to split tracks by which
// soundtrack pack they belong to (HoverBat's original "_Default", one of
// HoverBat's remix sets, or the player's own "_NESmix" imports). But there is
// NO key anywhere in Audio.dm of the form  assetname + STR_Set -- add_sound_data
// only ever records the set alongside a track's position WITHIN a theme
// (add_sound_data.gml:175-210). So the set cannot be recovered from an asset
// index on its own; it has to be harvested by walking the theme index once.
//
// Walk: the master theme list is enumerable the same way Audio_Create.gml:1544
// does it --
//     count  = dm[? STR_Theme + STR_Count + STR_Music]
//     theme  = dm[? STR_Theme + STR_Music + hex_str(i)]
// and each theme carries a de-duplicated track list --
//     _dk    = theme + STR_Unique + STR_Track
//     count  = dm[? _dk + STR_Count]
//     asset  = dm[? _dk + hex_str(n)]
//     set    = dm[? _dk + hex_str(n) + STR_Set]
//
// FIRST WIN: a track registered into several themes (the NESmix pool tracks are
// registered into every theme of their category) carries the same set each
// time, so the first hit is authoritative and re-visits are skipped cheaply.
//
// Returns the ds_map and also stores it in global.jukebox_set_of. The caller
// owns it; jukebox_build_playlist() rebuilds it each time so a set assignment
// changed at runtime is picked up.
//
// Play-safe (NOT DEV-gated). Reversible: delete this script + its yyp/.yy entry
// and the call in jukebox_build_playlist().
// ============================================================================
function jukebox_build_set_map() {

    // Destroy a previous map so repeated playlist rebuilds cannot leak.
    // Same is_real() trap as in jukebox_export_list: ds_map_create() returns a
    // REFERENCE, so is_real() is false and this destroy never fired -- leaking one
    // ds_map on every playlist rebuild.
    if (variable_global_exists("jukebox_set_of")
    &&  !is_undefined(global.jukebox_set_of)
    &&  ds_exists(global.jukebox_set_of, ds_type_map))
    {
        ds_map_destroy(global.jukebox_set_of);
    }

    var _map = ds_map_create();
    global.jukebox_set_of = _map;

    // Audio.dm must be live before any of this is meaningful.
    if (!instance_exists(Audio)
    ||  !variable_instance_exists(Audio, "dm")
    ||  !ds_exists(Audio.dm, ds_type_map))
    {
        if (DEV) show_debug_message("[JUKEBOX] set_map: Audio.dm not ready, empty map");
        return _map;
    }

    var _dm          = Audio.dm;
    var _theme_count = val(_dm[?STR_Theme + STR_Count + STR_Music]);
    var _pairs       = 0;

    for (var _i = 1; _i <= _theme_count; _i++)
    {
        var _theme = _dm[?STR_Theme + STR_Music + hex_str(_i)];
        if (is_undefined(_theme)) continue;

        // de-duplicated per-theme track list
        var _dk    = _theme + STR_Unique + STR_Track;
        var _count = val(_dm[?_dk + STR_Count]);

        for (var _n = 1; _n <= _count; _n++)
        {
            var _asset = _dm[?_dk + hex_str(_n)];
            if (is_undefined(_asset)) continue;
            if (!audio_exists(_asset))  continue;

            var _name = audio_get_name(_asset);
            if (!is_undefined(_map[?_name])) continue; // first win, already recorded

            var _set = _dm[?_dk + hex_str(_n) + STR_Set];
            if (is_undefined(_set)) continue;

            _map[?_name] = _set;
            _pairs++;
        }
    }

    if (DEV) show_debug_message("[JUKEBOX] set_map: " + string(_pairs)
        + " tracks mapped across " + string(_theme_count) + " themes");

    return _map;

}
