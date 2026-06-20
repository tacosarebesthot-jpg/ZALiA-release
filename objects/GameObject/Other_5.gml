//sdm("GameObject_Room End_1. "+object_get_name(object_index));

if(!persistent) GO_instance_end();


if (variable_instance_exists(id,"scr_room_end") 
&& !is_undefined(                scr_room_end) 
&&  is_callable( scr_room_end) )
{   script_execute(              scr_room_end);  }





