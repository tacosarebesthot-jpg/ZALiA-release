/// @description  init_vars_go_1a()
function init_vars_go_1a() {

	// go: GameObject


	state_NORMAL  = $01; // Normal
	state_DEATH1  = $E8; // Pending explosion (Boss)
	state_EXPLODE = $E9; // Exploding
	state_DROP    = $40; // Drop XP or item
	state = 0;

	ver = 1; // version number of object

	//                                      //
	ww  = sprite_width; // ww:  full width
	ww_ = ww>>1;        // ww_: half width
	hh  = sprite_height;// hh:  full height
	hh_ = hh>>1;        // hh_: half height
	//                                      //
	// GMS2: sprite_get_xoffset(-1) throws — guard when no sprite assigned
	var _spr_xoff = (sprite_index >= 0) ? sprite_get_xoffset(sprite_index) : 0;
	var _spr_yoff = (sprite_index >= 0) ? sprite_get_yoffset(sprite_index) : 0;
	xl  = x - _spr_xoff; // xl: x left.  004D-005B
	xc  = xl+ww_;        // xc: x center
	xr  = xl+ww;         // xr: x right
	//                                      //
	yt  = y - _spr_yoff; // yt: y top.  0029-003A
	//yt  = sprIdx_y(id); // yt: y top.  0029-003A
	yc  = yt+hh_;       // yc: y center
	yb  = yt+hh;        // yb: y bottom
	//                                      //

	timer = 0; // 0504,X 0504-0509. GO timers

	// GMS2: uninitialized variables throw — set defaults that GMS1.4 gave for free (0)
	can_draw_self           = true;
	can_draw_self_exception = false;
	scr_draw                = undefined; // overridden by init_vars_go_4a
	sprite_index_xoff       = 0; // overridden by GO_set_sprite_index when sprite is assigned
	sprite_index_yoff       = 0;

	// list index of g.go_mgr.dl_gob1/dl_gob2/dl_goc1
	// this instance's turn in the update order
	update_idx = UIDX_NULL;


	//BRIGHTNESS = 0;
	brightness = 0; // 0,1,2. Contributes to g.rm_brightness







}
