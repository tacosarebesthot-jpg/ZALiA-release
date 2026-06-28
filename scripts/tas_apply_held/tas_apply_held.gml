/// @description  tas_apply_held(_packed)
/// Called from inside Input_update2a; self = Input instance, so GP_*_held resolve to Input's vars.
function tas_apply_held(_packed)
{
	GP_Right_held      = (_packed & $01)  != 0;
	GP_Left_held       = (_packed & $02)  != 0;
	GP_Down_held       = (_packed & $04)  != 0;
	GP_Up_held         = (_packed & $08)  != 0;
	GP_Pause_held      = (_packed & $10)  != 0;
	GP_Magic_held      = (_packed & $20)  != 0;
	GP_Attack_held     = (_packed & $40)  != 0;
	GP_Jump_held       = (_packed & $80)  != 0;
	GP_Spell_Next_held = (_packed & $100) != 0;
	GP_Spell_Prev_held = (_packed & $200) != 0;
}
