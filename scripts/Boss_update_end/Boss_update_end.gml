/// @description  Boss_update_end()
function Boss_update_end() {


	if (g.view_lock_boss 
	&&  pending_death 
	&& !stun_timer )
	{
	    despawn_all_goc();
    
	    aud_play_sound(get_audio_theme_track(dk_StrikeEnemy));
	    audio_group_stop_all(audiogroup_mus);
	    Audio.can_play_mus_rm_body = false; // Prevent music until take key
	    Audio.can_play_boss_music  = false;
    
    
	    state = state_EXPLODE;
    
	    // Call the following AFTER changing state to 
	    // state_EXPLODE so timer won't get changed.
	    var _dl_gob1 = g.go_mgr.dl_gob1;
	    var _inst;
	    for(var _i=MAX_GOB1-1; _i>=0; _i--)
	    {
	        _inst = _dl_gob1[|_i];
	        if (!instance_exists(_inst)) continue;
	        with(_inst)
	        {
	            if (state==state_NORMAL)
	            {
	                damage_gob(id, max(hp,0), false);
	            }
	        }
	    }
    
	    with(Spawner)
	    {
	        if (state==state_NORMAL)
	        {
	            damage_gob(id, max(hp,0), false);
	        }
	    }
	}







}
