/// @description  NPC_0_update()
function NPC_0_update() {

	//  NPC_0 v1    Invisible
	//  NPC_0 v2    Town Sign
	//  NPC_0 v3    Mirror
	//  NPC_0 v4    Fountain
	//  NPC_0 v5    Stone Head


	// ------------------------------------------------------------------
	can_draw_self = true;
	//can_draw_self = object_index==NPC_0 && ver==2; // Town sign


	NPC_udp_2(); // update `RandoHint_hint_num`




	// ------------------------------------------------------------------
	if (is_talking)
	{
	    if (g.dialogue_source==id) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
	    is_talking = false;
    
	    // Mirror under table
	    if (object_index==NPC_0 
	    &&  ver==3 )
	    {
	        state = 0;
	    }
	}




	// ------------------------------------------------------------------
	// 9AC2: JSR 99B9
	NPC_update_2(); // collision, enter restore house, start dlg







}
