// ZALiA built-in web server. Serves the companion pages (jukebox now, tracker
// and twitch next) straight out of the running game, so a player just opens a
// browser -- no second GameMaker window, no Python, no install.
//
// WHY A SERVER AND NOT ANOTHER GM WINDOW: the companion windows were hand-drawn
// GUIs. Every label had to be measured by hand, they clipped, and each tweak
// cost a full rebuild to look at. A browser does layout for free, and the pages
// are Included Files on disk, so editing one needs no rebuild at all.
//
// RAW sockets (network_create_server_raw): the non-raw calls prepend GameMaker's
// own packet header, which is not HTTP and browsers reject it.
//
// Commands are NOT handled here. /cmd writes the same one-line jukebox_cmd.txt
// the companion always wrote, and the existing jukebox_poll_cmd() in g_Step
// consumes it next frame. One command path, already proven, not two.

ZWEB_PORT = 8777;

// Pages live in datafiles/web/ -> copied next to the exe at build time.
web_root = working_directory + "web/";

server = network_create_server_raw(network_socket_tcp, ZWEB_PORT, 8);

global.zweb_port   = ZWEB_PORT;
global.zweb_up     = (server >= 0);
global.zweb_status = global.zweb_up
    ? ("http://127.0.0.1:" + string(ZWEB_PORT))
    : "port busy";

if (DEV)
{
    if (global.zweb_up) show_debug_message("[ZWEB] listening on " + global.zweb_status);
    else                show_debug_message("[ZWEB] could not bind port " + string(ZWEB_PORT)
                                         + " (already in use?)");
}


/// Read an Included File whole. Returns "" if missing, so a missing page is a
/// 404 rather than a crash.
function zweb_read_file(_path)
{
    if (!file_exists(_path)) return "";
    var _b = buffer_load(_path);
    if (_b < 0) return "";
    var _s = buffer_read(_b, buffer_text);
    buffer_delete(_b);
    return _s;
}


/// Send one HTTP response and let the client close the connection.
function zweb_send(_sock, _status, _ctype, _body)
{
    var _head = "HTTP/1.1 " + _status + "\r\n"
              + "Content-Type: " + _ctype + "\r\n"
              + "Content-Length: " + string(string_byte_length(_body)) + "\r\n"
              + "Cache-Control: no-store\r\n"
              + "Connection: close\r\n\r\n";

    var _buf = buffer_create(string_byte_length(_head) + string_byte_length(_body) + 4,
                             buffer_grow, 1);
    buffer_write(_buf, buffer_text, _head);
    buffer_write(_buf, buffer_text, _body);
    network_send_raw(_sock, _buf, buffer_tell(_buf));
    buffer_delete(_buf);
}


/// Pull one value out of a query string. Returns "" when the key is absent, and
/// a marker-free "" is also what an explicit "key=" means -- callers that need to
/// tell "absent" from "cleared" use zweb_qs_has().
function zweb_qs(_query, _key)
{
    var _pairs = string_split(_query, "&");
    for (var _i = 0; _i < array_length(_pairs); _i++)
    {
        var _p  = _pairs[_i];
        var _eq = string_pos("=", _p);
        if (_eq <= 1) continue;
        if (string_copy(_p, 1, _eq - 1) == _key)
            return zweb_url_decode(string_copy(_p, _eq + 1, string_length(_p) - _eq));
    }
    return "";
}

function zweb_qs_has(_query, _key)
{
    var _pairs = string_split(_query, "&");
    for (var _i = 0; _i < array_length(_pairs); _i++)
    {
        var _eq = string_pos("=", _pairs[_i]);
        if (_eq > 1 && string_copy(_pairs[_i], 1, _eq - 1) == _key) return true;
    }
    return false;
}


/// Read twitch_config.txt into a ds_map of key -> value.
function zweb_twitch_cfg_read()
{
    var _m = ds_map_create();
    var _path = working_directory + "twitch_config.txt";
    if (!file_exists(_path)) return _m;

    var _f = file_text_open_read(_path);
    if (_f == -1) return _m;

    while (!file_text_eof(_f))
    {
        var _line = string_trim(file_text_read_string(_f));
        file_text_readln(_f);
        if (_line == "" || string_char_at(_line, 1) == "#") continue;
        var _eq = string_pos("=", _line);
        if (_eq <= 1) continue;
        _m[? string_lower(string_trim(string_copy(_line, 1, _eq - 1)))]
            = string_trim(string_copy(_line, _eq + 1, string_length(_line) - _eq));
    }
    file_text_close(_f);
    return _m;
}


/// Write the map back. REWRITES the whole file, which is why the caller must
/// read-modify-write rather than write a single key -- a partial write here
/// would silently drop the user's other settings (their token, most of all).
function zweb_twitch_cfg_write(_m)
{
    var _f = file_text_open_write(working_directory + "twitch_config.txt");
    if (_f == -1) return false;

    file_text_write_string(_f, "# ZALiA Twitch config -- written by the setup page.");
    file_text_writeln(_f);
    file_text_write_string(_f, "# Your token is personal. Do not paste this file anywhere public.");
    file_text_writeln(_f);

    var _k = ds_map_find_first(_m);
    while (!is_undefined(_k))
    {
        file_text_write_string(_f, string(_k) + "=" + string(_m[? _k]));
        file_text_writeln(_f);
        _k = ds_map_find_next(_m, _k);
    }
    file_text_close(_f);
    return true;
}


/// percent-decode a query value (+ for space), enough for our command strings
function zweb_url_decode(_s)
{
    _s = string_replace_all(_s, "+", " ");
    var _out = "";
    var _i = 1;
    var _n = string_length(_s);
    while (_i <= _n)
    {
        var _c = string_char_at(_s, _i);
        if (_c == "%" && _i + 2 <= _n)
        {
            var _hex = string_copy(_s, _i + 1, 2);
            // GML has no hex parser for strings; do it by hand
            var _v = 0, _ok = true;
            for (var _h = 1; _h <= 2; _h++)
            {
                var _d  = string_upper(string_char_at(_hex, _h));
                var _dv = string_pos(_d, "0123456789ABCDEF") - 1;
                if (_dv < 0) { _ok = false; break; }
                _v = _v * 16 + _dv;
            }
            if (_ok) { _out += chr(_v); _i += 3; continue; }
        }
        _out += _c;
        _i++;
    }
    return _out;
}
