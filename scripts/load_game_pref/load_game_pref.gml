/// @description  load_game_pref()
function load_game_pref() {


	var _val;


	var _FILE_NAME = UserPrefFileName;
	//var _FILE_NAME = string_letters(dk_UserPreferences)+"01"+".txt";
	//var _FILE_NAME = STR_Game+STR_Preferences+"01"+".txt";

	// Vanilla "Start With Reflect" new-game option. DEFAULT OFF so vanilla is unchanged.
	// Set here (before the first-run save below) so save_game_pref() always has it defined.
	global.start_with_reflect = false;

	if(!file_exists(_FILE_NAME)) save_game_pref();




	// --------------------------------------------------
	var _FILE    = file_text_open_read(working_directory+_FILE_NAME);
	var _ENCODED = file_text_read_string(_FILE);
	               file_text_close(_FILE);
	var _dm_FILE_DATA = json_decode(_ENCODED);
	// --------------------------------------------------


	if (_dm_FILE_DATA==-1) // `json_decode` returns -1 if it fails
	{
	    show_debug_message("");
	    show_debug_message("!!!! WARNING! load_game_pref(). `_dm_file_data` failed to get data from '"+_FILE_NAME+"' !!!!");
	    show_debug_message("");
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}




	// --------------------------------------------------
	g.WindowScale_scale = val(_dm_FILE_DATA[?STR_Window+STR_Scale], g.WindowScale_scale);
	window_set_scale(window_get_scale());

	var _XL = g.window_center_x - ((viewW()*g.WindowScale_scale)>>1);
	var _YT = g.window_center_y - ((viewH()*g.WindowScale_scale)>>1);
	window_set_position_(_XL,_YT);

	window_set_fullscreen(val(_dm_FILE_DATA[?STR_Fullscreen]));




	// --------------------------------------------------
	_val = _dm_FILE_DATA[?f.SDNAME_volume_sound];
	if(!is_undefined(_val))
	{
	    Audio.snd_vol = _val;
	    audio_group_set_gain(audiogroup_snd, Audio.snd_vol/10, 0);
	}

	_val = _dm_FILE_DATA[?f.SDNAME_volume_music];
	if(!is_undefined(_val))
	{
	    Audio.mus_vol = _val;
	    audio_group_set_gain(audiogroup_mus, Audio.mus_vol/10, 0);
	}


	_val = _dm_FILE_DATA[?STR_Music+STR_Set];
	if(!is_undefined(_val)) Audio.audio_set = string(_val);

	_val = _dm_FILE_DATA[?STR_Audio+STR_Random+STR_Custom];
	if(!is_undefined(_val)) Audio.dm_random_custom = json_decode(_val);



	_val = _dm_FILE_DATA[?STR_Input+STR_Preferences];
	if(!is_undefined(_val))
	{
	    var _dm = json_decode(_val);
	    ds_map_copy(Input.dm_UserInputConfig, _dm);
	    ds_map_destroy(_dm); _dm=undefined;
	}

	// Hydrate live keyboard bindings from the loaded config. val() defaults mean old save
	// files (no keyboard_* keys) keep the original D/A/S/W controls. Save side needs no
	// change — dm_UserInputConfig is json-encoded wholesale by save_game_pref.
	with(Input)
	{
	    Key_right  = val(dm_UserInputConfig[?"keyboard_right"],      Key_right_DEFAULT);
	    Key_right_alt  = val(dm_UserInputConfig[?"keyboard_right_alt"],  Key_right_alt_DEFAULT);
	    Key_left   = val(dm_UserInputConfig[?"keyboard_left"],       Key_left_DEFAULT);
	    Key_left_alt   = val(dm_UserInputConfig[?"keyboard_left_alt"],   Key_left_alt_DEFAULT);
	    Key_down   = val(dm_UserInputConfig[?"keyboard_down"],       Key_down_DEFAULT);
	    Key_down_alt   = val(dm_UserInputConfig[?"keyboard_down_alt"],   Key_down_alt_DEFAULT);
	    Key_up     = val(dm_UserInputConfig[?"keyboard_up"],         Key_up_DEFAULT);
	    Key_up_alt     = val(dm_UserInputConfig[?"keyboard_up_alt"],     Key_up_alt_DEFAULT);
	    Key_pause  = val(dm_UserInputConfig[?"keyboard_pause"],      Key_pause_DEFAULT);
	    Key_pause_alt  = val(dm_UserInputConfig[?"keyboard_pause_alt"],  Key_pause_alt_DEFAULT);
	    Key_magic  = val(dm_UserInputConfig[?"keyboard_magic"],      Key_magic_DEFAULT);
	    Key_magic_alt  = val(dm_UserInputConfig[?"keyboard_magic_alt"],  Key_magic_alt_DEFAULT);
	    Key_attack = val(dm_UserInputConfig[?"keyboard_attack"],     Key_attack_DEFAULT);
	    Key_attack_alt = val(dm_UserInputConfig[?"keyboard_attack_alt"], Key_attack_alt_DEFAULT);
	    Key_jump   = val(dm_UserInputConfig[?"keyboard_jump"],       Key_jump_DEFAULT);
	    Key_jump_alt   = val(dm_UserInputConfig[?"keyboard_jump_alt"],   Key_jump_alt_DEFAULT);
	    Key_spell_next = val(dm_UserInputConfig[?"keyboard_spell_next"],     Key_spell_next_DEFAULT);
	    Key_spell_next_alt = val(dm_UserInputConfig[?"keyboard_spell_next_alt"], Key_spell_next_alt_DEFAULT);
	    Key_spell_prev = val(dm_UserInputConfig[?"keyboard_spell_prev"],     Key_spell_prev_DEFAULT);
	    Key_spell_prev_alt = val(dm_UserInputConfig[?"keyboard_spell_prev_alt"], Key_spell_prev_alt_DEFAULT);
	    Key_tracker_toggle     = val(dm_UserInputConfig[?"keyboard_tracker_toggle"],     Key_tracker_toggle_DEFAULT);
	    Key_tracker_toggle_alt = val(dm_UserInputConfig[?"keyboard_tracker_toggle_alt"], Key_tracker_toggle_alt_DEFAULT);
	    Key_jukebox_toggle     = val(dm_UserInputConfig[?"keyboard_jukebox_toggle"],     Key_jukebox_toggle_DEFAULT);
	    Key_jukebox_toggle_alt = val(dm_UserInputConfig[?"keyboard_jukebox_toggle_alt"], Key_jukebox_toggle_alt_DEFAULT);
	    Key_jukebox_prev       = val(dm_UserInputConfig[?"keyboard_jukebox_prev"],       Key_jukebox_prev_DEFAULT);
	    Key_jukebox_prev_alt   = val(dm_UserInputConfig[?"keyboard_jukebox_prev_alt"],   Key_jukebox_prev_alt_DEFAULT);
	    Key_jukebox_next       = val(dm_UserInputConfig[?"keyboard_jukebox_next"],       Key_jukebox_next_DEFAULT);
	    Key_jukebox_next_alt   = val(dm_UserInputConfig[?"keyboard_jukebox_next_alt"],   Key_jukebox_next_alt_DEFAULT);
	    Key_jukebox_assign     = val(dm_UserInputConfig[?"keyboard_jukebox_assign"],     Key_jukebox_assign_DEFAULT);
	    Key_jukebox_assign_alt = val(dm_UserInputConfig[?"keyboard_jukebox_assign_alt"], Key_jukebox_assign_alt_DEFAULT);
	}



	// --------------------------------------------------
	_val = _dm_FILE_DATA[?STR_Background+STR_Flashing];
	if(!is_undefined(_val)) p.BackgroundFlash_setting = _val;

	_val = _dm_FILE_DATA[?STR_Screen+STR_Shake];
	if(!is_undefined(_val)) g.ScreenShake_user_pref = _val;

	_val = _dm_FILE_DATA[?STR_Dialogue+STR_Speed];
	if(!is_undefined(_val)) g.mod_DLG_SPEED = _val;

	_val = _dm_FILE_DATA[?STR_Game+STR_Font];
	if(!is_undefined(_val)) global.game_font_idx = _val;

	_val = _dm_FILE_DATA[?STR_Indicate+STR_Spell+STR_Active];
	if(!is_undefined(_val)) g.mod_IndicateSpellActive = _val;

	_val = _dm_FILE_DATA[?STR_Torch+STR_Lighting];
	if(!is_undefined(_val)) g.torch_lighting_method = _val;

	_val = _dm_FILE_DATA[?STR_HUD+STR_Type];
	if(!is_undefined(_val)) global.HUD_state = _val;

	_val = _dm_FILE_DATA[?STR_Quest+STR_Timer+"_Show"];
	if(!is_undefined(_val)) global.QuestTimer_show = _val;

	_val = _dm_FILE_DATA[?STR_Frenzy+STR_Stab];
	if(!is_undefined(_val)) g.mod_StabFrenzy = _val;

	_val = _dm_FILE_DATA[?STR_Cucco+STR_Spell+"02"+STR_Preference];
	if(!is_undefined(_val)) g.CuccoSpell2_Option = _val>0;

	_val = _dm_FILE_DATA[?STR_Rando+STR_Palette];
	if(!is_undefined(_val)) g.RandoPalette_state = _val;

	_val = _dm_FILE_DATA[?STR_Rando+STR_Enemy];
	if(!is_undefined(_val)) global.EnemyRando_enabled = _val;

	_val = _dm_FILE_DATA[?STR_Rando+STR_Overworld+STR_TSRC];
	if(!is_undefined(_val)) global.can_rando_ow_tsrc = _val;

	_val = _dm_FILE_DATA[?STR_Rando+STR_Scene];
	if(!is_undefined(_val)) global.SceneRando_enabled = _val;

	_val = _dm_FILE_DATA[?STR_Rando+STR_Hint];
	if(!is_undefined(_val)) global.RandoHints_enabled = _val;

	_val = _dm_FILE_DATA[?STR_Rando+STR_Dungeon+STR_Tileset];
	if(!is_undefined(_val)) global.RandoDungeonTilesets_enabled = _val;

	_val = _dm_FILE_DATA[?STR_Halloween+"01"];
	if(!is_undefined(_val)) global.Halloween1_enabled = _val;

	_val = _dm_FILE_DATA[?"LowHPBeepDisabled"];
	if(!is_undefined(_val)) global.LowHPBeep_disabled = _val;

	_val = _dm_FILE_DATA[?"StartWithReflect"];
	if(!is_undefined(_val)) global.start_with_reflect = _val;

	_val = _dm_FILE_DATA[?"Christmas01"];
	if(!is_undefined(_val)) global.Christmas_enabled = _val;

	_val = _dm_FILE_DATA[?STR_Map+STR_Show+STR_Key];
	if(!is_undefined(_val)) g.RandoKeys_MAP_items_show_keys = _val;

	_val = _dm_FILE_DATA[?STR_Overworld+STR_Mark+STR_Acquired];
	if(!is_undefined(_val)) global.MarkItemLocations_state = _val;

	_val = _dm_FILE_DATA[?STR_Overworld+STR_Mark+STR_Hidden+STR_Exit];
	if(!is_undefined(_val)) g.HiddenExitIndicator_enabled = _val;


	_val = _dm_FILE_DATA[?STR_PC+STR_Sprite+STR_Set];
	if(!is_undefined(_val)) global.pc.dm_skins[?STR_Current+STR_Idx] = clamp(_val, 0,val(global.pc.dm_skins[?STR_Set+STR_Count])-1);



	// Same trap as the two overlays below: every dev hotkey sets DevTools_state=true
	// and it persists, so it must not be restored on a locked-down launch either.
	_val = _dm_FILE_DATA[?"_DevTools"     +STR_State];
	if (dev_avail()) { if(!is_undefined(_val)) g.DevTools_state = _val; }
	else             { g.DevTools_state = false; }

	_val = _dm_FILE_DATA[?"_DoubleJump"   +STR_State];
	if(!is_undefined(_val)) g.DoubleJump_state = _val;

	// DEV OVERLAY STATE IS PERSISTED, so gating the hotkey alone is a trap: toggle it
	// on, lose dev access, and it is stuck on FOREVER across restarts with no way to
	// clear it. That happened for real 2026-07-27 -- the owner hit U before the gate
	// went in and could not turn it back off afterwards.
	//
	// Both of these were `if (DEV)`, i.e. always true, so a saved "on" was always
	// restored. dev_avail() makes them SELF-HEALING: a locked-down launch forces the
	// overlay off regardless of what the prefs file says, while the saved value is
	// left intact so it comes back when dev is unlocked again.
	var _dev_ok = dev_avail();

	_val = _dm_FILE_DATA[?"_DevDash"      +STR_State];
	if (_dev_ok) { if(!is_undefined(_val)) g.DevDash_state = _val; }
	else         { g.DevDash_state = false; }

	_val = _dm_FILE_DATA[?"_Debug_Overlay"+STR_State];
	if (_dev_ok)
	{
	    if(!is_undefined(_val))
	    {
	        g.can_show_debug_overlay = _val;
	        show_debug_overlay(g.can_show_debug_overlay);
	    }
	}
	else
	{
	    g.can_show_debug_overlay = false;
	    show_debug_overlay(false);
	}

	_val = _dm_FILE_DATA[?"_All_BGR_Black"+STR_State];
	if(!is_undefined(_val)) g.all_bg_black_only = _val;

	_val = _dm_FILE_DATA[?STR_Frame+STR_Count+"_App"            +"_can_draw"];
	if(!is_undefined(_val)) global.App_frame_count_can_draw = _val;

	_val = _dm_FILE_DATA[?STR_Frame+STR_Count+"_App"+"_Unpaused"+"_can_draw"];
	if(!is_undefined(_val)) global.App_frame_count_unpaused_can_draw = _val;

	_val = _dm_FILE_DATA[?STR_Frame+STR_Count+"_Room"           +"_can_draw"];
	if(!is_undefined(_val)) global.Room_frame_count_can_draw = _val;


	// Screen-scaling DISPLAY mode. val() default keeps current value for old save files.
	global.DisplayMode = val(_dm_FILE_DATA[?"_Display_Mode"], global.DisplayMode);




	ds_map_destroy(_dm_FILE_DATA); _dm_FILE_DATA=undefined;







}
