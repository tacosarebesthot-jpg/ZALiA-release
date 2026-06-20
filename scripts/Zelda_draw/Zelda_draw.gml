/// @description  Zelda_draw()
function Zelda_draw() {


	if(!can_draw_self) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


	// Draw "?" over head of NPC that has an undescovered hint
	if (global.RandoHints_enabled 
	&&  RandoHint_hint_num )
	{
	    draw_text_(x-4, yt+RandoHint_ytoff, "?");
	}


	GO_draw_sprite(sprite, palidx);







}
