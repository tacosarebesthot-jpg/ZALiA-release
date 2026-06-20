/// @description  collideRect(x, y, w, h, colliding obj, *colliding obj..)
/// @param x
/// @param  y
/// @param  w
/// @param  h
/// @param  colliding obj
/// @param  *colliding obj..
function collideRect() {


	for(var _i=4; _i<argument_count; _i++)
	{
	    with(argument[_i])
	    {
	        if (rectInRect(argument[0],argument[1],argument[2],argument[3], BodyHB_xl,BodyHB_yt, BodyHB_w,BodyHB_h))
	        {
	            return id;
	        }
	    }
	}


	return noone;







}
