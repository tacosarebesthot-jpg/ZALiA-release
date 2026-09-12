/// @description  twitch_config_save()
// ============================================================================
// Persist the two values the TWITCH options menu can change -- cooldown and
// effect length -- back into %LOCALAPPDATA%\ZALiA\twitch_config.txt.
//
// The critical property here is that this is a REWRITE, NOT A TRUNCATE-AND-WRITE.
// That file holds the owner's oauth token. Rewriting the whole file from the
// globals we happen to know about would silently destroy the token and the
// channel name, and the failure would only show up next time they tried to
// connect. So: read every existing line, replace only the keys we own, keep
// everything else verbatim (including comments and any key added later), and
// append our keys only if they were absent.
//
// Format is `key=value`, one per line, matching twitch_irc_load_config.
// Keys owned here: `cooldown` (FRAMES, as the loader expects) and
// `effect_secs`.
//
// If the file does not exist we create it with just our two keys -- we never
// invent a token.
// ============================================================================
function twitch_config_save() {

    var _path = working_directory + "twitch_config.txt";

    if (!variable_global_exists("tw_irc_cooldown_frames")) global.tw_irc_cooldown_frames = 600;
    if (!variable_global_exists("tw_effect_secs"))         global.tw_effect_secs         = 5;

    // ---- read the existing file verbatim -----------------------------------
    var _lines = [];
    if (file_exists(_path))
    {
        var _fr = file_text_open_read(_path);
        if (_fr != -1)
        {
            while (!file_text_eof(_fr))
            {
                array_push(_lines, file_text_read_string(_fr));
                file_text_readln(_fr);
            }
            file_text_close(_fr);
        }
    }

    // ---- replace our keys in place -----------------------------------------
    var _wrote_cd  = false;
    var _wrote_dur = false;
    var _wrote_ac  = false;
    var _wrote_jk  = false;
    var _ac_val    = (variable_global_exists("tw_irc_autoconnect") && global.tw_irc_autoconnect) ? "1" : "0";
    var _jk_val    = variable_global_exists("tw_jokes_mode") ? string(global.tw_jokes_mode) : "1";
    var _wrote_as  = false;
    var _as_val    = (!variable_global_exists("tw_autosave") || global.tw_autosave) ? "1" : "0";

    for (var _i = 0; _i < array_length(_lines); _i++)
    {
        var _line = _lines[_i];
        if (!is_string(_line)) continue;

        // compare on the trimmed, lowercased key only -- leave the rest untouched
        var _eq = string_pos("=", _line);
        if (_eq <= 1) continue;

        // tw_trim, not string_trim: the loader deliberately hand-rolls this so config
        // parsing survives Windows CRLF and padding around "key = value". Use the same
        // helper so save and load agree on what a key looks like.
        var _key = string_lower(tw_trim(string_copy(_line, 1, _eq - 1)));

        if (_key == "cooldown")
        {
            _lines[_i] = "cooldown=" + string(global.tw_irc_cooldown_frames);
            _wrote_cd  = true;
        }
        else if (_key == "effect_secs")
        {
            _lines[_i] = "effect_secs=" + string(global.tw_effect_secs);
            _wrote_dur = true;
        }
        else if (_key == "autoconnect")
        {
            _lines[_i] = "autoconnect=" + _ac_val;
            _wrote_ac  = true;
        }
        else if (_key == "jokes")
        {
            _lines[_i] = "jokes=" + _jk_val;
            _wrote_jk  = true;
        }
        else if (_key == "autosave")
        {
            _lines[_i] = "autosave=" + _as_val;
            _wrote_as  = true;
        }
    }

    if (!_wrote_cd)  array_push(_lines, "cooldown="    + string(global.tw_irc_cooldown_frames));
    if (!_wrote_dur) array_push(_lines, "effect_secs=" + string(global.tw_effect_secs));
    if (!_wrote_ac)  array_push(_lines, "autoconnect=" + _ac_val); // 1 = join chat on boot (twitch_irc_step)
    if (!_wrote_jk)  array_push(_lines, "jokes=" + _jk_val);       // 0 NORMAL text, 1 CLEAN jokes, 2 DIRTY (twitch_jokes)
    if (!_wrote_as)  array_push(_lines, "autosave=" + _as_val);    // 1 = rolling checkpoints (tw_checkpoint_tick)

    // ---- write it back ------------------------------------------------------
    var _fw = file_text_open_write(_path);
    if (_fw == -1)
    {
        if (DEV) show_debug_message("[TWITCH] config save FAILED: " + _path);
        return false;
    }

    for (var _j = 0; _j < array_length(_lines); _j++)
    {
        file_text_write_string(_fw, string(_lines[_j]));
        file_text_writeln(_fw);
    }
    file_text_close(_fw);

    if (DEV) show_debug_message("[TWITCH] config saved: cooldown="
        + string(global.tw_irc_cooldown_frames) + "f effect=" + string(global.tw_effect_secs) + "s");

    return true;

}
