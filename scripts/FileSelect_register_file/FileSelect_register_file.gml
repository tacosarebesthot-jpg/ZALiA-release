/// @description  FileSelect_register_file(file num)
/// @param file num
function FileSelect_register_file(argument0) {


	var _FILE_NUM  = argument0;
	var _FILE_NAME = f.dl_file_names[|_FILE_NUM-1];


	var _i,_j, _val;
	var _datakey, _file, _data_encoded;

	var _SAVE_NAME = f.dl_save_names[|_FILE_NUM-1];


	var _dm_save_file_settings_ENCODED = FileSelect_Rando_get_rando_settings();
	var _dm_save_file_settings = json_decode(_dm_save_file_settings_ENCODED);
	if (_dm_save_file_settings==-1) _dm_save_file_settings = ds_map_create();
	ds_map_copy(global.dm_save_file_settings, _dm_save_file_settings);


	var _RANDO_ON = false;
	if (val(_dm_save_file_settings[?STR_Randomize+STR_Palette])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Dungeon+STR_Tileset])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Item+STR_Locations])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_PBAG+STR_Locations])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Skill+STR_Locations])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Spell+STR_Locations])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Spell+STR_Cost])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_Method])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_Spawner])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_ENIGMA])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_HP])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_Damage])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Dungeon+STR_Room])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Dungeon+STR_Locations])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Dungeon+STR_Boss])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Town+STR_Locations])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_Level+STR_Cost])
	||  val(_dm_save_file_settings[?STR_Randomize+STR_XP]) )
	{
	    _RANDO_ON = true;
	}
	//var _RANDO_ON = FileSelect_Rando_is_on(-1);


	_val = 1;
	if (_RANDO_ON)
	{
	    _val = dg_RandoOTHER_Options[#RandoOTHER_MAIN_cursor_QUEST,2];
	}
	else
	{
	    if (string_pos("ZELDA",_SAVE_NAME) 
	    &&  string_count(" ",_SAVE_NAME)==string_length(_SAVE_NAME)-5 )
	    {
	        _val = 2;
	    }
	}

	var _QUEST_NUM = _val;


	init_new_save_file(_FILE_NUM, _QUEST_NUM);


	f.cont_run_town_num = 0;
	set_saved_value(_FILE_NUM, STR_Save+STR_Town+STR_Num, f.cont_run_town_num);


	set_saved_value(_FILE_NUM, get_file_seed_dk(_FILE_NUM,1), FileSelect_get_file_seed(_FILE_NUM,1));
	set_saved_value(_FILE_NUM, get_file_seed_dk(_FILE_NUM,2), FileSelect_get_file_seed(_FILE_NUM,2));




	//=====================================================================
	var _dm_save_file = ds_map_create();
	if (file_exists(_FILE_NAME))
	{
	    _file         = file_text_open_read(working_directory+_FILE_NAME);
	    _data_encoded = file_text_read_string(_file);
	                    file_text_close(      _file);
	    _dm_save_file = json_decode(_data_encoded);
	    if (_dm_save_file==-1) _dm_save_file = ds_map_create();
	}


	//if(!is_undefined(_dm_save_file[?STR_Rando+STR_Active])) ds_map_delete(_dm_save_file,STR_Rando+STR_Active);

	_dm_save_file[?STR_Save+STR_File+STR_Settings] = _dm_save_file_settings_ENCODED;


	if (_RANDO_ON)
	{
	    _dm_save_file[?dk_CanUseStartWithSelections] = true;
    
	    _dm_save_file[?f.SDNAME_questNum]  = _QUEST_NUM;
    
	    _dm_save_file[?f.SDNAME_level_atk] = dg_RandoOTHER_Options[#RandoOTHER_MAIN_cursor_ATTACK,2];
	    _dm_save_file[?f.SDNAME_level_mag] = dg_RandoOTHER_Options[#RandoOTHER_MAIN_cursor_MAGIC, 2];
	    _dm_save_file[?f.SDNAME_level_lif] = dg_RandoOTHER_Options[#RandoOTHER_MAIN_cursor_LIFE,  2];
    
    
	    // Start-With Main Items, Quest Items -----------------------------------------
	    _dm_save_file[?f.SDNAME_items] |= val(_dm_save_file_settings[?STR_File+STR_Start+STR_Items]);
    
    
	    // Start-With Containers ------------------------------------------------------
	    var _START_CONT_HP = dg_RandoOTHER_ITEMS[#RandoOTHER_ITEMS_item_cursor_HEART,2];
	    _val="";
	    for(_i=1; _i<=_START_CONT_HP; _i++)
	    {
	        for(_j=1; _j<=f.CONT_PIECE_PER_HP; _j++)
	        {
	            _val += hex_str(_i)+hex_str(_j);
	        }
	    }
	    _dm_save_file[?f.SDNAME_cont_pieces_hp] = _val;
    
    
	    var _START_CONT_MP = dg_RandoOTHER_ITEMS[#RandoOTHER_ITEMS_item_cursor_MAGIC,2];
	    _val="";
	    for(_i=1; _i<=_START_CONT_MP; _i++)
	    {
	        for(_j=1; _j<=f.CONT_PIECE_PER_MP; _j++)
	        {
	            _val += hex_str(_i)+hex_str(_j);
	        }
	    }
	    _dm_save_file[?f.SDNAME_cont_pieces_mp] = _val;
	     //sdm("_START_CONT_HP "+string(_START_CONT_HP)+", "+"_START_CONT_MP "+string(_START_CONT_MP));
    
    
	     // Start-With Spells -----------------------------------------------------------
	    _datakey = f.SDNAME_spells;
	    var _START_SPELLS = val(_dm_save_file[?_datakey]);
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_PROTECT,2]) _START_SPELLS |= SPL_PRTC;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_JUMP,   2]) _START_SPELLS |= SPL_JUMP;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_HEAL,   2]) _START_SPELLS |= SPL_LIFE;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_FAIRY,  2]) _START_SPELLS |= SPL_FARY;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_FIRE,   2]) _START_SPELLS |= SPL_FIRE;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_REFLECT,2]) _START_SPELLS |= SPL_RFLC;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_ENIGMA, 2]) _START_SPELLS |= SPL_SPEL;
	    if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_THUNDER,2]) _START_SPELLS |= SPL_THUN;
	    //if (dg_RandoOTHER_SPELLS[#RandoOTHER_SPELLS_cursor_SUMMON, 2]) _START_SPELLS |= SPL_SUMM;

	    // START REFLECT (the RandoOTHER MAIN row, backed by the persistent
	    // global.start_with_reflect). MOVED IN HERE 2026-07-27 -- it used to live in an
	    // `else` branch that fired on NON-rando files, so once the toggle had ever been
	    // set every plain vanilla new game silently started with Reflect.
	    //
	    // The option still WORKS, it is just gated on rando now: rando on + toggle on
	    // grants it, rando off never does. The preference stays persistent so the choice
	    // survives between rando runs, which is the point of it.
	    if (global.start_with_reflect) _START_SPELLS |= SPL_RFLC;

	    _dm_save_file[?_datakey] = _START_SPELLS;
    
    
	    if (dg_RandoOTHER_SKILLS[#RandoOTHER_SKILLS_cursor_STABDOWN,2]) _dm_save_file[?f.SDNAME_skills] = val(_dm_save_file[?f.SDNAME_skills]) | SKILL_THD;
	    if (dg_RandoOTHER_SKILLS[#RandoOTHER_SKILLS_cursor_STABUP,  2]) _dm_save_file[?f.SDNAME_skills] = val(_dm_save_file[?f.SDNAME_skills]) | SKILL_THU;
    
    
    
    
	    // Start-With 1-Up Dolls -------------------------------------------------------
	    var _DOLL_COUNT = dg_RandoOTHER_ITEMS[#RandoOTHER_ITEMS_item_cursor_DOLLS,2];
	        _DOLL_COUNT = clamp(_DOLL_COUNT, 0,val(f.dm_1up_doll[?STR_Count])-(_QUEST_NUM==2));
	        //_DOLL_COUNT = clamp(_DOLL_COUNT, 0,g.LifeDoll_MAX-(_QUEST_NUM==2));
	    if (_DOLL_COUNT)
	    {
	        var _item_id;
	        for(_i=1; _i<=_DOLL_COUNT; _i++)
	        {
	            _item_id = f.dm_1up_doll[?hex_str(_i)+STR_Item+STR_ID];
	            if(!is_undefined(_item_id)) f.dm_1up_doll[?_item_id+STR_Acquired] = true;
	        }
        
	        _val = json_encode(f.dm_1up_doll);
	        _dm_save_file[?f.SDNAME_linkDolls] = _val;
	    }
	}
	// REMOVED 2026-07-27: a non-rando "start with Reflect" branch lived here, granting
	// SPL_RFLC to VANILLA new games whenever global.start_with_reflect was set.
	//
	// Why it had to go: that global is PERSISTENT (UserPreferences "StartWithReflect",
	// load_game_pref.gml:180). Once ever switched on it stayed on, so every plain
	// vanilla new game silently started with Reflect and nothing on the file-select
	// screen said so. Caught in the act 2026-07-27: a fresh non-rando file was written
	// spells=0 and re-saved as spells=32 seconds later.
	//
	// Start-with-spells belongs to the RANDOMIZER, and the rando branch above already
	// does it properly via dg_RandoOTHER_SPELLS[...cursor_REFLECT]. Owner's rule: rando
	// may turn these on, but it must not STICK once rando is off.
	//
	// The menu row itself is NOT removed and is NOT inert -- its check simply moved up
	// into the rando branch above, so the option still works whenever rando is on.




	_file = file_text_open_write(working_directory+_FILE_NAME);
	        file_text_write_string(_file, json_encode(_dm_save_file));
	        file_text_close(_file);
	//




	// Putting this outside of `if (_RANDO_ON)` so stuff like palette rando, dungeon tileset rando will still run
	with(instance_create(0,0,Rando))
	{
	    var _SEED = get_saved_value(_FILE_NUM, STR_File+STR_Seed+STR_Quest+hex_str(_QUEST_NUM), FileSelect_get_file_seed(_FILE_NUM,_QUEST_NUM));
	    Rando_randomize_file(_FILE_NUM, _QUEST_NUM, _SEED, _dm_save_file_settings_ENCODED);
	    instance_destroy();
	}




	// --------------------------------------------------------------------------
	if (file_exists(_FILE_NAME))
	{
	    _file      = file_text_open_read(working_directory+_FILE_NAME);
	    _file_data = file_text_read_string(_file);
	                 file_text_close(_file);
	    //
	    global.dm_save_file_data[?STR_Save+STR_File+hex_str(_FILE_NUM)+STR_Encoded] = _file_data;
	    var _dm_file = json_decode(_file_data);
	    if (_dm_file!=-1)
	    {
	        ds_map_copy(global.dm_save_file, _dm_file);
	        ds_map_destroy(_dm_file); _dm_file=undefined;
	    }
	}




	FileSelect_refresh_save_file_rando_info(_FILE_NUM);


	ds_map_destroy(_dm_save_file); _dm_save_file=undefined;
	ds_map_destroy(_dm_save_file_settings); _dm_save_file_settings=undefined;







}
