/// @description  dev_avail()
// ============================================================================
// Is the DEV TOOLS surface available to whoever is playing right now?
//
// Why this exists: the dev menus (overlays, cheats, room sweeps, TAS capture,
// bugprobe, the room warper) were reachable by any player straight from the
// OPTIONS menu. They are debugging instruments, not features -- a player who
// wanders into CHEATS or starts a 793-room sweep has broken their own game and
// will report it as a bug. This gates them WITHOUT removing them, so the owner
// still gets one keypress access on their own machine.
//
// Two ways in, deliberately:
//
//   1. SESSION unlock -- enter the dev code on the controller/keyboard
//      (see konami_check, which owns the input-sequence detection). Sets
//      global.dev_unlocked for this run only. Good for a machine you do not
//      own, or for showing someone something once.
//
//   2. PERMANENT unlock -- a file named "dev_unlock.txt" in the game's save
//      directory (%LOCALAPPDATA%\ZALiA\). Presence is enough; content is
//      ignored. Good for the owner's own box, survives restarts, and is
//      trivially removable before handing a build to anyone.
//
// The file is checked ONCE and cached, not stat-ed every frame -- this is
// called from OptionsMenu_option_is_avail, which runs per visible row per
// frame while a menu is open.
//
// NOTE this is deliberately a RUNTIME gate, not the compile-time DEV macro.
// `#macro DEV` stays true so the dev code still exists and can be switched on
// in a shipped build; what changes is that a player never SEES it. Anything
// that must vanish from a release binary entirely should keep testing DEV.
// ============================================================================
function dev_avail() {

    // Lazy init: works no matter what order this is first called in, so it does
    // not depend on being wired into g_Create.
    if (!variable_global_exists("dev_unlocked"))
    {
        global.dev_unlocked = false;
    }

    if (!variable_global_exists("dev_unlock_checked"))
    {
        global.dev_unlock_checked = true;

        // working_directory is the save area (%LOCALAPPDATA%\ZALiA\), the same
        // place the save files, twitch_config.txt and tracker_state.json live.
        if (file_exists(working_directory + "dev_unlock.txt"))
        {
            global.dev_unlocked = true;
            if (DEV) show_debug_message("[DEV] unlocked by dev_unlock.txt");
        }
    }

    return global.dev_unlocked;

}

/// @description  note_typing() -- true while the player is TYPING into an on-screen note
/// box (key-4 flag note, or the room-warper's sweep note). Every dev hotkey must check
/// this: those keys are read in Step events that run BEFORE the note box consumes the
/// keystroke, so typing "x" into a note started the automated screen sweep on Lane's
/// 09-11 stream and cost him a restart (1:45:46 "how did I make it go black").
/// `#macro DEV` is hardcoded true, so the hotkeys exist in every build; gate the typist.
function note_typing() {
	if (variable_global_exists("note_active") && global.note_active) return true;
	if (variable_global_exists("sweep_note_active") && global.sweep_note_active) return true;
	return false;
}
