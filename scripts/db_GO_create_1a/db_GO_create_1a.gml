/// @description  db_GO_create_1a(id)
/// @param id
function db_GO_create_1a(argument0) {


	with(argument0)
	{
	    show_debug_message("");
	    var _str;
	    _str  = object_get_name(object_index) + " ver $" + hex_str(ver);
	    _str += " created. ";
	    if(!is_undefined(dk_spawn)) _str += dk_spawn+", ";
	    _str += "xl $" + hex_str(xl) + " yt $" + hex_str(yt) + ", ";
	    _str += "update_idx $" + hex_str(update_idx) + ", " + "spawn_idx " + string(spawn_idx) + ", ";
    
	    if (is_ancestor(object_index,Item))
	    {
	        _str += "ITEM_BIT $"+hex_str(ITEM_BIT)+", ";
	    }
    
    
	    show_debug_message(_str);
    
    
	    if (is_ancestor(object_index,GOB1))
	    {
	        var _i, _val, _gob;
	            _str = "g.go_mgr.dl_gob1:  ";
	        var          _COUNT = ds_list_size(g.go_mgr.dl_gob1);
	        for(_i=0; _i<_COUNT; _i++)
	        {
	            _gob = g.go_mgr.dl_gob1[|_i];
	            _val = !is_undefined(_gob) 
	                && true /* GMS2 port: was GMS1 id-validity idiom, threw "Malformed variable" */ 
	                && instance_exists(_gob) 
	                && _gob.state;
	            //_val = defined(_gob) && _gob && _gob.state;
	            _str += "[" + string(_val) + "] ";
	        }
        
	        show_debug_message(_str);
	    }
	}


	show_debug_message("");







}
