/// @description  NIAO_Room_End()
function NIAO_Room_End() {


	for(var _i=ds_list_size(g.dl_niao)-1; _i>=0; _i--)
	{
	    if (g.dl_niao[|_i])
	    {
	        with(g.dl_niao[|_i])
	        {
	            if(!is_undefined(  scr_room_end) 
	            &&  is_callable(   scr_room_end) ) 
	            {   script_execute(scr_room_end);  }
	        }
        
	        instance_destroy(g.dl_niao[|_i]);
	    }
    
	    g.dl_niao[|_i] = 0;
	}







}
