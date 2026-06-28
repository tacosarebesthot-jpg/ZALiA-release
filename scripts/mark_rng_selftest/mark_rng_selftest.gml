/// @description  mark_rng_selftest()
/// One-shot determinism check for the MARK -> REPRODUCIBLE REPLAY feature: proves the
/// GML built-in RNG (irandom/random/choose) can be CAPTURED mid-sequence via
/// random_get_seed() and faithfully RESTORED via random_set_seed(), so a replayed run
/// reproduces the same stream from the same anchor. This is the feature's key
/// determinism risk -- if it fails, replays diverge wherever the game calls irandom().
/// Logs "[MARKRNG] roundtrip=PASS" or "=FAIL". NON-DESTRUCTIVE: saves and restores the
/// live game seed so calling it can't perturb gameplay RNG. Call once at boot under DEV.
function mark_rng_selftest()
{
	var _orig = random_get_seed();          // preserve the live game seed

	random_set_seed(12345);
	repeat (50) irandom(1000);              // advance into the middle of a sequence
	var _s = random_get_seed();             // capture mid-sequence state

	var _a = array_create(20, 0);
	for (var _i = 0; _i < 20; _i++) _a[_i] = irandom(1000);

	random_set_seed(_s);                    // restore the captured mid-sequence state
	var _b = array_create(20, 0);
	for (var _j = 0; _j < 20; _j++) _b[_j] = irandom(1000);

	var _match = true;
	for (var _k = 0; _k < 20; _k++)
	{
	    if (_a[_k] != _b[_k]) { _match = false; break; } // _k
	}

	show_debug_message("[MARKRNG] roundtrip=" + (_match ? "PASS" : "FAIL"));

	random_set_seed(_orig);                 // restore live game seed -- no side effects
}
