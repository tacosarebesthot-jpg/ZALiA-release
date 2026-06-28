/// @description test_startup_exit_audit() — called from g_Create if DEV mode enabled
/// Runs exit tests immediately on game start, then exits game
/// Usage: set global.test_mode_exit = true before game launch
function test_startup_exit_audit() {

    if (!DEV) return;
    if (is_undefined(global.test_mode_exit) || !global.test_mode_exit) return;

    show_debug_message("[TEST] Running automated exit audit at startup...");

    // Run the test
    var _result = test_exit_automation();

    show_debug_message("[TEST] Audit complete: " + string(_result.failed) + " failures");
    show_debug_message("[TEST] Results written to: " + _result.log_file);

    // Wait a moment for file write to complete
    sleep(500);

    // Exit game
    show_debug_message("[TEST] Exiting game...");
    game_end(0);
}
