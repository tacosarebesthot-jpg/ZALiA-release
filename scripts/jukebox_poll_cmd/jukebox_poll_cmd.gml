/// @description  jukebox_poll_cmd()
// ============================================================================
// Reads and consumes commands written by the standalone ZALiA Jukebox window.
//
// Protocol: the companion writes a ONE-LINE file "jukebox_cmd.txt" into the save
// directory; the game reads it, deletes it, and acts. Deliberately the same
// fire-once file-drop shape as twitch_poll's twitch_drop folder, because that
// pattern is already proven here and needs no sockets, no ports and no
// permissions -- and it degrades to nothing if the companion is never run.
//
// Commands:
//     play <idx>      play the track at that index in the current playlist
//     playlist <n>    switch playlist, rebuild, re-export the list
//     next / prev     step a track
//     stop            leave jukebox mode, area music resumes
//     on              enter jukebox mode
//
// Deleting the file BEFORE acting is deliberate: if a command somehow crashes
// the handler, it must not re-fire on the next frame in an endless loop.
//
// Called from g_Step. Cheap: one file_exists() per frame when idle.
// ============================================================================
function jukebox_poll_cmd() {

    var _path = working_directory + "jukebox_cmd.txt";
    if (!file_exists(_path)) return;

    var _line = "";
    var _fh   = file_text_open_read(_path);
    if (_fh != -1)
    {
        if (!file_text_eof(_fh)) _line = file_text_read_string(_fh);
        file_text_close(_fh);
    }

    // consume FIRST -- never risk re-firing a command that faults
    file_delete(_path);

    _line = string_lower(tw_trim(_line));
    if (_line == "") return;

    // split "verb arg"
    var _verb = _line;
    var _arg  = "";
    var _sp   = string_pos(" ", _line);
    if (_sp > 0)
    {
        _verb = string_copy(_line, 1, _sp - 1);
        _arg  = tw_trim(string_copy(_line, _sp + 1, string_length(_line) - _sp));
    }

    if (DEV) show_debug_message("[JUKEBOX] cmd: " + _verb + " " + _arg);

    switch (_verb)
    {
        case "on":
            if (!global.jukebox_on)
            {
                global.jukebox_on = true;
                jukebox_build_playlist();
                audio_group_stop_all(audiogroup_mus);
                if (instance_exists(Audio)) Audio.mus_rm_inst = 0;
                jukebox_play();
            }
        break;

        case "stop":
            if (global.jukebox_on)
            {
                global.jukebox_on = false;
                if (global.jukebox_inst && audio_exists(global.jukebox_inst))
                    audio_stop_sound(global.jukebox_inst);
                global.jukebox_inst = 0;
                // area music restarts on its own -- Audio_update_2's room-music
                // restart is gated on !global.jukebox_on
            }
        break;

        case "play":
            var _idx = real(_arg);
            if (global.jukebox_count > 0)
            {
                if (!global.jukebox_on)
                {
                    global.jukebox_on = true;
                    audio_group_stop_all(audiogroup_mus);
                    if (instance_exists(Audio)) Audio.mus_rm_inst = 0;
                }
                global.jukebox_idx = clamp(_idx, 0, global.jukebox_count - 1);
                jukebox_play();
                global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps);
            }
        break;

        case "next":
        case "prev":
            if (global.jukebox_on && global.jukebox_count > 0)
            {
                var _d = (_verb == "next") ? 1 : -1;
                global.jukebox_idx = (global.jukebox_idx + _d + global.jukebox_count) mod global.jukebox_count;
                jukebox_play();
                global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps);
            }
        break;

        case "playlist":
            global.jukebox_playlist = clamp(real(_arg), 0, JukeboxPL.COUNT - 1);
            jukebox_build_playlist();
            jukebox_export_list();
            if (global.jukebox_on && global.jukebox_count > 0) jukebox_play();
        break;
    }

}
