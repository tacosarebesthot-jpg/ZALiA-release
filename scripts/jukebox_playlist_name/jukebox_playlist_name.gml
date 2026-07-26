/// @description  jukebox_playlist_name(playlist)
// ============================================================================
// NES-MUSIC JUKEBOX: display name for a playlist id. Kept in one place so the
// HUD, the empty-list message and the DEV logging cannot drift apart.
//
// Play-safe (NOT DEV-gated). Reversible: delete script + yyp/.yy entry.
// ============================================================================
function jukebox_playlist_name(argument0) {

    switch (argument0)
    {
        case JukeboxPL.HOVERBAT_OG:  return "HOVERBAT OG";      // the original soundtrack
        case JukeboxPL.REMIXED_NES:  return "REMIXED NES";      // HoverBat's remix sets
        case JukeboxPL.MY_NESMIX:    return "MY NES MIX";       // the player's own imports
        case JukeboxPL.EVERYTHING:   return "EVERYTHING";
        case JukeboxPL.EXTERNAL:     return "MUSIC FOLDER";     // loose .ogg files on disk
    }

    return "PLAYLIST " + string(argument0);

}
