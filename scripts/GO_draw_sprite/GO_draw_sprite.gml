/// @description  GO_draw_sprite(sprite, *palette index)
/// @param sprite
/// @param  *palette index
function GO_draw_sprite() {


	if(argument[0] <= 0) exit; // GMS2: guard 0 AND -1 (no sprite)



	switch(argument_count)
	{
	    // --------------------------------------------------------------
	    case 1:{ // sprite
	    draw_sprite_(argument[0],0, drawX,drawY, -1,          xScale,yScale);
	    break;}
    
    
	    // --------------------------------------------------------------
	    case 2:{ // sprite, palette index
	    draw_sprite_(argument[0],0, drawX,drawY, argument[1], xScale,yScale);
	    break;}
	}







}
