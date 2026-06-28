/// @description  obj_fairy_p2 :: Create -- co-op P2 floating fairy (MVP)

// Float just above P1's head if P1 exists, else wherever we were spawned.
if (instance_exists(global.pc))
{
	x = global.pc.x;
	y = global.pc.y - 16;
}

facing        = 1;  // last horizontal move dir (1 = right, -1 = left). Default right.
shoot_cooldown = 0; // frames remaining before the fairy can fire again
tank_cd        = 0; // frames remaining before TANK (shield P1) can fire again

depth = DEPTH_FLYER; // render above gameplay like a flyer
