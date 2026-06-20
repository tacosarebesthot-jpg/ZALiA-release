/// @description  TonnA_draw
function TonnA_draw() {


	if(!can_draw_self) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


	if (1)
	{
	    var     _color=p.C_BLK1;
	    switch((stun_timer>>1)&$3){
	    case 0:{_color=p.C_PNK1; break;}
	    case 1:{_color=p.C_PNK2; break;}
	    case 2:{_color=p.C_PNK3; break;}
	    case 3:{_color=p.C_PNK4; break;}
	    }
	    draw_sprite_(spr_1x1_WHT,0, drawX-ww_,drawY-hh_, -1, ww,hh-3, _color);
    
	    var _x = drawX+((ww_-6)*xScale);
	    var _y = drawY-$8;
	    //var _spr = spr_Eye_Open_1a_WRB; // open full
	    var _spr = spr_Eye_Open_1b_WRB; // open half
	    draw_sprite_(_spr,0, _x,_y, palidx);
	    draw_sprite_(spr_1x1_WHT,0, _x-1,_y-1, -1, 2,2, p.C_BLK1);
	}







}
