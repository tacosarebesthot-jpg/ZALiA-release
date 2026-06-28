/// @description  obj_twitch_fairy :: Create -- TWITCH messenger fairy (Navi herald)
// ============================================================================
// A visual herald for Twitch chat commands. Spawned by twitch_apply() whenever a
// recognized command fires. Lifecycle: POP IN from just off the nearest visible
// screen edge -> fly toward a hover point near the player -> HOVER while the toast
// shows -> fly back OFF-screen and instance_destroy().
//
// DISTINCT from the co-op P2 fairy (obj_fairy_p2, green): this one is Navi-blue and
// is driven entirely by the chat dispatcher, never by a controller. Non-persistent.
// Reversible: delete this object + its .yyp entry + the twitch_apply spawn hook.
// ============================================================================

depth = DEPTH_FLYER; // render above gameplay like a flyer (macros.gml)

life        = 0;     // frame counter (drives the gentle wing-bob)
phase       = 0;     // 0 = fly-in, 1 = hover, 2 = fly-out
phase_timer = 0;     // per-phase safety timeout so it can never get stuck
hover_timer = 180;   // hover duration (matches the toast timer in twitch_apply)
facing      = 1;     // sprite flip from travel direction (1 = right, -1 = left)

// ── HOVER POINT ── just above the player; fall back to screen-centre, then to self.
if (instance_exists(global.pc))
{
	hover_x = global.pc.x;
	hover_y = global.pc.y - 24;
}
else if (instance_exists(g))
{
	hover_x = g.view_xl_og + VIEW_W_OG_;
	hover_y = g.view_yt_og + VIEW_H_OG_;
}
else
{
	hover_x = x;
	hover_y = y;
}

// ── ENTRY / EXIT ── place just OFF the nearest visible screen edge to the hover
// point, using the OG view rect (same coord source obj_fairy_p2 clamps against).
if (instance_exists(g))
{
	var _vxl = g.view_xl_og;
	var _vyt = g.view_yt_og;
	var _vxr = _vxl + VIEW_W_OG;
	var _vyb = _vyt + VIEW_H_OG;

	var _dl = hover_x - _vxl; // distance from hover point to each edge
	var _dr = _vxr - hover_x;
	var _dt = hover_y - _vyt;
	var _db = _vyb - hover_y;
	var _m  = min(_dl, _dr, _dt, _db);

	var _pad = 24; // how far off-screen to start / end
	if      (_m == _dl) { x = _vxl - _pad; y = hover_y;      } // enter from left
	else if (_m == _dr) { x = _vxr + _pad; y = hover_y;      } // enter from right
	else if (_m == _dt) { x = hover_x;     y = _vyt - _pad;  } // enter from top
	else                { x = hover_x;     y = _vyb + _pad;  } // enter from bottom
}

// Remember where we came in from -> fly back out the SAME edge on despawn.
exit_x = x;
exit_y = y;
