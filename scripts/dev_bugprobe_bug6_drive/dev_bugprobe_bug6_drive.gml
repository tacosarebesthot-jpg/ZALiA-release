/// @description  dev_bugprobe_bug6_log_frame()
function dev_bugprobe_bug6_log_frame() {


	// ============================================================
	// DEV BUG PROBE HARNESS -- PROBE BUG6 per-frame OW-walk logger  (added 2026-06-22)
	//   Called from Dev_Bugprobe_Step() (self==g there) ONLY while global.OVERWORLD is
	//   live and the BUG6 walk-drive is actively holding Right. Writes one
	//   "PROBE BUG6 FRAME" line per call with the numbers needed to tell whether
	//   Link's draw-x advances in 8px snapped jumps (ow_pc_xy(0)'s >>3<<3) while the
	//   tile layer + a live mob's screen-x move smoothly at 1px/frame.
	//   No-ops entirely unless DEV is true AND the bugprobe flag is active (same gate
	//   as every other bugprobe helper), so it is inert in any normal/ship build.
	// ============================================================
	if (!(DEV && global.bugprobe)) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	if (!instance_exists(global.OVERWORLD)) exit;

	var _dest_dist, _move_x, _pc_ow_x, _pc_draw_x, _tile_x, _mob_x;
	with (global.OVERWORLD)
	{
	    _dest_dist = dest_dist;
	    _move_x    = move_x;
	    _pc_ow_x   = pc_ow_x;
	    _pc_draw_x = PC_draw_x;

	    _tile_x = "n/a (ow_tile_layer==-1)";
	    if (variable_instance_exists(other, "ow_tile_layer") && other.ow_tile_layer != -1)
	    {
	        _tile_x = string(layer_get_x(other.ow_tile_layer));
	    }

	    _mob_x = "none (no live encounter instance)";
	    var _gw = ds_grid_width(dg_enc_inst);
	    for (var _i = 0; _i < _gw; _i++)
	    {
	        if (dg_enc_inst[#_i, 0])
	        {
	            _mob_x = string(dg_enc_inst[#_i, 1]); // enc obj screen-space center x (already scroll-adjusted)
	            break;
	        }
	    }
	}

	directory_create(working_directory + "bugprobe");
	var _f = file_text_open_append(working_directory + "bugprobe/report.txt");
	file_text_write_string(_f, "PROBE BUG6 FRAME: app_frame=" + string(global.App_frame_count)
	      + "  dest_dist=" + string(_dest_dist)
	      + "  move_x=" + string(_move_x)
	      + "  pc_ow_x=" + string(_pc_ow_x)
	      + "  PC_draw_x=" + string(_pc_draw_x)
	      + "  tile_layer_x=" + string(_tile_x)
	      + "  mob_x=" + string(_mob_x));
	file_text_writeln(_f);
	file_text_close(_f);


}
