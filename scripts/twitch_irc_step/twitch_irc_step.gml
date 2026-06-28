/// @description  twitch_irc_step() -- cheap per-frame tick for the in-game IRC client.
// ============================================================================
// TWITCH IRC (no-bot mode) -- PER-FRAME STEP.
//
// Called every frame from g_Step (after twitch_poll/twitch_tick). The socket
// RECEIVE is event-driven (obj_twitch_irc Async-Networking event), so this does
// almost nothing: it just advances a monotonic frame counter that the chat-command
// cooldown in twitch_irc_handle_line() compares against. Early-returns immediately
// while the IRC client is disabled, so it costs a single bool check on a normal run.
// ============================================================================
function twitch_irc_step() {

	if (!variable_global_exists("tw_irc_enabled") || !global.tw_irc_enabled) return;

	if (!variable_global_exists("tw_irc_frame")) global.tw_irc_frame = 0;
	global.tw_irc_frame++;

	// Auto-hide countdown for the "connected" status line. twitch_irc_handle_line()
	// sets this to ~240 on the welcome 001; we tick it down here so the on-screen
	// "TWITCH: connected" label disappears after ~4s (the user is streaming and
	// doesn't want it stuck on-screen). Only counts while > 0 so it settles at 0;
	// "connecting"/error/no-config don't use it (they draw persistently).
	if (!variable_global_exists("tw_irc_status_timer")) global.tw_irc_status_timer = 0;
	if (global.tw_irc_status_timer > 0) global.tw_irc_status_timer--;
}
