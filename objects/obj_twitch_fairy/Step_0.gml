/// @description  obj_twitch_fairy :: Step -- fly-in / hover / fly-out lifecycle

life++;

// Re-track the hover point to the player each frame (the PC moves); keep last value
// if P1 has vanished. Only matters while flying-in / hovering, not while leaving.
if (phase < 2 && instance_exists(global.pc))
{
	hover_x = global.pc.x;
	hover_y = global.pc.y - 24;
}

// Pick this frame's move target + speed from the current phase.
var _tx, _ty, _spd, _bob;
switch (phase)
{
	case 0: // FLY IN
		phase_timer++;
		_bob = sin(life * 0.2) * 2;
		_tx = hover_x; _ty = hover_y + _bob; _spd = 4;
		break;

	case 1: // HOVER (gentle wing-bob in place)
		if (hover_timer > 0) hover_timer--;
		_bob = sin(life * 0.2) * 3;
		_tx = hover_x; _ty = hover_y + _bob; _spd = 3;
		break;

	default: // case 2: FLY OUT
		phase_timer++;
		_tx = exit_x; _ty = exit_y; _spd = 5;
		break;
}

// ── APPROACH the target at a fixed speed (snap when within one step) ──────────────
var _d = point_distance(x, y, _tx, _ty);
if (_d <= _spd)
{
	x = _tx;
	y = _ty;
}
else
{
	var _a = point_direction(x, y, _tx, _ty);
	x += lengthdir_x(_spd, _a);
	y += lengthdir_y(_spd, _a);
}

// ── PHASE TRANSITIONS ────────────────────────────────────────────────────────────
if (phase == 0)
{
	// arrived at the hover point (or safety-timeout) -> start hovering
	if (point_distance(x, y, hover_x, hover_y) <= 6 || phase_timer > 150)
	{
		phase       = 1;
		phase_timer = 0;
	}
}
else if (phase == 1)
{
	// hover elapsed -> head back off-screen
	if (hover_timer <= 0)
	{
		phase       = 2;
		phase_timer = 0;
	}
}
else // phase 2: despawn once off-screen / back at the entry point / safety-timeout
{
	var _off = false;
	if (instance_exists(g))
	{
		_off = (x < g.view_xl_og - 16) || (x > g.view_xl_og + VIEW_W_OG + 16)
		    || (y < g.view_yt_og - 16) || (y > g.view_yt_og + VIEW_H_OG + 16);
	}
	if (point_distance(x, y, exit_x, exit_y) <= 6 || _off || phase_timer > 150)
	{
		instance_destroy();
		exit;
	}
}

// Face the direction of travel (drives the draw flip).
if      (x > xprevious + 0.1) facing = 1;
else if (x < xprevious - 0.1) facing = -1;
