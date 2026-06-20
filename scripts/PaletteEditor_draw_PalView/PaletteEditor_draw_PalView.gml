/// @description  PaletteEditor_draw_PalView()
function PaletteEditor_draw_PalView() {


	var _xl,_yt, _count;


	// Full palette ----------------------------------------------------------------------------------------------------------
	_xl = PalView_xl;
	_count = global.palette_image_w;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, 0,                               _count, PalView_SCALE1);

	// PC --------------------------------------------------------------------------------------------------------------------
	_xl += (_count*PalView_SCALE1) + (PalView_PAD1<<1);
	_count = PalView_PAL_COUNT_PC;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_PC1,                   _count, PalView_SCALE2);
	// PC (dark room)
	_xl += (_count*PalView_SCALE2) +  PalView_PAD1;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_PC1+p.PAL_PER_SET,     _count, PalView_SCALE2);

	// Cucco -----------------------------------------------------------------------------------------------------------------
	_xl += (_count*PalView_SCALE2) + (PalView_PAD1<<1);
	_count = PalView_PAL_COUNT_CUCCO;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_CUCCO1,                _count, PalView_SCALE2);
	// Cucco (dark room)
	_xl += (_count*PalView_SCALE2) +  PalView_PAD1;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_CUCCO1+p.PAL_PER_SET,  _count, PalView_SCALE2);

	// Mobs ------------------------------------------------------------------------------------------------------------------
	_xl += (_count*PalView_SCALE2) + (PalView_PAD1<<1);
	_count = val(global.dm_pi[?"MOB"+STR_Count]);
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_MOB_ORG,               _count, PalView_SCALE2);
	// Mobs (dark room)
	_xl += (_count*PalView_SCALE2) +  PalView_PAD1;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_MOB_ORG+p.PAL_PER_SET, _count, PalView_SCALE2);

	// Background ------------------------------------------------------------------------------------------------------------
	_xl += (_count*PalView_SCALE2) + (PalView_PAD1<<1);
	_count = val(global.dm_pi[?"BGR"+STR_Count]);
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_BGR1,                  _count, PalView_SCALE2);
	// Background (dark room)
	_xl += (_count*PalView_SCALE2) +  PalView_PAD1;
	PaletteEditor_draw_PalView1(_xl, PalView_yt, global.PI_BGR1+p.PAL_PER_SET,    _count, PalView_SCALE2);




	if(!surface_exists(ObjPal_surf))
	{
	    ObjPal_surf = surface_create(ObjPal_surf_W,ObjPal_surf_H);
	    surface_set_target(ObjPal_surf);
	    draw_clear_alpha(c_white,1);
	    draw_sprite_(spr_1x1_WHT,0, (ObjPal_surf_W>>1)-(ObjPalBgr1_W>>1),(ObjPal_surf_H>>1)-(ObjPalBgr1_H>>1), -1, ObjPalBgr1_W,ObjPalBgr1_H, c_black);
	    surface_reset_target();
	}

	if(!is_undefined(p.pal_rm_curr) 
	&&  g.room_type=="A" )
	{
	    with(GameObject)
	    {
	        if (variable_instance_exists(id,"palidx"))
	        {
	            if(!variable_instance_exists(id,"state") 
	            ||  state )
	            {
	                _xl = x - (other.ObjPal_surf_W>>1);
	                _yt = yt - other.ObjPal_YT_OFFSET;
	                if (surface_exists(other.ObjPal_surf)) draw_surface(other.ObjPal_surf, _xl,_yt);
                
	                _xl  = x - (other.ObjPal_COL_SIZE>>1);
	                _yt  = yt - other.ObjPal_YT_OFFSET;
	                _yt += other.ObjPalOutline_W<<1;
	                _pal = string_copy(p.pal_rm_curr,get_pal_pos(palidx),global.PAL_CHAR_PER_PAL);
	                for(_i=0; _i<global.COLORS_PER_PALETTE; _i++)
	                {
	                    _color = string_copy(_pal,(global.PAL_CHAR_PER_COLOR*_i)+1,global.PAL_CHAR_PER_COLOR);
	                    _color = str_hex(_color);
	                    draw_sprite_(spr_1x1_WHT,0, _xl,_yt+(other.ObjPal_DIST1*_i), -1, other.ObjPal_COL_SIZE,other.ObjPal_COL_SIZE, _color);
	                }
                
	                // draw this object's current palette index
	                _xl  = x - (other.ObjPal_FONT_W>>1);
	                _yt  = yt - other.ObjPal_YT_OFFSET;
	                _yt -= 1; // pad
	                _yt -= other.ObjPal_FONT_H;
	                draw_text_(_xl,_yt, string_char_at(hex_str(palidx),2), other.ObjPal_FONT);
	                _yt -= 1; // pad
	                _yt -= other.ObjPal_FONT_H;
	                draw_text_(_xl,_yt, string_char_at(hex_str(palidx),1), other.ObjPal_FONT);
	            }
	        }
	    }
	}







}
