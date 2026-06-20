/// @description  PC_update_walk()
function PC_update_walk() {


	// 943D, 943F
	var _val1 = 1;

	if(!ogr)
	{
	    _val1 = hspd;
    
	    if (cs&$3 
	    && !stun_timer 
	    && !g.EnterRoom_control_timer )
	    {
	        if (Input.heldH) _val1 = 5;
	        else             _val1 = 0;
	    }

	    // 9444, 9448, 9453
	    if (_val1 
	    && !g.WalkAnim_timer )
	    {
	        var _IDX = (abs8b(_val1)>>3) &$3; // = 0,1,2,3
	        g.WalkAnim_timer = g.dl_WalkAnim_DURATION[|_IDX]; // [8,7,5,4]
        
	        var _HSPD = abs8b(hspd);
	        if (_HSPD>HSPD_MAX1)
	        {
	            g.WalkAnim_timer -= floor(g.WalkAnim_timer*((_HSPD-HSPD_MAX1)/HSPD_MAX1));
	            g.WalkAnim_timer  = max(1,g.WalkAnim_timer);
	        }
        
	        if (walk_frame<2) walk_frame++;
	        else              walk_frame = 0;
	    }
	}

	// 9468
	if(!ogr 
	&& !_val1 )
	{    PC_set_behavior(behavior_IDLE);  }
	else PC_set_behavior(behavior_WALK1 + walk_frame);
	//if (g.WalkAnim_timer==1 && g.pc_lock==PC_LOCK_ALL) sdm("hspd $"+hex_str(hspd)+", _val1 $"+hex_str(_val1)+", behavior $"+hex_str(behavior));







}
