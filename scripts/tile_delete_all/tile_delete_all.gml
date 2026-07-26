/// @description  tile_delete_all()
function tile_delete_all() {

	// delete all tiles in the room

	// PERF FIX (2026-07-26): this was O(N^2) and was THE fall-scene stall -- measured at
	// 9,880,929 us of a 9,885,234 us frame (99.96%) on _PalcD_09. Everything else in the
	// fall trigger was noise: surfaces 226us, palette 3,328us, audio 89us.
	//
	// Why it was quadratic: g.tile_pal_swap_ver == 1 (g_Create.gml:1316), so tile_delete_()
	// took its pal-swap branch for EVERY tile, and that branch calls tile_get_ids_at_depth(),
	// which runs layer_get_all() and walks every element of every matching layer. N tiles ->
	// N full scans of N tiles. It was doing all that work only to answer "was that the last
	// tile at this depth, so should I drop the depth from dl_pal_swap_depths?"
	//
	// That bookkeeping is pointless here because we are deleting EVERY tile: no depth can
	// retain a pal-swap tile afterwards. It is also already redundant -- g_Room_Start.gml:245
	// does ds_list_clear(dl_pal_swap_depths) on every room start, which is exactly what
	// follows a fall. So: one scan to collect ids, then the plain builtin tile_delete() per
	// tile (no per-tile rescan), then clear the depth list wholesale. O(N^2) -> O(N).
	//
	// NOTE: this is deliberately NOT calling tile_delete_(). That wrapper's only added value
	// over the builtin is the per-tile depth bookkeeping we are replacing with one clear.

	var _ar_TILE_IDS = tile_get_ids(); // single layer scan

	for(var _i=array_length(_ar_TILE_IDS)-1; _i>=0; _i--)
	{
	    var _id = _ar_TILE_IDS[_i];
	    // tile_get_ids() seeds its array with -1, so an empty room yields [-1]; skip it.
	    if (_id >= 0) tile_delete(_id);
	}

	_ar_TILE_IDS = 0;

	// Every tile is gone -> no depth can still hold pal-swap tiles. This replaces the
	// per-tile list maintenance that made the old version quadratic.
	if (instance_exists(g)
	&&  variable_instance_exists(g, "dl_pal_swap_depths")
	&&  !is_undefined(g.dl_pal_swap_depths)
	&&  ds_exists(g.dl_pal_swap_depths, ds_type_list))
	{
	    ds_list_clear(g.dl_pal_swap_depths);
	}

}
