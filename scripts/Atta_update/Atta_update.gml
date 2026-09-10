/// @description  Atta_update()
function Atta_update() {

	// B19 (2026-07-26 master list): the stun gate here made Atta FREEZE SOLID on
	// hit -- AI skipped entirely, a statue until the timer expired ("stun lock is
	// op"). GOB_update_2 -> update_EF11 already ticks stun_timer down, so letting
	// the AI run while stunned just makes it jitter and misfire instead of
	// hard-freezing. Atta & Balshot ONLY -- every other enemy keeps the gate.
	// if (stun_timer) { GOB_update_2(); exit; }

	var                          _DUR = $30;
	if ( counter == DUR_COOLDOWN+_DUR)
	{    counter = _DUR;  }
	else counter = (counter+1)&$FF;

	if ( counter == DUR_COOLDOWN)
	{
	    for(var _i=0; _i<2; _i++)
	    {
	        if (avail_uidx_goc(MAX_GOC1)==UIDX_NULL) continue; // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        
	        with(GOC1_create(x-4, yt-4, sign_(_i), projectile,projectile_ver))
	        {
	            vspd = $E0;
	            hspd = ($10*facing_dir) &$FF;
	        }
	    }
	}




	if (cs&CS_BD1) enemy_collide_pc_body();
	GO_update_cs(); // solids collision
	GOB_update_2(); // body/shield/sword collision
	GO_update_cs();



	if!(g.counter1&$7)
	{                                  var _Y_OFF=1;
	    if (g.counter1&$20) set_xy(id, x,y-_Y_OFF);
	    else                set_xy(id, x,y+_Y_OFF);
	}







}
