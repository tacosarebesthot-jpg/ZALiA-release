/// @description  ContinueSaveScreen_init()
function ContinueSaveScreen_init() {

	show_debug_message("ContinueSaveScreen_init(). start");


	var _i, _clms,_rows;


	                 _i=0;
	state_DELAY1   = _i++; // Only first couple frames draw solid black screen
	state_IDLE     = _i++; // Waiting for user input
	state_SELECTED = _i++; // Action of selection made
	state          = state_DELAY1;


	timer   = 0;
	counter = 0;


	READY_CUE            = $02;
	TITLE_SCREEN_CUE1    = $48;
	TITLE_SCREEN_CUE2    = $20;
	NEXT_LIFE_SCREEN_CUE = $08;


	SaveFlash_LIMIT = 8;
	SaveFlash_count = 0;
	if(global.DB0)show_debug_message("ContinueSaveScreen_init(). A");
	//SaveFlash_PAL   = build_pal(p.C_RED2,p.C_RED3,p.C_BLK1,p.C_BLK1,-2,-2,-2,-2);
	if(global.DB0)show_debug_message("ContinueSaveScreen_init(). B");
	//change_pal(strReplaceAt(p.pal_rm_curr, p.PAL_POS_BGR1, string_length(SaveFlash_PAL), SaveFlash_PAL));
	if(global.DB0)show_debug_message("ContinueSaveScreen_init(). C");



	Caution_srf = 0;
	Caution_dl_text = ds_list_create();
	ds_list_add(Caution_dl_text,"CAUTION");
	ds_list_add(Caution_dl_text,"TO AVOID DAMAGING GAME");
	ds_list_add(Caution_dl_text,"INFO  SAVED,  HOLD  IN");
	ds_list_add(Caution_dl_text,"RESET  BUTTON  AS  YOU");
	ds_list_add(Caution_dl_text,"TURN POWER OFF.");
	_clms = 0;
	for(_i=ds_list_size(Caution_dl_text)-1; _i>=0; _i--)
	{
	    _clms = max(_clms, string_length(Caution_dl_text[|_i]));
	}
	_clms += _clms&$1;

	Caution_dl_text[|0] = string_repeat(" ",(_clms>>1)-(string_length(Caution_dl_text[|0])>>1)) + Caution_dl_text[|0];

	_clms += $4;

	Caution_W  = _clms<<3;
	Caution_H  = ds_list_size(Caution_dl_text) + (ds_list_size(Caution_dl_text)-1);
	Caution_H += $4;
	Caution_H  = Caution_H<<3;
	if(global.DB0)show_debug_message("ContinueSaveScreen_init(). D");



	Options_dg = ds_grid_create(0,4);
	//                                              //
	//                                              //
	     ds_grid_resize(Options_dg, ds_grid_width(Options_dg)+1, ds_grid_height(Options_dg));
	_i = ds_grid_width( Options_dg)-1;
	Option_CONT = _i;
	Options_dg[#_i,0] = "CONTINUE";
	//                                              //
	//                                              //
	     ds_grid_resize(Options_dg, ds_grid_width(Options_dg)+1, ds_grid_height(Options_dg));
	_i = ds_grid_width( Options_dg)-1;
	Option_SAVE = _i;
	Options_dg[#_i,0] = "SAVE & QUIT";
	//                                              //
	//                                              //
	     ds_grid_resize(Options_dg, ds_grid_width(Options_dg)+1, ds_grid_height(Options_dg));
	_i = ds_grid_width( Options_dg)-1;
	Option_QUIT = _i;
	Options_dg[#_i,0] = "QUIT ONLY";
	//                                              //
	//                                              //

	Options_idx   = Option_CONT;
	Options_COUNT = ds_grid_width(Options_dg);
	if(global.DB0)show_debug_message("ContinueSaveScreen_init(). E");



	var _ROWS1 = $2;
	PAD1 = $02<<3;

	CLMS  = Caution_W>>3;

	ROWS  = Caution_H>>3;
	ROWS += Options_COUNT<<1;
	ROWS += _ROWS1; // pad between option text and warning

	Options_XL  = viewXC() - ($05<<3);
	Options_YT  = viewYC() - ((ROWS<<3)>>1);

	Caution_XL  = viewXC() - (Caution_W>>1);
	Caution_YT  = Options_YT;
	Caution_YT +=(Options_COUNT<<1)<<3;
	Caution_YT += _ROWS1<<3; // pad between option text and warning




	Cursor_SPRITE = spr_menu_bottle_icon;

	Cursor_XC  = Options_XL - ($01<<3);
	Cursor_XC += 4;
	Cursor_XC -= 1; // Text padding

	Cursor_YC  = Options_YT + 4;
	Cursor_yc  = Cursor_YC;
	Cursor_yc += Options_idx * PAD1;




	for(_i=0; _i<Options_COUNT; _i++)
	{
	    Options_dg[#_i,1] = Options_XL;
	    Options_dg[#_i,2] = Options_YT + (PAD1*_i);
	    Options_dg[#_i,3] = global.PI_GUI1;
	}


	show_debug_message("ContinueSaveScreen_init(). end");







}
