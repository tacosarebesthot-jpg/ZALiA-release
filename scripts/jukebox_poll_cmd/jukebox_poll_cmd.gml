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

        // STOP means SILENCE (2026-07-27, owner's call). It used to mean "leave
        // jukebox mode", which handed control straight back to the area music --
        // so pressing STOP started the game's music playing instead of stopping
        // anything. Staying in jukebox mode keeps the area music gated off
        // (Audio_update_2's restart checks !global.jukebox_on), so nothing plays
        // at all. Use "off" to actually hand music back to the game.
        case "stop":
            if (global.jukebox_inst && audio_exists(global.jukebox_inst))
                audio_stop_sound(global.jukebox_inst);
            global.jukebox_inst = 0;
            global.jukebox_on   = true;   // stay in jukebox mode = stay silent
            audio_group_stop_all(audiogroup_mus);
            if (instance_exists(Audio)) Audio.mus_rm_inst = 0;
        break;

        // START -- play the current track again after a STOP.
        case "start":
            if (global.jukebox_count > 0)
            {
                global.jukebox_on = true;
                jukebox_play();
                global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps);
            }
        break;

        // PAUSE / RESUME -- hold the playhead where it is. Distinct from STOP:
        // stop discards the position, pause keeps it.
        case "pause":
            if (global.jukebox_inst && audio_exists(global.jukebox_inst)
            &&  audio_is_playing(global.jukebox_inst))
                audio_pause_sound(global.jukebox_inst);
        break;

        case "resume":
            if (global.jukebox_inst && audio_exists(global.jukebox_inst)
            &&  audio_is_paused(global.jukebox_inst))
                audio_resume_sound(global.jukebox_inst);
        break;

        // OFF -- leave jukebox mode entirely; the area music takes over again.
        // This is what "stop" used to do.
        case "off":
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

        // vol <0-10> -- music volume, the same value the options menu writes, so the
        // companion and the in-game slider cannot disagree.
        case "vol":
            if (instance_exists(Audio))
            {
                Audio.mus_vol = clamp(real(_arg), 0, 10);
                audio_group_set_gain(audiogroup_mus, Audio.mus_vol / 10, 0);
                save_game_pref();
            }
        break;

        // seek <seconds> -- move the playhead of the CURRENTLY PLAYING jukebox track
        case "seek":
            if (global.jukebox_inst && audio_exists(global.jukebox_inst)
            &&  audio_is_playing(global.jukebox_inst))
            {
                audio_sound_set_track_position(global.jukebox_inst, max(0, real(_arg)));
            }
        break;

        // assignname <mus_asset> <zone 0-7> -- bind a track to a zone BY NAME.
        //
        // Prefer this over "assign". An index only means anything relative to the
        // playlist the game currently holds; a companion showing a stale list will
        // happily assign a completely different track and look like it worked.
        // Observed for real 2026-07-27. A name cannot drift.
        case "assignname":
            var _sp3 = string_pos(" ", _arg);
            if (_sp3 > 0)
            {
                var _nm = string_copy(_arg, 1, _sp3 - 1);
                var _nz = clamp(real(string_copy(_arg, _sp3 + 1, string_length(_arg) - _sp3)), 0, 7);

                // the command file is lowercased on read, so recover the real asset
                // name by case-insensitive match against the audiogroup
                var _all = audio_group_get_assets(audiogroup_mus);
                var _hit = -1;
                for (var _k = 0; _k < array_length(_all); _k++)
                {
                    if (string_lower(audio_get_name(_all[_k])) == _nm) { _hit = _all[_k]; break; }
                }

                if (_hit != -1)
                {
                    jukebox_assign_zone(audio_get_name(_hit), _nz);
                    global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps);
                }
                else if (DEV) show_debug_message("[JUKEBOX] assignname: no asset " + _nm);
            }
        break;

        // assign <trackIdx> <zone 0-7> -- bind a track to a zone by playlist index.
        // Kept for the in-game companion; see assignname for the safe form.
        case "assign":
            var _sp2 = string_pos(" ", _arg);
            if (_sp2 > 0 && global.jukebox_count > 0)
            {
                var _ai = clamp(real(string_copy(_arg, 1, _sp2 - 1)), 0, global.jukebox_count - 1);
                var _az = clamp(real(string_copy(_arg, _sp2 + 1, string_length(_arg) - _sp2)), 0, 7);
                var _aa = global.jukebox_assets[_ai];
                if (_aa != -1 && audio_exists(_aa))
                {
                    jukebox_assign_zone(audio_get_name(_aa), _az);
                    global.jukebox_hud_timer = 3 * game_get_speed(gamespeed_fps);
                }
            }
        break;

        // mode <0|1|2> -- 0 REPEAT one track, 1 ADVANCE in order, 2 SHUFFLE.
        // Also accepts the words, because typing "shuffle" is what anyone would try.
        //
        // Switching INTO or OUT OF repeat has to restart the track: the loop flag is
        // baked into the audio instance at play time, so a running track keeps its old
        // looping behaviour until it is replayed. Without this, picking REPEAT while a
        // track is already going appears to do nothing until the next song.
        case "mode":
            var _old = variable_global_exists("jukebox_mode") ? global.jukebox_mode : JB_ADVANCE;
            var _new = _old;
            switch (_arg)
            {
                case "repeat": case "loop": case "0": _new = JB_REPEAT;  break;
                case "advance": case "next": case "1": _new = JB_ADVANCE; break;
                case "shuffle": case "random": case "2": _new = JB_SHUFFLE; break;
                default: _new = clamp(real(_arg), 0, JB_MODE_COUNT - 1); break;
            }
            global.jukebox_mode = _new;

            // Plain branches, not a chained ternary -- this GML compiler rejects
            // `a ? b : c ? d : e` outright ("unexpected symbol ?").
            var _mname = "PLAY ALL";
            if      (_new == JB_REPEAT)  _mname = "REPEAT ONE";
            else if (_new == JB_SHUFFLE) _mname = "SHUFFLE";

            global.jukebox_msg       = _mname;
            global.jukebox_msg_timer = 120;

            if ((_old == JB_REPEAT) != (_new == JB_REPEAT)
            &&  global.jukebox_on && global.jukebox_inst && global.jukebox_count > 0)
            {
                jukebox_play();
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
