/// @description  konami_check() -- detect the Konami code on Player 1 and fire a harmless egg
// ============================================================================
// KONAMI CODE easter egg.  Called once per frame from g_Step(), AFTER
// `with(Input) Input_update2()` so the per-frame PRESSED edges are ready.
//
// Watches Player 1's NES pressed-edges (edge, not held):
//   UP/DOWN/LEFT/RIGHT = Input.Up_pressed / Down_pressed / Left_pressed / Right_pressed
//   B (NES B)          = Input.Attack_pressed   (the attack button)
//   A (NES A)          = Input.Jump_pressed     (the jump button)
// Sequence: UP UP DOWN DOWN LEFT RIGHT LEFT RIGHT B A.
//
// Detection keeps a rolling buffer (global.konami_seq) of the most recent single
// presses; whenever the tail of that buffer equals global.konami_target it fires
// konami_fire() ONCE, clears the buffer and sets a brief cooldown so it stays
// re-triggerable. An idle buffer self-resets after global.KONAMI_TIMEOUT frames,
// and an ambiguous simultaneous press resets it too.
//
// HARMLESS + RUNTIME-ONLY egg: full-heal HP+MP, a few extra lives (clamped), a
// toast and a positive SFX. Nothing here ever touches the save file.
//
// Reversible: delete this script (+ its .yyp entry) + the konami_* globals in
// g_Create + the konami_check() call in g_Step + the KONAMI toast block in
// Surface_Draw_GUI_End.
// ============================================================================
function konami_check() {

	// guard: globals must be initialized and the Input instance must exist
	if (!variable_global_exists("konami_seq")) return;
	if (!instance_exists(Input))               return;

	// brief re-trigger lockout after a fire
	if (global.konami_cooldown > 0) global.konami_cooldown--;

	// idle-timeout: drop a half-entered buffer after a quiet spell
	if (array_length(global.konami_seq) > 0)
	{
		global.konami_timer--;
		if (global.konami_timer <= 0) global.konami_seq = [];
	}

	// which Konami-relevant P1 button(s) had a PRESSED edge this frame?
	// tokens: 1=UP 2=DOWN 3=LEFT 4=RIGHT 5=B(attack) 6=A(jump)
	var _press = 0;
	var _multi = 0;
	if (Input.Up_pressed)     { _press = 1; _multi++; }
	if (Input.Down_pressed)   { _press = 2; _multi++; }
	if (Input.Left_pressed)   { _press = 3; _multi++; }
	if (Input.Right_pressed)  { _press = 4; _multi++; }
	if (Input.Attack_pressed) { _press = 5; _multi++; } // NES B
	if (Input.Jump_pressed)   { _press = 6; _multi++; } // NES A

	// nothing relevant this frame -> leave the buffer as-is
	if (_press == 0) return;

	// ambiguous simultaneous press (e.g. a diagonal) -> treat as a wrong input, reset
	if (_multi > 1) { global.konami_seq = []; return; }

	// don't advance the buffer while still cooling down from the last fire
	if (global.konami_cooldown > 0) return;

	// push this press, refresh the idle timer, keep only the last N (target length)
	array_push(global.konami_seq, _press);
	global.konami_timer = global.KONAMI_TIMEOUT;

	var _target = global.konami_target;
	var _tlen   = array_length(_target);
	while (array_length(global.konami_seq) > _tlen) array_delete(global.konami_seq, 0, 1);

	// fire when the rolling buffer matches the full sequence in order
	if (array_length(global.konami_seq) == _tlen)
	{
		var _match = true;
		for (var _i = 0; _i < _tlen; _i++)
		{
			if (global.konami_seq[_i] != _target[_i]) { _match = false; break; }
		}
		if (_match)
		{
			konami_fire();
			global.konami_seq      = [];
			global.konami_cooldown = 60; // ~1s lockout, then it can be entered again
		}
	}
}


/// @description  konami_fire() -- the harmless, runtime-only Konami easter-egg payload
function konami_fire() {

	// celebratory SFX: Z1 "secret found" jingle (SOUND group, so it won't clobber
	// the area music). aud_play_sound() guards bad ids internally.
	aud_play_sound(snd_Z1_Secret);

	// full-heal HP + MP. adjust_stat() clamps the result to each stat's max, so
	// passing the max value as the delta tops both bars off (never overflows).
	if (instance_exists(f))
	{
		adjust_stat(get_stat_max(STR_Heart), get_stat_max(STR_Magic));
	}

	// grant a few extra lives, clamped to the game's lives cap (runtime only, no save write)
	if (instance_exists(f) && variable_global_exists("pc_lives"))
	{
		global.pc_lives = min(global.pc_lives + 3, f.LIVES_MAX);
	}

	// on-screen toast (drawn by the KONAMI block in Surface_Draw_GUI_End). ASCII-only
	// so the default font (-1) glyph coverage is reliable.
	global.konami_toast       = "KONAMI! FULL HEAL +3 LIVES";
	global.konami_toast_timer = 180;
}
