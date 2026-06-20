/// @description  GO_init_palidx(palette index, *palette permut num)
/// @param palette index
/// @param  *palette permut num
function GO_init_palidx() {


	palidx_def = argument[0];

	// permutation (0-5)
	if (argument_count>1) palidx_permut = argument[1];
	//else                  palidx_permut = 0;

	switch(palidx_permut){
	case 1:{palidx_def=add_pi_permut(palidx_def,"WBRGYKMC",object_get_name(id)+" permut "+"WBRGYKMC"); break;} // hsm
	case 2:{palidx_def=add_pi_permut(palidx_def,"RWBGMYKC",object_get_name(id)+" permut "+"RWBGMYKC"); break;} // mhs
	case 3:{palidx_def=add_pi_permut(palidx_def,"RBWGMKYC",object_get_name(id)+" permut "+"RBWGMKYC"); break;} // msh
	case 4:{palidx_def=add_pi_permut(palidx_def,"BWRGKYMC",object_get_name(id)+" permut "+"BWRGKYMC"); break;} // shm
	case 5:{palidx_def=add_pi_permut(palidx_def,"BRWGKMYC",object_get_name(id)+" permut "+"BRWGKMYC"); break;} // smh
	}

	palidx_base = palidx_def;
	palidx      = palidx_base;







}
