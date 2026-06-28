/// @description debug_exit_audit_traversal() — traverse all rooms and verify exits match definitions
function debug_exit_audit_traversal() {

    var _i, _j, _k, _m, _idx, _str;
    var _area, _rm_name, _exit_name, _goto_name, _data;
    var _mismatch_count = 0;
    var _total_exits = 0;
    var _log = "";

    _log += "=== EXIT AUDIT TRAVERSAL START ===\n";
    _log += "Scanning all rooms for exit definition mismatches...\n\n";

    // DUNGEON/ACTION ROOMS
    for (_i = 0; _i < ds_list_size(g.dl_AREA_NAME); _i++) {
        _area = g.dl_AREA_NAME[| _i];
        if (area_is_ow(_area)) continue; // skip OW for now

        for (_j = 0; _j < $100; _j++) {
            _rm_name = _area + hex_str(_j);

            for (_k = 0; _k < ds_list_size(g.dl_exit_dirs); _k++) {
                for (_m = 0; _m < $10; _m++) {
                    _exit_name = hex_str(g.dl_exit_dirs[| _k] + _m);
                    _exit_name = _rm_name + _exit_name;

                    if (!is_undefined(g.dm_rm[? _exit_name + STR_Open])) {
                        _total_exits++;
                        _goto_name = g.dm_rm[? _exit_name + STR_goto_reen];

                        // Check if target exit exists
                        if (is_undefined(g.dm_rm[? _goto_name + STR_Open])) {
                            _mismatch_count++;
                            _str = "[MISMATCH] " + _exit_name + " -> " + _goto_name + " (TARGET NOT FOUND)\n";
                            _log += _str;
                            show_debug_message(_str);
                        }
                    }
                }
            }
        }
    }

    // OVERWORLD EXITS
    _log += "\n--- OVERWORLD EXITS ---\n";
    for (_i = 0; _i < $100; _i++) {
        for (_j = 0; _j < $100; _j++) {
            var _rc = _j + (_i << 8);
            _exit_name = hex_str(_rc);
            _data = global.OVERWORLD.dm[? _exit_name + STR_AccessData];

            if (!is_undefined(_data)) {
                _rm_name = global.OVERWORLD.dm[? _exit_name + STR_RmName];

                for (_k = 0; _k < 4; _k++) {
                    var _str_exit_num = string_copy(_data, (_k << 1) + 1, 2);

                    if (_str_exit_num != "FF") {
                        _total_exits++;
                        _goto_name = _rm_name + _str_exit_num;

                        if (is_undefined(g.dm_rm[? _goto_name + STR_Open])) {
                            _mismatch_count++;
                            _str = "[MISMATCH] OW " + _exit_name + " -> " + _goto_name + " (TARGET NOT FOUND)\n";
                            _log += _str;
                            show_debug_message(_str);
                        }
                    }
                }
            }
        }
    }

    _log += "\n=== EXIT AUDIT SUMMARY ===\n";
    _log += "Total exits scanned: " + string(_total_exits) + "\n";
    _log += "Mismatches found: " + string(_mismatch_count) + "\n";
    _log += "Status: ";
    if (_mismatch_count == 0) {
        _log += "ALL EXITS VALID ✓\n";
    } else {
        _log += "ERRORS DETECTED\n";
    }

    show_debug_message(_log);
    Dev_DebugHarness_Log("[AUDIT] " + _log);

    return _mismatch_count;
}
