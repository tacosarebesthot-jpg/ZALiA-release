/// @description  apply_display_mode()
/// Wires global.DisplayMode (Options -> DISPLAY) into the present pipeline.
///
/// SMOOTH (0) is the vanilla GameMaker present and is left 100% untouched: from a
/// clean boot in SMOOTH this code NEVER calls display_set_gui_size and NEVER flips
/// application_surface_draw_enable away from its boot value, so SMOOTH is byte-identical
/// to the previous behaviour.
///
/// The other modes (SHARP/PIXEL/FILL/CRT/SCAN) take over the final present in the
/// Surface object's Draw GUI Begin event (see apply_display_present below) -- but ONLY
/// while RetroShaders is OFF. RetroShaders keeps priority when enabled; this function
/// just makes the auto-present flag + GUI size agree with whoever owns the present.
function apply_display_mode() {

	// RetroShaders owns the present when live+enabled -> never take over then.
	var _retro = (global.RetroShaders_IS_LIVE && global.RetroShaders_enabled);
	var _takeover = (!_retro) && (global.DisplayMode != DISPLAY_SMOOTH);

	if (_takeover)
	{
		// We own the present: disable GameMaker's automatic application_surface
		// present so it does not draw underneath our scaled/letterboxed output.
		if (global.application_surface_draw_enable_state)
		{
			global.application_surface_draw_enable_state = false;
			application_surface_draw_enable(false);
		}

		// Own the whole window: put the GUI layer into window-pixel space so the
		// scaler/shader controls the upscale (GameMaker's Full-scale present is then
		// 1:1). Guarded so we only resize the GUI surface when it actually changes.
		// apply_display_present() re-asserts this every frame to follow live resizes.
		var _ww = window_get_width();
		var _wh = window_get_height();
		if (_ww > 0 && _wh > 0
		&&  (display_get_gui_width() != _ww || display_get_gui_height() != _wh) )
		{
			display_set_gui_size(_ww, _wh);
		}
		global.DisplayMode_gui_overridden = true;
	}
	else
	{
		// SMOOTH, or RetroShaders is on (it manages its own present). Make the
		// auto-present flag match the RetroShaders state: enabled when RetroShaders
		// is off (vanilla SMOOTH), disabled when RetroShaders is on.
		var _want_enable = !_retro;
		if (global.application_surface_draw_enable_state != _want_enable)
		{
			global.application_surface_draw_enable_state = _want_enable;
			application_surface_draw_enable(_want_enable);
		}

		// Restore the GUI ONLY if a takeover mode previously resized it. From a clean
		// boot (never overridden) we leave GameMaker's default GUI completely untouched
		// -> SMOOTH never calls display_set_gui_size, staying byte-identical. The restore
		// target is the live application_surface size, which is exactly what the default
		// GUI tracks (480x270 normally, RetroShaders_surface_scale*base while RetroShaders
		// is on), so RetroShaders keeps working after a takeover->SMOOTH/Retro switch.
		if (global.DisplayMode_gui_overridden)
		{
			var _aw = surface_get_width( application_surface);
			var _ah = surface_get_height(application_surface);
			if (_aw > 0 && _ah > 0
			&&  (display_get_gui_width() != _aw || display_get_gui_height() != _ah) )
			{
				display_set_gui_size(_aw, _ah);
			}
			global.DisplayMode_gui_overridden = false;
		}
	}
}




/// @description  apply_display_present()
/// Per-frame scaled present for the non-SMOOTH DisplayModes. Called from the Surface
/// object's Draw GUI Begin event ONLY when RetroShaders is off, GameMaker's auto-present
/// is disabled (global.application_surface_draw_enable_state == false) and the
/// application_surface is still at native resolution. Draws the 480x270 application_surface
/// across the whole window using the mode's scaler; GameMaker's Full-scale present then
/// maps the (window-sized) GUI buffer 1:1 to the window.
function apply_display_present() {

	var _ww = window_get_width();
	var _wh = window_get_height();
	if (_ww < 1) _ww = BASE_GAME_RESOLUTION_W;
	if (_wh < 1) _wh = BASE_GAME_RESOLUTION_H;

	// Keep the GUI layer in window-pixel space (guarded). Handles live window
	// resizing while a takeover mode is active. Skipped on steady-state frames.
	if (display_get_gui_width() != _ww || display_get_gui_height() != _wh)
	{
		display_set_gui_size(_ww, _wh);
	}
	global.DisplayMode_gui_overridden = true;

	var _aw = surface_get_width( application_surface);
	var _ah = surface_get_height(application_surface);
	if (_aw < 1) _aw = BASE_GAME_RESOLUTION_W;
	if (_ah < 1) _ah = BASE_GAME_RESOLUTION_H;

	var _prev_filter = gpu_get_tex_filter();
	draw_set_colour(c_white);
	draw_set_alpha(1);

	switch(global.DisplayMode)
	{
		// SHARP: crisp upscale that fills the window (sharp-bilinear shader snaps
		// texels, narrow blend band kills shimmer).
		case DISPLAY_SHARP:
		{
			gpu_set_tex_filter(true);
			if (shader_is_compiled(shd_SharpBilinear))
			{
				shader_set(shd_SharpBilinear);
				shader_set_uniform_f(shader_get_uniform(shd_SharpBilinear,"u_texSize"), _aw, _ah);
				draw_surface_stretched(application_surface, 0,0, _ww,_wh);
				shader_reset();
			}
			else
			{   // fallback: plain bilinear fill (still better than a blank present)
				draw_surface_stretched(application_surface, 0,0, _ww,_wh);
			}
		break;}

		// PIXEL: largest integer scale that fits, centred, black letterbox/pillarbox,
		// nearest-neighbour (no blur, perfectly square pixels).
		case DISPLAY_PIXEL:
		{
			var _scale = max(1, floor(min(_ww/_aw, _wh/_ah)));
			var _dw = _aw * _scale;
			var _dh = _ah * _scale;
			var _ox = (_ww - _dw) div 2;
			var _oy = (_wh - _dh) div 2;
			draw_clear(c_black);
			gpu_set_tex_filter(false);
			draw_surface_stretched(application_surface, _ox,_oy, _dw,_dh);
		break;}

		// FILL: nearest-neighbour stretch to fill the window (no bars; aspect may distort).
		case DISPLAY_FILL:
		{
			gpu_set_tex_filter(false);
			draw_surface_stretched(application_surface, 0,0, _ww,_wh);
		break;}

		// CRT: subtle scanlines + aperture mask + vignette, fills the window.
		case DISPLAY_CRT:
		{
			gpu_set_tex_filter(true);
			if (shader_is_compiled(shd_CRT))
			{
				shader_set(shd_CRT);
				shader_set_uniform_f(shader_get_uniform(shd_CRT,"u_resY"), _ah);
				draw_surface_stretched(application_surface, 0,0, _ww,_wh);
				shader_reset();
			}
			else
			{   // fallback: plain bilinear fill
				draw_surface_stretched(application_surface, 0,0, _ww,_wh);
			}
		break;}

		// SCAN: simple horizontal scanlines, fills the window.
		case DISPLAY_SCAN:
		{
			gpu_set_tex_filter(true);
			if (shader_is_compiled(shd_ScanLines01))
			{
				shader_set(shd_ScanLines01);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_texture_w"),      _aw);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_texture_h"),      _ah);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_line_brightness"), 0.70);
				shader_set_uniform_f(shader_get_uniform(shd_ScanLines01,"u_line_height"),     1.0);
				draw_surface_stretched(application_surface, 0,0, _ww,_wh);
				shader_reset();
			}
			else
			{   // fallback: plain bilinear fill
				draw_surface_stretched(application_surface, 0,0, _ww,_wh);
			}
		break;}

		// Safety fallback (SMOOTH is handled by the vanilla path and never reaches here).
		default:
		{
			gpu_set_tex_filter(true);
			draw_surface_stretched(application_surface, 0,0, _ww,_wh);
		break;}
	}

	gpu_set_tex_filter(_prev_filter);
}
