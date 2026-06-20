/// @description  Surface_Game_End()
function Surface_Game_End() {


	if (surface_exists(srf_app_paused_frame))
	{   surface_free(  srf_app_paused_frame);  }



	if (RoomPreview_VER)
	{
	    if (surface_exists(RoomPreview_surf))
	    {   surface_free(  RoomPreview_surf);  }
	}







}
