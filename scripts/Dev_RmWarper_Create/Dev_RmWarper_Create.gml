/// @description  Dev_RmWarper_Create()
function Dev_RmWarper_Create() {


	var _i,_j,_k,_m, _idx, _a, _val;
	var _count;
	var _str, _mapkey;


	depth = DEPTH_SURFACE-1;




	SND_OPEN_APP            = get_audio_theme_track(dk_OpenGUI);
	//                                              // 
	SND_OPTION_CHANGE1      = get_audio_theme_track(dk_CursorSpellMenu);
	SND_OPTION_CHANGE2      = get_audio_theme_track(dk_CursorFileSelect);
	SND_OPTION_CHANGE_UP    = SND_OPTION_CHANGE1;
	SND_OPTION_CHANGE_DWN   = SND_OPTION_CHANGE1;
	// SND_OPTION_CHANGE_UP    = Audio.SND_WLK_WTR1A;
	// SND_OPTION_CHANGE_DWN   = Audio.SND_WLK_WTR1B;
	//                                              // 
	SND_OPTION_SELECT1      = get_audio_theme_track(dk_ItemDrop); // 
	SND_OPTION_CONFIRM      = get_audio_theme_track(STR_Sword+STR_Beam); // 
	// SND_OPTION_CONFIRM      = Audio.SND_GUI_OPEN; // 

	SND_OPTION_CANCEL       = get_audio_theme_track(dk_StrikeEnemy);
	// SND_OPTION_BACK         = Audio.SND_PC_GRUNT1;
	// SND_SHLD_HIT1, SND_WLK_WTR1A, SND_WLK_WTR1B, 
	// SND_BLOK_BRK1, SND_BRDG_CRBL, SND_SPWN_ITM1
	// SND_ELEV_MVE1. SND_TYPE_CHR1, SND_STAB_1A
	// SND_GUI_OPEN,  SND_PC_GRUNT1, SND_STRK_ENM1
	// SND_SWRD_BEAM


	DUR1    = $20;
	DUR2    = $08;



	Text_CHAR_W     =  8;
	TEXT_PAD_X      = ($01 * Text_CHAR_W) + $0;
	TEXT_PAD_Y      = ($01 * Text_CHAR_W) + $0;
	TEXT_DIST_Y     = ($01 * Text_CHAR_W) + $0; // vertical dist between 2 options
	TEXT_DIST_Y    += TEXT_PAD_Y;


	//                  // 
	              _a = 0;
	STATE_FIRST = _a;
	//                  // 
	STATE_IDLE  = _a++; // IDLE
	STATE_AREA  = _a++; // 
	STATE_RM1   = _a++; // 
	STATE_EXIT  = _a++; // 
	STATE_GOTO  = _a++;
	//                  // 
	STATE_LAST  = _a-1;
	STATE_COUNT = _a;
	state       = STATE_IDLE;
	//                  // 
	//                  // 

	timer = 0;


	area_idx   = 0;
	AREA_COUNT = ds_list_size(g.dl_AREA_NAME);

	dl_area = ds_list_create();
	for(_i=0; _i<AREA_COUNT; _i++) ds_list_add(dl_area,g.dl_AREA_NAME[|_i]);
	ds_list_add(dl_area,Area_Title);
	AREA_COUNT = ds_list_size(dl_area);


	rm_id      =  $00;
	RmID_COUNT = $100;


	ExitType_COUNT = $05;
	ExitID_COUNT   = ExitType_COUNT<<4;
	ExitID         = 0;
	exit_idx       = 0;

	dl_ExitID = ds_list_create();
	for(_i=ExitID_COUNT-1; _i>=0; _i--)
	{
	    _val  = (_i>>4)&$F; //   0,  1,  2,  3,  4
	    _val  = $08 <<_val; // $08,$10,$20,$40,$80
	    _val &= $F0;        // $00,$10,$20,$40,$80
	    _val |= _i&$F;
	    dl_ExitID[|_i] = _val;
	    // sdm("_i $"+hex_str(_i)+", _j $"+hex_str(_j)+", _idx $"+hex_str(_idx)+",  dl_ExitID[| _idx] $"+hex_str(dl_ExitID[| _idx]));
	}

	dl_Rm_ExitIDs = ds_list_create();


	// ============================================================
	// DEV SCREEN-CHECK / SWEEP TOOL  (added 2026-06-20)
	//   F9  = start/stop auto-sweep (warp + screenshot EVERY scene)
	//   F8  = stop sweep
	//   F10 = flag CURRENT scene as a problem -> opens click-to-note overlay
	//   Output saved under working_directory (printed to debug log on start).
	// ============================================================
	SWEEP_DIR           = "screen_check/";
	SWEEP_PROB_DIR      = "problems/";
	SWEEP_SETTLE_FRAMES = 12;            // low: the programmatic scene-check is timing-independent; just enough for spawns to populate
	SWEEP_WAITROOM      = 1;
	SWEEP_SETTLE        = 2;
	SWEEP_SHOOT         = 3;
	sweep_active        = false;
	sweep_substate      = 0;
	sweep_idx           = 0;
	sweep_settle        = 0;
	sweep_flag_timer    = 0;
	sweep_watchdog      = 0;
	SWEEP_WATCHDOG      = 360;           // frames stuck on one scene before we log + skip it
	sweep_list          = ds_list_create(); // full goto-names: AREA + rmHex + exitHex

	// Click-to-note state.
	sweep_note_active   = false;
	sweep_note_scene    = "";
	sweep_note_cat      = "";
	sweep_cats = [
	    "Palette / wrong colors",
	    "Sprite missing / garbled",
	    "Tile / layout corruption",
	    "Crash / freeze",
	    "Wrong / empty room",
	    "Other"
	];

	directory_create(SWEEP_DIR);
	directory_create(SWEEP_PROB_DIR);

	// Build a flat list of every valid scene's goto-name.
	sweep_build_list = function() {
	    ds_list_clear(sweep_list);
	    var _ai, _ri, _rm_count, _rm_id, _area, _rm_name, _exit;
	    var _AREA_N = ds_list_size(g.dl_AREA_NAME);
	    for(_ai=0; _ai<_AREA_N; _ai++) {
	        _area     = g.dl_AREA_NAME[|_ai];
	        _rm_count = val(g.dm_rm[?_area+STR_Rm+STR_Count]);
	        for(_ri=1; _ri<=_rm_count; _ri++) {
	            _rm_id = val(g.dm_rm[?_area+STR_Rm+hex_str(_ri)+STR_ID], -1);
	            if (_rm_id < 0) continue;
	            _rm_name = _area + hex_str(_rm_id);
	            Dev_RmWarper_update_1a(_rm_name); // fills dl_Rm_ExitIDs
	            if (ds_list_size(dl_Rm_ExitIDs) <= 0) continue;
	            _exit = dl_Rm_ExitIDs[|0];
	            ds_list_add(sweep_list, _rm_name + hex_str(_exit));
	        }
	    }
	    return ds_list_size(sweep_list);
	}

	// Warp to a goto-name (AREA + rmHex + exitHex). Async room change.
	sweep_warp_to = function(_name) {
	    show_debug_message("[SWEEP] warp -> "+_name+"  ("+string(sweep_idx+1)+"/"+string(ds_list_size(sweep_list))+")");
	    var _f = file_text_open_append(SWEEP_DIR+"_progress.txt");
	    file_text_write_string(_f, "try "+_name); file_text_writeln(_f); file_text_close(_f);
	    g.exit_leave = Exit_construct(EXIT_NAME_GAME_START);
	    with(g.exit_leave) {
	        goToExitName = _name;
	        goToExitNum  = str_hex(string_copy(goToExitName, RmName_LEN-1, 2));
	        goToRoom     = string_copy(goToExitName, 1, RmName_LEN);
	    }
	}

	// F10: snapshot the current scene + open the click-to-note overlay.
	sweep_flag = function() {
	    sweep_note_scene  = g.rm_name;
	    screen_save(SWEEP_PROB_DIR + sweep_note_scene + ".png");
	    sweep_note_cat    = "";
	    keyboard_string   = "";
	    sweep_note_active = true;
	    show_debug_message("[SWEEP] flag (note mode): "+sweep_note_scene);
	}

	// ENTER: write "scene | tag | note" to the problem log, close the overlay.
	sweep_note_commit = function() {
	    var _line = sweep_note_scene + "  |  " + sweep_note_cat + "  |  " + string(keyboard_string);
	    var _f = file_text_open_append(SWEEP_PROB_DIR+"problems.txt");
	    file_text_write_string(_f, _line); file_text_writeln(_f); file_text_close(_f);
	    sweep_note_active = false;
	    sweep_flag_timer  = 90;
	    show_debug_message("[SWEEP] saved problem: "+_line);
	}

	sweep_start = function() {
	    var _n = sweep_build_list();
	    show_debug_message("[SWEEP] start. "+string(_n)+" scenes. saving under: "+working_directory+SWEEP_DIR);
	    if (_n <= 0) { sweep_active = false; return; }
	    sweep_idx      = 0;
	    sweep_watchdog = 0;
	    sweep_active   = true;
	    sweep_substate = SWEEP_WAITROOM;
	    sweep_warp_to(sweep_list[|0]);
	}

	// Advance to the next scene (or finish). _tag != "" logs the current scene to crashes.txt first.
	sweep_advance = function(_tag) {
	    if (_tag != "") {
	        var _f = file_text_open_append(SWEEP_DIR+"crashes.txt");
	        file_text_write_string(_f, _tag+"  "+sweep_list[|sweep_idx]); file_text_writeln(_f); file_text_close(_f);
	    }
	    sweep_idx++;
	    sweep_watchdog = 0;
	    if (sweep_idx >= ds_list_size(sweep_list)) { sweep_stop(); return; }
	    sweep_substate = SWEEP_WAITROOM;
	    sweep_warp_to(sweep_list[|sweep_idx]);
	}

	// Programmatic per-scene load check: did the content that SHOULD load actually load?
	// Writes one line per scene to scene_report.txt. Timing-independent (no render needed).
	sweep_scene_check = function() {
	    var _s    = g.rm_name;
	    var _pc   = instance_exists(global.pc) ? 1 : 0;
	    var _prio = val(g.dm_spawn[?get_spawn_datakey(g.rm_name, STR_PRIO, -1)]);
	    var _prxm = val(g.dm_spawn[?get_spawn_datakey(g.rm_name, STR_PRXM, -1)]);
	    var _gob  = instance_number(GameObject); // actual game objects alive (all GO descendants)
	    var _hud  = instance_number(HUD);
	    var _flag = "";
	    if (!_pc)                  _flag += "NO_PC ";
	    if (_prio > 0 && _gob <= 0) _flag += "NO_GOB ";   // scene expects PRIO spawns but none exist
	    if (_hud <= 0)             _flag += "NO_HUD ";
	    var _line = _s
	        + "  pc="      + string(_pc)
	        + "  prioExp=" + string(_prio)
	        + "  prxmExp=" + string(_prxm)
	        + "  gob="     + string(_gob)
	        + "  hud="     + string(_hud);
	    if (_flag != "") _line += "   <<< " + _flag;
	    var _f = file_text_open_append(SWEEP_DIR + "scene_report.txt");
	    file_text_write_string(_f, _line); file_text_writeln(_f); file_text_close(_f);
	}

	sweep_stop = function() {
	    sweep_active   = false;
	    sweep_substate = 0;
	    show_debug_message("[SWEEP] stopped at "+string(sweep_idx)+"/"+string(ds_list_size(sweep_list)));
	    // Unattended run: mark done + quit so the Igor process returns.
	    if (variable_global_exists("autosweep") && global.autosweep) {
	        var _f = file_text_open_append(SWEEP_DIR+"_DONE.txt");
	        file_text_write_string(_f, "DONE "+string(sweep_idx)+"/"+string(ds_list_size(sweep_list))); file_text_writeln(_f); file_text_close(_f);
	        game_end();
	    }
	}







	Text_DrawArea_X         = viewW()>>2;
	// Text_DrawArea_X         = round(viewW() * .25);
	Text_DrawArea_X         = (Text_DrawArea_X>>3)<<3; // round down to 8



	AreaID_DrawArea_W       = AreaID_LEN * Text_CHAR_W;
	AreaID_DrawArea_H       = (TEXT_DIST_Y * AREA_COUNT) - TEXT_PAD_Y;
	AreaID_DrawArea_H_      = AreaID_DrawArea_H>>1;
	AreaID_DrawArea_X       = Text_DrawArea_X;
	AreaID_DrawArea_Y       = viewH_() - AreaID_DrawArea_H_;



	RmID_DrawArea_W         = $02 * Text_CHAR_W;
	RmID_DrawArea_H         = (TEXT_DIST_Y * RmID_COUNT) - TEXT_PAD_Y;
	RmID_DrawArea_H_        = RmID_DrawArea_H>>1;
	RmID_DrawArea_X         = AreaID_DrawArea_X + AreaID_DrawArea_W + TEXT_PAD_X;
	RmID_DrawArea_Y         = viewH_() - RmID_DrawArea_H_;



	ExitID_DrawArea_W       = $02 * Text_CHAR_W;
	ExitID_DrawArea_H       = (TEXT_DIST_Y * ExitID_COUNT) - TEXT_PAD_Y;
	ExitID_DrawArea_H_      = ExitID_DrawArea_H>>1;
	ExitID_DrawArea_X       = RmID_DrawArea_X + RmID_DrawArea_W + TEXT_PAD_X;
	ExitID_DrawArea_Y       = viewH_() - ExitID_DrawArea_H_;



	Text_DrawArea_W         = AreaID_DrawArea_W + TEXT_PAD_X;
	Text_DrawArea_W        += RmID_DrawArea_W   + TEXT_PAD_X;
	Text_DrawArea_W        += ExitID_DrawArea_W;



	TEXT_DRAWAREA_PAD_X     = $10<<3;
	TEXT_DRAWAREA_PAD_Y     = $04<<3;







	// ExitName:  GO-TO exit name. Constantly displays.
	ExitName_goto   = REEN_DEFAULT;
	ExitName_CLM    = $02;
	ExitName_ROW    = $03;

	Area_CLM    = TEXT_DRAWAREA_PAD_X>>3;
	Area_ROW    = TEXT_DRAWAREA_PAD_Y>>3;

	Rm_CLM      = Area_CLM + AreaID_LEN + (TEXT_PAD_X>>3);

	Exit_CLM    = Rm_CLM + $02 + (TEXT_PAD_X>>3);





	/*
	dm_DATA = ds_map_create();
	for(_i=0; _i<AREA_COUNT; _i++) // Each area
	{
	    _mapkey  = g.dl_AREA_NAME[|_i];
    
	    for(_j=0; _j<RmID_COUNT; _j++) // Each rm of this area
	    {
	        _mapkey += hex_str(_j);
        
	        // g.dm_rm_data[? _RM_NAME + STR_rm_num]
	        if(!defined(g.dm_rm_data[? _mapkey + STR_rm_num]))
	        {   continue;  } // rm does NOT exist
        
	        ds_map_add(dm_DATA, _mapkey, 1); // Indicate rm exists
        
	        for(_k=0; _k<ExitType_COUNT; _k++) // Each possible exit type
	        {
	            for(_m=0; _m<$10; _m++) // Each possible exit of this exit type
	            {
	                _mapkey  = g.dl_AREA_NAME[|_i];
	                _mapkey += hex_str(_j);
                
	                _val  = $08<<_k;
	                _val &= $F0;
	                _val |= _m;
	                _mapkey += hex_str(_val);
                
	                // g.dm_rm_data[? _exit_name + STR_Num]
	                if(!defined(g.dm_rm_data[? _mapkey + STR_Num]))
	                {   break;  } // _m. Exit does NOT exist
                
                
	                ds_map_add(dm_DATA, _mapkey, 1); // Indicate exit exists
	            }
	        }
	    }
	}
	*/











}
