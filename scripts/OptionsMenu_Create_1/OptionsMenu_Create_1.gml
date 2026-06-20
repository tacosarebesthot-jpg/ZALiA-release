/// @description  OptionsMenu_Create_1(datakey, count)
/// @param datakey
/// @param  count
function OptionsMenu_Create_1(argument0, argument1) {


	var _i,_j, _dk, _text;


	dm_options[?argument0+STR_Count] = argument1;

	for(_i=0; _i<argument1; _i++)
	{
	    _dk = argument0+hex_str(_i);
	    _j = 0;
	    while (true)
	    {
	        _text = dm_options[?_dk+STR_State+hex_str(_j)+STR_Text];
	        if (is_undefined(_text)) break;//while (true)
	        dm_options[?_dk+STR_State+STR_Count] = ++_j;
	    }
    
	    _j = 0;
	    while (true)
	    {
	        _text = dm_options[?_dk+STR_Description+hex_str(_j)];
	        if (is_undefined(_text)) break;//while (true)
	        dm_options[?_dk+STR_Description+STR_Count] = ++_j;
	    }
	}







}
