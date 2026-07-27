// Async - Networking (eventType 7 / eventNum 68) -- the HTTP request path.
// Same event shape as obj_twitch_irc, but this is a SERVER socket.
//
// LOOPBACK ONLY. network_create_server binds every interface, so without this
// check anyone on the LAN could drive the game's music. A companion UI is not
// worth handing strangers a remote control.

var _type = async_load[? "type"];

if (_type == network_type_connect)
{
    // Windows hands us the IPv4-mapped IPv6 form "::ffff:127.0.0.1" as often as
    // a plain "127.0.0.1", so strip that prefix before comparing. Matching only
    // the bare form refuses every real local browser.
    var _ip = string(async_load[? "ip"]);
    if (string_copy(_ip, 1, 7) == "::ffff:") _ip = string_delete(_ip, 1, 7);

    if (_ip != "127.0.0.1" && _ip != "::1" && _ip != "0:0:0:0:0:0:0:1" && _ip != "localhost")
    {
        if (DEV) show_debug_message("[ZWEB] refused non-local client " + string(_ip));
        network_destroy(async_load[? "socket"]);
    }
    exit;
}

if (_type != network_type_data) exit;

var _sock = async_load[? "id"];
var _buf  = async_load[? "buffer"];
var _size = async_load[? "size"];
if (_buf < 0 || _size <= 0) exit;

buffer_seek(_buf, buffer_seek_start, 0);
var _req = buffer_read(_buf, buffer_text);

// Request line: "GET /path?query HTTP/1.1"
var _sp1 = string_pos(" ", _req);
if (_sp1 <= 0) exit;
var _rest = string_delete(_req, 1, _sp1);
var _sp2  = string_pos(" ", _rest);
if (_sp2 <= 0) exit;
var _target = string_copy(_rest, 1, _sp2 - 1);

var _path  = _target;
var _query = "";
var _q = string_pos("?", _target);
if (_q > 0)
{
    _path  = string_copy(_target, 1, _q - 1);
    _query = string_copy(_target, _q + 1, string_length(_target) - _q);
}

if (DEV) show_debug_message("[ZWEB] " + _path + (_query != "" ? "?" + _query : ""));

switch (_path)
{
    // GRANT for tracker verification. DEV-gated.
    //
    // Warping to each item does not work: several are SHOP PURCHASES (both maps),
    // some rooms drop you inside geometry at exit 00, and a few need progression to
    // reach at all. Verifying 25 items + 9 spells + keys + crystals by playing to
    // each one is hours; this is seconds, and it also tests the UNLIT direction,
    // which picking things up never can.
    //
    //   /give?items=N      OR N into f.items       (bitmask)
    //   /give?spells=N     OR N into f.spells
    //   /give?skills=N     OR N into f.skills
    //   /give?cucco=N      OR N into f.Cucco_skills
    //   /give?crystals=N   set crystals bitfield
    //   /give?all=1        everything on
    //   /give?clear=1      everything off  (runs BEFORE the others, so
    //                      ?clear=1&items=255 means "reset then grant")
    case "/give":
        if (!dev_avail()) { zweb_send(_sock, "403 Forbidden", "text/plain", "dev only"); break; }

        if (zweb_qs_has(_query, "clear"))
        {
            f.items = 0; f.spells = 0; f.skills = 0;
            f.Cucco_skills = 0; f.crystals = 0;
            g.CuccoSpell2_Acquired = 0;
            g.spells_active = 0;
            f.dm_quests[? STR_Bottle + "01" + STR_State] = 0;

            var _cd, _ck, _ckid, _ckc;
            for (_cd = 1; _cd <= 6; _cd++)
            {
                _ckc = val(g.dm_spawn[? STR_Dungeon + hex_str(_cd) + STR_Key + STR_Count]);
                for (_ck = 1; _ck <= _ckc; _ck++)
                {
                    _ckid = STR_KEY + hex_str(_cd) + hex_str(_ck);
                    f.dm_keys[? _ckid + STR_Acquired] = false;
                    f.dm_keys[? _ckid + STR_Used]     = false;
                }
            }
        }

        if (zweb_qs_has(_query, "all"))
        {
            // Only the bits that are REAL -- see the ITEMS/SPELLS/SKILLS tables in
            // tracker.html. Granting every bit would light slots that no longer
            // exist (TABLET/MELODY/FEATHER) and prove nothing.
            f.items        = ITM_CAND|ITM_GLOV|ITM_RAFT|ITM_BOOT|ITM_FLUT|ITM_CROS
                           | ITM_HAMM|ITM_BRAC|ITM_FRY1|ITM_MASK|ITM_BOOK|ITM_MEAT
                           | ITM_SHLD|ITM_RING|ITM_NKLC|ITM_SWRD|ITM_NOTE|ITM_MIRR
                           | ITM_TRPH|ITM_MEDI|ITM_CHLD|ITM_BTL1|ITM_SKEY|ITM_MAP1|ITM_MAP2;
            f.spells       = SPL_PRTC|SPL_JUMP|SPL_LIFE|SPL_FARY|SPL_FIRE
                           | SPL_RFLC|SPL_SPEL|SPL_THUN|SPL_SUMM;
            f.skills       = SKILL_THD|SKILL_THU;
            f.Cucco_skills = f.CuccoSkill_THRUST_D|f.CuccoSkill_THRUST_U
                           | f.CuccoSkill_BREAK1|f.CuccoSkill_PROJ1|f.CuccoSkill_PROJ2;
            g.CuccoSpell2_Acquired = 1;
            f.crystals     = $3F; // all six placed

            // Bottle FILLED with blood -- normally only from killing Dark Link
            // (Cutscene_ShadowBoss_2_update.gml:489) and it gates the extra ending.
            // Without this ?all=1 leaves the bottle in its unfilled state and the
            // tracker's third bottle state can never be seen.
            f.dm_quests[? STR_Bottle + "01" + STR_State] = 1;

            // every key found, none spent -- the state a full clear leaves you in
            var _ad, _ak, _akid, _akc;
            for (_ad = 1; _ad <= 6; _ad++)
            {
                _akc = val(g.dm_spawn[? STR_Dungeon + hex_str(_ad) + STR_Key + STR_Count]);
                for (_ak = 1; _ak <= _akc; _ak++)
                {
                    _akid = STR_KEY + hex_str(_ad) + hex_str(_ak);
                    f.dm_keys[? _akid + STR_Acquired] = true;
                    f.dm_keys[? _akid + STR_Used]     = false;
                }
            }
        }

        // KEYS are not a bitfield -- they live in f.dm_keys as per-key Acquired/Used
        // flags, and the tracker shows USED / COLLECTED / TOTAL. So grant them
        // properly rather than faking a count, and allow marking some USED, because
        // "collected but not spent" vs "spent" is a display state that needs testing
        // and cannot be reached any other way without playing the palace.
        //
        //   /give?keys=1        every key in every palace -> Acquired
        //   /give?keys=1&used=2 ...and the first 2 per palace also marked Used
        //   /give?keys=0        clear all key flags
        if (zweb_qs_has(_query, "keys"))
        {
            var _kon   = (zweb_qs(_query, "keys") != "0");
            var _nused = zweb_qs_has(_query, "used") ? tw_num(zweb_qs(_query,"used"), 0) : 0;
            var _d, _k, _kid, _kcount;
            for (_d = 1; _d <= 6; _d++)
            {
                _kcount = val(g.dm_spawn[? STR_Dungeon + hex_str(_d) + STR_Key + STR_Count]);
                for (_k = 1; _k <= _kcount; _k++)
                {
                    _kid = STR_KEY + hex_str(_d) + hex_str(_k);
                    f.dm_keys[? _kid + STR_Acquired] = _kon;
                    f.dm_keys[? _kid + STR_Used]     = (_kon && _k <= _nused);
                }
            }
        }

        if (zweb_qs_has(_query, "items"))    f.items        |= tw_num(zweb_qs(_query,"items"), 0);
        if (zweb_qs_has(_query, "spells"))   f.spells       |= tw_num(zweb_qs(_query,"spells"), 0);
        if (zweb_qs_has(_query, "skills"))   f.skills       |= tw_num(zweb_qs(_query,"skills"), 0);
        if (zweb_qs_has(_query, "cucco"))    f.Cucco_skills |= tw_num(zweb_qs(_query,"cucco"), 0);
        if (zweb_qs_has(_query, "crystals")) f.crystals      = tw_num(zweb_qs(_query,"crystals"), 0);

        // ?active=N -- fake ACTIVE spell effects so the tracker's pulse can be
        // checked without standing in a fight casting things. The game clears this
        // on every room change, so it will not stick; that is correct behaviour, not
        // a bug in the route.
        if (zweb_qs_has(_query, "active"))   g.spells_active = tw_num(zweb_qs(_query,"active"), 0);

        // ?bottle=1 / 0 -- the blood fill on its own.
        if (zweb_qs_has(_query, "bottle"))
            f.dm_quests[? STR_Bottle + "01" + STR_State] = (zweb_qs(_query,"bottle") != "0");

        zweb_send(_sock, "200 OK", "text/plain",
            "items="   + string(f.items)
          + " spells=" + string(f.spells)
          + " skills=" + string(f.skills)
          + " cucco="  + string(f.Cucco_skills)
          + " crystals=" + string(f.crystals));
    break;

    // Hub page. The OPTIONS menu opens THIS rather than three separate rows -- that
    // menu does not scroll and three launchers pushed CLOSE off the bottom.
    case "/home":
        var _hm = zweb_read_file(web_root + "home.html");
        if (_hm == "") zweb_send(_sock, "404 Not Found", "text/plain", "home.html missing");
        else           zweb_send(_sock, "200 OK", "text/html; charset=utf-8", _hm);
    break;

    // "/" stays on the jukebox: the dev .cmd files and old bookmarks point at it.
    case "/":
    case "/jukebox":
        var _html = zweb_read_file(web_root + "jukebox.html");
        if (_html == "") zweb_send(_sock, "404 Not Found", "text/plain", "jukebox.html missing");
        else             zweb_send(_sock, "200 OK", "text/html; charset=utf-8", _html);
    break;

    // The track list the game already exports for the companion.
    case "/list":
        jukebox_export_list();
        var _json = zweb_read_file(working_directory + "jukebox_list.json");
        zweb_send(_sock, "200 OK", "application/json",
                  _json == "" ? "{\"count\":0,\"tracks\":[],\"playlist\":0}" : _json);
    break;

    // What is playing RIGHT NOW. Polled by the page so the highlight follows the
    // game's own next/prev/auto-advance and the jukebox HUD -- not just the last
    // row the user happened to click.
    case "/now":
        var _on   = variable_global_exists("jukebox_on")  ? (global.jukebox_on ? 1 : 0) : 0;
        var _paused = (variable_global_exists("jukebox_inst") && global.jukebox_inst
                    && audio_exists(global.jukebox_inst)
                    && audio_is_paused(global.jukebox_inst)) ? 1 : 0;
        var _idx  = variable_global_exists("jukebox_idx") ? global.jukebox_idx : -1;
        var _name = "";
        var _len  = 0;
        if (variable_global_exists("jukebox_assets")
        &&  _idx >= 0 && _idx < array_length(global.jukebox_assets))
        {
            var _a = global.jukebox_assets[_idx];
            if (_a != -1 && audio_exists(_a))
            {
                _name = audio_get_name(_a);
                var _sl = audio_sound_length(_a);
                if (is_real(_sl) && _sl > 0) _len = _sl;
            }
        }

        // Live playhead, for the seek bar.
        var _pos = 0;
        if (variable_global_exists("jukebox_inst") && global.jukebox_inst
        &&  audio_exists(global.jukebox_inst) && audio_is_playing(global.jukebox_inst))
        {
            _pos = audio_sound_get_track_position(global.jukebox_inst);
        }

        zweb_send(_sock, "200 OK", "application/json",
              "{\"on\":" + string(_on) + ",\"idx\":" + string(_idx)
            + ",\"asset\":\"" + _name + "\""
            + ",\"pos\":" + string(_pos) + ",\"len\":" + string(_len)
            + ",\"vol\":" + string(instance_exists(Audio) ? Audio.mus_vol : 5)
            + ",\"paused\":" + string(_paused) + "}");
    break;

    // Display names. Plain data, hand-correctable, no rebuild to change.
    case "/tags":
        var _tags = zweb_read_file(web_root + "jukebox_tags.json");
        zweb_send(_sock, "200 OK", "application/json", _tags == "" ? "{}" : _tags);
    break;

    // Drop the command exactly where the companion always dropped it and let
    // jukebox_poll_cmd() pick it up next frame. One command path, not two.
    case "/cmd":
        var _c = "";
        if (string_copy(_query, 1, 2) == "c=")
            _c = zweb_url_decode(string_delete(_query, 1, 2));

        if (_c != "")
        {
            var _f = file_text_open_write(working_directory + "jukebox_cmd.txt");
            if (_f != -1)
            {
                file_text_write_string(_f, _c);
                file_text_close(_f);
            }
        }
        zweb_send(_sock, "200 OK", "text/plain", "ok");
    break;

    // ---- TRACKER ----------------------------------------------------------
    case "/tracker":
        var _tk = zweb_read_file(web_root + "tracker.html");
        if (_tk == "") zweb_send(_sock, "404 Not Found", "text/plain", "tracker.html missing");
        else           zweb_send(_sock, "200 OK", "text/html; charset=utf-8", _tk);
    break;

    // The game already writes this for the EmoTracker bridge; serve it straight
    // through. No memory reading, no admin rights, no AV warnings -- the whole
    // reason the old z2aol_watch.exe bridge existed goes away.
    case "/tracker/state":
        tracker_state_write();
        var _ts = zweb_read_file(working_directory + "tracker_state.json");
        zweb_send(_sock, "200 OK", "application/json", _ts == "" ? "{}" : _ts);
    break;

    // ---- DEV: WARP TO A SCENE ---------------------------------------------
    // /warp?rm=_WestA_5A00   (AREA + room hex + exit hex -- the same goto-name
    // the sweep tool uses). Replicates sweep_warp_to() verbatim rather than
    // reimplementing the exit construction, so it cannot drift from the tool
    // that is known to work.
    //
    // The room warper can only step scene-by-scene with the arrow keys; there is
    // no "jump to this one" input, which makes reaching a specific scene for a
    // one-off test tedious. DEV-gated.
    // One-shot tool: dump every item icon as a PNG with the pal-swap shader
    // applied, so the tracker can show TRUE colours instead of the base palette
    // the sprite files are stored in. See icon_export() for the full reasoning.
    // DEV-gated -- it writes files and is a build-time tool, not a feature.
    case "/icons/export":
        if (!dev_avail()) { zweb_send(_sock, "403 Forbidden", "text/plain", "dev only"); break; }
        var _cnt = icon_export();
        zweb_send(_sock, "200 OK", "text/plain",
            "exported " + string(_cnt) + " icons to " + working_directory + "icon_export\\");
    break;

    case "/warp":
        // Was `if (!DEV)` -- and `#macro DEV` is hardcoded true, so this route was
        // never actually gated: any page on this machine could teleport the player
        // mid-run. dev_avail() is the RUNTIME gate. (2026-07-27)
        if (!dev_avail()) { zweb_send(_sock, "403 Forbidden", "text/plain", "dev only"); break; }

        var _rmn = zweb_qs(_query, "rm");
        if (_rmn == "")
        {
            zweb_send(_sock, "200 OK", "text/plain",
                "usage: /warp?rm=_WestA_5A00   (area + room hex + exit hex)");
            break;
        }

        // exit hex defaults to 00 when the caller gives just the scene
        if (string_length(_rmn) == RmName_LEN) _rmn += "00";

        g.exit_leave = Exit_construct(EXIT_NAME_GAME_START);
        with (g.exit_leave)
        {
            goToExitName = _rmn;
            goToExitNum  = str_hex(string_copy(goToExitName, RmName_LEN-1, 2));
            goToRoom     = string_copy(goToExitName, 1, RmName_LEN);
        }

        // SPAWN AT THE DOOR, NOT AT 0,0.
        //
        // set_pc_spawn_xy() looks the position up as
        //   g.dm_rm[ scene + strR(f.reen, RmName_LEN+1) + STR_Spawn_x/y ]
        // and data_exit stores it under area+roomhex+exithex -- exactly the string
        // we were handed. But f.reen is only assigned inside the _EXITING_RM branch
        // of update_change_room_1a, and fabricating an exit here never trips that
        // path. So the lookup used a stale reen, val() defaulted to 0, and the
        // player materialised at literal 0,0 -- the top-left corner, inside the
        // wall, having to jump out and re-enter through the door every single warp.
        f.reen = _rmn;
        if (DEV) show_debug_message("[ZWEB] warp -> " + _rmn);
        zweb_send(_sock, "200 OK", "text/plain", "warping to " + _rmn);
    break;

    // ---- TWITCH SETUP -----------------------------------------------------
    case "/twitch":
        var _th = zweb_read_file(web_root + "twitch.html");
        if (_th == "") zweb_send(_sock, "404 Not Found", "text/plain", "twitch.html missing");
        else           zweb_send(_sock, "200 OK", "text/html; charset=utf-8", _th);
    break;

    case "/twitch/callback":
        var _tc = zweb_read_file(web_root + "twitch_callback.html");
        if (_tc == "") zweb_send(_sock, "404 Not Found", "text/plain", "twitch_callback.html missing");
        else           zweb_send(_sock, "200 OK", "text/html; charset=utf-8", _tc);
    break;

    // Status for the setup page. NOTE: reports only WHETHER a token exists --
    // the token itself is never sent back to any page. Nothing needs to read it
    // except the IRC connect, and a token echoed into a browser is a token that
    // ends up in a screenshot on stream.
    case "/twitch/status":
        var _cfg = zweb_twitch_cfg_read();
        var _tok = string(val(_cfg[? "token"], ""));
        var _js  = "{\"has_token\":" + string(_tok != "" ? 1 : 0)
                 + ",\"user\":\""      + string(val(_cfg[? "user"], "")) + "\""
                 + ",\"channel\":\""   + string(val(_cfg[? "channel"], "")) + "\""
                 + ",\"client_id\":\"" + string(val(_cfg[? "client_id"], "")) + "\""
                 + ",\"cooldown\":\""  + string(val(_cfg[? "cooldown"], "")) + "\""
                 + ",\"effect\":\""    + string(val(_cfg[? "effect_secs"], "")) + "\""
                 + ",\"status\":\""    + string(variable_global_exists("tw_irc_status")
                                              ? global.tw_irc_status : "idle") + "\""
                 + ",\"vs_mode\":" + string((variable_global_exists("tw_vs_mode")
                                          && global.tw_vs_mode) ? 1 : 0)
                 + ",\"vs_kills\":" + string(variable_global_exists("tw_vs_kills")
                                           ? global.tw_vs_kills : 0)
                 + ",\"enabled\":" + string((variable_global_exists("tw_enabled")
                                          && global.tw_enabled) ? 1 : 0) + "}";
        ds_map_destroy(_cfg);
        zweb_send(_sock, "200 OK", "application/json", _js);
    break;

    // Kick off the OAuth handoff. The GAME opens the URL with url_open(), which
    // launches the user's DEFAULT browser -- where they are already signed in to
    // Twitch. Doing this from the page would trap the login inside our isolated
    // window and make them sign in from scratch.
    case "/twitch/login":
        var _lc  = zweb_twitch_cfg_read();
        var _cid = string(val(_lc[? "client_id"], ""));
        ds_map_destroy(_lc);

        if (_cid == "")
        {
            zweb_send(_sock, "200 OK", "text/plain", "no client_id");
            break;
        }

        // Implicit grant: response_type=token, token comes back in the FRAGMENT.
        // Verified against dev.twitch.tv 2026-07-27.
        var _scope = zweb_qs(_query, "scope");
        if (_scope == "") _scope = "chat:read chat:edit";
        _scope = string_replace_all(_scope, " ", "+");

        var _auth = "https://id.twitch.tv/oauth2/authorize"
                  + "?response_type=token"
                  + "&client_id=" + _cid
                  + "&redirect_uri=http://localhost:" + string(ZWEB_PORT) + "/twitch/callback"
                  + "&scope=" + _scope;

        url_open(_auth);
        zweb_send(_sock, "200 OK", "text/plain", "opening browser");
    break;

    // Read-modify-write. Only the keys actually present in the query are touched,
    // so saving the channel cannot wipe the token.
    case "/twitch/save":
        var _sm = zweb_twitch_cfg_read();

        if (zweb_qs_has(_query, "token"))
        {
            var _t = zweb_qs(_query, "token");
            if (_t == "") ds_map_delete(_sm, "token");
            else          _sm[? "token"] = _t;
        }
        if (zweb_qs_has(_query, "user"))      _sm[? "user"]        = zweb_qs(_query, "user");
        if (zweb_qs_has(_query, "channel"))   _sm[? "channel"]     = zweb_qs(_query, "channel");
        if (zweb_qs_has(_query, "client_id")) _sm[? "client_id"]   = zweb_qs(_query, "client_id");

        // COOLDOWN / EFFECT LENGTH / REWARDS must take effect NOW, not on next launch.
        // These used to be menu rows that wrote the live globals directly; the menu is
        // gone (2026-07-27), so writing only the config file would leave a streamer
        // changing a value mid-stream and seeing nothing happen. Write BOTH.
        if (zweb_qs_has(_query, "cooldown"))
        {
            _sm[? "cooldown"] = zweb_qs(_query, "cooldown");
            global.tw_irc_cooldown_frames = max(0, floor(tw_num(_sm[? "cooldown"], 600)));
        }
        if (zweb_qs_has(_query, "effect"))
        {
            _sm[? "effect_secs"] = zweb_qs(_query, "effect");
            // Never 0 -- a zero-length effect is indistinguishable from a failed command.
            global.tw_effect_secs = max(1, floor(tw_num(_sm[? "effect_secs"], 5)));
        }
        if (zweb_qs_has(_query, "rewards"))
        {
            var _rw = zweb_qs(_query, "rewards");
            global.tw_enabled = (_rw == "1" || _rw == "true");
            _sm[? "rewards"]  = global.tw_enabled ? "1" : "0";
        }

        zweb_twitch_cfg_write(_sm);
        ds_map_destroy(_sm);
        zweb_send(_sock, "200 OK", "text/plain", "saved");
    break;

    // VS CHAT MODE toggle + scoreboard reset. Turning it ON also raises the
    // master gate -- a "vs chat" mode that silently ignores chat because
    // tw_enabled was still false is the kind of thing you only discover live.
    case "/twitch/vs":
        var _want = zweb_qs(_query, "on");
        if (_want != "")
        {
            global.tw_vs_mode = (_want == "1" || _want == "true");
            if (global.tw_vs_mode) global.tw_enabled = true;
            global.tw_toast       = global.tw_vs_mode ? "VS CHAT MODE ON" : "VS CHAT MODE OFF";
            global.tw_toast_timer = 180;
        }
        if (zweb_qs_has(_query, "reset")) global.tw_vs_kills = 0;
        zweb_send(_sock, "200 OK", "text/plain", "ok");
    break;

    case "/twitch/connect":
        global.tw_irc_enabled = true;
        twitch_irc_connect();
        zweb_send(_sock, "200 OK", "text/plain", "connecting");
    break;

    case "/twitch/disconnect":
        twitch_irc_disconnect();
        global.tw_irc_enabled = false;
        zweb_send(_sock, "200 OK", "text/plain", "disconnected");
    break;

    default:
        zweb_send(_sock, "404 Not Found", "text/plain", "no such page");
    break;
}
