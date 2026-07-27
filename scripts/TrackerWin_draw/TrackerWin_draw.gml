/// @description  TrackerWin_draw()
function TrackerWin_draw() {
	// Redraws the full tracker window. Called from TrackerWin_step().

	var _hwnd = global.TW_hwnd;
	if (!_hwnd) exit;
	if (!external_call(global.TW_fn_IsWindow, _hwnd)) exit;

	var _dc = external_call(global.TW_fn_GetDC, _hwnd);
	if (!_dc) exit;

	// ── Select persistent GDI objects ────────────────────────────────────────
	external_call(global.TW_fn_SelectObj, _dc, global.TW_null_pen);
	external_call(global.TW_fn_SelectObj, _dc, global.TW_font);
	external_call(global.TW_fn_SetBkMode, _dc, 1); // TRANSPARENT

	// ── Color for current/active spell highlight ──────────────────────────────
	var C_SEL = 0x000099FF; // #FF9900 orange  (COLORREF: R=0xFF G=0x99 B=0x00 → 0x000099FF)

	// ── Color constants (COLORREF = 0x00BBGGRR = blue-green-red byte order) ──
	var C_BG     = 0x001A0D0D;  // #0D0D1A dark panel
	var C_HDR    = 0x00221111;  // header strip
	var C_SEP    = 0x00554433;  // separator
	var C_ON     = 0x0088FF00;  // #00FF88 active/have
	var C_OFF    = 0x00221111;  // inactive/dim
	var C_WHITE  = 0x00FFFFFF;
	var C_GRAY   = 0x00CCBBAA;  // labels
	var C_RED    = 0x004444FF;  // offline
	var C_YELLOW = 0x0000CCFF;  // key count accent
	var C_SECTN  = 0x009966AA;  // section header labels
	var C_HP     = 0x0044FF44;  // HP bar fill
	var C_MP     = 0x00FF8844;  // MP bar fill
	var C_HP_BG  = 0x00112211;  // HP bar track
	var C_MP_BG  = 0x00111122;  // MP bar track

	// ── Layout ───────────────────────────────────────────────────────────────
	var _MX  = 8;     // left margin
	var _ROW = 17;    // pixels per text row
	var _BAR = 196;   // HP/MP bar width
	var _BH  = 10;    // bar height
	var _COL4 = 82;   // 4-column item grid step
	var _COL3 = 110;  // 3-column spell grid step

	// ─────────────────────────────────────────────────────────────────────────
	// Background + header
	// ─────────────────────────────────────────────────────────────────────────
	TrackerWin_fill(_dc, 0,0, 600,900, C_BG);
	TrackerWin_fill(_dc, 0,0, 600,22,  C_HDR);

	external_call(global.TW_fn_SelectObj, _dc, global.TW_font_bold);
	TrackerWin_put(_dc, _MX,4, "ZALiA TRACKER", C_WHITE);
	external_call(global.TW_fn_SelectObj, _dc, global.TW_font);

	var _f_ok = instance_exists(f);
	if (_f_ok) {
	    TrackerWin_put(_dc, 255,4, "* LIVE", C_ON);
	    // Current room name (right-side subtitle under header)
	    var _rname = room_get_name(room);
	    TrackerWin_put(_dc, _MX,20, _rname, C_GRAY);
	} else {
	    TrackerWin_put(_dc, 231,4, "* OFFLINE", C_RED);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Stats + item/spell sections
	// ─────────────────────────────────────────────────────────────────────────
	var _y = 36;  // shifted down to make room for room name line

	if (_f_ok)
	{
	    var _deaths   = f.death_count;
	    var _lives    = global.pc_lives;
	    var _quest    = f.quest_num;
	    var _atk      = f.level_atk;
	    var _mag      = f.level_mag;
	    var _lif      = f.level_lif;
	    var _xp       = f.xp;
	    var _xpnext   = val(f.xpNext, 0);
	    var _hp       = f.hp;
	    var _mp       = f.mp;
	    var _items    = f.items;
	    var _spells   = f.spells;
	    var _skills   = f.skills;
	    var _crystals = f.crystals;

	    // ── Pre-compute death rate ────────────────────────────────────────────
	    var _hours = global.QuestTimer_time / 3600000000;
	    var _rate_str = "";
	    if (_hours > 0.01 && _deaths > 0) {
	        _rate_str = " ("+string(floor(_deaths/_hours))+"d/h)";
	    }

	    // ── Rando seed ────────────────────────────────────────────────────────
	    var _seed = val(f.dm_rando[?STR_Rando+STR_Seed], 0);
	    if (_seed) {
	        TrackerWin_put(_dc, _MX,_y-_ROW, "SEED: "+string_upper(hex_str(_seed)), C_GRAY);
	    }

	    // ── Row 1: core stats ────────────────────────────────────────────────
	    TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	    TrackerWin_put(_dc, _MX,_y,
	        "QUEST:"+string(_quest)+"  D:"+string(_deaths)+_rate_str+"  LIV:"+string(_lives),
	        C_WHITE);
	    _y += _ROW;

	    // ── Row 2: levels ────────────────────────────────────────────────────
	    TrackerWin_put(_dc, _MX,_y,
	        "ATK:"+string(_atk)+"  MAG:"+string(_mag)+"  LIF:"+string(_lif)+"  XP:"+string(_xp),
	        C_WHITE);
	    _y += _ROW;

	    // ── Row 3: XP to next level + quest timer ────────────────────────────
	    if (_xpnext > 0 && _xp < _xpnext) {
	        TrackerWin_put(_dc, _MX,_y, "Next lvl: "+string(_xpnext - _xp)+" XP", C_GRAY);
	    } else {
	        TrackerWin_put(_dc, _MX,_y, "XP: max level", C_GRAY);
	    }
	    TrackerWin_put(_dc, 196,_y, global.QuestTimer_text, C_GRAY);
	    _y += _ROW + 2;

	    // ── HP bar ───────────────────────────────────────────────────────────
	    var _hp_max = 8 + val(f.cont_pieces_hp, 0)*2;
	    _hp_max = max(_hp_max, _hp);
	    var _hp_fill = floor((_hp / max(_hp_max,1)) * _BAR);
	    TrackerWin_put(_dc, _MX,_y, "HP", C_GRAY);
	    TrackerWin_fill(_dc, _MX+20,_y+2, _MX+20+_BAR,      _y+2+_BH, C_HP_BG);
	    TrackerWin_fill(_dc, _MX+20,_y+2, _MX+20+_hp_fill,  _y+2+_BH, C_HP);
	    TrackerWin_put(_dc, _MX+20+_BAR+4,_y, string(_hp)+"/"+string(_hp_max), C_HP);
	    _y += _ROW;

	    // ── MP bar ───────────────────────────────────────────────────────────
	    var _mp_max = 8 + val(f.cont_pieces_mp, 0)*2;
	    _mp_max = max(_mp_max, _mp);
	    var _mp_fill = floor((_mp / max(_mp_max,1)) * _BAR);
	    TrackerWin_put(_dc, _MX,_y, "MP", C_GRAY);
	    TrackerWin_fill(_dc, _MX+20,_y+2, _MX+20+_BAR,      _y+2+_BH, C_MP_BG);
	    TrackerWin_fill(_dc, _MX+20,_y+2, _MX+20+_mp_fill,  _y+2+_BH, C_MP);
	    TrackerWin_put(_dc, _MX+20+_BAR+4,_y, string(_mp)+"/"+string(_mp_max), C_MP);
	    _y += _ROW + 4;

	    // ─────────────────────────────────────────────────────────────────────
	    // ITEMS  (25 items, 4 per row)
	    // ─────────────────────────────────────────────────────────────────────
	    TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	    var _item_on = 0;
	    var _item_total = 25;

	    var _inames; var _ibits;
	    _inames[0]  = "CANDLE";  _ibits[0]  = 0;
	    _inames[1]  = "GLOVES";  _ibits[1]  = 1;
	    _inames[2]  = "RAFT";    _ibits[2]  = 2;
	    _inames[3]  = "BOOTS";   _ibits[3]  = 3;
	    _inames[4]  = "FLUTE";   _ibits[4]  = 4;
	    _inames[5]  = "CROSS";   _ibits[5]  = 5;
	    _inames[6]  = "HAMMER";  _ibits[6]  = 6;
	    _inames[7]  = "BRACLET"; _ibits[7]  = 7;
	    _inames[8]  = "RFAIRY";  _ibits[8]  = 8;
	    _inames[9]  = "MASK";    _ibits[9]  = 9;
	    _inames[10] = "BOOK";    _ibits[10] = 10;
	    _inames[11] = "MEAT";    _ibits[11] = 11;
	    _inames[12] = "SHIELD";  _ibits[12] = 12;
	    _inames[13] = "RING";    _ibits[13] = 13;
	    _inames[14] = "PENDANT"; _ibits[14] = 14;
	    _inames[15] = "SWORD";   _ibits[15] = 15;
	    _inames[16] = "NOTE";    _ibits[16] = 16;
	    _inames[17] = "MIRROR";  _ibits[17] = 17;
	    _inames[18] = "TROPHY";  _ibits[18] = 18;
	    _inames[19] = "FLOWER";  _ibits[19] = 19;
	    _inames[20] = "ALLKEY";  _ibits[20] = 22;
	    _inames[21] = "MAP1";    _ibits[21] = 23;
	    _inames[22] = "MAP2";    _ibits[22] = 24;
	    _inames[23] = "MELODY";  _ibits[23] = 26;
	    _inames[24] = "FEATHER"; _ibits[24] = 27;

	    // Count first pass
	    var _ii;
	    for (_ii=0; _ii<_item_total; _ii++) {
	        if ((_items >> _ibits[_ii]) & 1) _item_on++;
	    }

	    // Header with count
	    TrackerWin_put(_dc, _MX, _y, "ITEMS", C_SECTN);
	    TrackerWin_put(_dc, 260, _y, string(_item_on)+"/"+string(_item_total), C_GRAY);
	    _y += _ROW;

	    // Draw grid
	    var _row_y = _y;
	    for (_ii=0; _ii<_item_total; _ii++) {
	        var _col = _ii mod 4;
	        if (_col==0 && _ii>0) _row_y += _ROW;
	        TrackerWin_put(_dc, _MX + _col*_COL4, _row_y,
	            _inames[_ii],
	            ((_items >> _ibits[_ii]) & 1) ? C_ON : C_OFF);
	    }
	    _y = _row_y + _ROW + 4;

	    // ─────────────────────────────────────────────────────────────────────
	    // SPELLS  (9 spells, 3 per row)
	    // ─────────────────────────────────────────────────────────────────────
	    TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	    var _spell_on = 0;
	    var _snames; var _sbits;
	    _snames[0] = "JUMP";    _sbits[0] = 0;
	    _snames[1] = "HEAL";    _sbits[1] = 1;
	    _snames[2] = "FAIRY";   _sbits[2] = 2;
	    _snames[3] = "FIRE";    _sbits[3] = 3;
	    _snames[4] = "REFLECT"; _sbits[4] = 4;
	    _snames[5] = "ENIGMA";  _sbits[5] = 5;
	    _snames[6] = "THUNDER"; _sbits[6] = 6;
	    _snames[7] = "SUMMON";  _sbits[7] = 7;
	    _snames[8] = "PROTECT"; _sbits[8] = 8;

	    var _si;
	    for (_si=0; _si<9; _si++) {
	        if ((_spells >> _sbits[_si]) & 1) _spell_on++;
	    }

	    var _cur_spell_name = val(g.dm_Spell[?hex_str(g.spell_selected)+STR_Name], "");
	    TrackerWin_put(_dc, _MX, _y, "SPELLS", C_SECTN);
	    if (_cur_spell_name != "") {
	        TrackerWin_put(_dc, 70, _y, "["+_cur_spell_name+"]", C_SEL);
	    }
	    TrackerWin_put(_dc, 260, _y, string(_spell_on)+"/9", C_GRAY);
	    _y += _ROW;

	    _row_y = _y;
	    for (_si=0; _si<9; _si++) {
	        var _sc = _si mod 3;
	        if (_sc==0 && _si>0) _row_y += _ROW;
	        var _sbit = 1 << _sbits[_si];
	        var _shave = (_spells >> _sbits[_si]) & 1;
	        var _sclr  = _shave ? ((_sbit==g.spell_selected) ? C_SEL : C_ON) : C_OFF;
	        TrackerWin_put(_dc, _MX + _sc*_COL3, _row_y, _snames[_si], _sclr);
	    }
	    _y = _row_y + _ROW + 4;

	    // ─────────────────────────────────────────────────────────────────────
	    // SKILLS  (2 skills)
	    // ─────────────────────────────────────────────────────────────────────
	    TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	    TrackerWin_put(_dc, _MX, _y, "SKILLS", C_SECTN);
	    _y += _ROW;
	    TrackerWin_put(_dc, _MX,           _y, "DWNSTAB", (_skills & 1)      ? C_ON : C_OFF);
	    TrackerWin_put(_dc, _MX+_COL3,     _y, "UPSTAB",  ((_skills>>1) & 1) ? C_ON : C_OFF);
	    _y += _ROW + 4;

	    // ─────────────────────────────────────────────────────────────────────
	    // CRYSTALS  (6, one per palace)
	    // ─────────────────────────────────────────────────────────────────────
	    TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	    TrackerWin_put(_dc, _MX, _y, "CRYSTALS", C_SECTN);
	    var _ci;
	    for (_ci=0; _ci<6; _ci++) {
	        TrackerWin_put(_dc, _MX+90+_ci*40, _y, "C"+string(_ci+1),
	            ((_crystals>>_ci) & 1) ? C_ON : C_OFF);
	    }
	    _y += _ROW + 4;

	    // ─────────────────────────────────────────────────────────────────────
	    // PALACE KEYS  (per-palace, 3 per row)
	    // ─────────────────────────────────────────────────────────────────────
	    TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	    TrackerWin_put(_dc, _MX, _y, "KEYS", C_SECTN);
	    _y += _ROW;
	    var _pi;
	    for (_pi=1; _pi<=6; _pi++) {
	        var _pkc = get_key_count(_pi);
	        var _px = _MX + ((_pi-1) mod 3) * 110;
	        if (_pi==4) _y += _ROW;
	        TrackerWin_put(_dc, _px, _y, "P"+string(_pi)+":"+string(_pkc),
	            _pkc>0 ? C_YELLOW : C_GRAY);
	    }
	    _y += _ROW + 4;

	    // ─────────────────────────────────────────────────────────────────────
	    // HINTS  (if rando is on)
	    // ─────────────────────────────────────────────────────────────────────
	    if (global.RandoHints_enabled)
	    {
	        TrackerWin_fill(_dc, 0,_y-1, 600,_y, C_SEP);
	        var _hnums   = val(g.dm_RandoHintsRecorder[?STR_Found+STR_Hint+STR_Num], "");
	        var _hfound  = string_length(_hnums)>>1;
	        // SEED's hint count, not the world's. g.dm_RandoHints[Hint_Count] counts
	        // every hint-CAPABLE dialogue in the world data (data_spawn.gml:577-579),
	        // so it is identical for every seed and showed a fixed denominator like
	        // "0/38" that had nothing to do with this run. f.dm_rando[Rando_Hint_Count]
	        // is the real per-seed number (Rando_generate_hints.gml:208-209, +1 for the
	        // Zelda hint) and is what g_Room_Start.gml:1654 iterates.
	        // Same fix already applied to the web tracker; the two disagreed until now.
	        var _htotal  = val(f.dm_rando[?STR_Rando+STR_Hint+STR_Count], 0);
	        TrackerWin_put(_dc, _MX, _y,
	            "HINTS: "+string(_hfound)+"/"+string(_htotal)+" found",
	            C_GRAY);
	        _y += _ROW;

	        // ── Hint text replay (show each found hint's dialogue) ────────────
	        var _hi, _hnum_, _htxt1, _htxt2, _hitem;
	        for (_hi=0; _hi<_hfound; _hi++)
	        {
	            _hnum_  = string_copy(_hnums, (_hi<<1)+1, 2);
	            _htxt1  = val(g.dm_RandoHintsRecorder[?STR_Hint+_hnum_+STR_Text+"01"], "");
	            _hitem  = val(g.dm_RandoHintsRecorder[?STR_Hint+_hnum_+STR_Item], "");
	            _htxt2  = val(g.dm_RandoHintsRecorder[?STR_Hint+_hnum_+STR_Text+"02"], "");

	            // Draw: "  <pre> [ITEM] <post>" truncated to 38 chars
	            var _hline = string_copy(_htxt1+_hitem+_htxt2, 1, 38);
	            TrackerWin_put(_dc, _MX+4, _y, _hline, C_ON);
	            _y += _ROW;
	        }
	    }
	}
	else
	{
	    // No save loaded — show placeholder
	    _y = 36;
	    TrackerWin_put(_dc, _MX, _y, "Load a save to see tracker.", C_GRAY);
	}

	external_call(global.TW_fn_ReleaseDC, _hwnd, _dc);



}
