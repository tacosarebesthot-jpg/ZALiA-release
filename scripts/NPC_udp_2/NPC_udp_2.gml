/// @description  NPC_udp_2()
function NPC_udp_2() {


	if (RandoHint_hint_num 
	&& !is_undefined(g.dm_RandoHintsRecorder[?STR_Hint+hex_str(RandoHint_hint_num)+STR_Dialogue]) )
	{
	    RandoHint_hint_num = 0; // 0: tells draw not to draw the question mark
	}







}
