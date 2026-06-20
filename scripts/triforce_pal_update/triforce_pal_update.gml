/// @description  triforce_pal_update()
function triforce_pal_update() {


	var _POS  = get_pal_pos(p.triforce_pi);
	    _POS += p.PI_LIT1;
	var _PAL  = p.dg_pal_seq[#0,(g.counter1>>2)&$3];
	change_pal(strReplaceAt(p.pal_rm_new, _POS, string_length(_PAL), _PAL));







}
