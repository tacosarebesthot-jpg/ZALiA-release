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
    case "/warp":
        if (!DEV) { zweb_send(_sock, "403 Forbidden", "text/plain", "dev only"); break; }

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
        if (zweb_qs_has(_query, "cooldown"))  _sm[? "cooldown"]    = zweb_qs(_query, "cooldown");
        if (zweb_qs_has(_query, "effect"))    _sm[? "effect_secs"] = zweb_qs(_query, "effect");

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
