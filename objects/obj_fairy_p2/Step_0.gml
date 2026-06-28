/// @description  obj_fairy_p2 :: Step -- move / shoot / heal (MVP)

if (!global.coop_enabled) exit; // !!!!! OFF by default

// Stay completely INERT (no move/shoot/heal/tank/ferry) until a SEPARATE 2nd controller
// has actually JOINED P2: slot assigned (not -1) AND distinct from P1's pad. Same join
// check the Draw + GUI join-prompt use, so one controller can never drive both players.
if (!instance_exists(Input)
||  Input.gamepad_slot_p2 == -1
||  Input.gamepad_slot_p2 == Input.gamepad_slot) exit;

// ── MOVE ──────────────────────────────────────────────────────────────────────
x += Input.p2_moveH * 3;
y += Input.p2_moveV * 3;

// Track facing from the last horizontal input (used to aim the shot).
if (Input.p2_moveH != 0) facing = sign(Input.p2_moveH);

// Clamp to the visible OG-sized view so the fairy can't leave the screen.
x = clamp(x, g.view_xl_og + 8, g.view_xl_og + VIEW_W_OG - 8);
y = clamp(y, g.view_yt_og + 8, g.view_yt_og + VIEW_H_OG - 8);

// ── SHOOT ─────────────────────────────────────────────────────────────────────
if (shoot_cooldown > 0) shoot_cooldown--;
if (Input.p2_shoot_pressed
&&  shoot_cooldown <= 0 )
{
	spawn_fairy_proj(x, y, facing);
	shoot_cooldown = 12; // ~12-frame fire rate
}

// ── HEAL ──────────────────────────────────────────────────────────────────────
if (Input.p2_action_pressed)
{
	adjust_stat(2, 0); // give P1 2 HP (adjust_stat clamps to max itself)
}

// ── TANK (shield P1) ───────────────────────────────────────────────────────────
// On the 2nd P2 button, grant P1 brief invulnerability. Same lever twitch_apply's
// "invuln" verb uses (iframes_timer is ticked down by update_game_timers). A cooldown
// keeps it from being spammed into permanent invuln.
if (tank_cd > 0) tank_cd--;
if (Input.p2_tank_pressed
&&  tank_cd <= 0
&&  instance_exists(global.pc) )
{
	global.pc.iframes_timer = 30; // brief invuln for P1
	tank_cd = 120;                // ~2s before TANK can fire again
}

// ── FERRY (carry the nearest world pickup toward P1) ───────────────────────────
// The fairy has NO collision mask, so detect by proximity (instance_nearest) rather
// than instance_place. If the closest Item is within reach, nudge it toward P1 a few
// px/frame via set_xy -- set_xy moves the item's hitbox fields (xl/xr/yt/yb) too, so
// when the item reaches P1 the normal HOLD-item pickup (Item_update's cs&CS_BD1 body
// path) fires for an idle P1. SMALL items need an active stab P1 may not do, so the
// hand-off block below completes those once the item overlaps P1.
if (instance_exists(global.pc))
{
	var _itm = instance_nearest(x, y, Item);
	if (_itm != noone
	&&  instance_exists(_itm)
	&&  point_distance(x, y, _itm.x, _itm.y) <= 24 ) // ~overlap radius
	{
		var _ang = point_direction(_itm.x, _itm.y, global.pc.x, global.pc.y);
		set_xy(_itm, _itm.x + lengthdir_x(2, _ang),   // 2 px/frame toward P1
		             _itm.y + lengthdir_y(2, _ang) );

		// HAND-OFF: complete the pickup once the ferried item reaches P1.
		// HOLD items already get taken on body contact (Item_update's cs&CS_BD1
		// path fires for an idle P1). SMALL items (Key/Jar/P-Bag) normally need an
		// ACTIVE sword stab -- their pickup gates on SwordHB2/CS_SW1, which require
		// global.pc.SwordHB_collidable, and PC_update_SwordHB_xy leaves that FALSE
		// unless P1 is attacking. So an idle P1 being ferried-to would never collect
		// a small item; the fairy would just shove it against P1 forever. When the
		// ferried non-hold item has actually reached P1, trigger the SAME award
		// Item_update fires for a small-item pickup. Runs in the item's context so
		// every identifier resolves exactly as it does inside Item_update; gated to
		// state_NORMAL/IDLE so it awards once (afterwards state is DROP/0, not NORMAL).
		with (_itm)
		{
			if (state == state_NORMAL
			&&  sub_state == sub_state_IDLE
			&& !IS_HOLD_ITEM
			&& !stun_timer
			&&  point_distance(x, y, global.pc.x, global.pc.y) <= 16 ) // item overlaps P1
			{
				Item_update_1();                       // award (mirrors Item_update E771)
				stun_timer = STUN_DURATION1;
				global.pc.iframes_timer = 4;
				aud_play_sound(get_audio_theme_track(dk_StrikeEnemy));
				if (ITEM_TYPE == STR_PBAG) state = state_DROP; // xp-rise, then despawns
				else                       state = 0;
			}
		}
	}
}
