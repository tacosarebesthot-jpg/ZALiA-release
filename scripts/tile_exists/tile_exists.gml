/// @description Checks if a given tile exists in the room.
/// @param index The index of the tile to check for.
/// @returns {boolean} whether the tile exists
function tile_exists(argument0) {

	// GMS2: tile_add() returns -1 on failure; any non-negative ID is a valid tile
	return argument0 >= 0;


}
