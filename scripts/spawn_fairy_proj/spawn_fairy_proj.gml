/// @description  spawn_fairy_proj(_x, _y, _dir)
/// @param _x    world x to anchor the projectile to (the fairy's x)
/// @param _y    world y to anchor the projectile to (the fairy's y)
/// @param _dir  facing / horizontal velocity direction (-1 left, 1 right)
function spawn_fairy_proj(argument0, argument1, argument2) {

	// Forked from spawn_pc_proj(): activates a free ProjectileFriendly from the shared
	// pool g.go_mgr.dl_goc2, but anchored to (_x,_y) and facing _dir instead of global.pc.
	// The shared collision (GOB_body_collide_pc_proj -> damage_gob) damages enemies for us.

	if (!global.coop_enabled) return noone; // OFF by default

	if (!instance_exists(g)
	||  !instance_exists(g.go_mgr) )
	{
	    return noone;
	}


	var _ax  = argument0; // anchor x  (copied to locals so they're in scope inside with())
	var _ay  = argument1; // anchor y
	var _dir = sign(argument2);
	if (_dir == 0) _dir = 1; // default to facing right


	// Find a free (inactive) projectile in the pool AND count how many are free.
	// state == 0 means available (active projectiles carry state == state_NORMAL);
	// this mirrors spawn_pc_proj_2a().
	var _n    = ds_list_size(g.go_mgr.dl_goc2);
	var _proj = noone;
	var _free = 0;
	for (var _i = 0; _i < _n; _i++)
	{
	    var _p = g.go_mgr.dl_goc2[|_i];
	    if (is_undefined(_p)
	    || !instance_exists(_p) )
	    {
	        continue;
	    }
	    if (!_p.state)
	    {
	        _free++;
	        if (_proj == noone) _proj = _p; // remember the first free slot to use
	    }
	}

	// RESERVE slots for Link's sword beam so the fairy can never exhaust the shared
	// ProjectileFriendly pool (g.go_mgr.dl_goc2, size MAX_GOC2 = 6). spawn_pc_proj_2a()
	// only fires when it finds a free (!state) slot; if the fairy fills every slot,
	// Link's full-HP beam is silently blocked. So the fairy may only claim a free slot
	// when MORE than _RESERVE_FOR_PC remain free -- after it takes one there are still
	// >= _RESERVE_FOR_PC slots left for Link (his beam needs at most 2).
	var _RESERVE_FOR_PC = 2;
	if (_proj == noone)           return noone; // no free slot at all
	if (_free <= _RESERVE_FOR_PC) return noone; // keep slots open for Link's beam


	with(_proj)
	{
	    // Activate as a plain BEAM projectile (the non-FIRE path of spawn_pc_proj).
	    state                = state_NORMAL;
	    disintegrate_counter = 0;
	    brightness           = 0;

	    type_bits = BIT_BEM1;
	    TypeID    = TypeID_BEAM;

	    if (f.items&ITM_SWRD) timeout = timeout_BEAM2; // $C2
	    else                  timeout = timeout_BEAM1; // $D2

	    // Anchor to the fairy instead of global.pc. -3 mirrors spawn_pc_proj's beam _XOFF.
	    set_xlyt(id, _ax-3, _ay);

	    facing_dir = _dir;
	    xScale     = facing_dir;
	    hspd       = ($20*facing_dir) &$FF;

	    update_body_hb();
	    update_draw_xy();

	    aud_play_sound(get_audio_theme_track(STR_Sword+STR_Beam));
	}


	return _proj;




}
