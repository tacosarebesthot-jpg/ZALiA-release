/// @description  GO_set_sprite_index(sprite)
/// @param sprite
function GO_set_sprite_index(argument0) {

	// So that ww, hh, si_xoff, si_yoff are updated any time sprite_index changes.


	sprite_index = argument0;

	if (sprite_index >= 0) {
	    sprite_index_xoff = sprite_get_xoffset(sprite_index);
	    sprite_index_yoff = sprite_get_yoffset(sprite_index);
	    ww  = sprite_get_width( sprite_index);
	    hh  = sprite_get_height(sprite_index);
	} else {
	    sprite_index_xoff = 0;
	    sprite_index_yoff = 0;
	    ww  = 0;
	    hh  = 0;
	}
	ww_ = ww>>1;
	hh_ = hh>>1;







}
