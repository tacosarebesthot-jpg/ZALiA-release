/// @description  thunderbolt_spawn(x, y, delay_frames)
/// @param x             world x of the struck enemy
/// @param y             world y of the struck enemy
/// @param delay_frames  frames to wait before this bolt appears (staggers the cascade)
// ============================================================================
// THUNDER STRIKE VFX -- owner-designed, spec'd 2026-07-12, never built because it
// needed art that does not exist.
//
// Stock SPL_THUN is a whole-screen flash + screenshake + damage; enemies just
// vanish. This drops a jagged bolt from the top of the screen onto EACH dying
// enemy, staggered a couple of frames apart so a full screen reads as a cascade
// rather than one simultaneous blink.
//
// DRAWN PROCEDURALLY, no sprite. There is no lightning art anywhere in the
// project -- the only thunder asset is the Thunderbird boss -- and at NES scale a
// bolt is a handful of white and blue pixels in a zigzag, which code produces more
// convincingly than a fixed sprite would. It also lets every bolt be a different
// shape, so ten strikes do not look stamped from one image. Same approach as the
// Navi herald.
//
// Each bolt stores its own SEED, so its zigzag is stable frame to frame (it does
// not writhe) while still differing from every other bolt.
//
// Cosmetic and runtime-only: nothing here touches the save or gameplay state.
// Reversible -- delete these two scripts, the thunderbolt_draw() call at the end
// of g_Draw, and the spawn call in update_spell_effects.
// ============================================================================
function thunderbolt_spawn(_x, _y, _delay) {

    if (!variable_global_exists("thunder_bolts")) global.thunder_bolts = [];

    // Hard cap. A screen-clear on a busy room could otherwise queue dozens of
    // bolts; past a point they overlap into a white smear and cost draw time for
    // no extra readability.
    if (array_length(global.thunder_bolts) >= 24) return;

    array_push(global.thunder_bolts, {
        x     : _x,
        y     : _y,
        delay : _delay,
        life  : 14,                 // frames the bolt is visible after its delay
        seed  : irandom(100000),    // fixed per bolt -> stable zigzag
    });

}
