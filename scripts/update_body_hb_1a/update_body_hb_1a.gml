/// @description  update_body_hb_1a()
function update_body_hb_1a() {


	//  BodyHB_idx. 0:g.dg_BODY_HB[#0,i] is all 0,   -1:inst will manually set in its update
	if(!BodyHB_idx)
	{
	    BodyHB_can_draw = BodyHB_idx!=BODY_HB_IDX_DYNAMIC; // BODY_HB_IDX_DYNAMIC: -2
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}


	if (is_ancestor(object_index,ProjectileHostile)) // Projectile Hostile
	{    BodyHB_can_draw = true;  }
	else BodyHB_can_draw = state==state_NORMAL;


	BodyHB_xoff = g.dg_BODY_HB[#BodyHB_idx,0];
	BodyHB_yoff = g.dg_BODY_HB[#BodyHB_idx,1];
	BodyHB_w    = g.dg_BODY_HB[#BodyHB_idx,2];
	BodyHB_h    = g.dg_BODY_HB[#BodyHB_idx,3];
	BodyHB_r    = g.dg_BODY_HB[#BodyHB_idx,4]; // radius
	// !shrink / !grow (B26/B27): Link's hurt box follows the drawn size -- width around the
	// centre, height from the feet -- in the real fields, so fire ropes, challenge triggers and
	// every other direct BodyHB_* reader agree with what is on screen. Solids use xl/yt, untouched.
	if (instance_exists(global.pc) && id == global.pc
	&&  variable_instance_exists(id, "tw_scale_mul") && tw_scale_mul != 1)
	{
	    var _m = tw_scale_mul, _w0 = BodyHB_w, _h0 = BodyHB_h;
	    BodyHB_w = max(2, round(_w0 * _m));
	    BodyHB_h = max(2, round(_h0 * _m));
	    BodyHB_xoff += floor((_w0 - BodyHB_w) / 2);
	    BodyHB_yoff += (_h0 - BodyHB_h);
	}
	update_body_hb();







}
