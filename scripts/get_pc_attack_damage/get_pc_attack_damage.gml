/// @description  get_pc_attack_damage()
function get_pc_attack_damage() {


	// !rust (10-24 chat suggestion): the sword hits as `tw_rust_lvls` levels lower for the effect's
	// length. Only the damage lookup is lowered; f.level_atk, the HUD and the XP table are untouched,
	// so no level-up can misfire while it runs.
	var _lvl     = tw_pc_atk_level();
	var _damage  = global.pc.dl_ATTACK_DAMAGE[|_lvl];

	if (g.mod_PC_CUCCO_2    // Gives PC Cucco extra atk dmg
	&&  pc_is_cucco() )
	{
	    _damage += 1 + (_lvl>=4) + (_lvl>=6); // +1,2,3
	}


	return _damage;







}
