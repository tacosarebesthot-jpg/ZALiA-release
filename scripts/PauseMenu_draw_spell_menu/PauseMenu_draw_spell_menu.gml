/// @description  PauseMenu_draw_spell_menu()
function PauseMenu_draw_spell_menu() {


	var _i, _x,_y;
	var _text, _spell_bit, _amount, _pi;


	if (g.mod_SHOW_MAGIC_REMAINING_NUM 
	&&  Window_vertical_draw_section_count )
	{
	    _spell_bit = -1;
	    _text = Head_TEXT;
	    _amount = f.mp>>1;
	    _x  = Window_xl0;
	    _y  = drawY;
	    _y -= 1; // micro adj
	    PauseMenu_draw_spell(_spell_bit,_text,_amount, _x,_y, PI_MENU1);
	}



	for(_i=0; _i<Window_vertical_draw_section_count-1; _i++) // Each section
	{
	    if (_i>=g.SPELL_COUNT) break;//_i
    
	                 _spell_bit = $1<<_i;
	    if!(f.spells&_spell_bit) continue;//_i
    
    
    
	    if (_spell_bit==SPL_FARY 
	    &&  g.CuccoSpell2_Acquired 
	    &&  g.CuccoSpell2_Option )
	    {    _text = SPELL_TEXT_CUCCO;  }
	    else _text = dl_spell_str[|_i];
    
    
	    _amount = get_spell_cost(_spell_bit);
	    _x  = Window_xl0;
	    _y  = drawY + (_i<<4);
	    _y -= 1; // gives 1 extra pixel pad for 9th spell
    
    
	    if (g.mod_IndicateSpellUnaffordable 
	    &&  f.mp-_amount<0 )
	    {
	        _pi = global.spell_unaffordable_pi;
	    }
	    else if (g.mod_IndicateSpellActive 
	         &&  g.spells_active&_spell_bit )
	    {
	        _pi = global.spell_futile_pi;
	    }
	    else
	    {
	        _pi = PI_MENU1;
	    }
    
	    _amount = _amount>>1;
	    PauseMenu_draw_spell(_spell_bit,_text,_amount, _x,_y, _pi);
	}







}
