/// @description  Cutscene_GameEnd_1A_draw()
function Cutscene_GameEnd_1A_draw() {


	with(Zelda) other.depth = depth-1;
	for(var _i=ds_grid_width(dg_triforce)-1; _i>=0; _i--)
	{
	    draw_sprite_(dg_triforce[#_i,0],0,  // sprite & sub image
	                 dg_triforce[#_i,1],    // x
	                 dg_triforce[#_i,2],    // y
	                 p.triforce_pi );       // pi
	}

	// TOAD CARD (see Cutscene_GameEnd_1A_update case 7): a black plate over the view with the SMB line,
	// first quest only. If a sprite named spr_toad_card exists it is drawn where Zelda sits (Toadstool in
	// the princess's place, Lane's joke) and Zelda is hidden for the card; without the asset, text only.
	if (g.cutscene_part == 7 && variable_instance_exists(id, "toad_card_timer") && toad_card_timer > 0)
	{
	    var _vx = viewXL(), _vy = viewYT(), _vw = viewW(), _vh = viewH();
	    draw_set_alpha(0.85); draw_set_color(c_black);
	    draw_rectangle(_vx, _vy, _vx + _vw, _vy + _vh, false);
	    draw_set_alpha(1); draw_set_color(c_white);
	    var _lines = ["THANK YOU LINK!", "BUT OUR PRINCESS IS IN", "ANOTHER CASTLE...", "", "THE SECOND QUEST AWAITS.", "SAME FILE. PLAY IT AGAIN!"];
	    var _ch = 8, _cw = 8;
	    var _ty = _vy + (_vh >> 1) - (array_length(_lines) * (_ch + 4)) div 2;
	    var _toad = asset_get_index("spr_toad_card");
	    if (_toad >= 0 && sprite_exists(_toad))
	    {
	        with (Zelda) { visible = false; draw_sprite(_toad, 0, x, y); }
	        _ty += 24;
	    }
	    for (var _li = 0; _li < array_length(_lines); _li++)
	    {
	        var _tx = _vx + (_vw >> 1) - (string_length(_lines[_li]) * _cw) div 2;
	        draw_text_(_tx, _ty + _li * (_ch + 4), _lines[_li], -1, global.PI_BGR1);
	    }
	}
	else if (g.cutscene_part == 8) { with (Zelda) visible = true; }
}
