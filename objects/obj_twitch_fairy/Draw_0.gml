/// @description  obj_twitch_fairy :: Draw -- Navi-blue messenger fairy

// Needs g for the shared flap sprites + animation counter (same source obj_fairy_p2
// and PC_udp draw from). If g isn't up yet, draw nothing this frame.
if (!instance_exists(g)) exit;

// NAVI look: glowing blue (NOT the GREEN co-op fairy, NOT the red/dark/rescue fairies).
var _navi = make_colour_rgb(120, 200, 255);

// flap index toggles between the two fairy frames, exactly like obj_fairy_p2 / PC_udp.
var _flap = sign(g.counter1 & $4);

// If the user has imported a REAL Navi sprite (spr_navi / spr_Navi), draw THAT instead
// of the tinted fairy -- so this becomes genuine Navi art the moment the asset exists.
// Guarded lookup: asset_get_index returns -1 when the sprite doesn't exist yet.
var _ns = asset_get_index("spr_navi");
if (_ns == -1) _ns = asset_get_index("spr_Navi");

if (_ns != -1 && sprite_exists(_ns))
{
	// animate across the imported sprite's own frames (fall back to frame 0 if single).
	var _sub = (sprite_get_number(_ns) > 1) ? _flap : 0;
	draw_sprite_ext(_ns, _sub, x, y, facing, 1, 0, c_white, 1);
}
else
{
	// FALLBACK: PROCEDURAL NAVI -- a glowing, gently pulsing cyan orb with two
	// fluttering white wings per side, built from shape primitives so it reads
	// as OoT Navi (NOT the fairy sprite). Save draw state so nothing bleeds.
	var _oc = draw_get_colour();
	var _oa = draw_get_alpha();

	// --- TIMERS ---------------------------------------------------------
	// Body breathes slowly; wings flap fast. Both run -1 .. 1.
	var _pulse   = sin(current_time / 360);        // slow orb "breathing"
	var _flutter = sin(current_time / 70);         // fast wing flap

	// --- WHITE FLUTTERING WINGS (behind the orb) ------------------------
	// Two overlapping triangles per side; spread + height oscillate with
	// _flutter so the wings convincingly open and close as they flap.
	var _wx  = 5 + (_flutter * 2.0);               // wingtip reach (horizontal)
	var _wHi = 6 + (abs(_flutter) * 2.5);          // upper wing height (opens on flap)
	var _wLo = 2 + (abs(_flutter) * 1.0);          // lower wing height

	draw_set_alpha(0.85);
	draw_set_colour(make_colour_rgb(240, 248, 255));
	// left side: upper + lower wing
	draw_triangle(x - 1, y, x - _wx,       y - _wHi, x - _wx * 0.7, y + _wLo, false);
	draw_triangle(x - 1, y, x - _wx * 0.7, y + _wLo, x - _wx * 0.5, y + _wHi, false);
	// right side: mirrored
	draw_triangle(x + 1, y, x + _wx,       y - _wHi, x + _wx * 0.7, y + _wLo, false);
	draw_triangle(x + 1, y, x + _wx * 0.7, y + _wLo, x + _wx * 0.5, y + _wHi, false);

	// --- LAYERED GLOWING ORB -------------------------------------------
	// Outer soft glow: radius + alpha breathe with _pulse (the soft PULSE).
	var _glowR = 9 + (_pulse * 1.5);
	draw_set_alpha(0.22 + (_pulse * 0.06));
	draw_set_colour(make_colour_rgb(90, 180, 255));
	draw_circle(x, y, _glowR, false);

	// Mid ring: depth between the glow and the bright core.
	draw_set_alpha(0.55);
	draw_set_colour(make_colour_rgb(80, 190, 255));
	draw_circle(x, y, 5.5, false);

	// Bright tight core: the solid heart of the orb.
	draw_set_alpha(1);
	draw_set_colour(make_colour_rgb(150, 225, 255));
	draw_circle(x, y, 3, false);

	// --- HIGHLIGHT: small bright dot offset up-left --------------------
	draw_set_colour(make_colour_rgb(235, 252, 255));
	draw_circle(x - 1.2, y - 1.2, 1.2, false);

	// --- OPTIONAL SPARKLE: a faint blink that twinkles occasionally ----
	// Slow sine; only shows on its crest, fading in/out for a subtle wink.
	var _spark = sin(current_time / 500);
	if (_spark > 0.7)
	{
		draw_set_alpha((_spark - 0.7) / 0.3);     // 0 .. 1 fade
		draw_set_colour(c_white);
		draw_circle(x + 3, y - 4, 1, false);
	}

	// restore draw state (and hard-reset to safe defaults).
	draw_set_colour(_oc);
	draw_set_alpha(_oa);
	draw_set_alpha(1);
	draw_set_colour(c_white);
}
