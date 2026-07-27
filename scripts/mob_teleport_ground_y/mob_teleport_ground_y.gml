/// @description  mob_teleport_ground_y(x, y, half_height)
/// @param x            destination x (pixels) the mob is teleporting to
/// @param y            the mob's CURRENT y (pixels) -- used as the search start
/// @param half_height  hh_ of the caller, so the returned y sits the mob ON the floor
// ============================================================================
// Teleporting mobs pick a new X but keep their old Y, so on a room with more than
// one floor level they end up hanging in mid-air. Original-game rooms are flat
// where these enemies appear, so it never showed; ENEMY RANDO puts them in
// multi-tier rooms and it shows immediately. (Owner report, 2026-07-26.)
//
// This finds the first solid surface BELOW the destination and returns the y that
// puts the mob on top of it.
//
// WHY A HELPER AND NOT THE EXISTING CODE: Mago_update already had a ground-snap
// behind `g.mod_MAGO_ADJ2`, disabled by HoverBat in 2021 with the note "Inst always
// teleports to spawn coords". That guard had a real bug -- get_ground_y() returns a
// PIXEL y (it does its own `<<3` on the way out), but the caller treated the result
// as a ROW INDEX and shifted it left by 3 a second time, multiplying the coordinate
// by eight. Its "not found" test was broken the same way: it compared against -1,
// which get_ground_y never returns, since a failed search yields the caller's
// default argument. So the idea was right and the arithmetic was wrong.
//
// SAFETY: if nothing solid is found below, this returns the mob's CURRENT y
// unchanged -- i.e. exactly today's behaviour. It can move a mob onto a floor; it
// can never move one somewhere worse than where it already was.
// ============================================================================
function mob_teleport_ground_y(_x, _y, _hh) {

    // Search DOWNWARD from the mob's current height. Passing _y as the not-found
    // default is what makes failure a no-op rather than a teleport into the floor.
    var _ground = get_ground_y(_x, _y, 1, _y);

    // No solid below (elevator shafts, bottomless rooms) -> leave the mob alone.
    if (_ground == _y) return _y;

    // NEVER DROP BELOW THE ROOM'S OWN GROUND ROW. (Owner report, 2026-07-27.)
    //
    // "First solid surface below" is not the same as "the floor the player is on".
    // _EastA_59 has a lower deck beneath the main floor, so a Wizard teleporting
    // over a gap fell through to it and became unkillable -- and that room is a
    // REQUIRED quest fight, so the run simply stops. Trading a floating mob for an
    // unreachable one is not a fix.
    //
    // Rooms declare their intended floor as `<scene>_Ground_Row` (set in the
    // rm_data_init files, read the same way Leever_init2 does it). Where a room
    // declares one, clamp to it: a teleporting mob may land on a platform ABOVE the
    // ground, never below it. Rooms without the key keep the plain search.
    var _grow = g.dm_rm[? g.rm_name + STR_Ground + STR_Row];
    if (!is_undefined(_grow))
    {
        var _floor = _grow << 3;              // row -> pixels
        if (_ground > _floor) _ground = _floor;
    }

    // get_ground_y already returns pixels. Do NOT shift it again.
    return _ground - _hh;

}
