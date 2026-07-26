// PERF PROBE (2026-07-26): time the WHOLE room-start, not one suspected block at a
// time. The 8.7s stall is somewhere in this frame; this says whether it is inside
// g_Room_Start() at all, in ONE run instead of one rebuild per hypothesis.
var _t0 = get_timer();

g_Room_Start();

var _dt = get_timer() - _t0;
if (DEV && _dt > 50000)
{
    var _hf = file_text_open_append(working_directory + "fall_hitch.txt");
    file_text_write_string(_hf, "ROOMSTART rm=" + room_get_name(room)
        + " | scene=" + (instance_exists(g) ? string(g.rm_name) : "?")
        + " | total=" + string(_dt) + " us");
    file_text_writeln(_hf); file_text_close(_hf);
}
