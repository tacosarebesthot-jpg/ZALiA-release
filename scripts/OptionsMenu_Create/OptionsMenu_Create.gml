/// @description  OptionsMenu_Create()
function OptionsMenu_Create() {

	var _START_TIME = 0;
	if (DEV)
	{
	    _START_TIME = current_time;
	    show_debug_message("");
	    show_debug_message("OptionsMenu_Create() START");
	}


	var _i,_j,_k, _a, _idx, _val, _count,_count0,_count1,_count2;
	var _x,_y, _w,_h;
	var _dk,_dk0,_dk1,_dk2,_dk3;
	var _first;
	var _text, _font, _len, _size;
	var _theme;


	global.OPTIONS_MENU = id;


	dm_options = ds_map_create();


	timer2 = 0;


	DURATION0 = $4; // input delay 1
	DURATION1 = $8; // input delay 2
	DURATION2 = $2; // input delay 3


	//RandoOptionsMenu_IS_LIVE      = false;
	//RandoOptionsMenu_is_available = false;
	can_play_boss_music_at_open_RandomCustom = false;


	FONT1 = global.dl_game_font[|global.game_font_idx];
	FONT2 = spr_Font2_1;
	FONT3 = spr_Font2_1;


	Info_PAD1   = $4;

	Info_FONT   = spr_Font3;
	//Info_FONT   = spr_Font2;
	//Info_FONT   = spr_Font2_1;
	Info_FONT_W = sprite_get_width( Info_FONT);
	Info_FONT_H = sprite_get_height(Info_FONT);

	Info_Divider_can_draw = false;
	Info_Divider_row      = 0;
	Info_Divider_yt       = 0;

	Info_xl = 0;
	Info_xr = 0;
	Info_yt = 0;


	ARROW_SPRITE   = spr_arrow_1b;
	ARROW_SPRITE_W = sprite_get_width( ARROW_SPRITE);
	ARROW_SPRITE_H = sprite_get_height(ARROW_SPRITE);


	MenuWindow_w  = 0;
	MenuWindow_h  = 0;
	MenuWindow_xl = 0;
	MenuWindow_xr = 0;
	MenuWindow_yt = 0;
	MenuWindow_yb = 0;


	TextArea1_xl = 0;
	TextArea1_xr = 0;
	TextArea2_xl = 0;
	TextArea2_xr = 0;


	Cursor_xl = 0;
	Cursor_SPRITE = spr_menu_bottle_icon;
	Cursor_W      = sprite_get_width( Cursor_SPRITE);
	Cursor_H      = sprite_get_height(Cursor_SPRITE);


	CONFIRM_SOUND1 = get_audio_theme_track(dk_ChooseChar);
	//CONFIRM_SOUND2 = get_audio_theme_track(dk_ItemDrop);
	BACK_SOUND1    = get_audio_theme_track(STR_Stab);
	//BACK_SOUND1    = get_audio_theme_track(dk_StrikeEnemy);
	CURSOR_SOUND1  = get_audio_theme_track(dk_CursorSpellMenu);


	PI_MENU1 = global.PI_GUI1;
	PI_MENU2 = global.PI_GUI3; // darker version of global.PI_GUI1
	PI_DARK0 = global.PI_GUI2;
	PI_DARK1 = add_pi_permut(global.PI_GUI2, "WBRGYKMC", "OptionsMenu dark text 1");
	PI_DARK2 = add_pi_permut(global.PI_GUI2, "RWBGMKYC", "OptionsMenu dark text 2");
	PI_DARK3 = add_pi_permut(global.PI_GUI2, "RBWGMKYC", "OptionsMenu dark text 3");


	PCSpriteWalk_DURATION = 4;
	PCSpriteWalk_timer    = PCSpriteWalk_DURATION;
	PCSpriteWalk_frame    = 0;


	OpenClose_Key_KEY = ord("O");
	OpenClose_Key_pressed = false;

	//Backout_BUTTON = 0;
	Backout_requested = false;

	start_button_pressed  = false;
	select_button_pressed = false;
	a_button_pressed      = false; // equivilent to NES-A and xbox-A
	b_button_pressed      = false; // equivilent to NES-B and xbox-B
	right_input_pressed   = false;
	left_input_pressed    = false;
	down_input_pressed    = false;
	up_input_pressed      = false;




	gui_state_backup = 0;




	_first=1;                _a=_first;
	//state_oc         = 0; // oc: Open Close
	sub_state_IDLE_CLOSED  = _a++;
	sub_state_OPENING1     = _a++;
	sub_state_OPENING2     = _a++;
	sub_state_OPENING_ANIM = _a++;
	sub_state_OPEN1        = _a++;
	sub_state_CLOSING1     = _a++;
	sub_state_CLOSING2     = _a++;
	sub_state_CLOSING_ANIM = _a++;
	sub_state_CLOSING3     = _a++;
	sub_state              = _first;




	_first=1;                  _a=_first;
	menu_state_MAIN          = _a++;
	menu_state_INPUT_CONFIG  = _a++;
	menu_state_DEV_TOOLS     = _a++;
	menu_state_AUDIO_CUSTOM  = _a++;
	menu_state_RANDO         = _a++;
	menu_state_OTHER         = _a++;
	menu_state_TWITCH        = _a++; // player-facing; the Twitch toggles used to be buried in DEV TOOLS -> TEST/CAPTURE
	menu_state_DISPLAY       = _a++;
	menu_state_OVERLAYS      = _a++; // DEV TOOLS sub-folder
	menu_state_CHEATS        = _a++; // DEV TOOLS sub-folder
	menu_state_COLOR         = _a++; // DEV TOOLS sub-folder
	menu_state_TEST_CAP      = _a++; // DEV TOOLS sub-folder
	menu_state_SWEEPS        = _a++; // DEV TOOLS sub-folder
	menu_state_MISC          = _a++; // DEV TOOLS sub-folder
	menu_state               = _first;








	// --------------------------------------------------------
	MainOptions_dg_H = 5;
	MainOptions_dg = ds_grid_create(0,MainOptions_dg_H);
	//                                                                          //
	MainOption_SND_VOL           = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "SOUND ";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT1;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "SOUND-FX VOLUME";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "ADJUSTS THE GAME'S SOUND-FX VOLUME";
	//                                                                          //
	MainOption_MUS_VOL           = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "MUSIC ";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT1;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "MUSIC VOLUME";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "ADJUSTS THE GAME'S MUSIC VOLUME";
	//                                                                          //
	MainOption_MUSIC_SET         = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "AUDIO SET";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = ": CYCLE THROUGH SETS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "PRESS RIGHT OR LEFT TO CYCLE THROUGH SETS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "PRESS RIGHT OR LEFT TO CYCLE THROUGH MUSIC SETS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CHOOSE MUSIC FROM THE ORIGINAL GAME, FROM OTHER GAMES, OR MUSIC MADE BY THE COMMUNITY";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "PRESS START ON RANDOM-CUSTOM TO PICK AND CHOOSE WHICH TRACKS WILL BE IN THE RANDOM POOL";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "PRESS START ON CUSTOM-RANDOM TO SPECIFY WHICH TRACKS WILL BE IN THE RANDOM POOL";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "ALTERNATE MUSICS FROM OTHER GAMES AND MADE BY THE COMMUNITY";
	//                                                                          //
	MainOption_PC_SPRITES        = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "PLAYER SKIN";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = ": CYCLE THROUGH PLAYER SKINS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "PRESS RIGHT OR LEFT TO CYCLE THROUGH PLAYER SKINS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CHOOSE A PLAYER SKIN FROM THE ORIGINAL, OR ONE MADE BY THE COMMUNITY";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "THESE ARE ONLY COSMETIC AND DO NOT AFFECT GAMEPLAY";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "THESE ARE ONLY COSMETIC AND DO NOT ALTER THE GAMEPLAY";
	//                                                                          //
	MainOption_INPUT_CONFIG      = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "EDIT CONTROLS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "CONTROLS";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "INPUT CONFIGURATION FOR CONTROLLERS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CHANGE WHICH CONTROLLER BUTTONS DO WHAT";
	//                                                                          //
	// CO-OP master toggle (promoted to MAIN 2026-06-28; was DEV TOOLS -> MISC -> CO-OP).
	// Player-facing ON/OFF row that flips the SAME global.coop_enabled. Runtime-only flag
	// (re-inits false in g_Create each launch) so no save_game_pref(), like the old MISC row.
	MainOption_CO_OP             = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "CO-OP";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "TWO-PLAYER CO-OP: A 2ND CONTROLLER FLIES A HELPER FAIRY";
	//                                                                          //
	// (FULLSCREEN + APP SCALE main rows were MOVED into the DISPLAY submenu on 2026-06-27;
	//  fullscreen toggle / window-scale cycle now live as the first two DISPLAY rows.)
	//                                                                          //
	// ---- COMPANION PAGES ----------------------------------------------------
	// TWITCH promoted to the MAIN menu 2026-07-26; converted from a submenu to a
	// LAUNCHER 2026-07-27. Everything it used to hold -- rewards on/off, connect,
	// cooldown, effect length, the command list -- now lives on the setup page, which
	// has a keyboard, a mouse and room to explain itself. A NES-style option list is a
	// bad place to type a channel name and a terrible place to read documentation.
	//
	// All three rows are the same shape: an action that opens a loopback page in the
	// player's own browser. Grouped together because they are one idea, not three.
	// ONE row, not three. TWITCH SETUP / TRACKER / JUKEBOX were separate launchers
	// for a day and it pushed CLOSE off the bottom -- this menu does not scroll, and
	// tightening the gaps made rows collide instead. They now open a hub page that
	// lists all three, which also has room to explain what each one is.
	MainOption_TWITCH            = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	// v2.1.4: opens the in-game TWITCH page again (it had no entry point since round 10).
	// The browser hub moved to that page's COMPANION PAGES row.
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "TWITCH OPTIONS";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CHAT JOKES, ROCKET LEAGUE, POINTS, CHECKPOINTS, CHAT SETUP, AND THE JUKEBOX + TRACKER PAGES.";
	//                                                                          //
	MainOption_DEV_TOOLS         = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "DEV TOOLS";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "VARIOUS DEVELOPMENT TOOLS: APP PERFORMANCE, HITBOXES, XY COORDS, ETC...";
	//                                                                          //
	// (AUTOMATED TEST main-menu row REMOVED 2026-06-28 -- its sweeps + test/capture
	//  tools now live under DEV TOOLS -> SWEEPS + TEST/CAPTURE sub-folders.)
	//                                                                          //
	MainOption_DISPLAY           = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "DISPLAY";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CHOOSE HOW THE GAME IMAGE IS SCALED TO YOUR SCREEN";
	//                                                                          //
	MainOption_OTHER             = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "OTHER";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "VARIOUS OTHER OPTIONS: DIALOGUE SPEED, BACKGROUND FLASH COLOR, ETC...";
	//                                                                          //
	MainOption_RANDO             = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "RANDO OPTIONS";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "VARIOUS RANDOMIZATION RELATED OPTIONS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "VARIOUS OPTIONS RELATED TO RANDOMIZATION";
	/*
	//                                                                          //
	MainOption_PAL_EDITOR        = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "OPEN PALETTE EDITOR";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "EDIT THIS ROOM'S COLORS";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "ALLOWS YOU TO EDIT THIS ROOM'S COLORS";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "OPEN A TOOL THAT ALLOWS YOU TO EDIT THIS ROOM'S COLORS";
	*/
	//                                                                          //
	MainOption_FORCE_GAMEOVER    = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "FORCE GAMEOVER";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "WARP TO THE CONTINUE-SAVE SCREEN";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "OPENS A MENU THAT ALLOWS YOU TO WARP TO THE CONTINUE-SAVE SCREEN";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "KNOW THAT WARPING TO CONTINUE-SAVE IS CONSIDERED A GAME OVER";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "NOTE: DOING THIS IS CONSIDERED A GAME OVER";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "-WARPING TO CONTINUE-SAVE IS CONSIDERED A GAME OVER-";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,3] = "NOTE THAT WARPING TO CONTINUE-SAVE IS CONSIDERED A GAME OVER";
	//                                                                          //
	MainOption_CLOSE             = ds_grid_width(MainOptions_dg);
	ds_grid_resize(MainOptions_dg, ds_grid_width(MainOptions_dg)+1,MainOptions_dg_H);
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,0] = "CLOSE";
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,1] = FONT2;
	MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CLOSE THE OPTIONS MENU";
	//MainOptions_dg[#ds_grid_width(MainOptions_dg)-1,2] = "CLOSE THE OPTIONS MENU AND RETURN TO THE GAME";
	//                                                                          //
	MainOption = 0;


	MainOption_COUNT = ds_grid_width(MainOptions_dg);


	_len = 1;
	for(_i=0; _i<MainOption_COUNT; _i++) _len = max(_len, string_length(MainOptions_dg[#_i,0]));
	TEXT_LENGTH1 = _len;
	TEXT_LENGTH2 = TEXT_LENGTH1-2;
	TEXT_LENGTH3 = TEXT_LENGTH1+6;








	// --------------------------------------------------------
	_first=1;                  _a=_first;
	InputConfigState_MAIN    = _a++;
	InputConfigState_EDITING = _a++;
	InputConfigState_CALIBRATE = _a++; // raw-input controller calibration wizard
	InputConfigState_KB_EDITING = _a++; // keyboard rebind: press a key to assign
	InputConfigState         = _first;

	// Controls menu sections (cycle with LEFT/RIGHT in MAIN). GAMEPLAY = the original
	// gamepad rebind list (default so the menu looks/acts as before); KEYBOARD = new
	// keyboard rebinding; DEBUG = read-only hotkey reference.
	InputSection_GAMEPLAY = 0;
	InputSection_KEYBOARD = 1;
	InputSection_DEBUG    = 2;
	InputSection_COUNT    = 3;
	InputSection_NAME     = ["GAMEPLAY","KEYBOARD","DEBUG"];
	InputSection          = InputSection_GAMEPLAY;
	KbEdit_clear          = true; // keyboard rebind: require a clean key release before capture


	_first=0;                   _a=_first;
	InputConfigOption_RIGHT   = _a++;
	InputConfigOption_LEFT    = _a++;
	InputConfigOption_DOWN    = _a++;
	InputConfigOption_UP      = _a++;
	InputConfigOption_MAGIC   = _a++; // NES SELECT
	InputConfigOption_PAUSE   = _a++; // NES START
	InputConfigOption_ATTACK  = _a++; // NES B
	InputConfigOption_JUMP    = _a++; // NES A
	InputConfigOption_SPELL_NEXT = _a++; // quick spell cycle: next
	InputConfigOption_SPELL_PREV = _a++; // quick spell cycle: prev
	InputConfigOption_JUKEBOX_NEXT = _a++; // jukebox: next track
	InputConfigOption_JUKEBOX_PREV = _a++; // jukebox: prev track
	InputConfigOption_CALIBRATE = _a++; // build a fresh SDL mapping for an unrecognized pad
	InputConfigOption_DEFAULT = _a++;
	InputConfigOption_BACK    = _a++;
	InputConfigOption         = _first;

	InputConfigOption_COUNT   = _a;


	// --------------------------------------------------------
	// Controller-calibration wizard state.
	// Each step captures one SDL output name from a raw button/axis/hat,
	// letting us build a mapping for a pad the SDL DB doesn't recognise.
	Calib_active      = false;
	Calib_step        = 0;
	Calib_bindings    = ""; // accumulates "a:b0,b:b1,..." as steps complete
	Calib_input_clear = true; // require a full release between captures
	Calib_msg         = "";
	Calib_dg = ds_grid_create(2,14); // [#0,step]=SDL name, [#1,step]=on-screen prompt
	Calib_dg[#0, 0]="a";             Calib_dg[#1, 0]="PRESS LOWER FACE BUTTON";   // south  (Xbox A / PS Cross)
	Calib_dg[#0, 1]="b";             Calib_dg[#1, 1]="PRESS RIGHT FACE BUTTON";   // east   (Xbox B / PS Circle)
	Calib_dg[#0, 2]="x";             Calib_dg[#1, 2]="PRESS LEFT FACE BUTTON";    // west   (Xbox X / PS Square)
	Calib_dg[#0, 3]="y";             Calib_dg[#1, 3]="PRESS UPPER FACE BUTTON";   // north  (Xbox Y / PS Triangle)
	Calib_dg[#0, 4]="dpup";          Calib_dg[#1, 4]="PRESS D-PAD UP";
	Calib_dg[#0, 5]="dpdown";        Calib_dg[#1, 5]="PRESS D-PAD DOWN";
	Calib_dg[#0, 6]="dpleft";        Calib_dg[#1, 6]="PRESS D-PAD LEFT";
	Calib_dg[#0, 7]="dpright";       Calib_dg[#1, 7]="PRESS D-PAD RIGHT";
	Calib_dg[#0, 8]="leftshoulder";  Calib_dg[#1, 8]="PRESS LEFT BUMPER";
	Calib_dg[#0, 9]="rightshoulder"; Calib_dg[#1, 9]="PRESS RIGHT BUMPER";
	Calib_dg[#0,10]="lefttrigger";   Calib_dg[#1,10]="PRESS LEFT TRIGGER";
	Calib_dg[#0,11]="righttrigger";  Calib_dg[#1,11]="PRESS RIGHT TRIGGER";
	Calib_dg[#0,12]="start";         Calib_dg[#1,12]="PRESS START";
	Calib_dg[#0,13]="back";          Calib_dg[#1,13]="PRESS SELECT / BACK";
	Calib_COUNT = 14;



	_font = FONT2;
	_size = sprite_get_width(_font);

	dg_InputConfigOptions = ds_grid_create(InputConfigOption_COUNT,8);
	//                                                                          //
	//ds_grid_resize(dg_InputConfigOptions, ds_grid_width(dg_InputConfigOptions)+1, ds_grid_height(dg_InputConfigOptions));
	                       _i=InputConfigOption_RIGHT;
	dg_InputConfigOptions[#_i,0] = "RIGHT";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_LEFT;
	dg_InputConfigOptions[#_i,0] = "LEFT";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_DOWN;
	dg_InputConfigOptions[#_i,0] = "DOWN";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_UP;
	dg_InputConfigOptions[#_i,0] = "UP";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_MAGIC;
	dg_InputConfigOptions[#_i,0] = "MAGIC";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_PAUSE;
	dg_InputConfigOptions[#_i,0] = "PAUSE";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_ATTACK;
	dg_InputConfigOptions[#_i,0] = "ATTACK";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_JUMP;
	dg_InputConfigOptions[#_i,0] = "JUMP";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_SPELL_NEXT;
	dg_InputConfigOptions[#_i,0] = "NEXT SPELL";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_SPELL_PREV;
	dg_InputConfigOptions[#_i,0] = "PREV SPELL";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_JUKEBOX_NEXT;
	dg_InputConfigOptions[#_i,0] = "JUKEBOX NEXT";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_JUKEBOX_PREV;
	dg_InputConfigOptions[#_i,0] = "JUKEBOX PREV";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_CALIBRATE;
	dg_InputConfigOptions[#_i,0] = "CALIBRATE NEW CONTROLLER";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_DEFAULT;
	dg_InputConfigOptions[#_i,0] = "SET DEFAULTS";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //
	                       _i=InputConfigOption_BACK;
	dg_InputConfigOptions[#_i,0] = "BACK";
	dg_InputConfigOptions[#_i,1] = _font;
	//                                                                          //


	// --- KEYBOARD section rows (same actions; no CALIBRATE) ---
	_first=0; _a=_first;
	KbOption_RIGHT   = _a++;
	KbOption_LEFT    = _a++;
	KbOption_DOWN    = _a++;
	KbOption_UP      = _a++;
	KbOption_MAGIC   = _a++;
	KbOption_PAUSE   = _a++;
	KbOption_ATTACK  = _a++;
	KbOption_JUMP    = _a++;
	KbOption_SPELL_NEXT = _a++;
	KbOption_SPELL_PREV = _a++;
	KbOption_TRACKER_TOGGLE = _a++;
	KbOption_JUKEBOX_TOGGLE = _a++;
	KbOption_JUKEBOX_PREV   = _a++;
	KbOption_JUKEBOX_NEXT   = _a++;
	KbOption_JUKEBOX_ASSIGN = _a++;
	KbOption_DEFAULT = _a++;
	KbOption_BACK    = _a++;
	KbOption_COUNT   = _a;
	dg_KbOptions = ds_grid_create(KbOption_COUNT, 8);
	dg_KbOptions[#KbOption_RIGHT,0]  ="RIGHT";        dg_KbOptions[#KbOption_RIGHT,1]  =_font;
	dg_KbOptions[#KbOption_LEFT,0]   ="LEFT";         dg_KbOptions[#KbOption_LEFT,1]   =_font;
	dg_KbOptions[#KbOption_DOWN,0]   ="DOWN";         dg_KbOptions[#KbOption_DOWN,1]   =_font;
	dg_KbOptions[#KbOption_UP,0]     ="UP";           dg_KbOptions[#KbOption_UP,1]     =_font;
	dg_KbOptions[#KbOption_MAGIC,0]  ="MAGIC";        dg_KbOptions[#KbOption_MAGIC,1]  =_font;
	dg_KbOptions[#KbOption_PAUSE,0]  ="PAUSE";        dg_KbOptions[#KbOption_PAUSE,1]  =_font;
	dg_KbOptions[#KbOption_ATTACK,0] ="ATTACK";       dg_KbOptions[#KbOption_ATTACK,1] =_font;
	dg_KbOptions[#KbOption_JUMP,0]   ="JUMP";         dg_KbOptions[#KbOption_JUMP,1]   =_font;
	dg_KbOptions[#KbOption_SPELL_NEXT,0]="NEXT SPELL";     dg_KbOptions[#KbOption_SPELL_NEXT,1]=_font;
	dg_KbOptions[#KbOption_SPELL_PREV,0]="PREV SPELL";     dg_KbOptions[#KbOption_SPELL_PREV,1]=_font;
	dg_KbOptions[#KbOption_TRACKER_TOGGLE,0]="TRACKER WINDOW"; dg_KbOptions[#KbOption_TRACKER_TOGGLE,1]=_font;
	dg_KbOptions[#KbOption_JUKEBOX_TOGGLE,0]="JUKEBOX ON/OFF"; dg_KbOptions[#KbOption_JUKEBOX_TOGGLE,1]=_font;
	dg_KbOptions[#KbOption_JUKEBOX_PREV,0]  ="JUKEBOX PREV";   dg_KbOptions[#KbOption_JUKEBOX_PREV,1]  =_font;
	dg_KbOptions[#KbOption_JUKEBOX_NEXT,0]  ="JUKEBOX NEXT";   dg_KbOptions[#KbOption_JUKEBOX_NEXT,1]  =_font;
	dg_KbOptions[#KbOption_JUKEBOX_ASSIGN,0]="ASSIGN TRACK";   dg_KbOptions[#KbOption_JUKEBOX_ASSIGN,1]=_font;
	dg_KbOptions[#KbOption_DEFAULT,0]="SET DEFAULTS";  dg_KbOptions[#KbOption_DEFAULT,1]=_font;
	dg_KbOptions[#KbOption_BACK,0]   ="BACK";         dg_KbOptions[#KbOption_BACK,1]   =_font;


	// --- DEBUG section rows (read-only HOTKEY reference) ---
	// FULL special-hotkey list shown in one place (the controls menu "doesn't show
	// everything for buttons"). These are DISPLAY-ONLY rows: only DbgOption_CHEATS and
	// DbgOption_BACK have behavior in OptionsMenu_InputConfig_update (everything else
	// falls through to the read-only "play BACK_SOUND1" branch). Adding rows is safe:
	// members use enum-style _a++ names (no hardcoded indices), the grid is sized off
	// DbgOption_COUNT, and the cursor wraps on DbgOption_COUNT -- no enum-shift hazard.
	// Keys verified against scripts/Surface_Draw_GUI_End.gml (F1/F3/F4/F6/F8/F9/F11/F12,
	// [ / ], L/R triggers) and scripts/Input_Create.gml (Q/E + L1/R1 spell-cycle defaults).
	// Reversible: to shrink back to the original short list, delete the added
	// DbgOption_* members + their dg_DbgOptions rows below (keep F1, CHEATS, BACK).
	_first=0; _a=_first;
	DbgOption_HDR_WIN  = _a++; // sub-header: window / overlay toggles
	DbgOption_F1       = _a++;
	DbgOption_F3       = _a++;
	DbgOption_F4       = _a++;
	DbgOption_F5       = _a++;
	DbgOption_F6       = _a++;
	DbgOption_F7       = _a++;
	DbgOption_HDR_JUKE = _a++; // sub-header: music jukebox
	DbgOption_F8       = _a++;
	DbgOption_F12      = _a++;
	DbgOption_JUKE_TRK = _a++; // [ / ] and L/R triggers cycle tracks
	DbgOption_HDR_WALK = _a++; // sub-header: walk tuning
	DbgOption_F9       = _a++;
	DbgOption_F11      = _a++;
	DbgOption_WALK_SP  = _a++; // [ / ] speed, \ smoothing (while F9 overlay up)
	DbgOption_HDR_SPELL= _a++; // sub-header: spell quick-cycle (rebindable defaults)
	DbgOption_SPELL_KB = _a++; // Q / E
	DbgOption_SPELL_GP = _a++; // L1 / R1
	DbgOption_CHEATS   = _a++; // -> opens DEV TOOLS (the only actionable non-BACK row)
	DbgOption_BACK     = _a++;
	DbgOption_COUNT    = _a;
	dg_DbgOptions = ds_grid_create(DbgOption_COUNT, 8);
	dg_DbgOptions[#DbgOption_HDR_WIN,0] ="- WINDOWS / OVERLAYS -";    dg_DbgOptions[#DbgOption_HDR_WIN,1] =_font;
	dg_DbgOptions[#DbgOption_F1,0]      ="F1: TRACKER WINDOW";        dg_DbgOptions[#DbgOption_F1,1]      =_font;
	dg_DbgOptions[#DbgOption_F3,0]      ="F3: REC PLAY-TELEMETRY";    dg_DbgOptions[#DbgOption_F3,1]      =_font;
	dg_DbgOptions[#DbgOption_F4,0]      ="F4: DEPTH OVERLAY";         dg_DbgOptions[#DbgOption_F4,1]      =_font;
	dg_DbgOptions[#DbgOption_F5,0]      ="F5: MOVE SPEED CYCLE";      dg_DbgOptions[#DbgOption_F5,1]      =_font;
	dg_DbgOptions[#DbgOption_F6,0]      ="F6: FLAG / SCREENSHOT";     dg_DbgOptions[#DbgOption_F6,1]      =_font;
	dg_DbgOptions[#DbgOption_F7,0]      ="F7: BUG NOTE / SNAPSHOT";   dg_DbgOptions[#DbgOption_F7,1]      =_font;
	dg_DbgOptions[#DbgOption_HDR_JUKE,0]="- MUSIC JUKEBOX -";         dg_DbgOptions[#DbgOption_HDR_JUKE,1]=_font;
	dg_DbgOptions[#DbgOption_F8,0]      ="F8: JUKEBOX MODE";          dg_DbgOptions[#DbgOption_F8,1]      =_font;
	dg_DbgOptions[#DbgOption_F12,0]     ="F12: ASSIGN TRACK TO AREA"; dg_DbgOptions[#DbgOption_F12,1]     =_font;
	dg_DbgOptions[#DbgOption_JUKE_TRK,0]="] / [ OR R/L TRIG: TRACK";  dg_DbgOptions[#DbgOption_JUKE_TRK,1]=_font;
	dg_DbgOptions[#DbgOption_HDR_WALK,0]="- WALK TUNING -";           dg_DbgOptions[#DbgOption_HDR_WALK,1]=_font;
	dg_DbgOptions[#DbgOption_F9,0]      ="F9: WALK-TUNE PANEL";       dg_DbgOptions[#DbgOption_F9,1]      =_font;
	dg_DbgOptions[#DbgOption_F11,0]     ="F11: SAVE WALK VALUES";     dg_DbgOptions[#DbgOption_F11,1]     =_font;
	dg_DbgOptions[#DbgOption_WALK_SP,0] ="MOUSE: DRAG SLIDERS";   dg_DbgOptions[#DbgOption_WALK_SP,1] =_font;
	dg_DbgOptions[#DbgOption_HDR_SPELL,0]="- SPELL CYCLE (REBINDABLE) -";dg_DbgOptions[#DbgOption_HDR_SPELL,1]=_font;
	dg_DbgOptions[#DbgOption_SPELL_KB,0]="Q / E: NEXT / PREV SPELL";  dg_DbgOptions[#DbgOption_SPELL_KB,1]=_font;
	dg_DbgOptions[#DbgOption_SPELL_GP,0]="R1 / L1: NEXT / PREV SPELL";dg_DbgOptions[#DbgOption_SPELL_GP,1]=_font;
	dg_DbgOptions[#DbgOption_CHEATS,0]  ="CHEATS: SEE DEV TOOLS";     dg_DbgOptions[#DbgOption_CHEATS,1]  =_font;
	dg_DbgOptions[#DbgOption_BACK,0]    ="BACK";                      dg_DbgOptions[#DbgOption_BACK,1]    =_font;








	// --------------------------------------------------------
	_first=1;               _a=_first;
	DevToolsState_MAIN    = _a++;
	//DevToolsState_EDITING = _a++;
	DevToolsState         = _first;


	// DEV TOOLS is now a LAUNCHER (refactor 2026-06-28): each row opens a sub-folder
	// submenu (its own menu_state + enum + grid + update + draw). DEV TOOLS itself holds
	// NO toggles. The actual toggles/actions were relocated into the sub-folder enums
	// (Overlays / Cheats / ClrTools / TestCap / Sweeps / MiscTools, defined below), each
	// flipping the EXACT SAME global it did under the old flat DEV TOOLS / AUTO TEST menus.
	enum DevTools
	{
	    OVERLAYS,   // -> menu_state_OVERLAYS  (hitboxes, scp, xy, og-cam, hp, sprite-outline, frame-count, depth, death-counter, exits, solid/unique tiles, dungeon map, input display)
	    CHEATS,     // -> menu_state_CHEATS    (add-items, faster move, inf hp/mp/lives, invuln)
	    COLOR,      // -> menu_state_COLOR     (bgr color, room color editors)
	    TEST_CAP,   // -> menu_state_TEST_CAP  (bugprobe, TAS rec/playback, playlog, walktune, controller diag)
	    SWEEPS,     // -> menu_state_SWEEPS    (live room-sweep starters)
	    MISC,       // -> menu_state_MISC      (set-all-default, app performance, dev-tools master switch)
	    BACK,       //
	    COUNT
	}

	DevTools_cursor = 0;




	_font = FONT2;

	// DEV TOOLS launcher grid: one row per sub-folder + BACK. No toggles here.
	DevTools_dg = ds_grid_create(DevTools.COUNT,8);
	//                                                                          //
	             _i=DevTools.OVERLAYS;
	DevTools_dg[#_i,0] = "OVERLAYS";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Debug overlays: hitboxes, xy, hp, exits, tiles, input display, etc.";
	//                                                                          //
	             _i=DevTools.CHEATS;
	DevTools_dg[#_i,0] = "CHEATS";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Add items, faster movement, infinite hp / mp / lives, invincibility.";
	//                                                                          //
	             _i=DevTools.COLOR;
	DevTools_dg[#_i,0] = "COLOR";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Open the background / room color editors.";
	//                                                                          //
	             _i=DevTools.TEST_CAP;
	DevTools_dg[#_i,0] = "TEST / CAPTURE";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Bug-probe, TAS record / playback, playlog, walk-tune, controller diag.";
	//                                                                          //
	             _i=DevTools.SWEEPS;
	DevTools_dg[#_i,0] = "SWEEPS";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Run live automated room-sweep tests.";
	//                                                                          //
	             _i=DevTools.MISC;
	DevTools_dg[#_i,0] = "MISC";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Set all to default, app performance overlay, dev-tools master switch.";
	//                                                                          //
	             _i=DevTools.BACK;
	DevTools_dg[#_i,0] = "BACK";
	DevTools_dg[#_i,1] = _font;
	DevTools_dg[#_i,2] = "Return to the previous menu.";
	//                                                                          //




	// -------------------------------------------------------------
	// AUTOMATED TEST submenu (added 2026-06-27). Mirrors the DEV TOOLS submenu
	// (enum + dg grid + *_update + Draw_* + is_avail). Two groups of rows:
	//   (A) SWEEP STARTERS — start a live in-game room-sweep test using the granular
	//       sweep engine on the persistent Dev_RmWarper object. Selecting a row closes
	//       the options menu and runs that sweep with global.sweep_from_menu=true, so
	//       sweep_stop() finishes cleanly and returns to play (NO game_end) — see
	//       Dev_RmWarper_Create.sweep_stop().
	//   (B) TEST / CAPTURE TOGGLES — relocated from DEV TOOLS (BUGPROBE, TAS RECORD,
	//       TAS PLAYBACK, INPUT DISPLAY, PLAYLOG, WALKTUNE). Exact same behavior, just
	//       listed here instead of under DEV TOOLS.
	// NOTE: the Dev_RmWarper room-warp UI itself opens via a controller combo (SELECT +
	// xbox-B) inside the PAUSE menu (see Dev_RmWarper_Step STATE_IDLE), NOT a menu row,
	// so it is intentionally not duplicated here (forcing it open from the options menu,
	// outside the pause menu it expects, can soft-lock).
	_first=1;               _a=_first;
	// AUTOMATED TEST submenu DELETED 2026-07-26 -- it was orphaned (no entry point
	// anywhere) and its 18 rows duplicated DEV TOOLS -> SWEEPS + TEST/CAPTURE.




	// -------------------------------------------------------------
	// DISPLAY submenu (added 2026-06-27). Mirrors the AUTOMATED TEST submenu
	// (enum + dg grid + *_update + Draw_* + is_avail). One row per screen-scaling
	// MODE plus a BACK row. The selected mode is persisted in global.DisplayMode
	// (DISPLAY_* macros) via save_game_pref(); the rendering that APPLIES the mode
	// is a separate follow-up — DISPLAY_SMOOTH (default) is the current behavior so
	// nothing visually changes yet. Enum order maps 1:1 onto the DISPLAY_* macros.
	_first=1;               _a=_first;
	DisplayState_MAIN     = _a++;
	DisplayState          = _first;


	enum Display
	{
	    // Window/video options consolidated here (2026-06-27). FULLSCREEN + WINDOW_SCALE
	    // are NOT part of the scaling-mode radio group below: FULLSCREEN is an ON/OFF
	    // toggle and WINDOW_SCALE is a value, both driven by update_game_window_1a()
	    // (which keys off menu_state_DISPLAY + Display_cursor). The mode rows SMOOTH..SCAN
	    // stay contiguous and map 1:1 onto the DISPLAY_* macros via the Display.SMOOTH
	    // offset (macro = enum - Display.SMOOTH).
	    FULLSCREEN,   // fullscreen ON/OFF toggle  (logic in update_game_window_1a)
	    WINDOW_SCALE, // window scale value (e.g. "2X") (logic in update_game_window_1a)
	    SMOOTH,   // DISPLAY_SMOOTH (current behavior)
	    SHARP,    // DISPLAY_SHARP
	    PIXEL,    // DISPLAY_PIXEL
	    FILL,     // DISPLAY_FILL
	    CRT,      // DISPLAY_CRT
	    SCAN,     // DISPLAY_SCAN
	    BACK,     //
	    COUNT
	}

	Display_cursor = 0;


	_font = FONT2;

	Display_dg = ds_grid_create(Display.COUNT,8);
	//                                                                          //
	             _i=Display.FULLSCREEN;
	Display_dg[#_i,0] = "FULLSCREEN";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Toggle fullscreen. The 'F' key also toggles it.";
	//                                                                          //
	             _i=Display.WINDOW_SCALE;
	Display_dg[#_i,0] = "WINDOW SCALE";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Resize the window with LEFT/RIGHT. CTRL(+SHIFT)+'G' also works.";
	//                                                                          //
	             _i=Display.SMOOTH;
	Display_dg[#_i,0] = "SMOOTH";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Soft scaling, fills the window. (current)";
	//                                                                          //
	             _i=Display.SHARP;
	Display_dg[#_i,0] = "SHARP";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Crisp pixels, fills any size. Recommended.";
	//                                                                          //
	             _i=Display.PIXEL;
	Display_dg[#_i,0] = "PIXEL PERFECT";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Pixel-perfect, every pixel equal, black bars.";
	//                                                                          //
	             _i=Display.FILL;
	Display_dg[#_i,0] = "CRISP FILL";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Crisp-fill: hard pixels, fills window.";
	//                                                                          //
	             _i=Display.CRT;
	Display_dg[#_i,0] = "CRT";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Old-TV look: scanlines + curve.";
	//                                                                          //
	             _i=Display.SCAN;
	Display_dg[#_i,0] = "SCANLINES";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Light scanlines only.";
	//                                                                          //
	             _i=Display.BACK;
	Display_dg[#_i,0] = "BACK";
	Display_dg[#_i,1] = _font;
	Display_dg[#_i,2] = "Return to the previous menu.";
	//                                                                          //




	// =============================================================
	// DEV TOOLS SUB-FOLDERS (added 2026-06-28). DEV TOOLS is now a launcher; the
	// real toggles/actions live here, one sub-folder per enum, each mirroring the
	// DISPLAY submenu (enum + _dg grid + *_update + Draw_* + is_avail + dispatch).
	// Every toggle flips the EXACT SAME global it did under the old flat DEV TOOLS /
	// AUTOMATED TEST menus -- only its menu home changed.
	// =============================================================


	// -------- OVERLAYS --------
	_first=1;               _a=_first;
	OverlaysState_MAIN    = _a++;
	OverlaysState         = _first;

	enum Overlays
	{
	    HITBOXES, SCP, XY, OG_CAM, HP, SPRITE_OUTLINE, FRAME_COUNT,
	    DEPTH_DEBUG, DEATH_COUNTER, EXITS, SOLID_TILES, UNIQUE_TILES,
	    DUNGEON_MAP, INPUT_DISPLAY,
	    BACK,
	    COUNT
	}
	Overlays_cursor = 0;

	_font = FONT2;
	Overlays_dg = ds_grid_create(Overlays.COUNT,8);
	             _i=Overlays.HITBOXES;
	Overlays_dg[#_i,0]="HITBOXES";                    Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Draw collision hitboxes.";
	             _i=Overlays.SCP;
	Overlays_dg[#_i,0]="SOLID COLLISION POINTS";      Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Draw solid collision points.";
	             _i=Overlays.XY;
	Overlays_dg[#_i,0]="XY POINTS";                   Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Draw object XY origin points.";
	             _i=Overlays.OG_CAM;
	Overlays_dg[#_i,0]="ORIGINAL GAME CAMERA OUTLINE"; Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Outline the original game camera area.";
	             _i=Overlays.HP;
	Overlays_dg[#_i,0]="HP";                          Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Show HP values overlay.";
	             _i=Overlays.SPRITE_OUTLINE;
	Overlays_dg[#_i,0]="SPRITE OUTLINES";             Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Outline sprites (cycles modes).";
	             _i=Overlays.FRAME_COUNT;
	Overlays_dg[#_i,0]="APP FRAME COUNT";             Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Show app and room frame counters.";
	             _i=Overlays.DEPTH_DEBUG;
	Overlays_dg[#_i,0]="DEPTH OVERLAY";               Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Toggle the depth-layer debug overlay.";
	             _i=Overlays.DEATH_COUNTER;
	Overlays_dg[#_i,0]="DEATH COUNTER";               Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Toggle the on-screen HUD death counter.";
	             _i=Overlays.EXITS;
	Overlays_dg[#_i,0]="EXITS";                       Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Draw room-exit hitboxes.";
	             _i=Overlays.SOLID_TILES;
	Overlays_dg[#_i,0]="HIGHLIGHT SOLID TILES";       Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Highlight solid collision tiles.";
	             _i=Overlays.UNIQUE_TILES;
	Overlays_dg[#_i,0]="HIGHLIGHT UNIQUE TILES";      Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Highlight unique tiles.";
	             _i=Overlays.DUNGEON_MAP;
	Overlays_dg[#_i,0]="COMPLETE DUNGEON MAPS";       Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Reveal the entire dungeon map.";
	             _i=Overlays.INPUT_DISPLAY;
	Overlays_dg[#_i,0]="INPUT DISPLAY";               Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Show on-screen button input overlay.";
	             _i=Overlays.BACK;
	Overlays_dg[#_i,0]="BACK";                        Overlays_dg[#_i,1]=_font; Overlays_dg[#_i,2]="Return to the DEV TOOLS menu.";


	// -------- CHEATS --------
	_first=1;               _a=_first;
	CheatsState_MAIN      = _a++;
	CheatsState           = _first;

	enum Cheats
	{
	    ADD_ITEMS, PC_DASH, INF_HP, INF_MP, INF_LIVES, INVULN,
	    BACK,
	    COUNT
	}
	Cheats_cursor = 0;

	_font = FONT2;
	Cheats_dg = ds_grid_create(Cheats.COUNT,8);
	             _i=Cheats.ADD_ITEMS;
	Cheats_dg[#_i,0]="ADD ITEMS CHEAT";       Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Stab to grant items (cheat).";
	             _i=Cheats.PC_DASH;
	Cheats_dg[#_i,0]="FASTER MOVEMENT SPEED"; Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Move faster than normal.";
	             _i=Cheats.INF_HP;
	Cheats_dg[#_i,0]="CHEAT: INFINITE HP";    Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Cheat: never lose HP.";
	             _i=Cheats.INF_MP;
	Cheats_dg[#_i,0]="CHEAT: INFINITE MP";    Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Cheat: never lose magic.";
	             _i=Cheats.INF_LIVES;
	Cheats_dg[#_i,0]="CHEAT: INFINITE LIVES"; Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Cheat: never lose lives.";
	             _i=Cheats.INVULN;
	Cheats_dg[#_i,0]="CHEAT: INVINCIBILITY";  Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Cheat: take no damage.";
	             _i=Cheats.BACK;
	Cheats_dg[#_i,0]="BACK";                  Cheats_dg[#_i,1]=_font; Cheats_dg[#_i,2]="Return to the DEV TOOLS menu.";


	// -------- COLOR --------
	_first=1;               _a=_first;
	ColorState_MAIN       = _a++;
	ColorState            = _first;

	enum ClrTools
	{
	    BGR_COLOR, ROOM_COLOR,
	    BACK,
	    COUNT
	}
	Color_cursor = 0;

	_font = FONT2;
	Color_dg = ds_grid_create(ClrTools.COUNT,8);
	             _i=ClrTools.BGR_COLOR;
	Color_dg[#_i,0]="EDIT BACKGROUND COLOR"; Color_dg[#_i,1]=_font; Color_dg[#_i,2]="Open the background color editor.";
	             _i=ClrTools.ROOM_COLOR;
	Color_dg[#_i,0]="EDIT ROOM COLORS";      Color_dg[#_i,1]=_font; Color_dg[#_i,2]="Open the room color editor.";
	             _i=ClrTools.BACK;
	Color_dg[#_i,0]="BACK";                  Color_dg[#_i,1]=_font; Color_dg[#_i,2]="Return to the DEV TOOLS menu.";


	// -------- TEST / CAPTURE --------
	_first=1;               _a=_first;
	TestCapState_MAIN     = _a++;
	TestCapState          = _first;

	// ── TWITCH (player-facing) ────────────────────────────────────────────────
	// The two toggles moved out of DEV TOOLS -> TEST/CAPTURE so viewers-affect-the-game
	// is reachable without the dev unlock. COOLDOWN and DURATION are value rows the
	// streamer will actually want to tune mid-stream; both persist to twitch_config.txt.
	// The oauth token is deliberately NEVER shown -- the owner streams this menu.
	enum Twitch
	{
	    REWARDS, CHAT, COOLDOWN, DURATION, JOKES, AUTOSAVE, POINTS, RL, COMMANDS, SETUP,
	    PAGES, BACK,
	    COUNT
	}
	Twitch_cursor = 0;

	Twitch_dg = ds_grid_create(Twitch.COUNT,8);
	_font = FONT2;
	             _i=Twitch.REWARDS;
	Twitch_dg[#_i,0]="TWITCH REWARDS";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="CHANNEL-POINT REDEEMS AND DONATIONS. NEEDS THE COMPANION BOT RUNNING OUTSIDE THE GAME.";
	             _i=Twitch.CHAT;
	Twitch_dg[#_i,0]="TWITCH IRC";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="CONNECTS TO YOUR CHAT SO VIEWERS CAN TYPE !COMMANDS. NO BOT NEEDED - THIS IS THE EASY ONE.";
	             _i=Twitch.COOLDOWN;
	Twitch_dg[#_i,0]="COMMAND COOLDOWN";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="SECONDS BETWEEN CHAT COMMANDS. AFFECTS TWITCH IRC ONLY. LEFT/RIGHT TO CHANGE.";
	             _i=Twitch.DURATION;
	Twitch_dg[#_i,0]="EFFECT LENGTH";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="HOW LONG A TIMED EFFECT LASTS, LIKE SLOW OR DARK. LEFT/RIGHT TO CHANGE.";
	             _i=Twitch.JOKES;
	Twitch_dg[#_i,0]="CHAT JOKES";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="TOWN FOLK TALK LIKE CHAT. NORMAL = ORIGINAL TEXT. CLEAN = JOKES, NO CURSING. DIRTY = ALL OF IT. HINTS ARE NEVER CHANGED.";
	             _i=Twitch.AUTOSAVE;
	Twitch_dg[#_i,0]="CHECKPOINTS";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="A COPY OF YOUR SAVE EVERY 60 SECONDS, EVERY ITEM AND EVERY LEVEL UP, IN THE CHECKPOINTS FOLDER NEXT TO YOUR SAVES. YOUR REAL SAVE IS NOT TOUCHED.";
	             _i=Twitch.POINTS;
	Twitch_dg[#_i,0]="POINTS ECONOMY";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="VIEWERS EARN POINTS BY CHATTING (1 A MESSAGE, 5 EVERY 5 MINUTES) AND EVERY COMMAND COSTS SOME. !POINTS SHOWS A BALANCE. OFF = EVERYTHING IS FREE.";
	             _i=Twitch.RL;
	Twitch_dg[#_i,0]="ROCKET LEAGUE";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="QUICK-CHAT PLATES ON SAVES, WHIFFS, DEMOS AND DEATHS, AND !NICESHOT !WHATASAVE !GG IN CHAT. OFF HIDES ALL OF IT.";
	             _i=Twitch.COMMANDS;
	Twitch_dg[#_i,0]="COMMANDS";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="!HEAL !HURT !SLOW !SPEED !FLIP !CONFUSE !DARK !SPAWN !SWARM !PARTY !FREEZE !CUCCO !1UP !TAX !DMGUP !ATTRITION !SONG";
	             _i=Twitch.SETUP;
	// Was "HOW TO SET UP", pointing at a .bat and a text file. The setup is a web page
	// served by the game now, so this row OPENS it instead of describing homework.
	Twitch_dg[#_i,0]="OPEN SETUP PAGE";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="OPENS THE SETUP PAGE IN YOUR BROWSER. SIGN IN ON TWITCH'S OWN SITE - NEVER TYPE A PASSWORD INTO THE GAME.";
	             _i=Twitch.PAGES;
	Twitch_dg[#_i,0]="COMPANION PAGES";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="OPENS JUKEBOX, TRACKER AND TWITCH SETUP IN YOUR BROWSER.";
	             _i=Twitch.BACK;
	Twitch_dg[#_i,0]="BACK";  Twitch_dg[#_i,1]=_font; Twitch_dg[#_i,2]="RETURN TO THE MAIN OPTIONS MENU.";


	enum TestCap
	{
	    BUGPROBE, TAS_RECORD, TAS_PLAYBACK, PLAYLOG, WALKTUNE, GP_DIAG, COOP_TEST,
	    REPLAY_MARK, SPAWN_MARK,
	    // TWITCH + TWITCH_IRC moved to the player-facing TWITCH menu 2026-07-26 --
	    // they were unreachable once DEV TOOLS was hidden behind the unlock code.
	    BACK,
	    COUNT
	}
	TestCap_cursor = 0;

	_font = FONT2;
	TestCap_dg = ds_grid_create(TestCap.COUNT,8);
	             _i=TestCap.BUGPROBE;
	TestCap_dg[#_i,0]="RUN BUGPROBE";          TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Toggle the automated bug-probe test.";
	             _i=TestCap.TAS_RECORD;
	TestCap_dg[#_i,0]="TAS RECORD";            TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Record your inputs each frame to a file.";
	             _i=TestCap.TAS_PLAYBACK;
	TestCap_dg[#_i,0]="TAS PLAYBACK";          TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Replay the recorded inputs 1:1.";
	             _i=TestCap.PLAYLOG;
	TestCap_dg[#_i,0]="PLAYLOG (REC SESSION)"; TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Record play telemetry to a session log.";
	             _i=TestCap.WALKTUNE;
	TestCap_dg[#_i,0]="WALKTUNE PANEL";        TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Toggle the walk-tuning panel overlay.";
	             _i=TestCap.GP_DIAG;
	TestCap_dg[#_i,0]="CONTROLLER DIAG";       TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Live gamepad readout: buttons, triggers, axes + raw scan.";
	             _i=TestCap.COOP_TEST;
	TestCap_dg[#_i,0]="COOP TEST";             TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Run the automated co-op fairy test (move/shoot/heal/tank/ferry/revive/room-hop).";
	             _i=TestCap.REPLAY_MARK;
	TestCap_dg[#_i,0]="REPLAY LAST MARK";      TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Restore the last MARK (key 3) snapshot and replay its recorded inputs.";
	             _i=TestCap.SPAWN_MARK;
	TestCap_dg[#_i,0]="SPAWN AT LAST MARK";    TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Restore the last MARK (key 3) snapshot but KEEP the controls -- re-run a bug from its exact state without walking back.";
	             _i=TestCap.BACK;
	TestCap_dg[#_i,0]="BACK";                  TestCap_dg[#_i,1]=_font; TestCap_dg[#_i,2]="Return to the DEV TOOLS menu.";


	// -------- SWEEPS --------
	_first=1;               _a=_first;
	SweepsState_MAIN      = _a++;
	SweepsState           = _first;

	enum Sweeps
	{
	    SW_FULL, SW_OVERWORLD, SW_PALACES, SW_TOWNS, SW_CAVES,
	    SW_CAVES_WEST, SW_CAVES_EAST, SW_CAVES_DTHMT, SW_CAVES_MAZIS, SW_OTHER,
	    BACK,
	    COUNT
	}
	Sweeps_cursor = 0;

	_font = FONT2;
	Sweeps_dg = ds_grid_create(Sweeps.COUNT,8);
	             _i=Sweeps.SW_FULL;
	Sweeps_dg[#_i,0]="SWEEP: FULL";        Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over every action-room scene.";
	             _i=Sweeps.SW_OVERWORLD;
	Sweeps_dg[#_i,0]="SWEEP: OVERWORLD";   Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over every overworld page.";
	             _i=Sweeps.SW_PALACES;
	Sweeps_dg[#_i,0]="SWEEP: PALACES";     Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over palace (dungeon) scenes only.";
	             _i=Sweeps.SW_TOWNS;
	Sweeps_dg[#_i,0]="SWEEP: TOWNS";       Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over town scenes only.";
	             _i=Sweeps.SW_CAVES;
	Sweeps_dg[#_i,0]="SWEEP: CAVES";       Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over cave / connector scenes only.";
	             _i=Sweeps.SW_CAVES_WEST;
	Sweeps_dg[#_i,0]="SWEEP: CAVES-WEST";  Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over west-region cave scenes.";
	             _i=Sweeps.SW_CAVES_EAST;
	Sweeps_dg[#_i,0]="SWEEP: CAVES-EAST";  Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over east-region cave scenes.";
	             _i=Sweeps.SW_CAVES_DTHMT;
	Sweeps_dg[#_i,0]="SWEEP: CAVES-DTHMT"; Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over Death-Mountain cave scenes.";
	             _i=Sweeps.SW_CAVES_MAZIS;
	Sweeps_dg[#_i,0]="SWEEP: CAVES-MAZIS"; Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over Maze-Island cave scenes.";
	             _i=Sweeps.SW_OTHER;
	Sweeps_dg[#_i,0]="SWEEP: OTHER";       Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Run a live sweep over the system menu rooms.";
	             _i=Sweeps.BACK;
	Sweeps_dg[#_i,0]="BACK";               Sweeps_dg[#_i,1]=_font; Sweeps_dg[#_i,2]="Return to the DEV TOOLS menu.";


	// -------- MISC --------
	_first=1;               _a=_first;
	MiscState_MAIN        = _a++;
	MiscState             = _first;

	// CO_OP removed 2026-06-28 -- the CO-OP toggle was promoted to the MAIN options list
	// (MainOption_CO_OP), so it no longer lives here (avoid two toggles for one flag).
	enum MiscTools
	{
	    SET_DEFAULT, APP_PERFORMANCE, DEV_TOOLS_STATE,
	    BACK,
	    COUNT
	}
	Misc_cursor = 0;

	_font = FONT2;
	Misc_dg = ds_grid_create(MiscTools.COUNT,8);
	             _i=MiscTools.SET_DEFAULT;
	Misc_dg[#_i,0]="SET ALL TO DEFAULT"; Misc_dg[#_i,1]=_font; Misc_dg[#_i,2]="Reset all dev tool options to off.";
	             _i=MiscTools.APP_PERFORMANCE;
	Misc_dg[#_i,0]="APP PERFORMANCE";    Misc_dg[#_i,1]=_font; Misc_dg[#_i,2]="Show FPS and performance overlay.";
	             _i=MiscTools.DEV_TOOLS_STATE;
	Misc_dg[#_i,0]="DEV TOOLS STATE";    Misc_dg[#_i,1]=_font; Misc_dg[#_i,2]="Master switch for developer tools.";
	             _i=MiscTools.BACK;
	Misc_dg[#_i,0]="BACK";               Misc_dg[#_i,1]=_font; Misc_dg[#_i,2]="Return to the DEV TOOLS menu.";




	// -------------------------------------------------------------
	// -------------------------------------------------------------
	// -------------------------------------------------------------
	_first=1;               _a=_first;
	AudioCustomState_MAIN = _a++;
	AudioCustomState      = _first;


	_first=0;                _a=_first;
	AudioCustom_BACK       = _a++;
	AudioCustom_TOGGLE_ALL = _a++;
	AudioCustom_TOGGLE_SET = _a++;
	AudioCustom_Themes_IDX = _a;
	AudioCustom_cursor     = _first;

	//AudioCustom_COUNT = _a + val(Audio.dm[?STR_Theme+STR_Count+STR_Music]);
	//AudioCustom_COUNT = _a;


	dm_AudioCustom = ds_map_create();

	// 0: all off, 1: at least 1 on, 2: all on
	OptionsMenu_AudioCustom_refresh_indicator_states();

	_font = FONT2;
	_size = sprite_get_width(_font);
	var _dg_w = 0;
	var _dg_H = 5;
	dg_AudioCustom = ds_grid_create( _dg_w,_dg_H);
	//                                                                          //
	ds_grid_resize(dg_AudioCustom, ++_dg_w,_dg_H);
	dg_AudioCustom[#_dg_w-1,0] = "BACK";
	dg_AudioCustom[#_dg_w-1,1] = _font;
	dg_AudioCustom[#_dg_w-1,4] = dg_AudioCustom[#_dg_w-1,0];
	//                                                                          //
	ds_grid_resize(dg_AudioCustom, ++_dg_w,_dg_H);
	dg_AudioCustom[#_dg_w-1,0] = "TOGGLE ALL";
	dg_AudioCustom[#_dg_w-1,1] = _font;
	dg_AudioCustom[#_dg_w-1,3] = 3; // 3: state indicator
	dg_AudioCustom[#_dg_w-1,4] = dg_AudioCustom[#_dg_w-1,0];
	//                                                                          //
	ds_grid_resize(dg_AudioCustom, ++_dg_w,_dg_H);
	dg_AudioCustom[#_dg_w-1,0] = "TOGGLE SETS";
	dg_AudioCustom[#_dg_w-1,1] = _font;
	dg_AudioCustom[#_dg_w-1,2] = false; // 2: open state
	dg_AudioCustom[#_dg_w-1,4] = dg_AudioCustom[#_dg_w-1,0];
	//                                                                          //
	//ds_grid_resize(dg_AudioCustom, ++_dg_w,_dg_H); // divider
	//dg_AudioCustom[#_dg_w-1,0] = "DIVIDER";
	//                                                                          //
	_count = val(Audio.dm[?STR_Theme+STR_Count+STR_Music]);
	//sdm(STR_Theme+STR_Count+STR_Music+": $"+hex_str(_count));
	for(_i=1; _i<=_count; _i++)
	{
	    _theme = Audio.dm[?STR_Theme+STR_Music+hex_str(_i)];
	    if(!is_undefined(_theme))
	    {
	        ds_grid_resize(dg_AudioCustom, ++_dg_w,_dg_H);
	        dg_AudioCustom[#_dg_w-1,0] = _theme;
	        dg_AudioCustom[#_dg_w-1,1] = _font;
	        dg_AudioCustom[#_dg_w-1,2] = false; // 2: open state
	        dg_AudioCustom[#_dg_w-1,3] = 3; // 3: state indicator
        
	        _text = val(Audio.dm[?_theme+STR_Description], _theme);
	        dg_AudioCustom[#_dg_w-1,4] = _text;
	    }
	}
	//                                                                          //

	AudioCustom_COUNT = _dg_w;


	AudioCustom_cursor2 = 0;
	AudioCustom_track_inst = 0;

	AudioCustom_Scroll_Cursor_y = 0;


	AudioCustom_PLAY_KEY = vk_space;
	//AudioCustom_PLAY_KEY = ord("Y");


	//StateIndicator_SIZE = $6;








	// -------------------------------------------------------------
	// -------------------------------------------------------------
	// -------------------------------------------------------------
	_first=1;          _a=_first;
	Rando_state_MAIN = _a++;
	Rando_state      = _first;


	_i = -1;
	_dk0 = "Rando";


	_j=0; _k=0;
	Rando_MARK_ACQUIRED = ++_i;
	_dk2 = _dk0+hex_str(_i);
	switch(global.MarkItemLocations_VER)
	{
	    default:{
	    dm_options[?_dk2+STR_Font]                         = FONT2;
	    dm_options[?_dk2+STR_Option+STR_Text]              = "MARK ACQUIRED ITEMS";
	    dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "NO";
	    dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "YES";
	    dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "AN ACQUIRED ITEM'S OVERWORLD LOCATION WILL DISPLAY A CHECKMARK";
	    //dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "AFTER ACQUIRING AN ITEM, ITS OVERWORLD TILE WILL DISPLAY A CHECKMARK";
	    //dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "OVERWORLD TILES THAT CONTAINED AN ACQUIRED ITEM WILL DISPLAY A CHECK MARK";
	    dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "HIGHLY RECOMMENDED FOR ITEM RANDO";
	    //dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THIS IS EXTREMELY HELPFUL IN ITEM RANDO";
	    break;}//default
    
	    case  2:{
	    dm_options[?_dk2+STR_Font]                         = FONT2;
	    dm_options[?_dk2+STR_Option+STR_Text]              = "MARK ITEM LOCATIONS";
	    dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "0"; // OFF
	    dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "1"; // Mark acquired items only 
	    dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "2"; // Mark item locations and acquired info
	    dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "0: OFF";
	    dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "1: MARK ACQUIRED ITEM LOCATIONS";
	    dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "2: MARK ITEM LOCATIONS AND ACQUIRED INFO";
	    break;}//case  2
	}//switch(global.MarkItemLocations_VER)
	//                                                                          //
	_j=0; _k=0;
	Rando_RESHUFFLE = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "RESHUFFLE ENEMIES";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "GO";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "RE-ROLL THIS SEED'S ENEMY RANDOMIZER NOW. ITEMS, SPELLS, PALACES AND TOWNS STAY PUT. TAKES EFFECT ON THE NEXT SCREEN. THE SPOILER FILE KEEPS THE ORIGINAL ROLL.";
	//                                                                          //
	_j=0; _k=0;
	Rando_HINTS = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "ITEM LOCATION HINTS";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "NPCS WITH A '?' OVER THEIR HEAD GIVE A HINT TO THE LOCATION OF AN ITEM";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "NPCS WITH A '?' OVER THEIR HEAD GIVE A HINT TO A PROGRESSION ITEM";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "NPCS WITH A '?' OVER THEIR HEAD GIVE A HINT TO THE LOCATION OF A PROGRESSION ITEM";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "CERTAIN NPCS GIVE A HINT TO A PROGRESSION ITEM'S LOCATION";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "CERTAIN NPCS CAN GIVE A HINT TO THE LOCATION OF A PROGRESSION ITEM";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "CERTAIN NPCS, AND OTHER DIALOGUES, CAN GIVE A HINT TO THE LOCATION OF A PROGRESSION ITEM";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "NPCS THAT HAVE A HINT WILL HAVE A '?' OVER THEIR HEAD";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "HIGHLY RECOMMENDED FOR ITEM RANDO";
	//                                                                          //
	_j=0; _k=0;
	Rando_MAPS_SHOW_KEYS = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "KEYSANITY - MAP ITEMS SHOW KEYS";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "MAP ITEMS WILL SHOW LOCATIONS OF KEYS ON THE OVERWORLD";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE MAP ITEMS WILL ALSO SHOW LOCATIONS OF KEYS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE MAP ITEMS, WHICH NORMALLY DISPLAY IN THE OVERWORLD LOCATIONS OF ITEMS LIKE HEART PIECES AND MAGIC PIECES, WILL ALSO SHOW LOCATIONS OF KEYS";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THIS OPTION IS ONLY AVAILABLE FOR KEYSANITY";
	//                                                                          //
	_j=0; _k=0;
	Rando_ENEMY_RANDO = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "ENEMY RANDO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THIS IS JUST HERE SO YOU CAN TURN ENEMY RANDO OFF IN CASE OF ANY ISSUES WITH IT";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "YOU CAN TURN ENEMY RANDO OFF IN CASE OF ANY ISSUES WITH IT";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THIS IS HERE IN CASE OF ANY ISSUES WITH ENEMY RANDO";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE ENEMY RANDO ISN'T PERFECT, SO THIS IS HERE IN CASE IT GETS TOO FRUSTRATING";
	//                                                                          //
	_j=0; _k=0;
	Rando_DUNGEON_TILESETS = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "DUNGEON GRAPHICS RANDO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ON: DUNGEONS USE GRAPHICS RANDOMLY PICKED FOR THIS QUEST";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ON: DUNGEONS WILL USE WHAT GRAPHIC SET WAS RANDOMLY PICKED FOR THIS QUEST";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ON: DUNGEONS WILL USE THEIR RANDOMIZED GRAPHICS ASSIGNED FOR THIS QUEST";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "WHICH GRAPHICS A DUNGEON USES IS RANDOMIZED";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "WHICH GRAPHICS EACH DUNGEON USES IS RANDOMIZED";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE DUNGEON GRAPHICS ARE SHUFFLED";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "COSMETIC ONLY - DOES NOT AFFECT GAMEPLAY";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THIS IS ONLY COSMETIC AND DOES NOT AFFECT GAMEPLAY";
	//                                                                          //
	_j=0; _k=0;
	Rando_OW_BIOMES = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "OVERWORLD BIOME RANDO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "OVERWORLD WILL USE THIS QUEST'S SHUFFLED BIOMES";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "OVERWORLD BIOMES ARE SHUFFLED";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "SWAMPS STILL SLOW YOU AND CAN APPEAR ANYWHERE";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "SWAMPS WILL NOT SLOW YOUR SPEED SINCE THERE COULD BE A SIGNIFICANT NUMBER OF SWAMP TILES";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "SWAMPS WILL NOT SLOW YOUR SPEED AS THERE COULD BE A SIGNIFICANT NUMBER OF SWAMP TILES";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "-SWAMPS WILL NOT SLOW YOU DOWN LIKE THEY DO NORMALLY AS THERE COULD END UP BEING A SIGNIFICANT NUMBER OF SWAMP TILES";
	//                                                                          //
	_j=0; _k=0;
	Rando_SCENES = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "ROOM RANDO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ROOMS WITH EQUAL TRAVERSAL REQUIREMENTS ARE SHUFFLED";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ROOMS WITH EQUAL REQUIREMENTS TO TRAVERSE THEM ARE SHUFFLED";
	//                                                                          //
	_j=0; _k=0;
	Rando_PALETTE = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "PALETTE RANDO";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "0: OFF";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "1: ONLY PLAYER AND DUNGEONS USE THEIR RANDOMIZED COLORS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "1: PLAYER AND DUNGEON COLORS ARE RANDOMIZED";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "2: ALL SCENES USE THEIR RANDOMIZED COLORS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "2: USE EVERY SCENE'S RANDOMIZED COLORS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "2: ALL SCENE COLORS ARE RANDOMIZED";
	//                                                                          //
	_j=0; _k=0;
	Rando_DUNGEONS_REQUIREMENT = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "DUNGEONS REQUIREMENT";
	//dm_options[?_dk2+STR_State]                        = global.RandoDungeonRequirement_MAX;
	//dm_options[?_dk2+STR_State]                        = val(global.dm_save_file_settings[?STR_Crystal+STR_Required+STR_Count], global.RandoDungeonRequirement_MAX);
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "HOW MANY DUNGEONS MUST BE COMPLETED TO GET INTO THE FINAL DUNGEON";
	//                                                                          //
	_j=0; _k=0;
	Rando_BACK = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "BACK";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "RETURN TO THE MAIN OPTIONS MENU";
	//                                                                          //

	OptionsMenu_Create_1(_dk0, _i+1);
	Rando_cursor = 0;







	// ------------------------------------------------------------
	// ------------------------------------------------------------
	// ------------------------------------------------------------
	_first=1;          _i=_first;
	Other_state_MAIN = _i++;
	Other_state      = _first;


	_i = -1;
	_dk0 = "Other";


	_j=0; _k=0;
	Other_FLASHING = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "BACKGROUND FLASHING";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "WHAT COLOR THE BACKGROUND FLASHES DURING EVENTS SUCH AS: SPELL CASTING, BOSS EXPLOSIONS, ETC...";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE BACKGROUND COLOR DURING EVENTS LIKE: SPELL CASTING, BOSS EXPLOSIONS, ETC...";
	//                                                                          //
	_j=0; _k=0;
	Other_DIALOGUE_SPEED = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "DIALOGUE SPEED";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "1 IS THE ORIGINAL GAME'S DIALOGUE SPEED";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "1 IS THE ORIGINAL GAME SPEED";
	//                                                                          //
	_j=0; _k=0;
	Other_GAME_FONT = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "GAME FONT";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "FONT 0 IS THE GAME'S NORMAL FONT";
	//                                                                          //
	_j=0; _k=0;
	Other_HIDDEN_OW_EXITS = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "MARK HIDDEN OVERWORLD EXITS";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "NO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "YES";
	/*
	dm_options[?_dk2+STR_Option+STR_Text]              = "HIDDEN OVERWORLD EXITS";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "HIDE";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "MARK";
	*/
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": MOST OVERWORLD TILES WITH A HIDDEN EXIT WILL BE MARKED WITH A SPARKLE ANIMATION";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": NORMAL";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": OVERWORLD TILES WITH A HIDDEN EXIT WILL BE MARKED WITH A SPARKLE ANIMATION";
	//                                                                          //
	_j=0; _k=0;
	Other_HUD = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "HUD STATE";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "HIDE";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "MINIMAL";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "FULL";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": HIDE THE HUD";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": ONLY ORIGINAL GAME HUD INFO";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": HUD HAS ALL THE INFO FROM THE ORIGINAL GAME";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": HUD ONLY DISPLAYS INFORMATION FROM THE ORIGINAL GAME";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"02"+STR_Text]))+": EXTRA HUD INFO: QUEUED SPELL, LIVES, KEYS, NEXT LEVEL";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"02"+STR_Text]))+": HUD HAS EXTRA INFO: SPELL, LIVES, KEYS, ETC...";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"02"+STR_Text]))+": HUD INCLUDES EXTRA INFORMATION THAN WHAT THE ORIGINAL GAME DOES";
	//                                                                          //
	_j=0; _k=0;
	Other_QUEST_TIMER = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "QUEST TIMER";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "HIDE";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "SHOW";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE TIME PASSED SINCE STARTING THIS QUEST";
	//                                                                          //
	_j=0; _k=0;
	Other_TORCH_LIGHTING = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "TORCH LIGHTING";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "STAB";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "AUTO";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": LIGHT A TORCH BY STABBING IT";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+":  STAB A TORCH TO LIGHT IT";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": A TORCH MUST BE STABBED TO LIGHT IT";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": LIGHT A TORCH BY TOUCHING IT";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": TOUCH A TORCH TO LIGHT IT";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": TOUCHING A TORCH WILL LIGHT IT";
	//                                                                          //
	/*
	//global.RenderFrameDelay_state!=-1 // -1: App will not include this option
	_j=0; _k=0;
	Other_RENDER_DELAY = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "RENDER DELAY";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": NO RENDER DELAY";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": RENDER IS DELAYED BY 1 FRAME LIKE THE ORIGINAL GAME";
	//                                                                          //
	*/
	_j=0; _k=0;
	Other_SCREEN_SHAKE = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "SCREEN SHAKE";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": CERTAIN ACTIONS, LIKE A BOSS EXPLODING, WILL CAUSE THE SCREEN TO SHAKE";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": CERTAIN ACTIONS CAUSE THE SCREEN TO SHAKE";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": NO SCREEN SHAKE";
	//                                                                          //
	_j=0; _k=0;
	Other_BLACK_BGR = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "BACKGROUND COLOR BLACK ONLY";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "FOR USERS WITH A GRAPHICAL ISSUE THAT CAUSES BLACK TILE ARTIFACTS IN THE BACKGROUND";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": FOR USERS WITH A GRAPHICAL ISSUE THAT CAUSES BLACK TILE ARTIFACTS IN THE BACKGROUND";
	//                                                                          //
	_j=0; _k=0;
	Other_STAB_FRENZY = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "STAB FRENZY";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": HOLD ATTACK TO DO A FRENZY OF STABS"; // `STR_State+"01"+STR_Text` is whatever state word is used for the feature enabled
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE SWORD ITEM IS REQUIRED FOR THIS SKILL "+string(val(dm_options[?_dk2+STR_Option+STR_Text]));
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_Option+STR_Text]))+" IS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "WITH THIS TURNED ON, HOLD ATTACK TO DO A FRENZY OF STABS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "HOLD ATTACK TO DO A FRENZY OF STABS WITH THIS TURNED ON";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": NO ACTION";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": HOLD ATTACK TO DO A FRENZY OF STABS";
	//                                                                          //
	_j=0; _k=0;
	Other_ANARKHYA_OW = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "ALTERNATE OVERWORLD GRAPHICS";
	//dm_options[?_dk2+STR_Option+STR_Text]              = "DETAILED OVERWORLD GRAPHICS";
	//dm_options[?_dk2+STR_Option+STR_Text]              = "OVERWORLD BY: ANARKHYA, WYNG";
	//dm_options[?_dk2+STR_Option+STR_Text]              = "OVERWORLD GRAPHICS BY: ANARKHYA, WYNG";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "USE CUSTOM DETAILED GRAPHICS FOR THE OVERWORLD";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE OVERWORLD WILL USE CUSTOM DETAILED GRAPHICS";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ARTWORK BY: ANARKHYA, WYNG";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": NORMAL OVERWORLD GRAPHICS";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": OVERWORLD WILL USE GRAPHICS BY ANARKHYA AND WYNG";
	//                                                                          //
	_j=0; _k=0;
	Other_HP_BEEP = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "LOW HP BEEPING";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THE BEEPING SOUND WHEN HP IS LOW";
	//                                                                          //
	_j=0; _k=0;
	Other_HALLOWEEN1 = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "IT'S HALLOWEEN?";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "NO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "YES";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "THIS MAY BE SLIGHTLY SPOOKY";
	// CHRISTMAS: no content yet — uncomment when assets are ready
	/*
	//                                                                          //
	_j=0; _k=0;
	Other_CHRISTMAS1 = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "IT'S CHRISTMAS?";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "NO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "YES";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "'TIS THE SEASON";
	*/
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": NORMAL";
	//dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": IT'S HALLOWEEN!";
	//                                                                          //
	/*
	_j=0; _k=0;
	Other_SHOW_ACTIVE_SPELLS = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "SHOW ACTIVE SPELLS";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "NO";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "YES";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"00"+STR_Text]))+": ACTIVE SPELLS WILL SHOW AS RED";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = string(val(dm_options[?_dk2+STR_State+"01"+STR_Text]))+": ACTIVE SPELLS WILL BE THEIR NORMAL COLOR";
	//                                                                          //
	*/

	/*
	_j=0; _k=0;
	Other_SCENE_COLORS_EDITOR = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "EDIT ROOM COLORS";
	//dm_options[?_dk2+STR_Option+STR_Text]              = "EDIT SCENE COLORS";
	//dm_options[?_dk2+STR_Option+STR_Text]              = "OPEN COLOR EDITOR";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "OPEN A TOOL THAT ALLOWS YOU TO EDIT THIS ROOM'S COLORS";
	//                                                                          //
	_j=0; _k=0;
	Other_BGR_COLOR_EDITOR = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "EDIT BACKGROUND COLOR";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "OPEN A TOOL THAT ALLOWS YOU TO EDIT THIS ROOM'S BACKGROUND COLOR";
	//                                                                          //
	*/
	_j=0; _k=0;
	Other_DOUBLE_JUMP = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "FEATHER ITEM(DOUBLE JUMP)";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "OFF";
	dm_options[?_dk2+STR_State+hex_str(_j++)+STR_Text] = "ON";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "TURNING THIS ON GIVES THE PLAYER DOUBLE JUMP.";
	//                                                                          //
	_j=0; _k=0;
	Other_GEE = ++_i; // GEE: Graphics Effects Editor
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "GRAPHICS EFFECTS EDITOR";
	//dm_options[?_dk2+STR_Option+STR_Text]              = "OPEN GRAPHICS EFFECTS EDITOR";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "ADJUST BRIGHTNESS, SATURATION, BLOOM, BLUR, SCANLINES";
	//                                                                          //
	_j=0; _k=0;
	Other_BACK = ++_i;
	_dk2 = _dk0+hex_str(_i);
	dm_options[?_dk2+STR_Font]                         = FONT2;
	dm_options[?_dk2+STR_Option+STR_Text]              = "BACK";
	dm_options[?_dk2+STR_Description+hex_str(_k++)]    = "RETURN TO MAIN MENU";
	//                                                                          //

	OptionsMenu_Create_1(_dk0, _i+1);
	Other_cursor = 0;








	// -------------------------------------------------------------
	// -------------------------------------------------------------
	// -------------------------------------------------------------
	YOFF_HEAD = 1;
	YOFF_OPTN = YOFF_HEAD + 3; // 1st option y


	// CURS: CURSor
	XOFF_CURS = 1; // tile units
	//XOFF_CURS = 2; // tile units
	XOFF_TEXT  = XOFF_CURS + 1; // tile units
	XOFF_TEXT1 = $10; // tile units




	var _option_text_len_max   = 1;
	var _option_text_width_max = 1;

	for(_i=0; _i<MainOption_COUNT; _i++)
	{
	    _len  = string_length(MainOptions_dg[#_i,0]);
	    _font = MainOptions_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}

	for(_i=0; _i<InputConfigOption_COUNT; _i++)
	{
	    _len  = string_length(dg_InputConfigOptions[#_i,0]);
	    _font = dg_InputConfigOptions[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}

	for(_i=0; _i<DevTools.COUNT; _i++)
	{
	    _len  = string_length(DevTools_dg[#_i,0]);
	    _font = DevTools_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}

	// DEV TOOLS sub-folder grids (so the menu window is wide enough for their labels).
	for(_i=0; _i<Overlays.COUNT; _i++)
	{
	    _len  = string_length(Overlays_dg[#_i,0]);
	    _font = Overlays_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}
	for(_i=0; _i<Cheats.COUNT; _i++)
	{
	    _len  = string_length(Cheats_dg[#_i,0]);
	    _font = Cheats_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}
	for(_i=0; _i<ClrTools.COUNT; _i++)
	{
	    _len  = string_length(Color_dg[#_i,0]);
	    _font = Color_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}
	for(_i=0; _i<TestCap.COUNT; _i++)
	{
	    _len  = string_length(TestCap_dg[#_i,0]);
	    _font = TestCap_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}
	for(_i=0; _i<Sweeps.COUNT; _i++)
	{
	    _len  = string_length(Sweeps_dg[#_i,0]);
	    _font = Sweeps_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}
	for(_i=0; _i<MiscTools.COUNT; _i++)
	{
	    _len  = string_length(Misc_dg[#_i,0]);
	    _font = Misc_dg[#_i,1];
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}

	_dk0 = "Rando";
	for(_i=val(dm_options[?_dk0+STR_Count])-1; _i>=0; _i--)
	{
	    _len  = string_length(val(dm_options[?_dk0+hex_str(_i)+STR_Option+STR_Text],"0"));
	    _font =               val(dm_options[?_dk0+hex_str(_i)+STR_Font], FONT2);
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}

	_dk0 = "Other";
	for(_i=val(dm_options[?_dk0+STR_Count])-1; _i>=0; _i--)
	{
	    _len  = string_length(val(dm_options[?_dk0+hex_str(_i)+STR_Option+STR_Text],"0"));
	    _font =               val(dm_options[?_dk0+hex_str(_i)+STR_Font], FONT2);
	    _option_text_len_max   = max(_option_text_len_max, _len);
	    _option_text_width_max = max(_option_text_width_max, sprite_get_width(_font)*_len);
	}

	//OPTION_STATE_TEXT_XOFF = (_option_text_len_max+1) * _size;
	OPTION_TEXT_WIDTH_MAX  =  _option_text_width_max;








	// ------------------------------------------------------------
	Window_W  = (g.GUI_WIN_CLMS2+2)<<3; // g.GUI_WIN_CLMS2 = 24
	//Window_W  = g.GUI_WIN_CLMS2<<3; // g.GUI_WIN_CLMS2 = 24
	Window_H  = viewH();
	//Window_H -= $1<<3;
	//Window_H  = viewH() - ($1<<3) - viewYT_OFF;
	Window_H  = (Window_H>>3)<<3;

	CLMS = Window_W>>3;
	ROWS = Window_H>>3;
	// 8 pixel width/height
	//CLMS = g.GUI_WIN_CLMS2; // g.GUI_WIN_CLMS2 = 24
	//ROWS = g.PAUSE_MENU.ROWS_WIN_DEF; // 8p tall

	viewYT_OFF = ((viewH()>>3)<<3) - Window_H;
	//viewYT_OFF = (viewH()-($1<<3)) - Window_H;




	Main_CLMS        = OPTION_TEXT_WIDTH_MAX>>3;
	Main_CLMS       += $A; // padding between option text and option state text
	Main_CLMS        = max(CLMS+$A, Main_CLMS);
	InputConfig_CLMS = CLMS+$3;
	//draw_clms_COUNT  = Main_CLMS;
	//draw_clms_COUNT  = CLMS+$3;
	//draw_clms_max    = draw_clms_COUNT;
	draw_clms_count  = Main_CLMS;
	//draw_clms_count  = draw_clms_COUNT;

	Main_ROWS = ROWS;
	/*
	if (viewYT_OFF+(Main_ROWS<<3) >= viewH())
	{
	    _val  = viewH()-$8;
	    _val += viewYT_OFF&$7;
	    _val -= viewYT_OFF;
	    Main_ROWS = _val>>3;
	    Main_ROWS++;
	}
	*/

	//Main_ROWS =  MainOption_COUNT<<1;
	//Main_ROWS = (MainOption_COUNT<<1) + $05;


	InputConfig_ROWS = (InputConfigOption_COUNT<<1) + $06;
	if (viewYT_OFF+(InputConfig_ROWS<<3) >= viewH())
	{
	    _val  = viewH() - $8;
	    _val += viewYT_OFF&$7;
	    _val -= viewYT_OFF;
	    InputConfig_ROWS = _val>>3;
	    InputConfig_ROWS++;
	}


	draw_rows_count = 0;
	draw_rows_max   = 0;


	var _PAD = $8;
	ScrollArea_Y_MIN  = $8; // frame
	ScrollArea_Y_MIN += sprite_get_height(FONT1); // menu title
	ScrollArea_Y_MIN += _PAD; // title padding

	ScrollArea_Y_MAX  = Window_H;
	ScrollArea_Y_MAX -= $8; // frame
	ScrollArea_Y_MAX -= _PAD; // frame padding

	ScrollArea_H = ScrollArea_Y_MAX-ScrollArea_Y_MIN;


	ANIM_FRAMES_DEF = g.PAUSE_MENU.Window_ROWS_DEF>>1; // 11
	anim_frame      = 0;


	BackgroundFlash_W = $18;
	BackgroundFlash_H = $08;




	if (DEV)
	{
	    show_debug_message("OptionsMenu_Create() END. "+string(current_time-_START_TIME));
	    show_debug_message("");
	}







}
