/// @description  Mago_update()
function Mago_update() {


	// B7C5
	facing_dir = dir_to_pc(id);



	// ----------------------------------------------------------------------
	// ----------------------------------------------------------------------
	counter = (counter-1)&$FF;



	/* 
	// ----------------------------------------------------------------------
	// var _CASE = counter >>DUR1_BASE;
	switch(sub_state)
	{
	    // --------------------------------------------------------------
	    // ------------------------------------------------------
	    case 1:{
    
	    if(!timer)
	    {
	        timer = $
	        sub_state++;
	    }
	    break;}
    
    
    
	    // --------------------------------------------------------------
	    // ------------------------------------------------------
	    case 2:{
    
	    if(!timer) sub_state++;
	    break;}
    
    
    
	    // --------------------------------------------------------------
	    // ------------------------------------------------------
	    case 3:{
    
	    if(!timer) sub_state++;
	    break;}
    
    
    
	    // --------------------------------------------------------------
	    // ------------------------------------------------------
	    case 4:{
    
	    if(!timer) 1;
	    break;}
	}
	*/




	if (inRange(counter, $E0,$FF)) // --------  $FF-E0:  0.533s
	{
    
	    // --------------   FADE IN  -----------------------
	    if (counter&$1) update_EF11();
    
	}
	// B807 -----------------------------------------------------------------
	else if (inRange(counter, $C0,$DF)) // ---  $DF-C0:  0.533s
	{
    
    
	    // B7D6
	    if (counter == ATK_CUE-2  // ---------  ATK_CUE: $D2
	    &&  avail_uidx_goc(MAX_GOC1) != UIDX_NULL )
	    {
	        with(GOC1_create(x,y, facing_dir, projectile,projectile_ver)) // Flame1
	        {
	            spawn_xl  = other.xl + (8*facing_dir); // OG: Gives right a +4 advantage
	            if (g.mod_MAGO_ADJ1){
	            spawn_xl  = other.x  + (4*facing_dir); // 4 off from mago center
	            spawn_xl -= ww_; // bc spawn_xl is considered xl position
	            }
            
	            spawn_yt  = other.yb -  hh;
            
	            set_xy(id, spawn_xl+ww_, spawn_yt+hh_);
            
            
            
	            hspd = ($C*facing_dir) &$FF;
	        }
	    }
    
    
    
	    // B815, DE40
	    GOB_update_2();
	    // E2EF
	    if (cs&CS_BD1) enemy_collide_pc_body();
    
    
	}
	// ----------------------------------------------------------------------
	else if (inRange(counter, $A0,$BF)) // ---  $BF-A0:  0.533s
	{
    
	    // B81B ---------   FADE OUT  -----------------------
	    if!(counter&$1) update_EF11();
    
	}
	// ----------------------------------------------------------------------
	else if (inRange(counter, $00,$9F)) // ---  $9F-00:  2.667s
	{
	    stun_timer = 0;
    
    
	    if (counter==0) 
	    {
	        // B81E.  TELEPORT,  SET NEW X
	        var _RAND = rand();
	        var _x    = g.view_xl_og + _RAND + ww_;
	        var _y    = y;
        
	        // It seems if only one Mago is spawned, it 
	        // teleports much more often too far from PC.
	        // This will give a better chance of spawning 
	        // w/in a range that PC can get a hit in.
	        if (g.mod_MAGO_ADJ3 
	        &&  _RAND&$1 
	        //&&  _RAND&3 
	        &&  instance_number(object_index)==1 )
	        {
	            var _DIST = $06<<3;
	            _x = clamp(_x, global.pc.x-_DIST,global.pc.x+_DIST);
	            _x = clamp(_x, ww_,g.rm_w-ww_);
	        }
        
        
        
	        // GROUND SNAP (2026-07-26): the teleport above only chooses a new X, so on a
	        // multi-tier room the Mago rematerialises at its old height, hanging in the
	        // air. See mob_teleport_ground_y for why HoverBat's mod_MAGO_ADJ2 version of
	        // this was disabled in 2021 -- the idea was right, the arithmetic double-shifted
	        // a pixel value as if it were a row index. The helper is a no-op when there is
	        // no floor below, so this can never place the mob worse than before.
	        _y = mob_teleport_ground_y(_x, _y, hh_);

	        set_xy(id, _x,_y);
	    }
    
    
	}









	/*
	/// update_Mago()


	// B7C5
	facing_dir = dir_to_pc(id);



	// ----------------------------------------------------------------------
	// ----------------------------------------------------------------------
	counter = (counter-1)&$FF;


	// ----------------------------------------------------------------------
	if (inRange(counter, $E0,$FF)) // --------  $FF-E0:  0.533s
	{
    
	    // --------------   FADE IN  -----------------------
	    if (counter&1) update_EF11();
    
	}
	// B807 -----------------------------------------------------------------
	else if (inRange(counter, $C0,$DF)) // ---  $DF-C0:  0.533s
	{
    
    
	    // B7D6
	    if (counter == ATK_CUE-2  // ---------  ATK_CUE: $D2
	    &&  avail_uidx_goc(MAX_GOC1) != UIDX_NULL )
	    {
	        var _XX = x + (4 * facing_dir); // MOD. Start +4 towards from Mago center
	        // var _XX = xl + (4 * facing_dir); // MOD. Center on Mago.
	        // var _XX = xl + (8 * facing_dir); // OG: Gives right a +4 advantage
	        var _YY = yt + hh - $10;
        
	        with (GOC1_create(_XX,_YY, facing_dir, projectile)) // Flame1
	        {
	            hspd = ($C * facing_dir)&$FF;
	        }
	    }
    
    
    
	    // B815, DE40
	    GOB_update_2();
	    if (cs&CS_BD1) enemy_collide_pc_body();
    
    
	}
	// ----------------------------------------------------------------------
	else if (inRange(counter, $A0,$BF)) // ---  $BF-A0:  0.533s
	{
    
	    // B81B ---------   FADE OUT  -----------------------
	    if!(counter&1) update_EF11();
    
	}
	// ----------------------------------------------------------------------
	else if (inRange(counter, $00,$9F)) // ---  $9F-00:  2.667s
	{
	    tmr_stun = 0;
    
    
	    if (counter==0) 
	    {
	        // B81E.  TELEPORT,  SET NEW X
	        set_xy(id, g.view_xl_og + rand() + ww_, y);
	    }
    
    
	}
	*/











	/*
	// B7C5
	facing_dir = dir_to_pc(id);
	// setFacingDir();

	// B7C8
	counter = byte(counter - 1);

	if (counter < $E0 || counter & 1)
	{
	    if (counter >= $E0)
	    {
	        update_EF11();
	    }
	    else
	    {
	        // B7D6
	        if (counter == $D0)
	        {
	            if (avail_uidx_goc(MAX_GOC) != UIDX_NULL)
	            {
	                var _p, _x, _y;
	                _x = xl + (8 * facing_dir);
	                _y = yt + $10;
                
	                _p = Projectile_create(_x, _y, facing_dir, Flame1);
	                _p.hspd = byte($C * facing_dir);
	            }
	        }
        
	        // B807
	        if (counter >= $C0)
	        {
	            // B815, DE40
	            GOB_update_2();
            
	            // B818
	            if (cs & CS_BD1) enemy_collide_pc_body();
	        }
	        else if (counter < $A0)
	        {
	            // B81E
	            setXY(id, g.camXL + rand(), yt);
	            stunTimer = 0;
	        }
	        else if !(counter & 1)
	        {
	            // B81B
	            update_EF11();
	        }
	    }
	}
	*/









}
