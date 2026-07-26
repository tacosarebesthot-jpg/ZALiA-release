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

	// TWO sequences share this one buffer (2026-07-26): the original Konami egg, and
	// the DEV TOOLS unlock. Keeping one buffer means the input plumbing above -- the
	// edge reads, the idle timeout, the simultaneous-press reset -- is written once.
	// The buffer is therefore trimmed to the LONGEST target, and each target is tested
	// against the buffer's TAIL rather than the whole thing.
	var _k_target = global.konami_target;
	var _d_target = variable_global_exists("devcode_target") ? global.devcode_target : [];
	var _klen     = array_length(_k_target);
	var _dlen     = array_length(_d_target);
	var _maxlen   = max(_klen, _dlen);

	while (array_length(global.konami_seq) > _maxlen) array_delete(global.konami_seq, 0, 1);

	// Does the tail of the buffer equal this target, in order?
	var _tail_matches = function(_target)
	{
		var _tlen = array_length(_target);
		if (_tlen == 0) return false;

		var _blen = array_length(global.konami_seq);
		if (_blen < _tlen) return false;

		var _off = _blen - _tlen; // compare the LAST _tlen entries
		for (var _i = 0; _i < _tlen; _i++)
		{
			if (global.konami_seq[_off + _i] != _target[_i]) return false;
		}
		return true;
	};

	// DEV unlock first: if the two sequences ever share a suffix, the deliberate
	// action should win over the easter egg.
	if (_dlen > 0 && _tail_matches(_d_target))
	{
		dev_unlock_fire();
		global.konami_seq      = [];
		global.konami_cooldown = 60;
		return;
	}

	if (_tail_matches(_k_target))
	{
		konami_fire();
		global.konami_seq      = [];
		global.konami_cooldown = 60; // ~1s lockout, then it can be entered again
	}
}


/// @description  dev_unlock_fire() -- reveal the DEV TOOLS surface for this session
function dev_unlock_fire() {

	// Session-only. The permanent unlock is the dev_unlock.txt file in the save
	// directory -- see dev_avail(). Nothing here is written to the save.
	var _was = variable_global_exists("dev_unlocked") && global.dev_unlocked;
	global.dev_unlocked = !_was; // second entry hides it again, so it can be demoed and put away

	aud_play_sound(snd_Z1_Secret);

	// Reuse the Konami toast so there is one drawing path for both.
	global.konami_toast       = global.dev_unlocked ? "DEV TOOLS UNLOCKED" : "DEV TOOLS HIDDEN";
	global.konami_toast_timer = 180;

	if (DEV) show_debug_message("[DEV] dev_unlocked = " + string(global.dev_unlocked));
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
