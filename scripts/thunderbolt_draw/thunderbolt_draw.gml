/// @description  thunderbolt_draw()
// ============================================================================
// Ticks and draws the THUNDER STRIKE bolts queued by thunderbolt_spawn().
// Called from the END of g_Draw() -- world-space draw, so world coordinates are
// used directly with no camera maths.
//
// SHAPE: RECURSIVE MIDPOINT DISPLACEMENT, not a random walk.
// Earlier versions built the bolt as a top-to-bottom walk. That produced, in
// order: a Contra laser (too thick), a line on a point graph (too regular), and
// finally "close, but it doesn't jiggle and wiggle enough". A walk can only
// jitter at ONE scale -- its step size -- so it is either smooth or coarse,
// never both at once, and real lightning is both.
//
// Midpoint displacement is fractal and gives that for free: start with a
// straight line, split it, shove the new midpoint sideways, then do the same to
// each half with HALF the shove, and repeat. Five passes turn 2 points into 33
// and the detail is self-similar all the way down.
//
// DISCONNECTED FRAGMENTS: short detached slivers beside the channel -- the
// owner's "broken pieces that don't connect to anything". Real strikes leave
// glowing bits in the air. Cheap, and it does a lot of the work.
//
// TIMING: a hard 3-frame flash at full brightness then a fast decay, rather than
// a smooth 14-frame fade. Lightning is a blink with an afterimage; a shape you
// get to LOOK at for a quarter of a second reads as a drawn line.
//
// COLOUR stages white-hot -> pale blue as it cools.
//
// Cosmetic, runtime-only. Palette shader is switched off first (g_Draw binds it
// for the rain, and anything bound remaps raw colours -- bolts came out brown).
// RNG state is saved/restored: the rando seeds GML's generator and a VFX must
// never disturb a seeded run.
// ============================================================================
function thunderbolt_draw() {

    if (!variable_global_exists("thunder_bolts")) return;
    if (!is_array(global.thunder_bolts))          return;
    if (array_length(global.thunder_bolts) == 0)  return;

    pal_swap_reset();

    // Top of the VISIBLE area, from the camera. NOT cam_yt_min() -- that is the
    // minimum ALLOWED camera position, a scroll bound. Using it collapsed the bolt
    // into a stub hidden under its own impact flash.
    var _top      = camera_get_view_y(view_camera[0]);
    var _MIN_DROP = 180;
    var _LIFE     = 9;
    var _keep     = [];

    var _rng_state = random_get_seed();

    for (var _i = 0; _i < array_length(global.thunder_bolts); _i++)
    {
        var _b = global.thunder_bolts[_i];

        if (_b.delay > 0) { _b.delay--; array_push(_keep, _b); continue; }

        _b.life--;
        if (_b.life <= 0) continue;

        var _t   = _b.life / _LIFE;              // 1 at the strike -> 0 at the end
        var _hot = (_b.life > _LIFE - 3);        // first 3 frames

        // hard flash, then fall away fast
        var _alpha = _hot ? 1.0 : (_t * _t * 1.6);
        if (_alpha > 1) _alpha = 1;

        var _core = _hot ? c_white : make_colour_rgb(170, 210, 255);
        var _edge = _hot ? make_colour_rgb(150, 200, 255) : c_blue;

        random_set_seed(_b.seed);

        var _span = _b.y - _top;
        if (_span < _MIN_DROP) _span = _MIN_DROP;
        var _y0 = _b.y - _span;

        // ---- midpoint displacement -------------------------------------------
        var _px   = [_b.x + irandom_range(-30, 30), _b.x];
        var _py   = [_y0, _b.y];
        var _push = 26;

        repeat (5)
        {
            var _nx = [];
            var _ny = [];
            var _cnt = array_length(_px);
            for (var _s = 0; _s < _cnt - 1; _s++)
            {
                array_push(_nx, _px[_s]);
                array_push(_ny, _py[_s]);

                array_push(_nx, ((_px[_s] + _px[_s + 1]) * 0.5) + irandom_range(-_push, _push));
                array_push(_ny,  (_py[_s] + _py[_s + 1]) * 0.5);
            }
            array_push(_nx, _px[_cnt - 1]);
            array_push(_ny, _py[_cnt - 1]);
            _px   = _nx;
            _py   = _ny;
            _push = _push * 0.5;
        }

        var _n = array_length(_px);

        // ---- channel: 1px core, 1px edge tint offset sideways ----------------
        for (var _p = 0; _p < 2; _p++)
        {
            draw_set_colour(_p == 0 ? _edge : _core);
            draw_set_alpha(_alpha * (_p == 0 ? 0.55 : 1.0));
            var _ox = (_p == 0) ? 1 : 0;

            for (var _s2 = 0; _s2 < _n - 1; _s2++)
            {
                draw_line(_px[_s2] + _ox, _py[_s2], _px[_s2 + 1] + _ox, _py[_s2 + 1]);
            }
        }

        // ---- branches, kinked rather than straight ---------------------------
        draw_set_colour(_core);
        draw_set_alpha(_alpha * 0.85);
        repeat (irandom_range(5, 6))   // owner: "you had two or three, go for five or six"
        {
            var _bx = 0; var _by = 0;
            var _bi = irandom_range(3, _n - 4);   // spread them over more of the channel
            _bx = _px[_bi];
            _by = _py[_bi];
            var _dx = irandom_range(8, 30) * ((irandom(1) * 2) - 1);
            var _dy = irandom_range(10, 34);

            repeat (3)
            {
                var _tx = _bx + (_dx / 3) + irandom_range(-4, 4);
                var _ty = _by + (_dy / 3);
                draw_line(_bx, _by, _tx, _ty);
                _bx = _tx;
                _by = _ty;
            }
        }

        // ---- disconnected fragments -- "broken pieces that don't connect" ----
        if (_hot)
        {
            draw_set_alpha(_alpha * 0.7);
            repeat (irandom_range(5, 8))   // more detached slivers to match the extra branching
            {
                var _fi  = irandom_range(2, _n - 3);
                var _fx1 = _px[_fi] + irandom_range(-26, 26);
                var _fy1 = _py[_fi] + irandom_range(-14, 14);
                draw_line(_fx1, _fy1, _fx1 + irandom_range(-9, 9), _fy1 + irandom_range(4, 13));
            }
        }

        // ---- impact ring, hot frames only ------------------------------------
        if (_hot)
        {
            draw_set_colour(c_white);
            draw_set_alpha(_alpha * 0.8);
            draw_circle(_b.x, _b.y, 4 + (_LIFE - _b.life) * 3, true);
        }

        array_push(_keep, _b);
    }

    draw_set_alpha(1);
    draw_set_colour(c_white);

    random_set_seed(_rng_state);

    global.thunder_bolts = _keep;

}
