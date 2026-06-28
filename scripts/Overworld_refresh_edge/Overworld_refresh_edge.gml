/// @description  Overworld_refresh_edge(ow x, ow y, move x, move y)
/// @param ow x
/// @param  ow y
/// @param  move x
/// @param  move y
function Overworld_refresh_edge(argument0, argument1, argument2, argument3) {


	// EDGE-UPDATE (revert: at Overworld_Step.gml:~908 call Overworld_refresh_tiles instead of this).
	// PERF: the per-boundary FULL rebuild deleted+re-added all DRAW_CLMS*DRAW_ROWS tiles (~646 ops,
	// ~305ms). When Link crosses ONE tile only ONE edge row/column scrolls into view, so we add just
	// the new LEADING edge and delete the now off-screen TRAILING edge (~17 add + ~17 delete). The
	// middle tiles were already moved 1px/frame by tile_layer_shift (Overworld_Step.gml:~898) and, at
	// the boundary instant (dest_dist & T_SIZE-1 == 0), have shifted exactly T_SIZE px -> they land back
	// on the canonical grid, byte-identical to what the full rebuild would have re-snapped them to.
	// We only re-INDEX the dg_tid cache (a fixed-size ring) so each screen slot still maps to the tile
	// element occupying it. Edge cells read dg_tsrc + compute _ts/_tsrc0/_x/_y EXACTLY like the full
	// loop in Overworld_refresh_tiles.gml, so the new edge is seamless.

	// anarkhya overworld uses two extra detail layers + a different add path; its full rebuild is
	// cheap-ish and the edge math would need duplicating for two layers. Stay 100% faithful there:
	// fall back to the full rebuild (still fast relative to the main legacy tile_add cost).
	if (g.anarkhyaOverworld_MAIN
	&&  g.anarkhyaOverworld_enabled )
	{
	    Overworld_refresh_tiles(argument0,argument1);
	    exit;
	}


	var _ow_x = argument0;
	var _ow_y = argument1;
	var _move_x = argument2;
	var _move_y = argument3;


	// Only ONE axis moves per tile on the overworld. Guard against a zero/diagonal call (do nothing
	// rather than corrupt the ring); a stray diagonal is better handled by a full rebuild caller.
	if (_move_x!=0 && _move_y!=0)
	{
	    Overworld_refresh_tiles(_ow_x,_ow_y);
	    exit;
	}
	if (_move_x==0 && _move_y==0)
	{
	    exit;
	}


	// PERF: resolve the Tile_DEPTH1 layer id ONCE (same scan tile_add does) and pass it through every
	// add. Mirrors the cached-layer optimization already used by Overworld_refresh_tiles.gml.
	// -1 = fall back to per-call scan.
	var _ow_cached_layer = -1;
	var _ow_all_layers   = layer_get_all();
	var _ow_layer_i;
	for(_ow_layer_i=0; _ow_layer_i<array_length(_ow_all_layers); _ow_layer_i++)
	{
	    if (layer_get_depth(_ow_all_layers[_ow_layer_i]) == Tile_DEPTH1)
	    {
	        _ow_cached_layer = _ow_all_layers[_ow_layer_i];
	        break;
	    }
	}


	var _i,_j, _x,_y;
	var _ow_clm,_ow_row;
	var _tile_data, _val, _ts, _tsrc0, _tid;
	var _scale_x,_scale_y;


	if (_move_x!=0)
	{
	    // ---- HORIZONTAL move: one COLUMN scrolls in, one scrolls out ----
	    // move_x = -PC_DIR_SIGN_X. Walking RIGHT -> move_x<0 -> world shifts LEFT -> new column enters
	    // on the RIGHT (leading slot _j = DRAW_CLMS-1); trailing column leaves on the LEFT (slot 0).
	    // Walking LEFT -> move_x>0 -> mirror (leading slot 0, trailing slot DRAW_CLMS-1).
	    var _lead_clm;
	    var _trail_clm;
	    if (_move_x<0)
	    {
	        _lead_clm  = DRAW_CLMS-1;
	        _trail_clm = 0;
	    }
	    else
	    {
	        _lead_clm  = 0;
	        _trail_clm = DRAW_CLMS-1;
	    }

	    _x = _lead_clm<<SHIFT; // canonical screen x of the new column

	    for(_i=0; _i<DRAW_ROWS; _i++) // each row in the new leading column
	    {
	        _y = _i<<SHIFT;

	        _ow_clm = (_ow_x+_x)>>SHIFT;
	        _ow_row = (_ow_y+_y)>>SHIFT;

	        _scale_x = 1;
	        _scale_y = 1;

	        _tile_data = dg_tsrc[#_ow_clm,_ow_row];

	        if (RandoTSRC_active)
	        {
	            _val = dm_Rando_TSRC[?hex_str(_tile_data)];
	            if(!is_undefined(_val)) _tile_data = (_val>>2)<<2;
	        }

	        _tsrc0 = _tile_data&$FF;

	        if (g._YxY_)
	        {
	            if (_tsrc0==TSRC_TREE01
	            ||  _tsrc0==TSRC_TREE02
	            ||  _tsrc0==TSRC_TREE03
	            ||  _tsrc0==TSRC_TREE04
	            ||  _tsrc0==TSRC_GRAS01
	            ||  _tsrc0==TSRC_GRAS02
	            ||  _tsrc0==TSRC_GRAS03
	            ||  _tsrc0==TSRC_GRAS04
	            ||  _tsrc0==TSRC_SWAM01
	            ||  _tsrc0==TSRC_SWAM02
	            ||  _tsrc0==TSRC_SWAM03
	            ||  _tsrc0==TSRC_SWAM04
	            ||  _tsrc0==TSRC_VOLC01 )
	            {
	                if (irandom(1))
	                {
	                    _scale_x=-1;
	                    _x+=$1<<SHIFT;
	                }
	                if (irandom(1))
	                {
	                    _scale_y=-1;
	                    _y+=$1<<SHIFT;
	                }
	            }
	        }

	        _ts  = g.dl_tileset[|(_tile_data>>8)&$FF];

	        // 1) delete the off-screen TRAILING tile for this row, via its cached id (it has been
	        //    shifted ~T_SIZE px past the edge, so a position-based find would miss it).
	        tile_delete_(dg_tid[#_trail_clm,_i]);

	        // 2) add the new LEADING tile (delete-then-add at canonical pos; 0 = both). Same call the
	        //    full loop makes, with the cached layer.
	        _tid = tile_change_2a(T_SIZE, _ts,_tsrc0, _x,_y, Tile_DEPTH1, 0);

	        if (tile_exists(_tid)) tile_set_scale(_tid, _scale_x,_scale_y);

	        // 3) re-index the dg_tid ring: every surviving tile shifted ONE slot toward the trailing
	        //    side; rewrite the row so slot->element stays correct, then drop the new id in the lead.
	        if (_move_x<0)
	        {
	            // shift left: slot j takes what was in slot j+1
	            for(_j=0; _j<DRAW_CLMS-1; _j++) dg_tid[#_j,_i] = dg_tid[#_j+1,_i];
	        }
	        else
	        {
	            // shift right: slot j takes what was in slot j-1
	            for(_j=DRAW_CLMS-1; _j>0; _j--) dg_tid[#_j,_i] = dg_tid[#_j-1,_i];
	        }
	        dg_tid[#_lead_clm,_i] = _tid;

	        // restore _x/_y (the _YxY_ flip mutated them for the add only)
	        _x = _lead_clm<<SHIFT;
	    }
	}
	else
	{
	    // ---- VERTICAL move: one ROW scrolls in, one scrolls out ----
	    // move_y = -PC_DIR_SIGN_Y. Walking DOWN -> move_y<0 -> world shifts UP -> new row enters at the
	    // BOTTOM (leading slot _i = DRAW_ROWS-1); trailing row leaves at the TOP (slot 0).
	    // Walking UP -> move_y>0 -> mirror (leading slot 0, trailing slot DRAW_ROWS-1).
	    var _lead_row;
	    var _trail_row;
	    if (_move_y<0)
	    {
	        _lead_row  = DRAW_ROWS-1;
	        _trail_row = 0;
	    }
	    else
	    {
	        _lead_row  = 0;
	        _trail_row = DRAW_ROWS-1;
	    }

	    _y = _lead_row<<SHIFT; // canonical screen y of the new row

	    for(_j=0; _j<DRAW_CLMS; _j++) // each clm in the new leading row
	    {
	        _x = _j<<SHIFT;

	        _ow_clm = (_ow_x+_x)>>SHIFT;
	        _ow_row = (_ow_y+_y)>>SHIFT;

	        _scale_x = 1;
	        _scale_y = 1;

	        _tile_data = dg_tsrc[#_ow_clm,_ow_row];

	        if (RandoTSRC_active)
	        {
	            _val = dm_Rando_TSRC[?hex_str(_tile_data)];
	            if(!is_undefined(_val)) _tile_data = (_val>>2)<<2;
	        }

	        _tsrc0 = _tile_data&$FF;

	        if (g._YxY_)
	        {
	            if (_tsrc0==TSRC_TREE01
	            ||  _tsrc0==TSRC_TREE02
	            ||  _tsrc0==TSRC_TREE03
	            ||  _tsrc0==TSRC_TREE04
	            ||  _tsrc0==TSRC_GRAS01
	            ||  _tsrc0==TSRC_GRAS02
	            ||  _tsrc0==TSRC_GRAS03
	            ||  _tsrc0==TSRC_GRAS04
	            ||  _tsrc0==TSRC_SWAM01
	            ||  _tsrc0==TSRC_SWAM02
	            ||  _tsrc0==TSRC_SWAM03
	            ||  _tsrc0==TSRC_SWAM04
	            ||  _tsrc0==TSRC_VOLC01 )
	            {
	                if (irandom(1))
	                {
	                    _scale_x=-1;
	                    _x+=$1<<SHIFT;
	                }
	                if (irandom(1))
	                {
	                    _scale_y=-1;
	                    _y+=$1<<SHIFT;
	                }
	            }
	        }

	        _ts  = g.dl_tileset[|(_tile_data>>8)&$FF];

	        // 1) delete the off-screen TRAILING tile for this column, via its cached id.
	        tile_delete_(dg_tid[#_j,_trail_row]);

	        // 2) add the new LEADING tile (delete-then-add at canonical pos).
	        _tid = tile_change_2a(T_SIZE, _ts,_tsrc0, _x,_y, Tile_DEPTH1, 0);

	        if (tile_exists(_tid)) tile_set_scale(_tid, _scale_x,_scale_y);

	        // 3) re-index the dg_tid ring for this column: every surviving tile shifted ONE slot.
	        if (_move_y<0)
	        {
	            // shift up: slot i takes what was in slot i+1
	            for(_i=0; _i<DRAW_ROWS-1; _i++) dg_tid[#_j,_i] = dg_tid[#_j,_i+1];
	        }
	        else
	        {
	            // shift down: slot i takes what was in slot i-1
	            for(_i=DRAW_ROWS-1; _i>0; _i--) dg_tid[#_j,_i] = dg_tid[#_j,_i-1];
	        }
	        dg_tid[#_j,_lead_row] = _tid;

	        // restore _y (the _YxY_ flip mutated it for the add only)
	        _y = _lead_row<<SHIFT;
	    }
	}


}
