/// @description  sbc(num1, num2, *carry)
/// @param num1
/// @param  num2
/// @param  *carry
function sbc() {

	// Simulate 6502 SBC(SUBTRACT WITH CARRY)


	argument[0] &= $FF;
	argument[1] &= $FF;
	argument[1] ^= $FF;

	if (argument_count>2)
	{   return (argument[0]+argument[1] + (argument[2]>0)) &$FF;  }
	    return (argument[0]+argument[1])                   &$FF;
	// 







}
