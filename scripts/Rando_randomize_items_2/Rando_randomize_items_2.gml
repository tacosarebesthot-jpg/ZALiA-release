/// @description  Rando_randomize_items_2(hp pieces to place, mp pieces to place)
/// @param hp pieces to place
/// @param  mp pieces to place
function Rando_randomize_items_2() {


	var _COUNT_HP = argument[0];
	var _COUNT_MP = argument[1];

	var _i,_j,_k,_m, _idx, _val, _count, _qual;
	var _type, _item_id, _item_num, _loc_id, _loc_num;
	var _rm_name, _town_name, _dungeon_name;
	var _dl_remaining_items = ds_list_create();
	ds_list_copy(_dl_remaining_items,dl_ItemPool_C);


	//var _EXTRA_CONTAINER_COUNT = f.CONT_PIECE_PER * 2;
	for(_i=0; _i<2; _i++)
	{
	    if (_i)
	    {
	        _type = STR_MAGIC;
	        _count = _COUNT_MP;
	    }
	    else
	    {
	        _type = STR_HEART;
	        _count = _COUNT_HP;
	    }
    
	    for(_j=0; _j<_count; _j++)
	    {
	        if(!ds_list_size(dl_locations_remaining) 
	        || !ds_list_size(dl_ItemPool_C) )
	        {
	            _i=2;
	            break;//_j
	        }
        
	               ds_list_copy(_dl_remaining_items,dl_ItemPool_C);
	        for(_k=ds_list_size(_dl_remaining_items)-1; _k>=0; _k--)
	        {
	            _item_id = _dl_remaining_items[|_k];
            
	            if (string_pos(_type,_item_id))
	            {
	                ds_list_clear(dl_loc_num_options);
	                for(_m=ds_list_size(dl_locations_remaining)-1; _m>=0; _m--)
	                {
	                    _loc_num =      dl_locations_remaining[|_m];
	                    _loc_id  = dm_LOCATIONS[?hex_str(_loc_num)+STR_Location+STR_ID];
	                    _val     = dm_LOCATIONS[?hex_str(_loc_num)+STR_Category];
	                    if(!is_undefined(_loc_id) 
	                    && !is_undefined(_val) )
	                    {
	                        _rm_name = val(dm_LOCATIONS[?hex_str(_loc_num)+STR_Rm+STR_Name], "undefined");
	                        //LocCatID_West01,LocCatID_West02,LocCatID_DMtn01,LocCatID_NIsl01,LocCatID_RMtn01,
	                        //LocCatID_Nabo01,LocCatID_Daru01,LocCatID_Kasu01,LocCatID_Maze01,
	                        //LocCatID_Dngn01,LocCatID_Town01,
                        
	                        _qual = false;
	                        if (isVal(_val, LocCatID_West01,LocCatID_West02))
	                        //if (isVal(_val, LocCatID_West01,LocCatID_West02,LocCatID_NIsl01,LocCatID_RMtn01))
	                        {
	                            _qual = true;
	                        }
	                        else if (_val==LocCatID_Town01)
	                        {
	                            _town_name = g.dm_rm[?_rm_name+STR_Town+STR_Name];
	                            if(!is_undefined(_town_name))
	                            {
	                                if (TownLocations_WILL_RANDOMIZE) _town_name = val(dm_save_data[?STR_Town+STR_Rando+_town_name+"A"],_town_name);
	                                //dm_save_data[?STR_Town+STR_Rando+_town_name2+"A"] = _town_name1; // "A": Get what the overworld town is for _town_name2
	                                //dm_save_data[?STR_Town+STR_Rando+_town_name1+"B"] = _town_name2; // "B": Get what town inhabits the overworld town of _town_name1
	                                _qual = isVal(_town_name,STR_Rauru,STR_Ruto,STR_Saria);
	                            }
	                        }
	                        else if (_val==LocCatID_Dngn01)
	                        {
	                            _dungeon_name = g.dm_rm[?_rm_name+STR_Dungeon+STR_Name];
	                            if(!is_undefined(_dungeon_name))
	                            {
	                                if (DungeonLocations_WILL_RANDOMIZE) _dungeon_name = val(dm_save_data[?STR_Dungeon+STR_Rando+_dungeon_name+"A"],_dungeon_name);
	                                //dm_save_data[?STR_Dungeon+STR_Rando+_dungeon_name2+"A"] = _dungeon_name1; // _dungeon_name2+"A": Get overworld dungeon containing _dungeon_name2
	                                //dm_save_data[?STR_Dungeon+STR_Rando+_dungeon_name1+"B"] = _dungeon_name2; // _dungeon_name1+"B": Get dungeon inhabiting overworld dungeon _dungeon_name1
	                                _qual = isVal(_dungeon_name,STR_Parapa_Palace,STR_Midoro_Palace);
	                            }
	                        }
                        
	                        if (_qual) _qual = Rando_is_qual_location(string(_loc_id), _item_id);
	                        if (_qual) ds_list_add(dl_loc_num_options,_loc_num);
	                    }
	                }//for(_m
                
                
	                if (ds_list_size(   dl_loc_num_options))
	                {
	                    ds_list_shuffle(dl_loc_num_options);
	                    _loc_num =      dl_loc_num_options[|0];
                    
	                    if (Rando_set_data_1a(_loc_num,_item_id)) // if item got placed
	                    {
	                            _idx =    ds_list_find_index(dl_ItemPool_C,_item_id);
	                        if (_idx!=-1) ds_list_delete(    dl_ItemPool_C,_idx);
	                            _idx =    ds_list_find_index(dl_locations_remaining,_loc_num);
	                        if (_idx!=-1) ds_list_delete(    dl_locations_remaining,_idx);
                        
	                        if (DEBUG){
	                        _rm_name  = val(dm_LOCATIONS[?hex_str(_loc_num)+STR_Rm+STR_Name], "undefined");
	                        _item_num = val(dm_LOCATIONS[?hex_str(_loc_num)+STR_Rm+STR_Location+STR_Num]);
	                        _loc_id   = _rm_name+hex_str(_item_num);
	                        if(!Rando_is_qual_location(_loc_id,_item_id)) sdm("Rando_is_qual_location() THINKS YOU CANT GET TO:  "+_loc_id+" FOR ITEM "+_item_id);
	                        }
                        
	                        break;//_k
	                    }
	                }
	            }
	        }//for(_k
	    }//for(_j
	}//for(_i




	ds_list_destroy(_dl_remaining_items); _dl_remaining_items=undefined;







}
