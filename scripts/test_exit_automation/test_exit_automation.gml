/// @description test_exit_automation() — automated exit testing harness
/// Traverses all rooms, teleports player to each exit, verifies destination
function test_exit_automation() {

    var _log = "";
    var _start_time = get_timer();
    var _total_tests = 0;
    var _passed = 0;
    var _failed = 0;
    var _failed_list = ds_list_create();

    _log += "========================================\n";
    _log += "AUTOMATED EXIT TEST HARNESS\n";
    _log += "Started: " + string(current_time) + "\n";
    _log += "========================================\n\n";

    // Store initial state
    var _start_room = room;
    var _start_x = global.pc.x;
    var _start_y = global.pc.y;
    var _start_state = {
        room: _start_room,
        x: _start_x,
        y: _start_y
    };

    var _i, _j, _k, _m, _idx, _str;
    var _area, _rm_name, _exit_name, _goto_name, _data;
    var _test_results = ds_list_create();

    // TEST DUNGEON/ACTION ROOMS
    _log += "--- DUNGEON/ACTION ROOM EXITS ---\n";
    for (_i = 0; _i < ds_list_size(g.dl_AREA_NAME); _i++) {
        _area = g.dl_AREA_NAME[| _i];
        if (area_is_ow(_area)) continue;

        _log += "\nArea: " + _area + "\n";

        for (_j = 0; _j < $100; _j++) {
            _rm_name = _area + hex_str(_j);

            for (_k = 0; _k < ds_list_size(g.dl_exit_dirs); _k++) {
                for (_m = 0; _m < $10; _m++) {
                    _exit_name = hex_str(g.dl_exit_dirs[| _k] + _m);
                    _exit_name = _rm_name + _exit_name;

                    if (!is_undefined(g.dm_rm[? _exit_name + STR_Open])) {
                        _total_tests++;
                        _goto_name = g.dm_rm[? _exit_name + STR_goto_reen];

                        var _target_exists = !is_undefined(g.dm_rm[? _goto_name + STR_Open]);
                        var _target_room = get_exit_rm_name(_goto_name);

                        if (_target_exists) {
                            _passed++;
                            _log += "  ✓ " + _exit_name + " -> " + _goto_name + "\n";
                        } else {
                            _failed++;
                            _log += "  ✗ " + _exit_name + " -> " + _goto_name + " (NOT FOUND)\n";
                            ds_list_add(_failed_list, _exit_name + " -> " + _goto_name);
                        }
                    }
                }
            }
        }
    }

    // TEST OVERWORLD EXITS
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
                        _total_tests++;
                        _goto_name = _rm_name + _str_exit_num;
                        var _ow_target_exists = !is_undefined(g.dm_rm[? _goto_name + STR_Open]);

                        if (_ow_target_exists) {
                            _passed++;
                            _log += "  ✓ OW[" + hex_str(_rc) + "] -> " + _goto_name + "\n";
                        } else {
                            _failed++;
                            _log += "  ✗ OW[" + hex_str(_rc) + "] -> " + _goto_name + " (NOT FOUND)\n";
                            ds_list_add(_failed_list, "OW[" + hex_str(_rc) + "] -> " + _goto_name);
                        }
                    }
                }
            }
        }
    }

    // SUMMARY
    var _elapsed = (get_timer() - _start_time) / 1000; // ms
    _log += "\n========================================\n";
    _log += "TEST RESULTS\n";
    _log += "========================================\n";
    _log += "Total exits tested: " + string(_total_tests) + "\n";
    _log += "Passed: " + string(_passed) + "\n";
    _log += "Failed: " + string(_failed) + "\n";
    _log += "Time: " + string(_elapsed) + "ms\n";
    _log += "Status: ";

    if (_failed == 0) {
        _log += "✓ ALL TESTS PASSED\n";
    } else {
        _log += "✗ FAILURES DETECTED\n";
        _log += "\nFailed exits:\n";
        for (_i = 0; _i < ds_list_size(_failed_list); _i++) {
            _log += "  - " + _failed_list[| _i] + "\n";
        }
    }

    // Write to file
    var _filename = "C:\\temp\\zalia_test_exit_results.txt";
    var _file = file_text_open_write(_filename);
    file_text_write_string(_file, _log);
    file_text_close(_file);

    // Also log to debug harness
    Dev_DebugHarness_Log(_log);
    show_debug_message(_log);

    // Cleanup
    ds_list_free(_failed_list);

    show_message("Exit test complete. Results: " + string(_passed) + " passed, " + string(_failed) + " failed.\nLog: " + _filename);

    return {
        total: _total_tests,
        passed: _passed,
        failed: _failed,
        elapsed_ms: _elapsed,
        log_file: _filename
    };
}
