/// @description  adjust_stat(hp difference, mp difference)
/// @param hp difference
/// @param  mp difference
function adjust_stat(argument0, argument1) {


	if (argument0!=0) f.hp = clamp(f.hp+argument0, 0,get_stat_max(STR_Heart));

	// ROCKET LEAGUE (round 11): NEED BOOST! on the edge where magic runs dry -- read the old
	// value BEFORE the clamp so "spent the last of it" is distinguishable from "already empty
	// and something tried to charge you anyway". 10 s throttle.
	var _rl_mp_was = f.mp;
	if (argument1!=0) f.mp = clamp(f.mp+argument1, 0,get_stat_max(STR_Magic));
	if (argument1<0 && _rl_mp_was>0 && f.mp==0
	&&  variable_global_exists("tw_rl") && global.tw_rl && current_time - global.tw_rl_boost_t > 10000)
	{   global.tw_rl_boost_t = current_time; tw_toast_push("NEED BOOST!", "", "warn");  }







}
