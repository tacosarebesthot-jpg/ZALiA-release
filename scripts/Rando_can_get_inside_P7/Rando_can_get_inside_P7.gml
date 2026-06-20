/// @description  Rando_can_get_inside_P7()
function Rando_can_get_inside_P7() {


	if (Rando_is_qual_location(val(dm_save_data[?STR_Dungeon+STR_Rando+STR_Great_Palace+"A"], STR_Great_Palace)))
	{   // Place all crystals to dispell barrier
	    if (Rando_can_reach_CrystalHolder(STR_Parapa_Palace) 
	    &&  Rando_can_reach_CrystalHolder(STR_Midoro_Palace) 
	    &&  Rando_can_reach_CrystalHolder(STR_Island_Palace) 
	    &&  Rando_can_reach_CrystalHolder(STR_Maze_Island_Palace) 
	    &&  Rando_can_reach_CrystalHolder(STR_Palace_On_The_Sea) 
	    &&  Rando_can_reach_CrystalHolder(STR_Three_Eye_Rock_Palace) )
	    {
	        return true;
	    }
	}


	return false;







}
