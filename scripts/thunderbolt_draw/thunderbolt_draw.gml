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

        // SHAPE. Two earlier attempts failed in opposite directions: thick and smooth
        // read as "the Contra laser", then thin-but-evenly-alternating read as "a line
        // on a point graph". Both were too REGULAR -- equal row spacing plus a forced
        // left-right-left flip is literally a sawtooth, which is what a plotted chart
        // looks like.
        //
        // Real lightning is an irregular WALK: it mostly runs near-vertical, wanders a
        // little, occasionally throws a hard jag, and the steps are all different
        // lengths. So: random vertical step sizes, and a horizontal random walk that is
        // pulled gently back toward the target rather than flipped every step.
        var _off = 0;              // current horizontal offset from the strike line
        var _acc = 0;              // accumulated vertical distance
        for (var _s = 0; _s <= _segs; _s++)
        {
            var _f = _acc / _span;
            if (_f > 1) _f = 1;

            _py[_s] = _y0 + (_span * _f);
            _px[_s] = _b.x + _off;

            // uneven vertical steps -- some short and choppy, some long and smooth
            _acc += (_span / _segs) * random_range(0.45, 1.75);

            // horizontal random walk. Occasional big jag (1 in 5), otherwise small
            // drift, and always a pull back toward centre so it converges on the enemy.
            var _kick = (irandom(4) == 0) ? irandom_range(9, 20) : irandom_range(1, 6);
            _off += _kick * ((irandom(1) * 2) - 1);
            _off -= _off * 0.30;                       // restoring pull
            var _lim = (1 - _f) * 26;                  // allowed wander, tightens near the target
            _off = clamp(_off, -_lim, _lim);
        }
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

        // ONE PIXEL. No halo strokes at all.
        //
        // This is the third go at thickness and the halo was the whole problem. The game
        // renders at NES resolution and the window scales it up ~6x, so a "3px" stroke
        // lands as roughly EIGHTEEN screen pixels -- which is precisely the fat, even
        // beam the owner kept calling the Contra laser. The 1px core was never the issue;
        // the two wide passes behind it were.
        //
        // A NES lightning bolt is a single-pixel line. The only concession is one
        // pale-blue pass drawn 1px to the side, which tints the edge without adding
        // measurable width.
        var _passes = [[1, c_aqua, 0.60], [1, c_white, 1.0]];

        for (var _p = 0; _p < 2; _p++)
        {
            var _w = _passes[_p][0];
            draw_set_colour(_passes[_p][1]);
            draw_set_alpha(_alpha * _passes[_p][2]);

            // pass 0 (aqua) is nudged 1px sideways so it edges the core rather than
            // fattening it; pass 1 (white) is the bolt itself
            var _ox = (_p == 0) ? 1 : 0;
            for (var _s2 = 0; _s2 < _segs; _s2++)
            {
                draw_line_width(_px[_s2] + _ox, _py[_s2], _px[_s2 + 1] + _ox, _py[_s2 + 1], _w);
            }

            // forks drawn one step thinner so they read as secondary
            var _fw = 1;   // forks are 1px too -- everything is 1px now
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
            var _r = 5 * (1 - _t) * 4;   // smaller: a thin bolt with a huge ring looked wrong
            draw_set_colour(c_white);
            draw_set_alpha(_alpha * 0.8);
            draw_circle(_b.x, _b.y, _r, true);   // outline -- a filled disc read as a blob
        }

        array_push(_keep, _b);
    }

    draw_set_alpha(1);
    draw_set_colour(c_white);

    random_set_seed(_rng_state);

    global.thunder_bolts = _keep;

}
