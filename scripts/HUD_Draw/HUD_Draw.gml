/// @description  HUD_Draw()
function HUD_Draw() {


	if(!can_draw_self) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// ----------------------------------------------------------------------------------
	var _i;




	pal_swap_set(global.palette_image, PI_MENU1);


	// ----------------------------------------------------------------------------------
	// MAGIC & LIFE METERS  -----------------------------------------------------

	// MAGIC METER -----------------------------
	// Magic Amount
	if (MeterFill_can_draw_MP)
	{
	    draw_sprite_(spr_1x1_WHT,0, MeterFill_xl_MP,MeterFill_yt_MP, -1, MeterFill_w_MP,METER_H, MeterFill_COLOR_MP);
	}

	// Meter Head && Container Boxes
	for(_i=MeterContainer_count_MP-1; _i>=0; _i--)
	{   draw_sprite_(MeterCont_SPRITE_MP,0, MeterCont_xl_MP+(_i<<3), MeterCont_yt_MP);  } // Container Boxes
	    draw_sprite_(MeterHead_SPRITE_MP,0, MeterHead_xl_MP,         MeterHead_yt_MP);    // Meter Head
	//


	// LIFE METER ------------------------------
	// Life Amount
	if (MeterFill_can_draw_HP)
	{
	    draw_sprite_(spr_1x1_WHT,0, MeterFill_xl_HP,MeterFill_yt_HP, -1, MeterFill_w_HP,METER_H, MeterFill_COLOR_HP);
	}

	// Meter Head && Container Boxes
	for(_i=MeterContainer_count_HP-1; _i>=0; _i--)
	{   draw_sprite_(MeterCont_SPRITE_HP,0, MeterCont_xl_HP+(_i<<3), MeterCont_yt_HP);  } // Container Boxes
	    draw_sprite_(MeterHead_SPRITE_HP,0, MeterHead_xl_HP,         MeterHead_yt_HP);    // Meter Head
	//




	// ----------------------------------------------------------------------------------
	// LEVELS  ---------------------------------------------------------------
	// Attack level
	draw_spr_aligned(global.SPR_ICON_ATK, Level_ATK_xl,Levels_yt,  -1,-1);
	draw_text_(Level_ATK_xl+8,Levels_yt, string(f.level_atk), -1,-1);

	// Magic level
	draw_spr_aligned(global.SPR_ICON_MAG, Level_MAG_xl,Levels_yt,  -1,-1);
	draw_text_(Level_MAG_xl+8,Levels_yt, string(f.level_mag), -1,-1);

	// Life level
	draw_spr_aligned(global.SPR_ICON_LIF, Level_LIF_xl,Levels_yt,  -1,-1);
	draw_text_(Level_LIF_xl+8,Levels_yt, string(f.level_lif), -1,-1);




	// ----------------------------------------------------------------------------------
	// XP  -------------------------------------------------------------------
	draw_text_(XP_xl,XP_yt, XP_text, -1,-1);


	// Next level-up stat icon
	if (NextLevel_can_draw)
	{
	    draw_sprite_(NextLevel_sprite,0, NextLevel_x,NextLevel_y, -1, NextLevel_xscale);
	}




	// -------------------------------------------------------------------
	//  LIVES & KEYS  ------------------------------------------------
	// Lives ----------------------------
	if (Lives_can_draw)
	{
	    draw_spr_aligned(spr_Lives_icon, Lives_xl,Lives_yt, -1,-1, -1, -1);
	    draw_text_(Lives_xl+8,Lives_yt, Lives_text, -1,-1);
	}
	// Keys -----------------------------
	if (Keys_can_draw)
	{
	    draw_spr_aligned(spr_Key_icon, Keys_xl,Keys_yt, -1,-1);
	    draw_text_(Keys_xl+8,Keys_yt, Keys_text, -1,-1);
	}
	// Deaths ---------------------------
	if (Deaths_can_draw)
	{
	    draw_text_(Deaths_xl,Deaths_yt, Deaths_text, -1,-1);
	}


	pal_swap_reset();




	// -------------------------------------------------------------------
	if (SpellQueued_can_draw)
	{
	    draw_spr_aligned(SpellQueued_ICON_SPR, SpellQueuedIcon_xl,SpellQueuedIcon_yt, -1,-1, PI_MENU1);
	    draw_text_(SpellQueued_xl,SpellQueued_yt, SpellQueued_text, -1, SpellQueued_palidx);
	}




	/*
	// -------------------------------------------------------------------
	if (g.DoubleJump_state 
	&&  f.items&ITM_FTHR )
	{
	    if (g.pc.jump_tokens)
	    {
	        _x = (viewXL()+X_BASE)-($4<<3);
	        _y = _Y1+8;
	        draw_sprite_(spr_Item_Feather_1a,0, _x,_y, PI_MOB_ORG);
	    }
	}
	*/




	/*
	/// HUD_Draw()


	if(!can_draw_self) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// ----------------------------------------------------------------------------------
	var _i, _x,_y, _w,_h;
	var _xscale = 1;
	var _text;

	var _X_BASE = viewXL();
	//var _X_BASE = viewXL() + X_BASE;
	var _Y1     = viewYT() + Y_LINE1;
	var _Y2     = viewYT() + Y_LINE2;




	pal_swap_set(p.palette_image, PI_MENU1);


	// ----------------------------------------------------------------------------------
	// MAGIC & LIFE METERS  -----------------------------------------------------

	// MAGIC METER -----------------------------
	_x = _X_BASE + MP_X + 8;
	_y = _Y2;

	// Magic Amount
	if (MeterFill_can_draw_MP)
	{
	    draw_sprite_(spr_1x1_WHT,0, _x,_y, -1, MeterFill_w_MP,METER_H, MeterFill_COLOR_MP);
	}

	// Meter Head && Container Boxes
	for(_i=MeterContainer_count_MP-1; _i>=0; _i--)
	{   draw_sprite_(METER_CONT_SPR_MP,0, _x+(_i<<3),_y);  } // Container Boxes
	    draw_sprite_(METER_HEAD_SPR_MP,0, _x-8,      _y);    // Meter Head
	//


	// LIFE METER ------------------------------
	_x = _X_BASE + HP_X + 8;
	_y = _Y2;

	// Life Amount
	if (MeterFill_can_draw_HP)
	{
	    draw_sprite_(spr_1x1_WHT,0, _x,_y, -1, MeterFill_w_HP,METER_H, MeterFill_COLOR_HP);
	}

	// Meter Head && Container Boxes
	for(_i=MeterContainer_count_HP-1; _i>=0; _i--)
	{   draw_sprite_(METER_CONT_SPR_HP,0, _x+(_i<<3),_y);  } // Container Boxes
	    draw_sprite_(METER_HEAD_SPR_HP,0, _x-8,      _y);    // Meter Head
	//




	// ----------------------------------------------------------------------------------
	// LEVELS  ---------------------------------------------------------------
	_y = _Y1;

	// Attack level
	_x = _X_BASE + Level_ATK_X;
	draw_spr_aligned(global.SPR_ICON_ATK, _x,_y,  -1,-1);
	draw_text_(_x+8,_y, string(f.level_atk), -1,-1);

	// Magic level
	_x = _X_BASE + Level_MAG_X;
	draw_spr_aligned(global.SPR_ICON_MAG, _x,_y,  -1,-1);
	draw_text_(_x+8,_y, string(f.level_mag), -1,-1);

	// Life level
	_x = _X_BASE + Level_LIF_X;
	draw_spr_aligned(global.SPR_ICON_LIF, _x,_y,  -1,-1);
	draw_text_(_x+8,_y, string(f.level_lif), -1,-1);




	// ----------------------------------------------------------------------------------
	// XP  -------------------------------------------------------------------
	_x = _X_BASE + XP_X;
	_y = _Y2;
	draw_text_(_x,_y, XP_text, -1,-1);


	// Next level-up stat icon
	if (global.HUD_state>=2 
	&&  NextLevel_sprite )
	{
	    _x = _X_BASE + XPNextIcon_X;
	    draw_spr_aligned(NextLevel_sprite, _x,_y, -1,-1, -1, NextLevel_sprite_xscale);
	}




	// -------------------------------------------------------------------
	//  LIVES & KEYS  ------------------------------------------------
	var _x1 = _X_BASE + HP_X;
	if (global.HUD_state>=2)
	{
	    // lives
	    _x = _x1;
	    _y = _Y1;
	    draw_spr_aligned(spr_Lives_icon, _x,_y, -1,-1, -1, -1);
	    _x += 8;
	    draw_text_(_x,_y, Lives_text, -1,-1);
	    _x1 += $05<<3; // for keys position
	    //_x1 += 4;
    
	    // keys
	    if (g.dungeon_num) // if in a dungeon
	    {
	        _x = _x1;
	        _y = _Y1;
	        draw_spr_aligned(spr_Key_icon, _x,_y, -1,-1);
	        _x += 8;
	        draw_text_(_x,_y, Keys_text, -1,-1);
	    }
	}


	pal_swap_reset();




	// -------------------------------------------------------------------
	if (global.HUD_state>=2 
	&&  g.mod_HUD_SPELL_READY )
	{
	    _x = _X_BASE + SpellQueued_ICON_X;
	    _y = _Y1;
	    draw_spr_aligned(SpellQueued_ICON_SPR, _x,_y, -1,-1, PI_MENU1);
    
	    _x = _X_BASE + SpellQueued_TEXT_X;
	    draw_text_(_x,_y, SpellQueued_text, -1, SpellQueued_palidx);
	}
	*/



}
