/// @description  Surface_Draw_GUI_Begin()
function Surface_Draw_GUI_Begin() {


	// -------------------------------------------------------------------------------------
	// SHADER PRE-WARM (one-time). GameMaker links/compiles a shader lazily on its FIRST
	// shader_set in a draw context, so the first time the player picks Sharp/CRT/Scanlines
	// (Options -> DISPLAY) the present stalls for a frame. We are already in a draw context
	// here (Draw GUI Begin runs every frame), so on the very first frame we touch each of the
	// three DisplayMode present shaders once -- set it, push its REAL uniform(s) to a harmless
	// value (so GameMaker emits no "uniform not set" warnings), draw a 1x1 throwaway far
	// off-screen, then shader_reset() -- moving that one-time cost to boot. Fully invisible
	// (1px at negative coords), each shader guarded by shader_is_compiled (skips a missing
	// one), and the flag is set BEFORE the warm work so it can only ever run once.
	// Revert: delete this block + the global.shaders_prewarmed init in g_Create.
	if (!variable_global_exists("shaders_prewarmed") || !global.shaders_prewarmed)
	{
		global.shaders_prewarmed = true; // arm-once first: even an early-out below never re-runs this

		if (surface_exists(application_surface))
		{
			var _pw_aw = surface_get_width( application_surface);
			var _pw_ah = surface_get_height(application_surface);
			if (_pw_aw < 1) _pw_aw = BASE_GAME_RESOLUTION_W;
			if (_pw_ah < 1) _pw_ah = BASE_GAME_RESOLUTION_H;

			// throwaway draw: 1x1, far off the top-left of any buffer -> never visible.
			var _pw_x = -64;
			var _pw_y = -64;

			// SHARP -> u_texSize (vec2), matches apply_display_present()'s DISPLAY_SHARP set.
			if (shader_is_compiled(shd_SharpBilinear))
			{
				shader_set(shd_SharpBilinear);
				shader_set_uniform_f(shader_get_uniform(shd_SharpBilinear,"u_texSize"), _pw_aw, _pw_ah);
				draw_surface_stretched(application_surface, _pw_x,_pw_y, 1,1);
				shader_reset();
			}

			// CRT -> u_resY (float), matches DISPLAY_CRT.
			if (shader_is_compiled(shd_CRT))
			{
				shader_set(shd_CRT);
				shader_set_uniform_f(shader_get_uniform(shd_CRT,"u_resY"), _pw_ah);
				draw_surface_stretched(application_surface, _pw_x,_pw_y, 1,1);
				shader_reset();
			}

			// SCAN -> u_texture_w/h + u_line_brightness/height (floats), matches DISPLAY_SCAN.
			if (shader_is_compiled(shd_ScanLines01))
			{
				shader_set(shd_ScanLines01);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_texture_w"),       _pw_aw);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_texture_h"),       _pw_ah);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_line_brightness"), 0.70);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_line_height"),     1.0);
				draw_surface_stretched(application_surface, _pw_x,_pw_y, 1,1);
				shader_reset();
			}
		}
	}


	CamZoom_test1();




	if (RetroShaders_can_draw)
	{
	    //display_set_gui_size(Window_w,Window_h);
	    var _srf1 = surface_create(application_surface_w,application_surface_h);
	    var _srf_blur = -1;
    
    
	    // Saturation and Brightness ------------------------
	    if (RetroShaders_SaturationBrightness_can_draw)
	    {
	        surface_set_target(_srf1);
	        draw_clear_alpha(c_black,0);
        
	        shader_set(shd_SaturationBrightness);
	        shader_set_uniform_f(shader_get_uniform(shd_SaturationBrightness,"u_saturation"), RetroShaders_Saturation_amount);
	        shader_set_uniform_f(shader_get_uniform(shd_SaturationBrightness,"u_brightness"), RetroShaders_Brightness_amount);
	        shader_set_uniform_f(shader_get_uniform(shd_SaturationBrightness,"u_effect_type"), 1); // Brightness effect
	        draw_surface(application_surface, 0,0);
	        shader_reset();
        
	        surface_reset_target();
	        surface_copy(application_surface, 0,0, _srf1);
	    }
    
    
	    // Scanlines ---------------------------------------
	    if (RetroShaders_Scanlines_can_draw)
	    {
	        surface_set_target(_srf1);
	        draw_clear_alpha(c_black,0);
        
	        shader_set(shd_ScanLines01);
	        shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_texture_w"), application_surface_w);
	        shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_texture_h"), application_surface_h);
	        shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_line_brightness"), GEE.dg_Scanlines[#GEE.Scanlines_EDIT,$5]);
	        shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_line_height"), RetroShaders_Scanlines_line_height);
	        draw_surface(application_surface, 0,0);
	        shader_reset();
        
	        surface_reset_target();
	        surface_copy(application_surface, 0,0, _srf1);
	    }
    
    
	    // Bloom ----------------------------------
	    if (RetroShaders_Bloom_can_draw)
	    {
	        surface_set_target(_srf1);
	        draw_clear_alpha(c_black,0);
        
	        shader_set(shd_Bloom01);
	        texture_set_stage(shader_get_sampler_index(shd_Bloom01,"u_texture"), surface_get_texture(application_surface));
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_texture_w"), application_surface_w);
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_texture_h"), application_surface_h);
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_dist_x"), RetroShaders_u_dist_x);
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_dist_y"), RetroShaders_u_dist_y);
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_a"), GEE.dg_Bloom[#GEE.Bloom_A,$5]); // default: 0.0004
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_b"), GEE.dg_Bloom[#GEE.Bloom_B,$5]); // default: 0.0120
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_c"), GEE.dg_Bloom[#GEE.Bloom_C,$5]); // default: 0.0090
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_d"), GEE.dg_Bloom[#GEE.Bloom_D,$5]); // default: 0.0075
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_e"), GEE.dg_Bloom[#GEE.Bloom_E,$5]); // default: 0.3000
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_f"), GEE.dg_Bloom[#GEE.Bloom_F,$5]); // default: 0.5000
	        shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_g"), GEE.dg_Bloom[#GEE.Bloom_G,$5]); // default: 0.2500
	        //shader_set_uniform_f(shader_get_uniform(shd_Bloom01,"u_scanlines_effect_enabled"), GEE.dg_Scanlines[#GEE.Scanlines_ENABLE,$5]);
	        draw_surface(application_surface, 0,0);
	        shader_reset();
        
	        surface_reset_target();
	        surface_copy(application_surface, 0,0, _srf1);
	    }
    
    
	    // Blur --------------------------------
	    if (RetroShaders_Blur_can_draw)
	    {
	        _srf_blur = surface_create(application_surface_w,application_surface_h);
        
	        var _TEXTURE = surface_get_texture(application_surface);
        
	        //surface_resize(_srf_blur, Window_w,Window_h);
	        surface_set_target(_srf_blur);
	        draw_clear_alpha(c_black,0);
        
	        shader_set(shd_Blur01);
	        texture_set_stage(shader_get_sampler_index(shd_Blur01,"u_texture"), _TEXTURE);
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01, "u_texel_size"), texture_get_texel_width(_TEXTURE),texture_get_texel_height(_TEXTURE));
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01, "u_pixel_scale"), RetroShaders_u_pixel_scale_x,RetroShaders_u_pixel_scale_y);
	        //shader_set_uniform_f(shader_get_uniform(shd_Blur02,"u_scanlines_effect_enabled"), GEE.dg_Scanlines[#GEE.Scanlines_ENABLE,$5]);
	        /*
	        shader_set(shd_Blur01);
	        texture_set_stage(shader_get_sampler_index(shd_Blur01,"u_texture"), surface_get_texture(application_surface));
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01,"u_texture_w"), application_surface_w);
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01,"u_texture_h"), application_surface_h);
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01,"u_dist_x"), RetroShaders_u_dist_x);
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01,"u_dist_y"), RetroShaders_u_dist_y);
	        shader_set_uniform_f(shader_get_uniform(shd_Blur01,"u_texture_scale"), global.RetroShaders_surface_scale);
	        //shader_set_uniform_f(shader_get_uniform(shd_Blur02,"u_scanlines_effect_enabled"), GEE.dg_Scanlines[#GEE.Scanlines_ENABLE,$5]);
	        */
	        draw_surface(application_surface, 0,0);
	        shader_reset();
        
	        surface_reset_target();
	    }
    
    
    
    
	    // FILL-WINDOW: keep this draw native (0,0). This Draw-event target IS the 480x270
	    // application_surface, so it must stay 1:1 (a stretched draw here would crop/zoom into
	    // the small surface, not fill). The fill-the-window stretch is GameMaker's final
	    // present, set to Full-scale via option_windows_scale:1 in
	    // options/windows/options_windows.yy (revert: scale->0).
	    draw_surface(application_surface, 0,0);


	    if (RetroShaders_Blur_can_draw)
	    {   // *** Blur is drawn transparent over application_surface because it will not blend properly when the draw target is to a surface
	        draw_surface_ext(_srf_blur, 0,0, 1,1, 0,c_white, GEE.dg_Blur[#GEE.Blur_EDIT,$5]);
	        surface_free(_srf_blur);
	    }
    
    
	    surface_free(_srf1);
	}
	else if(!global.application_surface_draw_enable_state)
	{
	    // Manual present (RetroShaders off, GameMaker auto-present disabled).
	    // DisplayMode takeover (SHARP/PIXEL/FILL/CRT/SCAN) owns the present here, but
	    // only while the application_surface is still native res. SMOOTH never gets here
	    // (it keeps the auto-present enabled), and CamZoom / any resized-surface case
	    // falls through to the original native (0,0) draw below.
	    if (global.DisplayMode != DISPLAY_SMOOTH
	    &&  application_surface_w == BASE_GAME_RESOLUTION_W
	    &&  application_surface_h == BASE_GAME_RESOLUTION_H )
	    {
	        apply_display_present();
	    }
	    else
	    {
	        // FILL-WINDOW: native (0,0) on purpose -- see note above; GameMaker's Full-scale
	        // present (option_windows_scale:1) stretches the app_surface to fill the window.
	        draw_surface(application_surface, 0,0);
	    }
	}

	//if (keyboard_check_pressed(vk_f7)) sdm("Surface_Draw_GUI_Begin()");






	/*
	if(!g.app_paused 
	&&  Input.GP_Other5_held      // trig L held
	&&  Input.GP_Other6_held      // trig R held
	&&  Input.GP_Other4_held      // bump R held
	&&  Input.GP_Other3_pressed ) // bump L pressed
	{
	    g.app_paused = true;
	}
	*/





	/*
	var _FONT_SPR = spr_Font2_1;
	var _DIST1 = sprite_get_height(_FONT_SPR)+1;
	var _XL = $10;
	var _yt = $30;

	draw_text_(_XL,_yt, "xport "+string_repeat("-",view_xport[0]<0)+string_repeat(" ",view_xport[0]>=0)+hex_str(abs(view_xport[0])), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "yport "+string_repeat("-",view_yport[0]<0)+string_repeat(" ",view_yport[0]>=0)+hex_str(abs(view_yport[0])), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "wport "+string_repeat("-",view_wport[0]<0)+string_repeat(" ",view_wport[0]>=0)+hex_str(abs(view_wport[0])), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "hport "+string_repeat("-",view_hport[0]<0)+string_repeat(" ",view_hport[0]>=0)+hex_str(abs(view_hport[0])), _FONT_SPR);
	_yt+=_DIST1;

	_yt+=_DIST1;
	draw_text_(_XL,_yt, "xview "+string_repeat("-",view_xview[0]<0)+string_repeat(" ",view_xview[0]>=0)+hex_str(abs(view_xview[0])), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "yview "+string_repeat("-",view_yview[0]<0)+string_repeat(" ",view_yview[0]>=0)+hex_str(abs(view_yview[0])), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "wview "+string_repeat("-",view_wview[0]<0)+string_repeat(" ",view_wview[0]>=0)+hex_str(abs(view_wview[0])), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "hview "+string_repeat("-",view_hview[0]<0)+string_repeat(" ",view_hview[0]>=0)+hex_str(abs(view_hview[0])), _FONT_SPR);
	_yt+=_DIST1;

	_yt+=_DIST1;
	draw_text_(_XL,_yt, "application_surface w "+string_repeat("-",surface_get_width( application_surface)<0)+string_repeat(" ",surface_get_width( application_surface)>=0)+hex_str(abs(surface_get_width( application_surface))), _FONT_SPR);
	_yt+=_DIST1;
	draw_text_(_XL,_yt, "application_surface h "+string_repeat("-",surface_get_height(application_surface)<0)+string_repeat(" ",surface_get_height(application_surface)>=0)+hex_str(abs(surface_get_height(application_surface))), _FONT_SPR);
	_yt+=_DIST1;
	*/







}
