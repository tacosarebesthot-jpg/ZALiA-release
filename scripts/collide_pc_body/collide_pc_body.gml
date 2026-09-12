/// @description  collide_pc_body(x, y, w, h, *radius)
/// @param x
/// @param  y
/// @param  w
/// @param  h
/// @param  *radius
function collide_pc_body() {


	with(global.pc)
	{
	    // !shrink / !grow (B26/B27, round 10h): the body box follows the drawn size.
	    // Scaled here, at test time only -- width around the centre, height from the
	    // feet -- so solids and the real box fields are never touched.
	    var _m  = variable_instance_exists(id, "tw_scale_mul") ? tw_scale_mul : 1;
	    var _bw = BodyHB_w, _bh = BodyHB_h, _bx = BodyHB_xl, _by = BodyHB_yt;
	    if (_m != 1)
	    {
	        _bw = max(2, BodyHB_w * _m); _bh = max(2, BodyHB_h * _m);
	        _bx = BodyHB_xl + (BodyHB_w - _bw) * 0.5;
	        _by = BodyHB_yt + (BodyHB_h - _bh);
	    }
	    if (argument_count>4
	    &&  argument[4] )
	    {   // radius
	        return rectInCirc(argument[0],argument[1],argument[4],             _bx,_by,_bw,_bh);
	    }
	    else
	    {
	        return rectInRect(argument[0],argument[1],argument[2],argument[3], _bx,_by,_bw,_bh);
	    }
	}

	return false;







}
