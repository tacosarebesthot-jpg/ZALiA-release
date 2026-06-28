/// @description  PC_draw()
function PC_draw() {


	// WALKTUNE HOOK 2 (revert: delete this _wt_ow_suppress var + remove it from the
	// "if (can_draw_self ...)" guard below) -- DUPLICATE-LINK GATE.
	// On the overworld (g.room_type=="C") the persistent Lonk object draws Link here
	// EVERY frame, on top of the manual Overworld_Draw Link. At faithful default
	// (ow_smooth_pct==0) the manual Link is NOT offset, so the two overlap exactly and
	// look like one (correct -- leave them). But when smoothing>0 the manual Link is
	// nudged sub-tile while this persistent one stays snapped, so it would show as a
	// SECOND, snapped Link. Suppress THIS body-draw only in that case.
	// NO-OP at default: ow_smooth_pct==0 -> _wt_ow_suppress is false -> draws normally.
	var _wt_ow_suppress = (g.room_type == "C"
	                    && variable_global_exists("ow_smooth_pct")
	                    && global.ow_smooth_pct > 0);

	if (can_draw_self && !_wt_ow_suppress)
	{
	    if (RescueFairy_sprite)
	    {
	        draw_sprite_(RescueFairy_sprite,0, RescueFairy_draw_x,RescueFairy_draw_y, global.PI_MOB_RED, 1);
	    }
    
    
    
	    var _x,_y, _x1,_y1;
	    var _SURF = surface_create(Draw_surface_size,Draw_surface_size);
	    surface_set_target(_SURF);
	    draw_clear_alpha(c_black,0);
    
	    // _x1/_y1: surface's center point
	    _x1 = Draw_surface_size>>1;
	    _y1 = Draw_surface_size>>1;
    
	    if (is_cucco)
	    {
	        if (Cucco_sprite_is_whole)
	        {
	            _x = _x1;
	            _y = _y1;
	            draw_sprite_(Cucco_sprite_body,0, _x,_y, Draw_palidx, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	        }
	        else
	        {
	            _x = _x1;
	            _y = _y1;
	            pal_swap_set(global.palette_image, Draw_palidx);
	            if (Cucco_legs_draw_first)
	            {   // draw legs behind body
	                draw_sprite_(Cucco_sprite_legs,0, _x,_y, -1, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	                draw_sprite_(Cucco_sprite_body,0, _x,_y, -1, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	            }else
	            {   // draw legs in front of body
	                draw_sprite_(Cucco_sprite_body,0, _x,_y, -1, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	                draw_sprite_(Cucco_sprite_legs,0, _x,_y, -1, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	            }
            
	            if (Cucco_eye_can_draw)
	            {
	                _x = _x1 + Cucco_eye_xoff;
	                _y = _y1 + Cucco_eye_yoff;
	                draw_point_colour(_x,_y, Cucco_eye_color);
	            }
            
	            _x = _x1;
	            _y = _y1 + Cucco_sprite_wing_yoff;
	            draw_sprite_(Cucco_sprite_wing,0, _x,_y, -1, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	            pal_swap_reset();
	        }
	    }
	    else if (is_fairy)
	    {
	        _x = _x1;
	        _y = _y1;
	        draw_sprite_(fairy_sprite,0, _x,_y, Draw_palidx, Draw_xscale1,Draw_yscale1, c_white,1, Draw_rotation1);
	    }
	    else
	    {
	        _x = _x1;
	        _y = _y1;
	        draw_pc_skin(_x,_y, Draw_xscale1,Draw_yscale1, Draw_behavior, Disguise_enabled, -1,-1, Draw_palidx, -1, Draw_rotation1);
	    }
    
	    surface_reset_target();
    
    
    
    
	    if (Shadow_can_draw) // PC Shadow During Boss Explosion
	    {
	        Shadow_can_draw = false;
        
	        var _depth_COPY = depth;
	        depth = Shadow_DEPTH;
        
	        draw_surface_ext(_SURF, Draw_surface_xl+Shadow_xoff, Draw_surface_yt, Draw_xscale2,Draw_yscale2, Draw_rotation2, p.C_BLK1,1);
        
	        depth = _depth_COPY;
	    }
    
    
	    draw_surface_ext(_SURF, Draw_surface_xl,Draw_surface_yt, Draw_xscale2,Draw_yscale2, Draw_rotation2, c_white,1);
	    surface_free(_SURF);
    
	    /* // debug -------------------
	    var _val=.5; // alpha
	    draw_rect_(c_green,   _x1,                  _y1,                   Draw_surface_size,Draw_surface_size, _val, true); // square 0, bottom right
	    draw_rect_(c_fuchsia, _x1,                  _y1-Draw_surface_size, Draw_surface_size,Draw_surface_size, _val, true); // square 1,    top right
	    draw_rect_(c_green,   _x1-Draw_surface_size,_y1-Draw_surface_size, Draw_surface_size,Draw_surface_size, _val, true); // square 2,    top left
	    draw_rect_(c_fuchsia, _x1-Draw_surface_size,_y1,                   Draw_surface_size,Draw_surface_size, _val, true); // square 3, bottom left
	    */
	}








	//dev_create_pc_skin_sprite();


	if (g.DevTools_state)
	{
	    // Body. Toggle with 'N'
	    GO_draw_body_hb();
    
	    // Sword. Toggle with 'N'
	    GO_draw_sword_hb();
    
	    // Shield. Toggle with 'N'
	    GO_draw_shield_hb();
    
	    // draw ocs lines. Toggle with 'C'
	    GO_draw_ocs();
    
	    // CS: Collide Solid points. Toggle with 'H'
	    GO_draw_cs_points();
    
	    // SCS: Sword Collide Solid. Toggle with 'N'
	    PC_draw_scs();
    
	    // Draw PC hp. Toggle with 'V'
	    PC_draw_hp();
    
	    // Toggle with 'L'. Outline representing the og camera
	    draw_view_og_outline();
	}







}
