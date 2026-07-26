/// @description  thunderbolt_draw()
// ============================================================================
// Ticks and draws the THUNDER STRIKE bolts queued by thunderbolt_spawn().
// Called from the END of g_Draw() -- that is the world-space draw, so world
// coordinates can be used directly with no camera maths.
//
// Look, per the 2026-07-12 spec: a jagged bolt from the top of the screen down
// onto the enemy, a bright impact flash, fading out over a few frames.
//
// Built from three passes so it reads at NES scale without an actual sprite:
//   1. a wide dark-blue stroke      -> gives the bolt weight against dark tiles
//   2. a mid pale-blue stroke       -> the glow
//   3. a 1px white core             -> what the eye actually follows
// Drawing the same polyline three times at decreasing width is the cheapest way
// to fake a glow, and it survives the palette swap because it is raw draw calls
// rather than sprite blitting.
//
// The zigzag is regenerated every frame from the bolt's OWN stored seed, so the
// shape is stable while the bolt lives (it does not writhe) but differs between
// bolts. random_set_seed is saved and restored around it -- the randomizer seeds
// GML's generator and a VFX must never disturb that.
// ============================================================================
function thunderbolt_draw() {

    if (!variable_global_exists("thunder_bolts")) return;
    if (!is_array(global.thunder_bolts))          return;
    if (array_length(global.thunder_bolts) == 0)  return;

    // PALETTE SHADER OFF FIRST. g_Draw binds pal_swap_set() for the rain (and other
    // passes bind it too), and anything still bound remaps raw draw_set_colour output
    // through the palette -- which is why the bolt came out tinted RED instead of blue.
    // These are deliberately raw colours, not palette indices, so the shader must be off.
    pal_swap_reset();

    // TOP OF THE VISIBLE AREA, taken from the CAMERA. Do NOT use cam_yt_min() here --
    // that is the minimum ALLOWED camera position (a scroll bound), not where the view
    // currently is. When it sat at or below the struck enemy the span collapsed to the
    // 8px floor and the bolt became a stub hidden under its own impact flash: flagged
    // frames showed the ring on the ground with no bolt above it at all.
    var _top = camera_get_view_y(view_camera[0]);

    // Belt and braces: however the camera happens to be placed, a bolt must visibly
    // arrive from ABOVE. If the enemy sits near or above the view top, drop from
    // overhead regardless.
    var _MIN_DROP = 180;
    var _keep = [];

    // Preserve the global RNG state -- the rando seeds it and this must not shift it.
    var _rng_state = random_get_seed();

    for (var _i = 0; _i < array_length(global.thunder_bolts); _i++)
    {
        var _b = global.thunder_bolts[_i];

        if (_b.delay > 0) { _b.delay--; array_push(_keep, _b); continue; }

        _b.life--;
        if (_b.life <= 0) continue;   // dropped

        // 1 at the moment of the strike -> 0 as it fades
        var _t     = _b.life / 14;
        var _alpha = _t * _t;         // squared, so it snaps bright then falls away fast

        random_set_seed(_b.seed);

        // --- build the zigzag once, top of screen down to the enemy ---
        var _segs = 18;   // short steps + big sideways throw = sharp angles, not a curve
        var _px   = array_create(_segs + 1);
        var _py   = array_create(_segs + 1);
        var _span = _b.y - _top;
        if (_span < _MIN_DROP) _span = _MIN_DROP;
        var _y0 = _b.y - _span;   // start point, always above the enemy

        // SHAPE. Earlier passes read as a Contra laser -- thick, smooth, constant
        // width, gently curving. Lightning is the opposite: THIN, sharply angular, and
        // FORKED. The branching is most of what sells it, and it was missing entirely.
        //
        // Sharp angles come from large horizontal deviation over SHORT vertical steps,
        // so segments are kept short and the sideways throw is big relative to them.
        var _side = (irandom(1) * 2) - 1;
        for (var _s = 0; _s <= _segs; _s++)
        {
            var _f = _s / _segs;
            _py[_s] = _y0 + (_span * _f);
            // amplitude stays wide most of the way down, then snaps to the target in
            // the last fifth -- a bolt does not funnel smoothly, it jags then hits
            var _amp = (_f > 0.8) ? (1 - _f) * 5 * 18 : 18;
            _px[_s]  = _b.x + (_side * irandom_range(_amp * 0.55, _amp));
            _side   *= -1;
        }
        _px[0]     = _b.x + (_side * irandom_range(12, 30));
        _px[_segs] = _b.x;
        _py[_segs] = _b.y;

        // --- FORKS: 1-2 short dead-end branches off random mid points. These are what
        // make it read as lightning rather than a beam. Each peels away from the main
        // line and stops after a couple of segments.
        var _forks   = irandom_range(1, 2);
        var _fork_pt = array_create(_forks);
        var _fork_dx = array_create(_forks);
        var _fork_dy = array_create(_forks);
        for (var _k = 0; _k < _forks; _k++)
        {
            _fork_pt[_k] = irandom_range(2, _segs - 4);
            _fork_dx[_k] = irandom_range(10, 26) * (((irandom(1) * 2) - 1));
            _fork_dy[_k] = irandom_range(12, 26);
        }

        // --- three passes: weight, glow, core. THIN -- the core is 1px, which is what
        // an NES bolt actually is; the wider strokes only give it a faint halo.
        var _passes = [[3, c_navy, 0.30], [2, c_aqua, 0.55], [1, c_white, 1.0]];

        for (var _p = 0; _p < 3; _p++)
        {
            var _w = _passes[_p][0];
            draw_set_colour(_passes[_p][1]);
            draw_set_alpha(_alpha * _passes[_p][2]);

            for (var _s2 = 0; _s2 < _segs; _s2++)
            {
                draw_line_width(_px[_s2], _py[_s2], _px[_s2 + 1], _py[_s2 + 1], _w);
            }

            // forks drawn one step thinner so they read as secondary
            var _fw = max(1, _w - 1);
            for (var _k2 = 0; _k2 < _forks; _k2++)
            {
                var _fi = _fork_pt[_k2];
                var _fx = _px[_fi] + _fork_dx[_k2];
                var _fy = _py[_fi] + _fork_dy[_k2];
                draw_line_width(_px[_fi], _py[_fi], _fx, _fy, _fw);
                draw_line_width(_fx, _fy, _fx + (_fork_dx[_k2] * 0.4), _fy + (_fork_dy[_k2] * 0.7), _fw);
            }
        }

        // --- impact flash on the enemy, only for the first few frames ---
        if (_t > 0.55)
        {
            var _r = 7 * (1 - _t) * 4;   // smaller: a thin bolt with a huge ring looked wrong
            draw_set_colour(c_white);
            draw_set_alpha(_alpha * 0.8);
            draw_circle(_b.x, _b.y, _r, false);
        }

        array_push(_keep, _b);
    }

    draw_set_alpha(1);
    draw_set_colour(c_white);

    random_set_seed(_rng_state);

    global.thunder_bolts = _keep;

}
