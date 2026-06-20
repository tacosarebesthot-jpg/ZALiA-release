/// @description  HUD_Step()
function HUD_Step() {


	var _x,_y, _xl,_yt;
	var _X_BASE = viewXL();
	var _Y1     = viewYT() + Y_LINE1;
	var _Y2     = viewYT() + Y_LINE2;


	can_draw_self = g.ChangeRoom_timer<=0 && global.HUD_state;


	XP_text  = get_xp_str(f.xp);     // XP current
	XP_text += "/";                  // XP Forward slash
	XP_text += get_xp_str(f.xpNext); // XP next


	// Next level-up stat icon
	if (0 
	&&  f.level_atk>=STAT_LEVEL_MAX 
	&&  f.level_mag>=STAT_LEVEL_MAX 
	&&  f.level_lif>=STAT_LEVEL_MAX )
	{
	    NextLevel_sprite = spr_Lives_icon;
	    NextLevel_xscale = -1;
	}
	else
	{
	         if (get_xp_next(STAT_ATK)==f.xpNext) NextLevel_sprite = global.SPR_ICON_ATK;
	    else if (get_xp_next(STAT_MAG)==f.xpNext) NextLevel_sprite = global.SPR_ICON_MAG;
	    else if (get_xp_next(STAT_LIF)==f.xpNext) NextLevel_sprite = global.SPR_ICON_LIF;
	    else                                      NextLevel_sprite = 0;
	    //else                                      NextLevel_sprite = spr_Text_WrongChar;
	    NextLevel_xscale = 1;
	}



	Lives_text = g.CHAR_TIMES+string(global.pc_lives);


	if (f.items&ITM_SKEY)
	{
	    Keys_text = g.CHAR_TIMES+"A";
	}
	else
	{
	    var _DUNGEON_NUM = val(f.dm_rando[?g.rm_name+STR_Dungeon+STR_Num], g.dungeon_num);
	    Keys_text = g.CHAR_TIMES+string(get_key_count(_DUNGEON_NUM));
	    //Keys_text = g.CHAR_TIMES+string(f.key_count);
	}






	var _SPELL = 0;
	if (f.spells)
	{
	         if (g.spell_ready)            _SPELL = g.spell_ready;
	    else if (p.SpellReady_flash_timer) _SPELL = spell_last_used();
	}

	if (_SPELL==SPL_FARY 
	&&  g.CuccoSpell2_Acquired 
	&&  g.CuccoSpell2_Option )
	{
	    SpellQueued_text = "CUCCO";
	}
	else
	{
	    SpellQueued_text = val(g.dm_Spell[?hex_str(_SPELL)+STR_Name], SpellQueued_NONE);
	}

	if (SpellQueued_text!=SpellQueued_NONE)
	{
	    SpellQueued_text = string_letters(SpellQueued_text);
	}


	SpellQueued_palidx = PI_MENU1;
	if (SpellQueued_text!=SpellQueued_NONE)
	{
	    if (p.SpellReady_flash_timer)
	    {
	        SpellQueued_palidx = p.dg_PI_SEQ[#$04,(p.SpellReady_flash_timer-1)&$3];
	    }
	    else if (g.mod_IndicateSpellUnaffordable 
	         &&  f.mp-get_spell_cost(g.spell_ready) < 0 )
	    {
	        SpellQueued_palidx = global.spell_unaffordable_pi;
	    }
	    else if (g.mod_IndicateSpellActive 
	         &&  g.spells_active & g.spell_ready )
	    {
	        SpellQueued_palidx  = global.spell_futile_pi;
	    }
	}






	MeterContainer_count_MP = cont_cnt_mp();
	MeterContainer_count_HP = cont_cnt_hp();




	MeterHead_xl_HP = _X_BASE + HP_X;
	MeterHead_yt_HP = _Y2;

	MeterHead_xl_MP = _X_BASE + MP_X;
	MeterHead_yt_MP = _Y2;


	MeterCont_xl_HP = MeterHead_xl_HP + 8;
	MeterCont_yt_HP = MeterHead_yt_HP;

	MeterCont_xl_MP = MeterHead_xl_MP + 8;
	MeterCont_yt_MP = MeterHead_yt_MP;


	MeterFill_can_draw_MP = f.mp!=0;
	MeterFill_can_draw_HP = f.hp!=0;

	MeterFill_w_MP = ceil(f.mp / MeterFill_AMOUNT_PER_PIXEL); // _w will be AT LEAST 1. ceil() rounds UP to nearest int
	MeterFill_w_HP = ceil(f.hp / MeterFill_AMOUNT_PER_PIXEL); // _w will be AT LEAST 1. ceil() rounds UP to nearest int


	MeterFill_xl_HP = MeterCont_xl_HP;
	MeterFill_yt_HP = MeterCont_yt_HP;

	MeterFill_xl_MP = MeterCont_xl_MP;
	MeterFill_yt_MP = MeterCont_yt_MP;




	Levels_xl = _X_BASE;
	Levels_yt = _Y1;

	Level_ATK_xl = Levels_xl + Level_ATK_XL;
	Level_MAG_xl = Levels_xl + Level_MAG_XL;
	Level_LIF_xl = Levels_xl + Level_LIF_XL;




	XP_xl = _X_BASE + XP_X;
	XP_yt = _Y2;




	NextLevel_can_draw = can_draw_self && global.HUD_state>=2 && NextLevel_sprite;
	NextLevel_x        = _X_BASE + NextLevel_X;
	NextLevel_y        = _Y2;
	NextLevel_y       += sprite_get_height(NextLevel_sprite)>>1;




	Lives_can_draw = global.HUD_state>=2;
	Lives_xl = _X_BASE + HP_X;
	Lives_yt = _Y1;

	Keys_xl  = Lives_xl;
	Keys_xl += $02<<3; // lives text + lives sprite
	Keys_xl += $03<<3; // padding
	Keys_yt  = _Y1;
	Keys_can_draw  = global.HUD_state>=2 && g.dungeon_num;


	Deaths_text     = "D:"+string(f.death_count);
	Deaths_can_draw = global.HUD_state>=2;
	Deaths_yt       = _Y1;
	if (Keys_can_draw)
	{   Deaths_xl = Keys_xl + ($03<<3);      } // after keys in dungeon
	else
	{   Deaths_xl = Lives_xl + ($05<<3);     } // after lives on overworld



	SpellQueued_can_draw = global.HUD_state>=2 && g.mod_HUD_SPELL_READY;
	SpellQueuedIcon_xl = _X_BASE + SpellQueued_ICON_X;
	SpellQueuedIcon_yt = _Y1;
	SpellQueued_xl     = _X_BASE + SpellQueued_TEXT_X;
	SpellQueued_yt     = _Y1;







}
