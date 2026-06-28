/// @description  NPC_draw()
function NPC_draw() {


	/*
	// Draw "?" over head of NPC that has an undescovered hint
	if (global.RandoHints_enabled 
	&&  RandoHint_hint_num )
	{
	    if (object_index==NPC_0 
	    ||  can_draw_self )
	    {
	        draw_text_(x-4, yt+RandoHint_ytoff, "?");
	    }
	}
	*/


	NPC_draw_door();




	// --------------------------------------------------------------------------------
	if(!can_draw_self) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// --------------------------------------------------------------------------------
	// Draw "?" over head of NPC that has an undescovered hint
	if (global.RandoHints_enabled
	&&  RandoHint_hint_num
	&&  is_undefined(g.dm_RandoHintsRecorder[?STR_Hint+hex_str(RandoHint_hint_num)+STR_Dialogue]) )
	{
	    draw_text_(x-4, yt+RandoHint_ytoff, "?");
	}




	// --------------------------------------------------------------------------------
	if (sprite_datakey==STR_Zant) // Bulblin wiseman
	{
	    if (g.counter1&($1<<3) 
	    ||  CastSpellSprite_timer )
	    {    var _WING_SPR = spr_Wing_1b_1;  } // b: down
	    else var _WING_SPR = spr_Wing_1a_1;    // a: up
	    pal_swap_set(global.palette_image, palidx);
	    draw_sprite_(_WING_SPR,0, drawX,drawY, -1,  1);
	    draw_sprite_(_WING_SPR,0, drawX,drawY, -1, -1);
	    GO_draw_sprite(sprite);
	    pal_swap_reset();
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}


	// --------------------------------------------------------------------------------
	if (object_index==NPC_0 
	&&  ver==2 ) // NPC_0,2: sign
	{
	    var _SPRITE = spr_Pole01Segment;
	    var _H = sprite_get_height(_SPRITE);
	    var _ROWS = max((hh>>3)-1, 1);
	    var _Y1  = drawY+hh_;   // yb(ground)
	        _Y1  = (_Y1>>3)<<3; // align w/ grid
	        _Y1 -= (_ROWS<<3);  // sign graphic yt
	        _Y1 += _H>>1;       // sign board yc
	    for(var _i=0; _i<_ROWS; _i++) draw_sprite_(_SPRITE,0, drawX,_Y1+(_H*_i), palidx);
	    draw_sprite_(spr_SignBoard01,0, drawX,_Y1, palidx);
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}


	// --------------------------------------------------------------------------------
	if (object_index==NPC_9 
	&&  ver==5 ) // NPC_9,5: Bagu's Bot
	{
	    Bot_draw();
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}




	// --------------------------------------------------------------------------------
	if (object_index==NPC_9 
	&&  ver==1 ) // NPC_9,1: Bagu
	{   // Draw Riverman portrait
	    var     _DEPTH = depth;
	    depth =  DEPTH_BG5+1;
	    draw_sprite_(spr_Riverman_portrait_1a_1,0, ((drawX>>3)<<3)+(6<<3), ((drawY>>3)<<3)-(3<<3)-4, global.PI_BGR4);
	    depth = _DEPTH;
	}




	GameObject_draw_1a(sprite, palidx);







}
