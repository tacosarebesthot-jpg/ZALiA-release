/// @description  collide_pc_sword(x, y, w, h, *radius)
/// @param x
/// @param  y
/// @param  w
/// @param  h
/// @param  *radius
function collide_pc_sword() {


	with(global.pc)
	{
	    // SwordHB_collidable is set and determined at end of master update in update_swrdXY()
	    if(!SwordHB_collidable) return false;
    
	    PC_update_sword_hb();
	    // !shrink / !grow (round 10h): sword reach follows the drawn size, test-time only
	    var _m  = variable_instance_exists(id, "tw_scale_mul") ? tw_scale_mul : 1;
	    var _sw = SwordHB_w, _sh = SwordHB_h, _sx = SwordHB_x, _sy = SwordHB_y;
	    if (_m != 1)
	    {
	        _sw = max(2, SwordHB_w * _m); _sh = max(2, SwordHB_h * _m);
	        _sx = SwordHB_x + (SwordHB_w - _sw) * 0.5;
	        _sy = SwordHB_y + (SwordHB_h - _sh) * 0.5;
	    }
	    if (argument_count>4
	    &&  argument[4] )
	    {   // radius
	        return rectInCirc(argument[0],argument[1],argument[4], _sx,_sy,_sw,_sh);
	    }
	    else
	    {
	        return rectInRect(argument[0],argument[1],argument[2],argument[3], _sx,_sy,_sw,_sh);
	    }
	}

	return false;







}
